# 🍎 Codemagic — iOS App Store Build & Upload Rehberi
**US Outdoor Navigator | Windows'ta iOS Build = Codemagic Cloud (Ücretsiz)**

---

## Neden Codemagic?

Windows'ta Xcode çalışmaz → Codemagic macOS cloud builder'ı kullanarak:
- iOS IPA oluşturur
- Code signing otomatik yapar
- TestFlight'a yükler
- App Store'a submit eder

**Fiyat:** İlk 500 dakika/ay ÜCRETSİZ (iOS build ~15-20 dakika)

---

## 📋 Ön Hazırlık

### 1. Apple Developer Account ($99/yıl)
```
https://developer.apple.com/account
→ Account aktif olmalı
```

### 2. App Store Connect API Key (P8)
```
https://appstoreconnect.apple.com/access/integrations/api
→ Generate API Key
   Name: Codemagic
   Access: App Manager
→ Download .p8 dosyasını indir (sadece 1 kez indirilir!)
→ Key ID'yi not al (örn: ABC123DEF4)
→ Issuer ID'yi not al (örn: 12345678-1234-1234-1234-123456789012)
```

### 3. App Store Connect'te Uygulama Kaydı
```
https://appstoreconnect.apple.com/apps
→ (+) New App
→ iOS
→ Name: US Outdoor Navigator: RV & Camp
→ Bundle ID: com.mert.usoutdoor
→ SKU: usoutdoor-ios-v1
```

### 4. In-App Purchases Tanımla
```
App Store Connect → [Uygulamanız] → Monetization → In-App Purchases
→ (+) Create
   Product ID: com.mert.usoutdoor.explorer_weekly
   Type: Auto-Renewable Subscription
   Price: $9.99
   
→ (+) Create  
   Product ID: com.mert.usoutdoor.nomad_yearly
   Type: Auto-Renewable Subscription
   Price: $59.99
```

---

## 🚀 Codemagic Kurulum Adımları

### Adım 1: Codemagic Hesabı & Repo Bağlantısı
```
1. https://codemagic.io → GitHub ile giriş yap
2. Apps → Add application
3. GitHub repo'yu seç: US-Outdoor-Navigator
4. "Flutter App" türünü seç
5. "Use codemagic.yaml" seç → codemagic.yaml dosyası otomatik algılanır
```

### Adım 2: App Store Connect Integration
```
Codemagic Dashboard → Teams → [Takımınız] → Integrations
→ App Store Connect → Add integration
→ Name: US_Outdoor_ASC
→ Key Identifier: <App Store Connect Key ID>
→ Issuer ID: <App Store Connect Issuer ID>
→ Private Key: <.p8 dosyasının içeriğini yapıştır>
→ Save
```

### Adım 3: Environment Variable Grupları

**Grup 1: `revenuecat_keys`**
| Variable | Value | Secure |
|---|---|---|
| `RC_KEY_ANDROID` | `goog_YOUR_KEY` | ✅ |
| `RC_KEY_IOS` | `appl_YOUR_KEY` | ✅ |

**Grup 2: `android_signing`**
| Variable | Value | Secure |
|---|---|---|
| `KEYSTORE_BASE64` | *(keystore base64 — aşağıda)* | ✅ |
| `CM_KEYSTORE_PASSWORD` | `usoutdoor2026` | ✅ |
| `CM_KEY_ALIAS` | `usoutdoor` | ✅ |
| `CM_KEY_PASSWORD` | `usoutdoor2026` | ✅ |

**Grup 3: `google_play_credentials`**
| Variable | Value | Secure |
|---|---|---|
| `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` | *(Google Cloud JSON)* | ✅ |

#### Keystore'u Base64'e çevir (PowerShell):
```powershell
$bytes = [System.IO.File]::ReadAllBytes("C:\Users\Mert\Desktop\US-Outdoor-Navigator\frontend\android\app\usoutdoor-release.jks")
[System.Convert]::ToBase64String($bytes) | Set-Clipboard
# Pano'ya kopyalandı → KEYSTORE_BASE64 değeri olarak yapıştır
```

### Adım 4: Build Tetikle
```
Codemagic Dashboard → [US-Outdoor-Navigator] → Start new build
→ Branch: main
→ Workflow: ios-app-store
→ Start build

Alternatif (otomatik): git tag push → build otomatik başlar
  git tag v1.0.0
  git push origin v1.0.0
```

---

## 📱 iOS Code Signing (Otomatik)

`codemagic.yaml`'daki script otomatik yapıyor:
```yaml
- keychain initialize
- app-store-connect fetch-signing-files  # Apple'dan otomatik çeker
- keychain add-certificates
- xcode-project use-profiles
```

**Manual signing gerekmez** — Codemagic Apple Developer API üzerinden:
- Distribution certificate oluşturur
- App Store provisioning profile oluşturur
- Xcode'a atar

---

## 🔍 Build Süreci (~20 dakika)

```
[1] Flutter pub get         ~30s
[2] CocoaPods install       ~3 dk
[3] Code signing setup      ~1 dk
[4] flutter build ios       ~5 dk
[5] Xcode archive           ~8 dk
[6] IPA oluşturma           ~2 dk
[7] TestFlight upload       ~2 dk
─────────────────────────────
TOPLAM: ~20-22 dakika
```

---

## ✅ TestFlight'tan App Store'a

```
1. TestFlight build hazır olunca:
   App Store Connect → [Uygulamanız] → TestFlight
   → İç testçilere dağıt (sen dahil)
   → 1-3 gün test et

2. App Store'a submit için:
   App Store Connect → [Uygulamanız] → App Store
   → (+) Sürüm ekle: 1.0.0
   → Screenshots ekle (STORE_SUBMISSION.md'deki gereksinimlere göre)
   → Build seç (TestFlight'taki build)
   → App Review'a gönder → Submit for Review

3. Apple Review süresi: 24-72 saat
```

---

## 🔑 Hızlı Referans

| Bilgi | Değer |
|---|---|
| Bundle ID | `com.mert.usoutdoor` |
| App Name | `US Outdoor Navigator: RV & Camp` |
| API URL | `https://us-outdoor-api-production.up.railway.app` |
| codemagic.yaml | Repo kök dizininde |
| Workflow (iOS) | `ios-app-store` |
| Workflow (Android) | `android-play-store` |

---

## 🆘 Sorun Giderme

**"No provisioning profile"**
→ Apple Developer → Certificates, IDs & Profiles → Bundle ID `com.mert.usoutdoor` kayıtlı mı kontrol et

**"Invalid API key"**  
→ .p8 dosyasının tüm içeriğini (başlık ve alt bilgi dahil) yapıştır:
```
-----BEGIN PRIVATE KEY-----
MIGHAgEA...
-----END PRIVATE KEY-----
```

**"No matching subscriptions"**
→ App Store Connect → In-App Purchases → Status: "Ready to Submit" olmalı
→ RevenueCat Dashboard → Products → App Store Connect'teki ID'lerle eşleşmeli

---

*Codemagic Docs: https://docs.codemagic.io/flutter-publishing/publishing-to-app-store/*
