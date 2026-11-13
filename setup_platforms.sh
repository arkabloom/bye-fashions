#!/usr/bin/env bash
set -e
if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK not found. Install Flutter stable and add it to PATH."
  exit 1
fi
flutter create --platforms=android,web --project-name=bye_fashions .
flutter pub get
echo "BYE FASHIONS project is ready. Run: flutter run -d chrome"
