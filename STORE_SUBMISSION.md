# 🏕️ US Outdoor Navigator — Play Store & App Store Submission Guide
**v1.0.0 | Package: `com.mert.usoutdoor` | Bundle ID: `com.mert.usoutdoor` | Last Updated: March 2026**

---

## ✅ Pre-Launch Master Checklist

### Her İki Platform (Ortak)
- [x] `build.gradle.kts` — NDK 27, Core Library Desugaring, Signing Config
- [x] `AndroidManifest.xml` — İzinler gözden geçirildi, background location kaldırıldı
- [x] `key.properties` — Keystore hazır (`frontend/android/app/usoutdoor-release.jks`)
- [x] `Info.plist` — Tüm NSUsageDescription anahtarları mevcut
- [x] Privacy Policy — Backend `/privacy` endpoint'i aktif
- [x] Terms of Service — Backend `/terms` endpoint'i aktif
- [x] Account Deletion — `DELETE /delete_account` endpoint'i mevcut
- [x] `app_config.dart` — RC key `--dart-define` ile inject edilebilir
- [ ] RevenueCat Android Key → `--dart-define=RC_KEY_ANDROID=goog_xxxx`
- [ ] RevenueCat iOS Key → `--dart-define=RC_KEY_IOS=appl_xxxx`
- [ ] Railway deploy et → `productionUrl` güncelle
- [ ] Fiziksel cihazda son test (Android + iPhone)
- [ ] App icon 1024×1024 PNG → `assets/icons/app_icon_1024.png`
- [ ] `dart run flutter_launcher_icons` çalıştır
- [ ] Screenshot'lar hazırla (her iki platform için)

### Android-Spesifik
- [ ] Play Console'da Data Safety formu doldur
- [ ] Content Rating anketi tamamla
- [ ] AAB yükle (APK değil)
- [ ] Target API 34 olduğunu doğrula

### iOS-Spesifik
- [ ] Apple Developer Program aktif ($99/yıl)
- [ ] App Store Connect'te uygulama kaydı oluştur
- [ ] RevenueCat'te iOS In-App Purchases tanımla
- [ ] TestFlight'ta en az 1 hafta test
- [ ] Xcode → Archive → Distribute App
- [ ] App Review Notes doldur (SOS background location justification)

---

## 📱 Google Play Store

### App Metadata
| Alan | Değer |
|---|---|
| **App Name** | US Outdoor Navigator |
| **Package** | `com.mert.usoutdoor` |
| **Category** | Travel & Local → Outdoor |
| **Content Rating** | Everyone |
| **Price** | Free (In-App Purchases) |
| **Target SDK** | 34 (Android 14) |
| **Min SDK** | 21 (Android 5.0) |

### Short Description (80 karakter)
```
Find campgrounds, track wildfires & RV routes across all 50 US states.
```

### Full Description (4000 karakter max)
```
🏕️ US OUTDOOR NAVIGATOR — The Complete American Wilderness Companion

Navigate the great outdoors with confidence. US Outdoor Navigator combines
real-time wildfire alerts, NOAA weather intelligence, and 1,500+ campground
database into one powerful app built for campers, RV travelers, and
wilderness adventurers.

━━━ CORE FEATURES (FREE) ━━━

🔥 LIVE WILDFIRE RADAR
• Real-time NASA FIRMS satellite fire detection
• Color-coded safety zones (SAFE / CAUTION / DANGER / CRITICAL)
• Automatic evacuation recommendations

⛺ 1,500+ CAMPGROUNDS
• California, Arizona & Utah — free forever
• Detailed filters: price, RV length, amenities, water/hookups
• Community-verified conditions

🌩️ WEATHER SENTINEL
• NOAA/NWS integration — hourly forecast + severe alerts
• Night safety scoring (lightning, flood, extreme cold)
• Sound + visual alarms for critical conditions

🆘 SOS PANIC BUTTON
• One-tap emergency with GPS coordinates
• Dead Man's Switch auto-alert if check-in missed
• Location logged even without cell signal

📊 COMMUNITY REPORTS
• Trail conditions, fire hazards, road closures
• Real-time from fellow adventurers

━━━ PRO FEATURES ━━━

🗺️ ALL 50 STATES
Unlock campgrounds across all US states + Alaska & Hawaii

🚐 RV GUARD
• RV-friendly routing (bridge/tunnel height clearance)
• Nearest dump stations, fresh water, propane

☀️ SOLAR OPTIMIZER
• Panel efficiency by location & tree cover
• Generator vs. solar recommendation

🛰️ STARLINK FINDER (AR)
• Augmented reality satellite dish pointer
• Signal quality prediction

⚖️ DIGITAL LEVELING
• Precision campsite leveler using device sensors

🌡️ GROUND RISK SCORE
• Mud risk after rainfall by terrain type
• 4x4 vs RV passability rating

━━━ SAFETY FIRST ━━━

Every safety feature (wildfire radar, weather alerts, SOS, community
reports) is FREE. No subscription required for emergency tools.

━━━ SUBSCRIPTIONS ━━━

Explorer Weekly: $9.99/week (3-day free trial)
Nomad Pro Yearly: $59.99/year — save 50% ($5.00/month)

Cancel anytime in Google Play → Subscriptions.
```

