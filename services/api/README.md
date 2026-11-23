# claimelens API

Use 64-bit Python 3.12 with the pinned PaddleOCR runtime. The API uses Firebase
Authentication REST endpoints for email/password login and email actions, and
Firebase Admin for ID-token verification and Firestore. Uploaded files use private
local storage on the API computer so this setup requires no cloud billing.

## Local setup

```powershell
Set-Location services/api
py -3.12 -m venv .venv-paddle
.venv-paddle/Scripts/python -m pip install -r requirements-dev.txt
Copy-Item .env.example .env
```

Do not overwrite an existing configured `.env`. Set `FIREBASE_API_KEY` from the
Firebase app configuration and `GOOGLE_APPLICATION_CREDENTIALS` to an absolute
path to a server service-account JSON file stored outside the repository. The
service account needs Firestore data access, Firebase Authentication administration,
on the Firebase project. Production should use workload identity
or application-default credentials instead of distributing keys.

Set `DOCUMENT_STORAGE_PATH` to a private persistent folder outside the repository.
It defaults to the user's local application-data folder under `claimelens/documents`.
`PUBLIC_API_URL` defaults to `http://127.0.0.1:8000`, which works on a phone using
USB port forwarding. In production set it to the API's HTTPS origin and back up
the document folder. Losing that folder loses uploaded files; Firestore retains
only their metadata. Local files stay on the API computer and are not synced to
Firebase. Keep the `.signing-key` file private; it signs short-lived download links.

```powershell
.venv-paddle/Scripts/python -m app.serve
```

This command initializes PaddleOCR before listening on port 8000. Models download
on first use and are reused from the PaddleX cache. It uses PP-OCRv5 mobile detection
and English recognition. `PADDLE_DEVICE=cpu` is the default. Digital PDF and DOCX
extraction use embedded text; images and scanned PDFs use PaddleOCR. A failed draft
can be opened from Claims and processed again with **Retry processing**.

Health: `http://127.0.0.1:8000/api/v1/health`. API contract: `/docs`.
Firebase profile status is checked on every protected request. Signup always creates
a client profile. Claims officers see assigned claims; supervisors and administrators
see operational claims. Clients see only their own records. Claim confirmation and
processing acquisition use Firestore transactions. Signed document URLs expire in
five minutes. The API serves files only through verified download links. Direct
client access to Firestore is denied by rules. No Firebase Storage subscription
or billing activation is needed for this development setup.

## Staff accounts

Public registration never assigns staff roles or overwrites an existing profile.
An authorized project operator can provision a staff account from the API directory:

```powershell
.venv-paddle/Scripts/python -m app.provision_staff --email staff@example.com --role claims_officer
```

Roles supported by this command are `administrator`, `claims_officer`, and
`supervisor`. It requires the server's Firebase Admin credentials. Existing
passwords and profile status are retained. New accounts receive generated initial
passwords saved to the operator's private local application-data folder in
`claimelens/staff-first-login.txt`. The command never prints passwords or emails
them. That local file is excluded from Git. Clients and staff use the same mobile
sign-in screen.

## Tests

```powershell
.venv-paddle/Scripts/python -m pytest -q
$env:RUN_PADDLE_OCR_TESTS='1'
.venv-paddle/Scripts/python -m pytest tests/test_paddle_integration.py -q
```

The real OCR test downloads models and uses synthetic image/PDF documents.
Ordinary tests do not send emails or change real user accounts.

An additional opt-in live Firebase test creates two disposable accounts and a
generated Word invoice, then checks login, private uploads, document downloads,
extraction, confirmation, and cross-user denial. It cleans up only its own records:

```powershell
$env:RUN_FIREBASE_LIVE_TESTS='1'
.venv-paddle/Scripts/python -m pytest tests/test_firebase_live.py -q
```

## Container

```powershell
docker build -t claimelens-api services/api
```

Pass environment configuration securely at deployment. Mount credentials read-only
and persist `/root/.paddlex` to avoid downloading models on each startup. Mount a
persistent private document volume and set `DOCUMENT_STORAGE_PATH` to its path. Deploy the
container behind HTTPS. The existing Flutter debug build uses USB port forwarding.
