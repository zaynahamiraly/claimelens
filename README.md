# claimelens

A Flutter Android app for submitting and tracking medical-insurance claims.
Upload invoices, receipts, and supporting documents, review extracted values,
correct mistakes, and submit a claim for review.

Repository: [zaynahamiraly/claimelens](https://github.com/zaynahamiraly/claimelens).

## Stack

| Component | Purpose |
| --- | --- |
| Flutter / Dart | Android screens, file selection, secure sessions, and claim review |
| Firebase Authentication | Email/password accounts, session refresh, and password reset emails |
| Cloud Firestore | User profiles, claims, extracted fields, processing jobs, and audit events |
| FastAPI / Python | Authenticated uploads, access checks, document extraction, and claim confirmation |
| PaddleOCR | Recognize text from images and scanned PDFs on the API computer |
| Private local files | Store claim documents without enabling paid cloud storage |

## Why FastAPI is included

Keep FastAPI for this version. PaddleOCR runs in Python on the API computer;
FastAPI receives Flutter uploads, runs extraction, and returns structured results.
It also checks ownership and staff roles before accessing Firebase Admin data or
issuing private document links. Firebase provides authentication and database
services; FastAPI provides the application and OCR endpoints.

The phone needs access to the running API. USB forwarding is used during local
development; a deployed version needs a reachable HTTPS API and persistent storage.

## Project layout

```text
mobile/claimlens_mobile/   Flutter app; Dart package name: claimelens
services/api/             FastAPI, Firebase integration, and PaddleOCR
firebase/                 Private Firestore access rules
docs/                     Mobile architecture and security notes
```

The existing folder name and Android ID `ai.claimlens.claimlens_mobile` are retained
so this build can update the app already installed on the test phone. Its displayed
name, Dart package, Firebase project, and GitHub repository are **claimelens**.

## Run locally

Requirements: Flutter with Android SDK, 64-bit Python 3.12, and Firebase server
credentials. Firebase project ID: `claimelens`.

### 1. Open the repository

```powershell
git clone https://github.com/zaynahamiraly/claimelens.git
Set-Location claimelens
code .
```

If already cloned, open that folder instead of cloning again.

### 2. Start the API

```powershell
Set-Location services/api
py -3.12 -m venv .venv-paddle
.venv-paddle/Scripts/python -m pip install -r requirements.txt
Copy-Item .env.example .env
```

Copy the example only on first setup; keep an existing configured `.env`.
Fill `FIREBASE_API_KEY` and set `GOOGLE_APPLICATION_CREDENTIALS` to the server
credential file outside the repository. `DOCUMENT_STORAGE_PATH` must point to a
private persistent folder. See [API setup](services/api/README.md).

```powershell
.venv-paddle/Scripts/python -m app.serve
```

This loads PaddleOCR models before opening port 8000. The first run needs internet
access to download models. API documentation: `http://127.0.0.1:8000/docs`.

### 3. Run Flutter on the phone

In a second terminal at the repository root:

```powershell
Set-Location mobile/claimlens_mobile
flutter pub get
adb devices
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Enable USB debugging and approve the computer on the phone. Keep the API computer
running and the USB connection active while testing.

## Accounts and documents

- **Create account** registers a Firebase client account.
- **Forgot password** emails a Firebase-hosted reset link.
- A project administrator assigns staff roles in Firestore; signup cannot assign them.
- Existing accounts from the previous backend must be registered in Firebase or explicitly migrated.
- Firebase Authentication and Firestore use the project's free quotas. Billing remains disabled.
- Uploaded files stay on the API computer, outside Git. They are not uploaded to Firebase Storage.
- Document links expire after five minutes. Back up the private document folder.

## Checks

Flutter:

```powershell
Set-Location mobile/claimlens_mobile
flutter analyze
flutter test
```

API, from the repository root:

```powershell
Set-Location services/api
.venv-paddle/Scripts/python -m pip install -r requirements-dev.txt
.venv-paddle/Scripts/python -m pytest -q
```

Optional real-model OCR and live Firebase tests are explained in the
[API README](services/api/README.md). The live test uses disposable accounts and
a generated invoice, then removes its own data.

## Git and VS Code Source Control

Open the repository root containing `.git`, `mobile`, and `services` in VS Code.
An unrelated Flutter demo folder will not show this repository's commits.

```powershell
git remote -v
git status -sb
git log -5 --oneline
```

The remote should be `https://github.com/zaynahamiraly/claimelens.git`. After a
successful push, Source Control may show no outgoing changes because the local
branch and GitHub are already synchronized; inspect the commit graph or Git log.

More detail: [mobile architecture](docs/mobile-architecture.md).
