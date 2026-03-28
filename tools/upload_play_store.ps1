# upload_play_store.ps1 - Google Play Console AAB Uploader
# Run: powershell -ExecutionPolicy Bypass -File tools\upload_play_store.ps1

$ErrorActionPreference = "Stop"

$AAB_PATH = "frontend\build\app\outputs\bundle\release\app-release.aab"
$PACKAGE  = "com.mert.usoutdoor"

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  US Outdoor Navigator - Play Store Uploader" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check AAB file
if (-Not (Test-Path $AAB_PATH)) {
    Write-Host "[ERROR] AAB not found: $AAB_PATH" -ForegroundColor Red
    Write-Host "Run first:" -ForegroundColor Yellow
    Write-Host "  cd frontend" -ForegroundColor White
    Write-Host "  flutter build appbundle --release --dart-define=API_URL=https://us-outdoor-api-production.up.railway.app" -ForegroundColor White
    exit 1
}

$aabFile = Get-Item $AAB_PATH
$aabSizeMB = [math]::Round($aabFile.Length / 1MB, 1)
Write-Host "[OK] AAB found: $AAB_PATH ($aabSizeMB MB)" -ForegroundColor Green

# 2. Show upload info
Write-Host ""
Write-Host "--- UPLOAD INFO ---" -ForegroundColor Yellow
Write-Host "  Package : $PACKAGE"
Write-Host "  Size    : $aabSizeMB MB"
Write-Host "  Path    : $((Resolve-Path $AAB_PATH).Path)"
Write-Host ""

# 3. Open Play Console
Write-Host "[1/3] Opening Google Play Console..." -ForegroundColor Cyan
$playUrl = "https://play.google.com/console/u/0/developers"
Start-Process $playUrl
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "===== UPLOAD STEPS =====" -ForegroundColor Magenta
Write-Host ""
Write-Host "1. Play Console -> your app -> Release -> Production (or Internal testing)" -ForegroundColor White
Write-Host "   -> Create new release" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Click 'Upload' in App bundles section" -ForegroundColor White
Write-Host ""
Write-Host "3. Select this file:" -ForegroundColor White
Write-Host "   $((Resolve-Path $AAB_PATH).Path)" -ForegroundColor Yellow
Write-Host ""
Write-Host "4. Release notes (English):" -ForegroundColor White
Write-Host "   'Initial release: wildfire alerts, campground finder, RV routing, SOS'" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Save -> Review release -> Start rollout to Internal testing" -ForegroundColor White
Write-Host ""

# 4. Open AAB in Explorer
Write-Host "[2/3] Opening AAB location in Explorer..." -ForegroundColor Cyan
$absPath = (Resolve-Path $AAB_PATH).Path
Start-Process "explorer.exe" "/select,""$absPath"""

Start-Sleep -Seconds 1

# 5. Open Data Safety
Write-Host "[3/3] Opening Data Safety form..." -ForegroundColor Cyan
$dataSafetyUrl = "https://play.google.com/console/u/0/developers/app/data-safety"
Start-Process $dataSafetyUrl

Write-Host ""
Write-Host "===== DATA SAFETY FORM =====" -ForegroundColor Magenta
Write-Host ""
Write-Host "Fill these fields:" -ForegroundColor White
Write-Host ""
Write-Host "  Location -> Precise Location" -ForegroundColor Gray
Write-Host "    Collected: YES | Purpose: App functionality | Optional: YES" -ForegroundColor Gray
Write-Host ""
Write-Host "  Location -> Approximate Location" -ForegroundColor Gray
Write-Host "    Collected: YES | Purpose: App functionality | Optional: YES" -ForegroundColor Gray
Write-Host ""
Write-Host "  Shared with 3rd parties: NO" -ForegroundColor Gray
Write-Host "  Encrypted in transit: YES (HTTPS)" -ForegroundColor Gray
Write-Host "  Users can request deletion: YES" -ForegroundColor Gray
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Done! Follow the steps in your browser." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
