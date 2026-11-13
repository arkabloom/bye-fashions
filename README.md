# BYE FASHIONS — Shop Management

A Flutter project targeting **Android and Web**. The current MVP includes:
- Dashboard with today's sales, bill count, stock units and low-stock count
- Product inventory: add, edit, delete, SKU, category, cost, selling price and quantity
- Single-item billing: customer details, discount, payment mode, invoice number and stock deduction
- Invoice preview and PDF print/save
- Expense tracking by category
- Revenue, estimated gross/net summary and payment-mode report
- Local JSON backup export (copied to clipboard)

## Requirements
- Flutter stable (3.3+; recommended current stable)
- Android Studio / Android SDK for Android builds
- Chrome for web builds

## First-time setup (required)
This ZIP contains the application source. Generate the standard Android and Web platform folders with Flutter, then resolve packages:

macOS / Linux:
```bash
chmod +x setup_platforms.sh
./setup_platforms.sh
```

Windows:
```bat
setup_platforms.bat
```

This requires Flutter stable installed and available in PATH. The setup command generates the platform scaffolding; it does not erase `lib/` or `pubspec.yaml`.

## Run locally
```bash
flutter run
```

## Run in Chrome
```bash
flutter config --enable-web
flutter run -d chrome
```

## Build Android APK
```bash
flutter build apk --release
```
APK output: `build/app/outputs/flutter-apk/app-release.apk`

## Build website
```bash
flutter build web --release
```
Upload the contents of `build/web/` to GitHub Pages (or another static host). For GitHub Pages, configure the repository Pages source to the `gh-pages` branch or deploy the `build/web` output with a Pages workflow.

## Data and important limitations
- Hive local storage is used. Android data stays on that device; web data stays in that browser's local storage.
- Android and web do **not** share/synchronize records automatically.
- Export Backup currently copies JSON to clipboard. Save it manually as a `.json` file.
- This is a usable MVP scaffold, not a certified GST/accounting product. Confirm tax, invoice numbering and statutory requirements with your accountant before issuing tax invoices.
- The current billing form supports one product per bill. A multi-item cart, barcode scanner, purchase entry, supplier ledger, customer credit ledger, GST configuration, backup import, cloud sync, staff roles and audit log are future enhancements.
- Do not uninstall/clear browser data before exporting a backup.

## Suggested next release
1. Multi-item cart and invoice line items
2. GST / non-GST invoice settings, business address, phone and GSTIN
3. Customer and supplier ledgers
4. Purchase entry and stock adjustment history
5. Backup import + encrypted backup
6. Shared cloud database for Android and Web
7. CSV/Excel reports and role-based staff access
8. Barcode/QR scanning and thermal printer support
