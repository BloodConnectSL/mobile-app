# Local development

Use the matching `feature/nipuna/project-completion` Go API and web-dashboard branches. The API must run on port 8080. The API's local bootstrap provides isolated synthetic accounts and mock OTP; see that repository's `.env.local.example` and `cmd/dev`.

```sh
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

Android emulator defaults to `http://10.0.2.2:8080`. For a USB device, run `adb reverse tcp:8080 tcp:8080`, then select `http://127.0.0.1:8080` in the login screen's server settings. A configured server URL is remembered on the device. Set Android SDK path in ignored `android/local.properties`; do not commit machine-specific paths.

```sh
flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:8080
flutter build apk --debug
```

Test camera scanning, GPS, permissions and session persistence on a physical device before release. The Go API owns role/facility permissions and donation rules. Production hosting, signing, SMS and push delivery require separate configuration and verification.
