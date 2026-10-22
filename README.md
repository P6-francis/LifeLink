# LifeLink

Flutter application for blood donors and blood-request coordination. The app
uses Firebase Authentication and Cloud Firestore; a small PHP-based admin
dashboard is kept separately in `web/`.

## Project structure

```text
lib/
├── app/                         # App bootstrap, auth routing, and navigation
│   ├── lifelink_app.dart
│   ├── auth_gate.dart
│   ├── app_shell.dart
│   └── tab_navigation.dart
├── features/                    # Feature-owned UI and feature logic
│   ├── auth/presentation/
│   ├── donors/presentation/
│   ├── home/presentation/
│   ├── messaging/presentation/
│   ├── profile/presentation/
│   └── requests/presentation/
├── widgets/                     # Reusable widgets shared by multiple features
│   ├── app_notice.dart
│   └── async_state_view.dart
├── firebase_options.dart         # Generated Firebase configuration
└── main.dart                     # Application entry point

assets/                           # Bundled images and SVG files
test/                             # Automated tests
web/                              # PHP admin dashboard (separate from Flutter web)
```

There is intentionally no `lib/screens/` directory. Screens belong to the
feature that owns them, under `lib/features/<feature>/presentation/`. New UI
should follow the same convention.

## Run locally

```bash
flutter pub get
flutter run
```

## Quality checks

```bash
flutter analyze
flutter test
```

## Firebase

Firebase is initialized in `lib/main.dart`. Platform settings live in the
native platform directories and the generated `lib/firebase_options.dart`.
Do not place credentials or local PHP session files in version control.