### In-App Products (Play Console → Monetize → Products)
| Product ID | Type | Name | Price | Trial |
|---|---|---|---|---|
| `com.mert.usoutdoor.explorer_weekly` | Auto-Renewing Subscription | Explorer Weekly | $9.99/wk | 3 days |
| `com.mert.usoutdoor.nomad_yearly` | Auto-Renewing Subscription | Nomad Pro Yearly | $59.99/yr | 3 days |

---

## 🔐 Android Permission Declarations

### Data Safety Form — Veri Türleri

| Veri Türü | Toplandı mı? | Paylaşıldı mı? | Amaç | Zorunlu mu? | Kullanıcı Kontrolü |
|---|---|---|---|---|---|
| Precise Location | Evet | Hayır | Kamp arama, SOS, yangın mesafesi | Hayır (opt-in) | Evet |
| Approximate Location | Evet | Hayır | Fallback GPS | Hayır (opt-in) | Evet |
| Background Location | Evet | Hayır | SOS Dead Man's Switch | Hayır (opt-in) | Evet |
| Crash Logs | Hayır | — | — | — | — |
| Analytics | Hayır | — | — | — | — |

**Data Safety Declaration Text:**
```
This app collects device location to find nearby campgrounds, display
wildfire proximity alerts, and provide an opt-in SOS emergency check-in
feature. Background location is used only when the user manually activates
the Dead Man's Switch safety feature. Location data is never sold, shared
with third parties, or used for advertising.
```

### AndroidManifest.xml — İzin Tablosu

| İzin | Neden? | Zorunlu |
|---|---|---|
| `ACCESS_FINE_LOCATION` | Yakın kamp alanları, yangın, RV lojistik | Evet |
| `ACCESS_COARSE_LOCATION` | Hassas GPS yokken fallback | Evet |
| `INTERNET` | NOAA, NASA FIRMS, kamp verisi | Evet |
| `ACCESS_NETWORK_STATE` | Offline mod → cache göster | Evet |
| `POST_NOTIFICATIONS` | Hava durumu, Dead Man's Switch timer | Evet |
| `SCHEDULE_EXACT_ALARM` | Dead Man's Switch geri sayım | Evet |
| `RECEIVE_BOOT_COMPLETED` | Yeniden başlatma sonrası DMS restore | Evet |
| `FOREGROUND_SERVICE` | DMS bildirimi uygulama açıkken | Evet |
| `CAMERA` | Starlink AR (Pro özelliği) | Hayır |
| `VIBRATE` | SOS haptic feedback | Hayır |
| `READ_EXTERNAL_STORAGE` | Offline harita tile cache (Android ≤12) | Hayır |

### ⚠️ Background Location — KULLANILMIYOR
`ACCESS_BACKGROUND_LOCATION` **AndroidManifest.xml'den KALDIRILDI.**
Uygulama yalnızca **foreground'da (açıkken)** konum toplar.
SOS Dead Man's Switch son cached foreground konumu kullanır.

---

## 🍎 Apple App Store

### App Store Connect — App Metadata

| Alan | Değer |
|---|---|
| **App Name** | US Outdoor Navigator: RV & Camp |
| **Bundle ID** | `com.mert.usoutdoor` |
| **SKU** | `usoutdoor-ios-v1` |
| **Primary Category** | Navigation |
| **Secondary Category** | Travel |
| **Content Rating** | 4+ |
| **Price** | Free (In-App Purchases) |
| **Availability** | United States (tüm bölgeler) |
| **Primary Language** | English (U.S.) |

### Subtitle (30 karakter max — App Store)
```
Survival Maps & SOS Safety
```

