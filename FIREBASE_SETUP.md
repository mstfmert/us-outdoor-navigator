# Firebase Setup — US Outdoor Navigator
## Status: COMPLETED ✅

Firebase projesi CLI ile tam otomatik oluşturuldu ve yapılandırıldı.

---

## Proje Bilgileri

| Alan | Değer |
|------|-------|
| **Project ID** | `us-outdoor-navigator-app` |
| **Project Number** | `203303398714` |
| **Firebase Console** | https://console.firebase.google.com/project/us-outdoor-navigator-app/overview |
| **Account** | mert.neck@gmail.com |

---

## İndirilen Config Dosyaları

### Android — `google-services.json` ✅
- **Konum:** `frontend/android/app/google-services.json`
- **Package:** `com.mert.usoutdoor`
- **App ID:** `1:203303398714:android:545f65d9d1c4e5c04f7403`
- **API Key:** `AIzaSyAkUdbY_1dPHKyeVjK5bY4YBmom4f39MUI`

### iOS — `GoogleService-Info.plist` ✅
- **Konum:** `frontend/ios/Runner/GoogleService-Info.plist`
- **Bundle ID:** `com.mert.usoutdoor`
- **App ID:** `1:203303398714:ios:8517b5b7f1438f0e4f7403`
- **API Key:** `AIzaSyD5BSef8F0qNX2ofIYBVKvMnRqW8Nqucrw`

---

## Kalan 2 Manuel Adım (Firebase Console)

### 1. Crashlytics Aktif Et
1. https://console.firebase.google.com/project/us-outdoor-navigator-app/crashlytics adresine git
2. **"Enable Crashlytics"** butonuna tıkla
3. İlk crash raporu uygulamayı test cihazında çalıştırınca otomatik gelir

### 2. Google Analytics Aktif Et
1. https://console.firebase.google.com/project/us-outdoor-navigator-app/analytics adresine git
2. **"Enable Google Analytics"** → Default account for Firebase seç
3. `GoogleService-Info.plist` içindeki `IS_ANALYTICS_ENABLED` otomatik `true` olur

> **Not:** Bu 2 adım Firebase Console'da "Enable" butonuna tek tıklamadır, başka bir şey gerekmez.

---

## Kurulum Özeti

```
✅ firebase projects:create us-outdoor-navigator-app
✅ firebase apps:create ANDROID com.mert.usoutdoor  → App ID: ...android:545f65d9d1c4e5c04f7403
✅ firebase apps:create IOS     com.mert.usoutdoor  → App ID: ...ios:8517b5b7f1438f0e4f7403
✅ google-services.json   → frontend/android/app/
✅ GoogleService-Info.plist → frontend/ios/Runner/
✅ frontend/.firebaserc   → project: us-outdoor-navigator-app
✅ frontend/firebase.json → crashlytics config
```

---

## Flutter Build

```bash
cd frontend
flutter pub get
flutter run                    # debug
flutter build apk --release   # Android release
flutter build ipa              # iOS release (macOS gerekli)
```

---

## Güvenlik Notu

`google-services.json` ve `GoogleService-Info.plist` dosyaları `.gitignore`'a eklenmiştir.
Bu dosyaları **asla** public repo'ya push etmeyin.
