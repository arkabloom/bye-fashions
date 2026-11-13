@echo off
where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter SDK not found. Install Flutter stable and add it to PATH.
  exit /b 1
)
flutter create --platforms=android,web --project-name=bye_fashions .
if errorlevel 1 exit /b 1
flutter pub get
if errorlevel 1 exit /b 1
echo BYE FASHIONS project is ready. Run: flutter run -d chrome
