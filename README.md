# ClaimLens

A Flutter Android app for submitting and tracking medical-insurance claims.
Upload invoices, receipts, and supporting documents, review extracted values,
correct mistakes, and submit a claim for review.

The native mobile workspace includes client, claims officer, supervisor, finance, and
administrator workflows. It does not require the former Vercel website to run.

## Mobile workspace

ClaimLens 1.2 includes **Chats**: clients can ask questions in their own support
conversation; administrators, supervisors and claims officers share the inbox and
can see each reply's author, role and timestamp. Conversations have unread counts,
history pagination and safe send retries. See [the chat guide](docs/support-chat.md)
and [device/integration verification](docs/chat-workflow-qa-2026-11-24.md).

| Account | Available options |
| --- | --- |
| Client | Sign up, upload/camera/gallery, confirm extracted evidence, search/filter claims, follow progress, answer information requests with files, read notifications, edit profile and change password |
| Claims officer | Assigned and unassigned queues, take assignment, compare private source documents, correct evidence and totals, request information, verify, analytics and audit trail |
| Supervisor | Assign officers, review evidence, approve/reject another verifier's work with notes and approved amounts, analytics and audit trail |
| Finance | Access approved/payment claims, record payment pending and settlement with method/reference, analytics and audit trail |
| Administrator | Create users, assign roles/additional rights, activate/deactivate accounts, set temporary passwords, configure claim requirements and retain claim history. Review/decision/payment rights require explicit grants. |

Client navigation: **Overview · Claims · Updates · Account**.
Staff navigation: **Overview · Claims · Review · Workspace**. Analytics, audit,
notifications, user access (administrators), and account settings are under Workspace.
Light/dark/system appearance and notification badge preferences are saved per account.

The API checks every role and status transition and uses Firestore transactions for
assignment, review, decisions, information responses, and administrator access changes.
Public signup always creates a client. Existing staff roles are preserved.
See [workflow details](docs/mobile-workflows.md).

Repository: [zaynahamiraly/claimelens](https://github.com/zaynahamiraly/claimelens).

For operation with the computer switched off, see the
[Render deployment and migration plan](docs/render-deployment.md). The prepared
configuration requires account access and approval of hosting/storage costs;
it has not yet been deployed.

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
mobile/claimlens_mobile/   Flutter app; Dart package name: claimlens
services/api/             FastAPI, Firebase integration, and PaddleOCR
firebase/                 Private Firestore access rules
docs/                     Mobile architecture and security notes
```

The existing folder name and Android ID `ai.claimlens.claimlens_mobile` are retained
so this build can update the app already installed on the test phone. Its displayed
name is **ClaimLens** and its Dart package is **claimlens**. The Firebase project
ID and existing GitHub repository retain the legacy technical name `claimelens`.

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

### Internet testing without USB

The app can use Wi-Fi or mobile data through a temporary HTTPS tunnel. From `services/api`:

```powershell
.\start-internet.ps1
```

Pass `-PythonPath` if your configured Python environment is elsewhere. The script
downloads the official Cloudflare connector, starts/reuses a tunnel, updates the
private `.env` public document URL, and starts the API. It stores runtime settings
and logs outside the repository under `%LOCALAPPDATA%\claimelens`.

Build the Android app with the generated internet endpoint:

```powershell
Set-Location mobile/claimlens_mobile
flutter build apk --debug --dart-define-from-file="$env:LOCALAPPDATA\claimelens\internet-build.json"
```

Install that APK once; USB is unnecessary while using the installed app. Keep the
API computer awake and online. This is a development tunnel, not an independently
hosted production backend. A new tunnel has a new address: install a build made
with the new configuration, or update **Development connection** on the sign-in
screen. A newly configured build replaces the earlier saved USB address and asks
for sign-in again. App installation alone does not install FastAPI/PaddleOCR on
Android. Disabling USB forwarding is part of the cable-free acceptance test.
Stable service while the computer is off requires a hosted Python API and persistent
private document storage. No Vercel service or paid Firebase plan is used here.

Document extraction runs in the background; the app polls status so longer image
or scanned-PDF processing does not depend on one long internet request.

## Accounts and documents

- **Create account** registers a Firebase client account.
- The dedicated sign-up page is `lib/screens/signup_screen.dart`. Clients and staff share the sign-in page; signup never changes existing staff roles.
- **Forgot password** emails a Firebase-hosted reset link.
- Administrators manage roles from **Workspace → User access**; public signup cannot assign staff roles.
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
