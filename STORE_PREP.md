# 🏔️ US Outdoor Navigator — Store Preparation Guide
**Package:** `com.mert.usoutdoor` | **Bundle ID:** `com.mert.usoutdoor`  
**Version:** 1.0.0 (Build 1) | **Last Updated:** March 2026

---

## 📍 1. Background Location Justification

### Apple App Store — App Review Note
> To be submitted in App Store Connect → App Review Information → Notes

```
US Outdoor Navigator uses background location for ONE specific safety feature:
the "SOS Dead Man's Switch."

When a user enables this opt-in safety feature before an off-grid camping trip,
the app performs silent GPS check-ins every 30 minutes. If the user misses a
check-in (e.g., injury, unconsciousness, emergency), the app sends their last
known GPS coordinates to their designated emergency contact via push notification.

Background location is NEVER used for advertising, analytics, or any purpose
other than this safety check-in. The feature:
  - Must be manually enabled by the user from Settings screen
  - Shows a persistent foreground service notification when active
  - Can be disabled at any time
  - Does not transmit location to any server — only to the designated contact

This app is designed for backcountry campers, hikers, and overlanders who
operate in areas with no cellular signal, making this safety feature critical
for user safety.

NSLocationAlwaysUsageDescription plist key is present and the justification
fully applies to this single use case.
```

### Google Play — Data Safety Form Answers

| Data Type | Collected? | Shared? | Purpose | Required? | User Control? |
|-----------|-----------|---------|---------|-----------|---------------|
| Precise Location | Yes | No | App functionality (campground search, SOS) | No (opt-in) | Yes |
| Approximate Location | Yes | No | App functionality | No (opt-in) | Yes |
| Background Location | Yes | No | SOS Dead Man's Switch safety feature | No (opt-in) | Yes — user enables/disables |
| Crash logs | No | — | — | — | — |
| Analytics | No | — | — | — | — |

**Declaration Text for Play Console:**
```
This app collects device location to find nearby campgrounds, display
wildfire proximity alerts, and provide an opt-in SOS emergency check-in
feature. Background location is used only when the user manually activates
the Dead Man's Switch safety feature. Location data is never sold, shared
with third parties, or used for advertising.
```

---

## 📱 2. App Store Listing — Marketing Copy

### App Name
```
US Outdoor Navigator: RV & Camp
```

### Subtitle (30 chars max — Apple)
```
Survival Maps & SOS Safety
```

### Short Description (80 chars — Google Play)
```
Campgrounds, wildfire alerts & SOS for backcountry adventurers.
```

### Full Description

**Apple App Store (4000 chars max):**
```
US Outdoor Navigator is the ultimate companion for RVers, overlanders,
and backcountry campers exploring America's wilderness.

★ 1,500+ CAMPGROUNDS ACROSS 10 WESTERN STATES
Discover BLM-free dispersed campsites, National Forest sites, and
state park campgrounds. Filter by RV length, amenities, hookups, water,
and price. Never be surprised by a campground that can't fit your rig.

★ REAL-TIME WILDFIRE PROXIMITY ALERTS
NASA FIRMS satellite data overlaid directly on your map. See active
fire perimeters, get automatic safety status updates, and know your
evacuation distance before you make camp.

★ SOS EMERGENCY SYSTEM
One long-press activates the SOS Panic Button — your GPS coordinates
are instantly logged and your emergency contact is notified. The optional
Dead Man's Switch checks in every 30 minutes; if you miss a check-in,
your location is automatically shared with emergency services.

★ SMART RV LOGISTICS
Find RV-friendly fuel stops, propane fill stations, dump stations, repair
shops, and EV charging along your route. Filter by distance and services.
Never run dry or get stranded again.

★ EXTREME WEATHER INTELLIGENCE
Flash flood warnings, high wind alerts, lightning strike proximity, and
night temperature forecasts tailored to your campsite location. Packed
with survival-grade meteorological data.

★ OFFLINE MODE
Download maps and campground data before heading off-grid. Full
functionality with zero cellular signal required.

★ STARLINK AR VIEW (Pro)
Point your camera at the sky — the AR overlay shows satellite positions
and signal obstruction analysis to help you aim your Starlink dish
perfectly.

★ SOLAR & POWER PLANNING (Pro)
Daily solar hour estimates, optimal panel angles, and power consumption
forecasts for your solar setup.

PRO PLANS:
• Explorer — $9.99/week (3-day free trial)
• Nomad Pro — $59.99/year = $5/month (3-day free trial, BEST VALUE)

Cancel anytime in App Store settings.

Built for: Van-lifers • RV Full-timers • Overlanders • Backpackers •
Hunters • Off-Grid Explorers • Emergency Preppers
```

