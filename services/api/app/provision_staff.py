"""Provision staff from a trusted operator terminal, never from public signup."""

import argparse
from datetime import datetime, timezone
import os
from pathlib import Path
import re
import secrets

from firebase_admin import auth, firestore

from .firebase import firebase_app


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--email", required=True)
    parser.add_argument(
        "--role",
        required=True,
        choices=["administrator", "claims_officer", "supervisor"],
    )
    args = parser.parse_args()
    email = args.email.strip().lower()
    if not re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", email):
        parser.error("Enter a valid email.")
    app = firebase_app()
    password = None
    try:
        user = auth.get_user_by_email(email, app=app)
    except auth.UserNotFoundError:
        password = secrets.token_urlsafe(24)
        user = auth.create_user(
            email=email,
            password=password,
            display_name=args.role.replace("_", " ").title(),
            app=app,
        )
    db = firestore.client(app)
    ref = db.collection("profiles").document(user.uid)

    @firestore.transactional
    def assign(transaction):
        snapshot = ref.get(transaction=transaction)
        if snapshot.exists:
            transaction.update(ref, {"role": args.role})
        else:
            transaction.set(
                ref,
                {
                    "id": user.uid,
                    "email": email,
                    "display_name": user.display_name
                    or args.role.replace("_", " ").title(),
                    "role": args.role,
                    "status": "active",
                    "created_at": datetime.now(timezone.utc).isoformat(),
                },
            )

    assign(db.transaction())
    if password:
        private_dir = (
            Path(os.getenv("LOCALAPPDATA", str(Path.home() / ".local/share")))
            / "claimelens"
        )
        private_dir.mkdir(parents=True, exist_ok=True)
        output = private_dir / "staff-first-login.txt"
        descriptor = os.open(output, os.O_WRONLY | os.O_CREAT | os.O_APPEND, 0o600)
        with os.fdopen(descriptor, "a", encoding="utf-8") as stream:
            stream.write(
                f"Account: {email}\nRole: {args.role}\nInitial password: {password}\n\n"
            )
        print(f"Created {email} as {args.role}. Initial password saved to {output}")
    else:
        print(
            f"Existing account {email} assigned {args.role}; its password was retained."
        )


if __name__ == "__main__":
    main()
