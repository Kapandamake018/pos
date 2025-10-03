Place your PNG icon here as app_icon.png (recommended 1024x1024, transparent background).

After saving the file run:

powershell -Command "flutter pub get; flutter pub run flutter_launcher_icons:main"

Or use the helper script in the tools folder:

powershell -ExecutionPolicy Bypass -File .\tools\generate_icons.ps1
