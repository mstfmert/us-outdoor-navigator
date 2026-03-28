# US Outdoor Navigator

Profesyonel bir Flutter mobil uygulaması ve FastAPI backend sistemi. Kampçılar ve karavancılar için gerçek zamanlı güvenlik, lojistik ve harita navigasyonu sağlar.

## 🎯 Özellikler

### 📱 Flutter Frontend (Mobil Uygulama)
- **Harita**: Mapbox ile gece modu harita, kamp alanları ve yangın noktaları gösterimi
- **Güvenlik**: Canlı güvenlik barı - DANGER durumunda yanıp sönen EVACUATION WARNING
- **Lojistik**: Kamp alanı detayları (ücret, yakıt mesafesi, RV uzunluk limiti)
- **Raporlama**: Kullanıcı geri bildirim sistemi (ayı görüldü, yol kapalı vb.)
- **Offline Desteği**: shared_preferences ile harita verisi ve acil durum numaraları önbelleği

### 🐍 FastAPI Backend
- **Güvenlik API**: NASA yangın verilerini çekme ve analiz etme
- **Lojistik API**: Kamp alanı ve benzin istasyonu verileri
- **Rapor API**: Kullanıcı raporlarını işleme

## 🚀 Kurulum

### Backend (FastAPI)

1. Python 3.8+ yüklü olduğundan emin olun
2. Backend dizinine gidin:
   ```bash
   cd backend
   ```
3. Gereksinimleri yükleyin:
   ```bash
   pip install -r requirements.txt
   ```
4. NASA API anahtarını alın (opsiyonel):
   - https://firms.modaps.eosdis.nasa.gov/api/ adresinden kayıt olun
   - `wildfire_service.py` dosyasındaki `api_key` değişkenini güncelleyin
5. Backend'i başlatın:
   ```bash
   python run_backend.py
   ```
   veya
   ```bash
   python api_gateway.py
   ```

### Frontend (Flutter)

1. Flutter SDK'yı yükleyin (3.0+)
2. Frontend dizinine gidin:
   ```bash
   cd frontend
   ```
3. Bağımlılıkları yükleyin:
   ```bash
   flutter pub get
   ```
4. Mapbox token'ını alın:
   - https://account.mapbox.com/ adresinden kayıt olun
   - `lib/main.dart` ve `lib/screens/map_screen.dart` dosyalarındaki `YOUR_MAPBOX_ACCESS_TOKEN_HERE` değişkenini güncelleyin
5. Uygulamayı çalıştırın:
   ```bash
   flutter run
   ```

## 📁 Proje Yapısı

### Backend
```
backend/
├── api_gateway.py          # Ana FastAPI uygulaması
├── wildfire_service.py     # NASA yangın verisi servisi
├── logistics_service.py    # Kamp alanı ve benzin istasyonu servisi
├── run_backend.py         # Başlatma script'i
└── requirements.txt       # Python bağımlılıkları
```

### Frontend
```
frontend/lib/
├── main.dart              # Uygulama giriş noktası
├── screens/
│   └── map_screen.dart    # Ana harita ekranı
├── models/
│   ├── app_state.dart     # Uygulama durumu
│   ├── location.dart      # Konum modeli
│   ├── campground.dart    # Kamp alanı modeli
│   └── fire_point.dart    # Yangın noktası modeli
├── services/
│   ├── api_service.dart   # Backend API iletişimi
│   ├── map_service.dart   # Mapbox harita işlemleri
│   └── cache_service.dart # Offline önbellek yönetimi
└── widgets/
    ├── safety_bar_widget.dart     # Güvenlik barı
    ├── logistics_panel.dart       # Kamp alanı paneli
    ├── report_button.dart         # Rapor butonu
    └── offline_indicator.dart     # Offline göstergesi
```

## 🔧 API Endpoint'leri

### GET `/`
- **Açıklama**: Sistem durumu kontrolü
- **Yanıt**:
  ```json
  {
    "status": "online",
    "systems": ["NASA_Fire_Service", "Logistics_Engine", "Geo_Calculator"],
    "timestamp": "2026-03-27T20:22:25"
  }
  ```

### POST `/get_full_report`
- **Açıklama**: Kullanıcı konumu için tüm verileri getirir
- **İstek Gövdesi**:
  ```json
  {
    "lat": 33.8734,
    "lon": -115.9010,
    "user_id": "user123",
    "max_camp_price": 100.0
  }
  ```
- **Yanıt**:
  ```json
  {
    "metadata": { ... },
    "safety": {
      "status": "SAFE|DANGER",
      "message": "Güvenlik durumu mesajı"
    },
    "logistics": [
      {
        "camp_info": { ... },
        "distance_to_user": 15.5,
        "nearest_fuel_miles": 8.2,
        "fuel_station_name": "Shell - 24/7 Diesel"
      }
    ]
  }
  ```

## 🧪 Test

### Backend Testi
```bash
cd backend
python run_backend.py
# Tarayıcıda http://localhost:8000/docs adresini açın
```

### Flutter Testi
```bash
cd frontend
# Android emülatör veya fiziksel cihazda
flutter run
# iOS simülatör için
flutter run -d "iPhone Simulator"
```

## ⚙️ Yapılandırma

### Backend Yapılandırması
1. **NASA API Anahtarı**: `wildfire_service.py` dosyasında
2. **Sunucu Portu**: `api_gateway.py` dosyasında (varsayılan: 8000)
3. **Mock Veriler**: `logistics_service.py` dosyasında kamp alanı ve benzin istasyonu verileri

### Frontend Yapılandırması
1. **Mapbox Token**: `main.dart` ve `map_screen.dart` dosyalarında
2. **Backend URL**: `api_service.dart` dosyasında (varsayılan: http://localhost:8000)
3. **Offline Cache Süresi**: `cache_service.dart` dosyasında (varsayılan: 6 saat)

## 🆘 Sorun Giderme

### Backend Başlamıyor
- Python bağımlılıklarını kontrol edin: `pip install -r requirements.txt`
- Port 8000'in kullanımda olmadığından emin olun
- NASA API anahtarı gerekli değil (mock veri kullanılacak)

### Flutter Derleme Hatası
- Bağımlılıkları güncelleyin: `flutter pub get`
- Mapbox token'ını güncelleyin
- Android/iOS yapılandırmasını kontrol edin

### Harita Gösterilmiyor
- Mapbox token'ının geçerli olduğundan emin olun
- İnternet bağlantısını kontrol edin
- GPS izinlerini kontrol edin

## 📝 Katkıda Bulunma

1. Bu repository'yi fork edin
2. Yeni bir branch oluşturun: `git checkout -b feature/yeni-özellik`
3. Değişikliklerinizi commit edin: `git commit -am 'Yeni özellik eklendi'`
4. Branch'inizi push edin: `git push origin feature/yeni-özellik`
5. Pull Request oluşturun

## 📄 Lisans

MIT License

---

## 🎨 Ekran Görüntüleri (Planlanan)

1. **Ana Harita**: Gece modu harita, kamp alanı ve yangın ikonları
2. **Güvenlik Barı**: DANGER durumunda yanıp sönen kırmızı bar
3. **Kamp Paneli**: Kamp detayları, fiyat, yakıt mesafesi
4. **Rapor Ekranı**: Kullanıcı geri bildirim formu

## 🔮 Gelecek Güncellemeler

- [ ] Gerçek zamanlı hava durumu entegrasyonu
- [ ] Topluluk yorumları ve puanlamaları
- [ ] Rezervasyon sistemi entegrasyonu
- [ ] Yol durumu ve trafik bilgileri
- [ ] SOS butonu ve acil durum iletişimi