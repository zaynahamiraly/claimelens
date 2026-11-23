# claimelens

Flutter Android app for submitting and tracking medical-insurance claims.
Firebase Authentication manages accounts, Firestore stores claims and profiles,
and private Firebase Storage holds uploaded documents. The Python FastAPI server
enforces access permissions and runs PaddleOCR for images and scanned PDFs.

## Project structure

- `mobile/claimlens_mobile`: Flutter application (Dart package `claimelens`).
- `services/api`: authenticated API, Firestore persistence, and PaddleOCR.
- `firebase`: deny-by-default database and document-storage rules.
- `docs/mobile-architecture.md`: data flow, access controls, and migration notes.

The Android application ID stays `ai.claimlens.claimlens_mobile` to update the
existing installed app. Its visible name and Dart package name are `claimelens`.

## Firebase project

Project ID: **claimelens**. Email/password Authentication and the default Firestore
database are configured. Firebase Storage requires the Blaze plan and a bucket;
document uploads remain unavailable until those are configured. Billing is never
activated by the setup scripts. See `services/api/README.md` for server setup.

The mobile app talks to the API using Dio; Firebase Admin credentials belong only
on the server. No Firebase service-account key belongs in Flutter or GitHub.

## Run on an Android phone

```powershell
Set-Location mobile/claimlens_mobile
flutter pub get
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

For deployment, use an HTTPS API URL. USB forwarding is only for local development.
Sign up creates a client account. Forgot password sends a Firebase-hosted reset
link; use the link, then return to the app to sign in. Staff roles are provisioned
in Firestore by an authorized project administrator, never by signup requests.

## Checks

```powershell
Set-Location mobile/claimlens_mobile
flutter analyze
flutter test
```

Backend tests and optional real OCR checks are documented in the API README.

## Migration

This version replaces the earlier Supabase backend. Existing Supabase passwords,
users, and claim data are not automatically imported; create a Firebase account
or arrange an explicit data migration. Old remote data has not been deleted.
The removed Next.js web app, SQL migrations, and unused research experiments
remain in Git history. This repository now targets the Flutter mobile app.