### Promotional Text (170 karakter — güncellenebilir)
```
🔥 New: Ground Risk Score now shows mud & passability ratings by terrain. Stay safe on every trail.
```

### Keywords (100 karakter max, virgülle ayrılmış)
```
camping,campground,RV,wildfire,hiking,trail,outdoor,survival,SOS,NOAA,weather,overlander,national park
```
> ⚠️ App adında ve subtitle'da geçen kelimeleri burada tekrarlama — Apple puanlamayı düşürür.

### Full Description (4000 karakter max)
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

### Support & Marketing URLs
| Tür | URL |
|---|---|
| Support URL | `https://us-outdoor-api-production.up.railway.app/support` |
| Marketing URL | `https://us-outdoor-api-production.up.railway.app` |
| Privacy Policy URL | `https://us-outdoor-api-production.up.railway.app/privacy` |

---

## 🔒 iOS Privacy Permissions (Info.plist Özeti)

| NSUsage Key | Açıklama | Neden? |
|---|---|---|
| `NSLocationWhenInUseUsageDescription` | Uygulama açıkken konum | Yakın kamp alanları, yangın mesafesi |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Her zaman konum | SOS Dead Man's Switch |
| `NSLocationAlwaysUsageDescription` | Arka plan konum (eski iOS) | SOS güvenlik check-in |
| `NSCameraUsageDescription` | Kamera | Starlink AR (Pro) |
| `NSMotionUsageDescription` | Hareket sensörü | Dijital seviye (Pro) |
| `NSPhotoLibraryUsageDescription` | Fotoğraf kütüphanesi | Offline harita tile kayıt |
| `NSUserNotificationUsageDescription` | Bildirimler | Hava durumu + SOS alarm |

### UIBackgroundModes (Info.plist)
```xml
<key>UIBackgroundModes</key>
<array>
    <string>location</string>   <!-- SOS Dead Man's Switch -->
    <string>fetch</string>      <!-- Arka plan veri güncelleme -->
</array>
```

### App Store Privacy Nutrition Labels
> App Store Connect → App Privacy → Privacy Practices

| Veri Türü | Kullanım | Kimliğe Bağlı mı? | İzleme? |
|---|---|---|---|
| Precise Location | App Functionality | Hayır | Hayır |
| Coarse Location | App Functionality | Hayır | Hayır |
| Background Location | App Functionality (SOS opt-in) | Hayır | Hayır |
| Camera | App Functionality (Pro, opt-in) | Hayır | Hayır |
| Motion/Fitness | App Functionality (Pro, opt-in) | Hayır | Hayır |
| Photos | App Functionality (offline cache) | Hayır | Hayır |

> ✅ **Reklam / Analytics / Üçüncü Taraf Paylaşım: YOK**

---

## 💳 iOS In-App Purchases (App Store Connect)

### App Store Connect → Monetization → Subscriptions
**Subscription Group Adı:** `US Outdoor Pro`

| Product ID | Tür | İsim | Fiyat | Tier | Deneme |
|---|---|---|---|---|---|
| `com.mert.usoutdoor.explorer_weekly` | Auto-Renewable | Explorer Weekly | $9.99 | Tier 10 | 3 gün |
| `com.mert.usoutdoor.nomad_yearly` | Auto-Renewable | Nomad Pro Yearly | $59.99 | Tier 60 | 3 gün |

### Subscription Localization (App Store Connect → Subscriptions → [Ürün] → Localizations)
**Explorer Weekly:**
- Display Name: `Explorer Weekly`
- Description: `All 50 states campgrounds, RV routing, solar planner & more.`

**Nomad Pro Yearly:**
- Display Name: `Nomad Pro Yearly`
- Description: `Full access to all Pro features. Best value — just $5/month.`

---

## 📸 Screenshot Gereksinimleri

### Google Play Screenshots
| Cihaz Tipi | Adet | Çözünürlük |
|---|---|---|
| Phone | 2–8 | 1080×1920 px min |
| 7" Tablet | 2+ | Opsiyonel, önerilir |
| Feature Graphic | 1 | 1024×500 px |

### App Store Screenshots (Xcode Simülatörden)
| Cihaz | Boyut | Adet | Çözünürlük |
|---|---|---|---|
| iPhone 6.7" (15 Pro Max) | 6.7" | 3–10 | 1290×2796 px |
| iPhone 6.5" (14 Plus) | 6.5" | 3–10 | 1242×2688 px |
| iPad Pro 12.9" (3rd+) | 12.9" | 3–10 | 2048×2732 px |

