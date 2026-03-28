# US Outdoor Navigator -- Firebase Automated Setup Script
# Usage: powershell -ExecutionPolicy Bypass -File tools\setup_firebase.ps1
#
# Steps:
#   1. Firebase CLI login (browser opens -- sign in with Google)
#   2. Create or reuse "us-outdoor-navigator" project
#   3. Register Android app (com.mert.usoutdoor)
#   4. Register iOS app     (com.mert.usoutdoor)
#   5. Download google-services.json   -> frontend/android/app/
#   6. Download GoogleService-Info.plist -> frontend/ios/Runner/
#   7. Create firebase.json (Crashlytics)

$ErrorActionPreference = "Stop"
$rootDir = "C:\Users\Mert\Desktop\US-Outdoor-Navigator"

Write-Host ""
Write-Host "=== US Outdoor Navigator -- Firebase Setup ===" -ForegroundColor Cyan
Write-Host ""

Set-Location $rootDir
Write-Host "Working dir: $rootDir" -ForegroundColor Gray

# --- 1. Check Firebase CLI ---
Write-Host ""
Write-Host "[1/7] Checking Firebase CLI..." -ForegroundColor Yellow
$fbVersion = firebase --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Firebase CLI not found. Installing..." -ForegroundColor Red
    npm install -g firebase-tools
}
Write-Host "  OK: firebase $fbVersion" -ForegroundColor Green

# --- 2. Login ---
Write-Host ""
Write-Host "[2/7] Firebase login..." -ForegroundColor Yellow
Write-Host "  -> Browser will open. Sign in with your Google account." -ForegroundColor Cyan
Write-Host "  -> If already logged in, this will continue automatically." -ForegroundColor Cyan
firebase login --no-localhost
Write-Host "  OK: Logged in!" -ForegroundColor Green

# --- 3. Project ---
Write-Host ""
Write-Host "[3/7] Checking Firebase project..." -ForegroundColor Yellow

$PROJECT_ID = ""
$timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

# List existing projects
$rawProjects = firebase projects:list --json 2>&1
try {
    $jsonProjects = $rawProjects | ConvertFrom-Json
    if ($jsonProjects.result) {
        foreach ($proj in $jsonProjects.result) {
            if ($proj.projectId -like "*us-outdoor*") {
                $PROJECT_ID = $proj.projectId
                Write-Host "  Found existing project: $PROJECT_ID" -ForegroundColor Green
                break
            }
        }
    }
} catch {
    Write-Host "  Could not parse project list, will create new." -ForegroundColor Yellow
}

if ($PROJECT_ID -eq "") {
    $PROJECT_ID = "us-outdoor-nav-$timestamp"
    Write-Host "  Creating new project: $PROJECT_ID" -ForegroundColor Cyan
    try {
        firebase projects:create $PROJECT_ID --display-name "US Outdoor Navigator"
        Write-Host "  OK: Project created: $PROJECT_ID" -ForegroundColor Green
    } catch {
        Write-Host "  Could not create project automatically." -ForegroundColor Yellow
        $PROJECT_ID = Read-Host "  Enter your Firebase Project ID manually"
    }
}

firebase use $PROJECT_ID
Write-Host "  Active project: $PROJECT_ID" -ForegroundColor Green

# --- 4. Android App ---
Write-Host ""
Write-Host "[4/7] Registering Android app (com.mert.usoutdoor)..." -ForegroundColor Yellow

$androidAppId = ""
$rawAndroid = firebase apps:list ANDROID --json 2>&1
try {
    $jsonAndroid = $rawAndroid | ConvertFrom-Json
    if ($jsonAndroid.result) {
        foreach ($app in $jsonAndroid.result) {
            if ($app.packageName -eq "com.mert.usoutdoor") {
                $androidAppId = $app.appId
                Write-Host "  Found existing Android app: $androidAppId" -ForegroundColor Green
                break
            }
        }
    }
} catch {}

