import requests
import pandas as pd
from io import StringIO
from geopy.distance import geodesic
import datetime

class NASAWildfireService:
    def __init__(self):
        # NASA FIRMS API URL (24 saatlik aktif yangınlar - ABD bölgesi)
        # Not: Üretim aşamasında kendi NASA MAPS API anahtarını buraya ekleyeceğiz.
        self.base_url = "https://firms.modaps.eosdis.nasa.gov/api/area/csv/"
        self.api_key = "9c304a6f3951c8055e7804ab7bf04f7f" # NASA FIRMS API Key
        
    def get_active_fires_us(self):
        """
        NASA uydularından ABD üzerindeki son 24 saatlik aktif yangın verilerini çeker.
        """
        # Örnek bölge: ABD sınırlarını kapsayan koordinat kutusu (Bounding Box)
        # format: [west, south, east, north]
        area = "-125,24,-66,50" 
        url = f"{self.base_url}{self.api_key}/VIIRS_SNPP_NRT/{area}/1"
        
        try:
            response = requests.get(url, timeout=10)
            if response.status_code == 200:
                # CSV verisini Pandas DataFrame'e çeviriyoruz
                df = pd.read_csv(StringIO(response.text))
                return df
            else:
                print(f"Hata: NASA API yanıt vermedi. Kod: {response.status_code}")
                return None
        except Exception as e:
            print(f"Kritik Bağlantı Hatası: {e}")
            return None

    def check_safety(self, user_lat, user_lon, fire_df, danger_radius=20.0):
        """
        Kullanıcının etrafındaki yangınları tarar. 
        20 mil (danger_radius) altındaki her şeyi raporlar.
        """
        threats = []
        user_pos = (user_lat, user_lon)

        if fire_df is None or fire_df.empty:
            return {"status": "DATA_ERROR", "message": "Yangın verisi alınamadı!"}

        for _, fire in fire_df.iterrows():
            fire_pos = (fire['latitude'], fire['longitude'])
            distance = geodesic(user_pos, fire_pos).miles
            
            if distance <= danger_radius:
                threats.append({
                    "distance": round(distance, 2),
                    "intensity": fire['bright_ti4'], # Yangın şiddeti (Kelvin)
                    "confidence": fire['confidence']   # Veri güvenilirliği
                })
        
        if threats:
            # En yakın tehdide göre sırala
            threats = sorted(threats, key=lambda x: x['distance'])
            return {
                "status": "DANGER",
                "message": f"DİKKAT! {threats[0]['distance']} mil mesafede aktif yangın saptandı!",
                "threat_count": len(threats),
                "nearest_threat": threats[0]
            }
        
        return {"status": "SAFE", "message": "Yakın çevrede aktif yangın saptanmadı."}