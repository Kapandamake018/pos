param(
    [string]$ImagePath = "assets/icon/app_icon.png"
)

if (-not (Test-Path $ImagePath)) {
    Write-Host "Icon not found at $ImagePath. Please place your PNG there (recommended 1024x1024)"
    exit 2
}

Write-Host "Running flutter pub get..."
flutter pub get

Write-Host "Generating icons with flutter_launcher_icons..."
flutter pub run flutter_launcher_icons:main

Write-Host "Done. Clean and rebuild your project to see updated icons."