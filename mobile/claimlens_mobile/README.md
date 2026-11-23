# claimelens Flutter mobile app

Install Flutter, then run `flutter pub get` in this directory. The app uses Dio to
communicate with the Firebase-backed Python API; no server credentials are embedded
in the app. Run `flutter analyze` and `flutter test` before building.

For a USB-connected phone:

```powershell
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Signup creates a Firebase client account. Forgot password emails a Firebase reset
link that opens the hosted password form. Existing accounts from the previous
backend must be recreated or explicitly migrated to Firebase.

The folder and Android application ID are retained for upgrade compatibility;
the visible application name and Dart package name are `claimelens`.
