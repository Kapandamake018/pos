# Replacing the App Launcher Icon

This project includes a small helper script to replace the launcher icon for
Android and iOS using a single PNG source image.

Quick steps (Windows PowerShell):

1. Save your icon image as a PNG (1024x1024 recommended). If you already
   have the image (like the one pasted into the conversation), save it to
   somewhere like `C:\Users\You\Downloads\app_icon.png`.

2. From the project root run:

```powershell
.\tools\set_app_icon.ps1 -SourcePath C:\Users\You\Downloads\app_icon.png
```

3. Clean and rebuild your Flutter app:

```powershell
flutter clean; flutter pub get; flutter run
```

Notes and recommendations:

- The script copies the same PNG into Android mipmap folders and a minimal
  iOS AppIcon set. It does not perform resizing or create perfectly sized
  icons for App Store submission.

- For best results, generate platform-specific icons (proper sizes) with
  `flutter_launcher_icons` or an icon generator tool. Example:

  1. Add to `pubspec.yaml` (dev_dependencies):

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.10.0

flutter_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"
```

  2. Run:

```powershell
flutter pub get; flutter pub run flutter_launcher_icons:main
```

- After running either approach, restart your IDE and rebuild the app to
  see the updated launcher icon.

If you want, I can:
- Add the `flutter_launcher_icons` config into `pubspec.yaml` and run it for
  you (I will create the required resized images), or
- Attempt to generate resized PNGs from the attached image and place them
  into the correct platform folders automatically.

Tell me which option you prefer and I will proceed.
