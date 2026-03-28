#!/usr/bin/env python3
"""
US Outdoor Navigator Backend Server
Bu script backend FastAPI sunucusunu başlatır.
"""

import subprocess
import sys
import os

def check_dependencies():
    """Gerekli Python paketlerini kontrol eder."""
    required_packages = ['fastapi', 'uvicorn', 'pandas', 'geopy', 'requests', 'pydantic']
    missing = []
    
    for package in required_packages:
        try:
            __import__(package)
        except ImportError:
            missing.append(package)
    
    if missing:
        print(f"Eksik paketler: {', '.join(missing)}")
        print("requirements.txt'den kurmak için: pip install -r requirements.txt")
        return False
    return True

def start_server():
    """FastAPI sunucusunu başlatır."""
    print("=" * 60)
    print("US Outdoor Navigator Backend Server")
    print("=" * 60)
    print("\n⚠️  ÖNEMLİ NOTLAR:")
    print("1. NASA API anahtarı gerekiyor (wildfire_service.py'de ayarlanmalı)")
    print("2. Sunucu varsayılan olarak http://localhost:8000 adresinde çalışacak")
    print("3. API testi için: http://localhost:8000/docs")
    print("=" * 60)
    
    try:
        # API Gateway'i import et ve çalıştır
        from api_gateway import app
        import uvicorn
        
        print("\n✅ Sunucu başlatılıyor...")
        print("📡 API Endpoint: http://localhost:8000")
        print("📚 API Dokümantasyonu: http://localhost:8000/docs")
        print("🏥 Health Check: http://localhost:8000/")
        print("\n🛑 Durdurmak için CTRL+C tuşlarına basın\n")
        
        uvicorn.run("api_gateway:app", host="0.0.0.0", port=8000, reload=True)
        
    except KeyboardInterrupt:
        print("\n\n✅ Sunucu kapatılıyor...")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Hata oluştu: {e}")
        sys.exit(1)

def test_api():
    """API'yi basit bir test ile kontrol eder."""
    import requests
    import time
    
    print("\n🧪 API testi yapılıyor...")
    
    # Sunucunun başlamasını bekle
    time.sleep(2)
    
    try:
        response = requests.get("http://localhost:8000/", timeout=5)
        if response.status_code == 200:
            print("✅ Health check başarılı!")
            print(f"📊 Yanıt: {response.json()}")
            return True
        else:
            print(f"❌ Health check başarısız: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ Sunucuya bağlanılamadı")
        return False

def main():
    """Ana fonksiyon."""
    if not check_dependencies():
        print("\nLütfen eksik paketleri yükleyin ve tekrar deneyin.")
        sys.exit(1)
    
    # Sunucuyu başlat
    start_server()

if __name__ == "__main__":
    main()