> 💡 **6.7" ekran zorunlu.** Diğerleri opsiyonel. iPad ekranı eklenirse ayrıca yükle.

### Screenshot Sırası (Her İki Platform)
1. 🗺️ Map screen — aktif yangın pinleri görünür, wildfire heatmap
2. 🆘 SOS panic button close-up — uzun basış animasyonu
3. 🚐 RV Guard route — köprü yükseklik uyarısı ile
4. 🌩️ Weather Sentinel — gece kritik uyarı ekranı
5. 💳 Paywall/Pro features screen
6. ⛺ Campground detail — filter bar ve detay paneli

---

## 🚀 Build Komutları

### Debug (local test)
```bash
cd frontend
flutter run
```

### Release AAB (Play Store)
```bash
cd frontend
flutter build appbundle --release \
  --dart-define=API_URL=https://<your-app>.railway.app \
  --dart-define=RC_KEY_ANDROID=goog_YOUR_RC_KEY
```

### Release APK (direkt yükleme testi)
```bash
cd frontend
flutter build apk --release \
  --dart-define=API_URL=https://<your-app>.railway.app \
  --dart-define=RC_KEY_ANDROID=goog_YOUR_RC_KEY
```

### iOS IPA (App Store)
```bash
cd frontend
flutter build ios --release \
  --dart-define=API_URL=https://<your-app>.railway.app \
  --dart-define=RC_KEY_IOS=appl_YOUR_RC_KEY

# Ardından Xcode'da:
# Product → Archive → Distribute App → App Store Connect → Upload
```

### iOS Simulator Test (screenshot için)
```bash
# iPhone 15 Pro Max simülatöründe çalıştır
cd frontend
flutter run -d "iPhone 15 Pro Max"
```

---

## 🏗️ Backend Deploy (Railway)

```bash
# 1. Railway hesabı oluştur: railway.app
# 2. CLI kur:
npm install -g @railway/cli
railway login

# 3. Deploy:
cd backend
railway init           # Proje oluştur
railway up             # Deploy et

# 4. Ortam değişkenleri (Railway Dashboard → Variables):
#    ENVIRONMENT = production
#    NASA_API_KEY = <firms.modaps.eosdis.nasa.gov'dan al>
#    SECRET_KEY   = <güçlü random string>

# 5. Deploy URL'ini al → app_config.dart → productionUrl'e gir
# Örnek: https://us-outdoor-api-production.up.railway.app
```

### Deploy Sonrası URL Güncelleme
```dart
// frontend/lib/config/app_config.dart
static const String productionUrl = 'https://US_OUTDOOR_API.railway.app';
```

---

## 🍎 App Store Connect — Adım Adım Yükleme

### 1. Uygulama Kaydı
```
App Store Connect (appstoreconnect.apple.com)
→ My Apps → (+) New App
→ Platform: iOS
→ Name: US Outdoor Navigator: RV & Camp
→ Primary Language: English (U.S.)
→ Bundle ID: com.mert.usoutdoor  (Xcode'da oluşturulmuş olmalı)
→ SKU: usoutdoor-ios-v1
→ User Access: Full Access
```

### 2. Xcode Signing
```
Xcode → Runner.xcworkspace → Runner target
→ Signing & Capabilities
→ Team: <Apple Developer Account'un>
→ Bundle Identifier: com.mert.usoutdoor
→ Provisioning Profile: Automatic (Xcode Managed)
```

### 3. Gerekli Capabilities (Xcode → Signing & Capabilities → +)
- ✅ **Push Notifications** — Hava durumu + SOS bildirimleri
- ✅ **Background Modes** → Location updates + Background fetch
- ✅ **In-App Purchase** — RevenueCat subscription
- ✅ **Maps** — Flutter MapLibre/OSM entegrasyonu

### 4. Archive & Upload
```
Xcode → Product → Destination: Any iOS Device (arm64)
→ Product → Archive
→ Distribute App → App Store Connect
→ Upload → Next → Next → Upload

# Yükleme tamamlandıktan sonra:
# App Store Connect → TestFlight → Build'i bekle (~30 dk)
```

### 5. App Review Notları
> App Store Connect → App Version → App Review Information → Notes

