<#
Usage: .\set_app_icon.ps1 -SourcePath C:\path\to\app_icon.png
This script copies a provided PNG icon into Android mipmap folders and into
an iOS AppIcon set so it can be used as the app launcher icon. It does not
resize images - it duplicates the same source PNG into all target sizes.

For best results, supply a 1024x1024 PNG. To produce proper, platform-quality
icons, consider using a tool like flutter_launcher_icons or an image editor to
export multiple sizes.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$SourcePath
)

if (-not (Test-Path $SourcePath)) {
    Write-Error "Source file not found: $SourcePath"
    exit 2
}

$projectRoot = Resolve-Path "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)\.."
$projectRoot = (Get-Item $projectRoot).FullName
Write-Host "Project root: $projectRoot"

# Android mipmap targets
$mipmapFolders = @("android/app/src/main/res/mipmap-mdpi",
                   "android/app/src/main/res/mipmap-hdpi",
                   "android/app/src/main/res/mipmap-xhdpi",
                   "android/app/src/main/res/mipmap-xxhdpi",
                   "android/app/src/main/res/mipmap-xxxhdpi")

<#
Usage: .\set_app_icon.ps1 -SourcePath C:\path\to\app_icon.png
This script copies a provided PNG icon into Android mipmap folders and into
an iOS AppIcon set so it can be used as the app launcher icon. It does not
resize images - it duplicates the same source PNG into all target sizes.

For best results, supply a 1024x1024 PNG. To produce proper, platform-quality
icons, consider using a tool like flutter_launcher_icons or an image editor to
export multiple sizes.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$SourcePath
)

if (-not (Test-Path $SourcePath)) {
    Write-Error "Source file not found: $SourcePath"
    exit 2
}

$projectRoot = Resolve-Path "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)\.."
$projectRoot = (Get-Item $projectRoot).FullName
Write-Host "Project root: $projectRoot"

# Android mipmap targets
$mipmapFolders = @(
    "android/app/src/main/res/mipmap-mdpi",
    "android/app/src/main/res/mipmap-hdpi",
    "android/app/src/main/res/mipmap-xhdpi",
    "android/app/src/main/res/mipmap-xxhdpi",
    "android/app/src/main/res/mipmap-xxxhdpi"
)

foreach ($mf in $mipmapFolders) {
    $destDir = Join-Path $projectRoot $mf
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    $dest = Join-Path $destDir "ic_launcher.png"
    Copy-Item -Path $SourcePath -Destination $dest -Force
    Write-Host "Copied to: $dest"
}

# Adaptive icon (foreground) for Android O+ (mipmap-anydpi-v26)
$anydpiDir = Join-Path $projectRoot "android/app/src/main/res/mipmap-anydpi-v26"
if (-not (Test-Path $anydpiDir)) { New-Item -ItemType Directory -Path $anydpiDir -Force | Out-Null }
$xml = @"
<?xml version=\"1.0\" encoding=\"utf-8\"?>
<adaptive-icon xmlns:android=\"http://schemas.android.com/apk/res/android\">
  <background android:drawable=\"@color/white\" />
  <foreground android:drawable=\"@mipmap/ic_launcher\" />
</adaptive-icon>
"@
$xmlPath = Join-Path $anydpiDir "ic_launcher.xml"
$xml | Out-File -FilePath $xmlPath -Encoding utf8
Write-Host "Wrote adaptive icon xml: $xmlPath"

# iOS: copy PNG into AppIcon.appiconset and create Contents.json entries if missing
$iosAppIconsDir = Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset"
if (-not (Test-Path $iosAppIconsDir)) { New-Item -ItemType Directory -Path $iosAppIconsDir -Force | Out-Null }

# Copy the source PNG as a generic AppIcon file (Xcode expects specific sizes, but many builds will accept a single file named appropriately)
$iosDest = Join-Path $iosAppIconsDir "app_icon.png"
Copy-Item -Path $SourcePath -Destination $iosDest -Force
Write-Host "Copied iOS icon: $iosDest"

# Create a minimal Contents.json if it does not exist (Xcode normally requires precise size mappings). This will help Xcode see the asset but you should still supply full-size assets for App Store.
$contentsJsonPath = Join-Path $iosAppIconsDir "Contents.json"
if (-not (Test-Path $contentsJsonPath)) {
    $contents = @{
        images = @(
            @{ idiom = "iphone"; scale = "1x"; filename = "app_icon.png" },
            @{ idiom = "iphone"; scale = "2x"; filename = "app_icon.png" },
            @{ idiom = "iphone"; scale = "3x"; filename = "app_icon.png" },
            @{ idiom = "ios-marketing"; scale = "1x"; filename = "app_icon.png" }
        );
        info = @{ version = 1; author = "xcode" }
    } | ConvertTo-Json -Depth 5
    $contents | Out-File -FilePath $contentsJsonPath -Encoding utf8
    Write-Host "Wrote Contents.json for iOS AppIcon set: $contentsJsonPath"
} else {
    Write-Host "Contents.json already exists at $contentsJsonPath — not overwriting."
}

Write-Host "Done. You may need to clean/rebuild the Flutter project and restart IDE to see updated icons."
Write-Host 'Recommended: use a 1024x1024 source PNG and consider running flutter pub run flutter_launcher_icons:main for production-quality icons.'