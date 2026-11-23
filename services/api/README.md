# claimelens API

Use 64-bit Python 3.12 with the pinned PaddleOCR runtime. The API uses Firebase
Authentication REST endpoints for email/password login and email actions, and
Firebase Admin for ID-token verification, Firestore, and private Storage.

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
and object access to the document bucket. Production should use workload identity
or application-default credentials instead of distributing keys.

Set `FIREBASE_STORAGE_BUCKET` only after creating the actual bucket in Firebase.
Cloud Storage requires Blaze billing. An empty value produces a clear 503 before
an upload creates a draft; signup and dashboards do not require Storage.

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
five minutes. Direct client access to Firestore and Storage is denied by rules.

## Tests

```powershell
.venv-paddle/Scripts/python -m pytest -q
$env:RUN_PADDLE_OCR_TESTS='1'
.venv-paddle/Scripts/python -m pytest tests/test_paddle_integration.py -q
```

The real OCR test downloads models and uses synthetic image/PDF documents.
Ordinary tests do not send emails or change real user accounts.

## Container

```powershell
docker build -t claimelens-api services/api
```

Pass environment configuration securely at deployment. Mount credentials read-only
and persist `/root/.paddlex` to avoid downloading models on each startup. Deploy the
container behind HTTPS. The existing Flutter debug build uses USB port forwarding.