**Google Play Short Description:**
```
Find campgrounds, track wildfires, and stay safe off-grid with NASA fire
data, SOS panic button, and 1500+ Western US campsites.
```

---

## 🔑 3. Required Keys & Credentials Checklist

### Before Submission

- [ ] **RevenueCat Android Key**: Replace `goog_YOUR_RC_KEY_HERE` in `app_config.dart`
  - Get from: [app.revenuecat.com](https://app.revenuecat.com) → Project Settings → API Keys
  
- [ ] **RevenueCat iOS Key**: Replace `appl_YOUR_RC_KEY_HERE` in `app_config.dart`
  
- [ ] **Product IDs** in RevenueCat console:
  - `com.mert.usoutdoor.explorer_weekly`
  - `com.mert.usoutdoor.nomad_yearly`

- [ ] **Backend URL**: Replace `https://us-outdoor-api.railway.app` with your actual deployed URL

- [ ] **Privacy Policy URL**: Host a live page at `https://usoutdoor.app/privacy`
  - Can use: Termly, Iubenda, or a simple GitHub Pages site

- [ ] **Terms of Service URL**: Host at `https://usoutdoor.app/terms`

- [ ] **App Icon**: Place 1024×1024 PNG at `assets/icons/app_icon_1024.png`
  - Run: `dart run flutter_launcher_icons`

- [ ] **Android Keystore**: Generate production keystore
  ```bash
  keytool -genkey -v -keystore ~/usoutdoor-release.jks \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias usoutdoor
  ```
  Add to `build.gradle.kts` release signingConfig

- [ ] **Firebase** (optional but recommended):
  - Add `google-services.json` to `android/app/`
  - Add `GoogleService-Info.plist` to `ios/Runner/`
  - Set `enableFirebase = true` in `app_config.dart`

---

## 🏗️ 4. Production Build Commands

### Android AAB (Play Store)
```bash
cd frontend
flutter build appbundle --release \
  --dart-define=API_URL=https://us-outdoor-api.railway.app \
  --dart-define=RC_KEY_ANDROID=your_rc_key_here
```

### iOS IPA (App Store)
```bash
cd frontend
flutter build ios --release \
  --dart-define=API_URL=https://us-outdoor-api.railway.app \
  --dart-define=RC_KEY_IOS=your_rc_key_here
# Then archive in Xcode: Product → Archive → Distribute App
```

---

## 🔒 5. Android Signing Config Template

Add to `build.gradle.kts`:
```kotlin
android {
    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("KEYSTORE_PATH") ?: "usoutdoor-release.jks")
            storePassword = System.getenv("KEYSTORE_PASS") ?: ""
            keyAlias = System.getenv("KEY_ALIAS") ?: "usoutdoor"
            keyPassword = System.getenv("KEY_PASS") ?: ""
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}
```

---

## ✅ 6. Pre-Submission Checklist

### Both Platforms
- [ ] App tested on physical device (not just emulator)
- [ ] All API endpoints return data (backend deployed)
- [ ] SOS button tested (long press → confirm dialog → log saved)
- [ ] Offline mode tested (airplane mode → cached data shown)
- [ ] RevenueCat sandbox purchase completed successfully
- [ ] Account deletion tested (Settings → Delete Account)

### Apple App Store Specific
- [ ] App reviewed in TestFlight first (minimum 1 week)
- [ ] Location permission dialog appears correctly (first launch)
- [ ] Background location dialog justified in App Review notes (see Section 1)
- [ ] No crashes on iPhone 12 (iOS 16+) and iPhone 15 (iOS 17+)
- [ ] Landscape mode disabled (confirmed — portrait-only in Info.plist)
- [ ] App clip optional (not required for v1.0)

### Google Play Specific  
- [ ] Data Safety form completed (see Section 1)
- [ ] Target API level = 34 (Android 14) — confirm in build.gradle.kts
- [ ] `com.example.*` package NOT used (confirmed: `com.mert.usoutdoor`)
- [ ] AAB uploaded (not APK)
- [ ] Content rating questionnaire completed (likely "Everyone")
- [ ] App tested on Android 10 (API 29) minimum

---

## 📊 7. App Size Targets

| Platform | Current | Target | Method |
|----------|---------|--------|--------|
| Android AAB | ~45 MB | < 30 MB | minify + shrink + split ABIs |
| iOS IPA | ~55 MB | < 40 MB | Bitcode disabled, strip symbols |

**Android ABI Split** (add to build.gradle.kts):
```kotlin
splits {
    abi {
        isEnable = true
        reset()
        include("arm64-v8a", "armeabi-v7a", "x86_64")
        isUniversalApk = false
    }
}
```

---

*US Outdoor Navigator — Built with Flutter 3.x | Python FastAPI Backend | OpenStreetMap Data*  
*© 2026 Mert — All rights reserved*
