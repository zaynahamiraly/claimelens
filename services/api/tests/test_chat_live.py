"""Opt-in support-chat privacy, attribution, retry, pagination and concurrency."""

import os
import uuid
from concurrent.futures import ThreadPoolExecutor
import pytest

pytestmark = pytest.mark.skipif(
    os.getenv("RUN_FIREBASE_LIVE_TESTS") != "1", reason="Live Firebase opt-in required"
)


def test_live_shared_support_chat():
    from fastapi.testclient import TestClient
    from firebase_admin import auth, firestore
    from google.cloud.firestore_v1.base_query import FieldFilter
    from app.firebase import firebase_app
    from app.main import app

    fb = firebase_app()
    db = firestore.client(fb)
    users, threads, headers = [], [], {}
    password = "Synthetic-chat-check-2026!"
    try:
        with TestClient(app) as client:
            for role in [
                "owner",
                "other",
                "claims_officer",
                "supervisor",
                "administrator",
                "finance",
            ]:
                account = auth.create_user(
                    email=f"claimlens-chat-{uuid.uuid4().hex}@example.com",
                    password=password,
                    display_name=f"QA {role}",
                    app=fb,
                )
                users.append(account)
                response = client.post(
                    "/api/v1/auth/login",
                    json={"email": account.email, "password": password},
                )
                assert response.status_code == 200, response.text
                headers[role] = {
                    "Authorization": "Bearer " + response.json()["access_token"]
                }
                db.collection("profiles").document(account.uid).update(
                    {"role": "client" if role in {"owner", "other"} else role}
                )
            for name in ["owner", "other"]:
                response = client.post(
                    "/api/v1/chat/conversations",
                    headers=headers[name],
                    json={"subject": "Synthetic claim question"},
                )
                assert response.status_code == 201, response.text
                threads.append(response.json()["id"])
            thread, stranger = threads
            path = f"/api/v1/chat/conversations/{thread}"
            assert client.get("/api/v1/chat/conversations").status_code == 401
            assert (
                client.post(
                    "/api/v1/chat/conversations",
                    headers=headers["administrator"],
                    json={},
                ).status_code
                == 403
            )
            assert (
                client.get(
                    "/api/v1/chat/conversations", headers=headers["finance"]
                ).status_code
                == 403
            )
            assert (
                client.get(path + "/messages", headers=headers["other"]).status_code
                == 404
            )
            assert (
                client.post(
                    path + "/read",
                    headers=headers["other"],
                    json={"through_sequence": 0},
                ).status_code
                == 404
            )

            def send(role, text, key=None, **extra):
                return client.post(
                    path + "/messages",
                    headers=headers[role],
                    json={
                        "text": text,
                        "client_message_id": key or uuid.uuid4().hex,
                        **extra,
                    },
                )

            assert send("other", "Not my chat").status_code == 404
            assert send("finance", "Restricted").status_code == 403
            assert send("owner", "  ").status_code == 422
            key = uuid.uuid4().hex
            response = send(
                "owner",
                "Which receipt should I attach?",
                key,
                sender_role="administrator",
                sender_name="Forged",
            )
            assert response.status_code == 201, response.text
            first = response.json()
            assert first["client_message_id"] == key
            assert (
                first["sender_role"] == "client" and first["sender_name"] == "QA owner"
            )
            assert send("owner", first["text"], key).json()["id"] == first["id"]
            assert send("owner", "Changed text with old key", key).status_code == 409
            for role in ["claims_officer", "supervisor", "administrator"]:
                result = client.get(path + "/messages", headers=headers[role]).json()
                assert result["messages"][0]["text"] == first["text"]
                assert result["conversation"]["unread_count"] == 1
            assert (
                client.post(
                    path + "/read",
                    headers=headers["claims_officer"],
                    json={"through_sequence": 1},
                ).status_code
                == 200
            )
            assert (
                client.get(
                    path + "/messages", headers=headers["claims_officer"]
                ).json()["conversation"]["unread_count"]
                == 0
            )
            assert (
                client.get(path + "/messages", headers=headers["supervisor"]).json()[
                    "conversation"
                ]["unread_count"]
                == 1
            )
            assert (
                send(
                    "claims_officer", "Please attach the itemized receipt."
                ).status_code
                == 201
            )
            assert (
                send(
                    "supervisor", "We can clarify the claim requirements here."
                ).status_code
                == 201
            )
            owner = client.get(path + "/messages", headers=headers["owner"]).json()
            assert owner["conversation"]["unread_count"] == 2
            assert [m["sequence"] for m in owner["messages"]] == [1, 2, 3]
            assert (
                client.post(
                    path + "/read",
                    headers=headers["owner"],
                    json={"through_sequence": 4},
                ).status_code
                == 422
            )
            assert (
                client.post(
                    path + "/read",
                    headers=headers["owner"],
                    json={"through_sequence": 2},
                ).status_code
                == 200
            )
            assert (
                client.post(
                    path + "/read",
                    headers=headers["owner"],
                    json={"through_sequence": 1},
                ).status_code
                == 200
            )
            assert (
                client.get(path + "/messages", headers=headers["owner"]).json()[
                    "conversation"
                ]["unread_count"]
                == 1
            )
            latest = client.get(
                path + "/messages?limit=2", headers=headers["owner"]
            ).json()
            assert latest["has_more"] and [
                m["sequence"] for m in latest["messages"]
            ] == [2, 3]
            older = client.get(
                path + "/messages?before=2", headers=headers["owner"]
            ).json()
            assert [m["sequence"] for m in older["messages"]] == [1]
            newer = client.get(
                path + "/messages?after=1&limit=1", headers=headers["owner"]
            ).json()
            assert newer["has_more"] and newer["messages"][0]["sequence"] == 2
            assert (
                client.get(
                    path + "/messages?after=999999999999", headers=headers["owner"]
                ).json()["messages"]
                == []
            )
            inbox = client.get(
                "/api/v1/chat/conversations?limit=1", headers=headers["administrator"]
            ).json()
            assert inbox["next_before"] is not None
            second_page = client.get(
                "/api/v1/chat/conversations",
                headers=headers["administrator"],
                params={"limit": 1, "before": inbox["next_before"]},
            )
            assert second_page.status_code == 200, second_page.text
            assert (
                second_page.json()["conversations"][0]["id"]
                != inbox["conversations"][0]["id"]
            )
            client_inbox = client.get(
                "/api/v1/chat/conversations", headers=headers["other"]
            ).json()
            assert [r["id"] for r in client_inbox["conversations"]] == [stranger]
            # Transaction retries must allocate unique, ordered message numbers.
            with ThreadPoolExecutor(max_workers=3) as pool:
                responses = list(
                    pool.map(
                        lambda n: send("owner", f"Synthetic concurrent message {n}"),
                        range(3),
                    )
                )
            assert all(r.status_code == 201 for r in responses), [
                r.text for r in responses
            ]
            assert len({r.json()["sequence"] for r in responses}) == 3
            all_messages = client.get(
                path + "/messages", headers=headers["administrator"]
            ).json()["messages"]
            assert [m["sequence"] for m in all_messages] == list(range(1, 7))
            db.collection("profiles").document(users[0].uid).update(
                {"display_name": "QA Client Renamed"}
            )
            renamed = send("owner", "Synthetic profile update check")
            assert (
                renamed.status_code == 201
                and renamed.json()["sender_name"] == "QA Client Renamed"
            )
            assert (
                client.get(path + "/messages", headers=headers["administrator"]).json()[
                    "conversation"
                ]["client_name"]
                == "QA Client Renamed"
            )
            assert (
                client.get(path + "/messages", headers=headers["administrator"]).json()[
                    "messages"
                ][0]["sender_name"]
                == "QA owner"
            )
    finally:
        for identifier in threads:
            for collection in ["support_messages", "support_message_requests"]:
                for record in (
                    db.collection(collection)
                    .where(filter=FieldFilter("conversation_id", "==", identifier))
                    .stream()
                ):
                    record.reference.delete()
            for record in (
                db.collection("audit_events")
                .where(filter=FieldFilter("metadata.conversation_id", "==", identifier))
                .stream()
            ):
                record.reference.delete()
            db.collection("support_threads").document(identifier).delete()
        for account in users:
            db.collection("profiles").document(account.uid).delete()
            auth.delete_user(account.uid, app=fb)