```
TEST ACCOUNT: No login required — the app is fully anonymous.
User ID is device-generated UUID; no email/password needed.

BACKGROUND LOCATION — SOS DEAD MAN'S SWITCH:
Background location is used exclusively for one opt-in safety feature:
the "Dead Man's Switch." When a backcountry camper enables this feature,
the app performs a GPS check-in every 30 minutes. If the user misses
a check-in (e.g., injury or emergency), their last known coordinates
are sent to their designated emergency contact.

This feature:
  - Is NOT enabled by default
  - Requires explicit user activation from Settings screen
  - Shows a persistent foreground notification when active
  - Does not transmit location to any server — only to the emergency contact
  - Can be disabled at any time

CAMERA — STARLINK AR VIEW (Pro Feature Only):
Camera is only accessed when the user navigates to the Starlink AR screen.
It is never requested at app launch or in the background.
Camera feed is processed entirely on-device; nothing is transmitted or stored.

SOS PANIC BUTTON:
One long-press logs GPS coordinates locally and notifies the emergency
contact. Direct 911 calling is NOT automated — users are instructed to
call 911 themselves. No SMS is sent automatically.

SUBSCRIPTION:
Both plans include a 3-day free trial. Cancel anytime via App Store Settings.
```

---

## 🔗 Legal URLs

Tüm URL'ler Railway deploy sonrası aktif olur:

| Sayfa | URL |
|---|---|
| Privacy Policy | `https://<your-railway-app>.railway.app/privacy` |
| Terms of Service | `https://<your-railway-app>.railway.app/terms` |
| Support | `https://<your-railway-app>.railway.app/support` |
| Account Deletion | `DELETE https://<your-railway-app>.railway.app/delete_account?user_id=X` |

> ⚠️ **App Store için Support URL zorunludur.** Boş bırakılamaz.  
> ⚠️ **Her iki platform için Privacy Policy URL aktif (live) olmalıdır.**

---

## 📋 Review Notları Özeti (Google/Apple Reviewer İçin)

| Konu | Detay |
|---|---|
| Test Hesabı | Gerekmez — uygulama tamamen anonim |
| Arka Plan Konum | Yalnızca SOS Dead Man's Switch (opt-in) |
| Kamera | Yalnızca Starlink AR ekranında (Pro, opt-in) |
| SOS | GPS koordinatları local kaydedilir; 911 otomatik aranmaz |
| Subscription | 3 günlük ücretsiz deneme; istediğin zaman iptal |
| Reklam/Analytics | Yok — kullanıcı verisi asla satılmaz/paylaşılmaz |

---

## 📊 App Boyutu Hedefleri

| Platform | Tahmini | Hedef | Yöntem |
|---|---|---|---|
| Android AAB | ~45 MB | < 30 MB | `minify + shrinkResources + ABI split` |
| iOS IPA | ~55 MB | < 40 MB | Bitcode kapalı, strip symbols |

### Android ABI Split (`build.gradle.kts`)
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

## 🛠️ Sorun Giderme

### Flutter Build Hataları
```bash
# Cache temizle
flutter clean && flutter pub get

# iOS pod'larını güncelle
cd frontend/ios && pod install --repo-update
```

### Android Keystore Hatası
```bash
# key.properties yolunu doğrula
cat frontend/android/key.properties
# storeFile=app/usoutdoor-release.jks → dosyanın burada olduğunu kontrol et
ls frontend/android/app/usoutdoor-release.jks
```

### RevenueCat "No Offerings" Hatası
- App Store Connect → Subscriptions → Status: **Approved** olmalı
- RevenueCat Dashboard → Offerings → Default offering oluşturulmalı
- Product ID'ler birebir eşleşmeli: `com.mert.usoutdoor.explorer_weekly`

### iOS "Missing Compliance" Uyarısı
```
App Store Connect → Build → Missing Compliance
→ Does your app use encryption? → No (veya sadece HTTPS kullanıyorum: Yes, Exempt)
```

---

## 📅 Yayın Zaman Çizelgesi (Tahmini)

| Adım | Süre | Platform |
|---|---|---|
| Backend deploy (Railway) | ~15 dk | — |
| Android AAB build | ~5 dk | Android |
| Play Console review | 1–3 gün | Android |
| iOS build + upload | ~20 dk | iOS |
| TestFlight iç test | 1 hafta | iOS |
| App Store review | 24–72 saat | iOS |
| **Canlıya çıkış** | **~10 gün toplam** | **Her iki platform** |

---

*US Outdoor Navigator — Flutter 3.x | Python FastAPI Backend | OpenStreetMap Data*  
*© 2026 Mert — All rights reserved*