if ($androidAppId -eq "") {
    $rawCreate = firebase apps:create ANDROID "US Outdoor Navigator" --package-name com.mert.usoutdoor --json 2>&1
    try {
        $jsonCreate = $rawCreate | ConvertFrom-Json
        $androidAppId = $jsonCreate.result.appId
        Write-Host "  OK: Android app created: $androidAppId" -ForegroundColor Green
    } catch {
        Write-Host "  Waiting for app registration..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        $rawAndroid2 = firebase apps:list ANDROID --json 2>&1
        try {
            $jsonAndroid2 = $rawAndroid2 | ConvertFrom-Json
            if ($jsonAndroid2.result -and $jsonAndroid2.result.Count -gt 0) {
                $androidAppId = $jsonAndroid2.result[0].appId
            }
        } catch {}
    }
}

# --- 5. iOS App ---
Write-Host ""
Write-Host "[5/7] Registering iOS app (com.mert.usoutdoor)..." -ForegroundColor Yellow

$iosAppId = ""
$rawIos = firebase apps:list IOS --json 2>&1
try {
    $jsonIos = $rawIos | ConvertFrom-Json
    if ($jsonIos.result) {
        foreach ($app in $jsonIos.result) {
            if ($app.bundleId -eq "com.mert.usoutdoor") {
                $iosAppId = $app.appId
                Write-Host "  Found existing iOS app: $iosAppId" -ForegroundColor Green
                break
            }
        }
    }
} catch {}

if ($iosAppId -eq "") {
    $rawCreateIos = firebase apps:create IOS "US Outdoor Navigator" --bundle-id com.mert.usoutdoor --json 2>&1
    try {
        $jsonCreateIos = $rawCreateIos | ConvertFrom-Json
        $iosAppId = $jsonCreateIos.result.appId
        Write-Host "  OK: iOS app created: $iosAppId" -ForegroundColor Green
    } catch {
        Write-Host "  Waiting for app registration..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        $rawIos2 = firebase apps:list IOS --json 2>&1
        try {
            $jsonIos2 = $rawIos2 | ConvertFrom-Json
            if ($jsonIos2.result -and $jsonIos2.result.Count -gt 0) {
                $iosAppId = $jsonIos2.result[0].appId
            }
        } catch {}
    }
}

# --- 6. Download Config Files ---
Write-Host ""
Write-Host "[6/7] Downloading config files..." -ForegroundColor Yellow

$androidOut = "$rootDir\frontend\android\app\google-services.json"
if ($androidAppId -ne "") {
    Write-Host "  Downloading google-services.json..." -ForegroundColor Cyan
    firebase apps:sdkconfig ANDROID $androidAppId -o $androidOut
    Write-Host "  OK: $androidOut" -ForegroundColor Green
} else {
    Write-Host "  WARN: Android App ID not found. Download manually from Firebase Console." -ForegroundColor Yellow
}

$iosOut = "$rootDir\frontend\ios\Runner\GoogleService-Info.plist"
if ($iosAppId -ne "") {
    Write-Host "  Downloading GoogleService-Info.plist..." -ForegroundColor Cyan
    firebase apps:sdkconfig IOS $iosAppId -o $iosOut
    Write-Host "  OK: $iosOut" -ForegroundColor Green
} else {
    Write-Host "  WARN: iOS App ID not found. Download manually from Firebase Console." -ForegroundColor Yellow
}

# --- 7. firebase.json for Crashlytics ---
Write-Host ""
Write-Host "[7/7] Creating firebase.json..." -ForegroundColor Yellow

$fbJson = '{"crashlytics":{"symbolUpload":false}}'
$fbJsonPath = "$rootDir\frontend\firebase.json"
$fbJson | Out-File -FilePath $fbJsonPath -Encoding UTF8 -Force
Write-Host "  OK: frontend/firebase.json created" -ForegroundColor Green

# --- Done ---
Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "  Firebase Setup COMPLETE!" -ForegroundColor Green
Write-Host "  Project  : $PROJECT_ID" -ForegroundColor Green
Write-Host "  Android  : frontend/android/app/google-services.json" -ForegroundColor Green
Write-Host "  iOS      : frontend/ios/Runner/GoogleService-Info.plist" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  cd frontend" -ForegroundColor Cyan
Write-Host "  flutter run" -ForegroundColor Cyan
Write-Host ""
