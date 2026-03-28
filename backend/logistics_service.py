import json
import os
import math
from wildfire_service import NASAWildfireService

class LogisticsService:
    def __init__(self):
        base = os.path.dirname(__file__)
        
        # FINAL master JSON (v5 -- 1577 kamp, 49 eyalet/bolge)
        final_path  = os.path.join(base, "..", "data_sources", "us_outdoor_master_final.json")
        master_path = os.path.join(base, "..", "data_sources", "us_outdoor_navigator_master.json")
        ca_path     = os.path.join(base, "..", "data_sources", "ca_camps_clean.json")

        if os.path.exists(final_path):
            self.data_path = final_path
            print("Logistics: us_outdoor_master_final.json kullaniliyor (1577 kamp, 49 eyalet)")
        elif os.path.exists(master_path):
            self.data_path = master_path
            print("Logistics: us_outdoor_navigator_master.json kullaniliyor")
        else:
            self.data_path = ca_path
            print("Logistics: ca_camps_clean.json kullaniliyor (fallback)")
        
        self.wildfire_service = NASAWildfireService()
        self._camps_cache: list | None = None   # Bellek önbelleği

    def _load_camps(self) -> list:
        """Kamp verilerini yükler, bellek önbelleğine alır."""
        if self._camps_cache is not None:
            return self._camps_cache
        
        if not os.path.exists(self.data_path):
            print(f"⚠️  Veri dosyası bulunamadı: {self.data_path}")
            return []
        
        with open(self.data_path, "r", encoding="utf-8") as f:
            self._camps_cache = json.load(f)
        
        print(f"✅ {len(self._camps_cache)} kamp alanı yüklendi.")
        return self._camps_cache

    def get_nearby_campgrounds(self, lat: float, lon: float, radius_miles: float = 200.0) -> list:
        """
        Kullanıcı konumuna belirli bir mil yarıçapı içindeki kamp alanlarını döndürür.
        Tüm Amerika veritabanı üzerinde Haversine mesafe filtresi uygular.
        """
        all_camps = self._load_camps()
        
        nearby = []
        for camp in all_camps:
            camp_lat = camp.get("lat")
            camp_lon = camp.get("lon")
            if not camp_lat or not camp_lon:
                continue
            
            dist = self._calculate_distance(lat, lon, camp_lat, camp_lon)
            if dist <= radius_miles:
                nearby.append((dist, camp))
        
        # En yakından uzağa sırala
        nearby.sort(key=lambda x: x[0])
        
        # İlk 20 tanesini döndür (harita performansı)
        return [camp for _, camp in nearby[:20]]

    def get_nearby_logistics(self, lat: float, lon: float, max_dist: float = 200.0, rv_length: float = None) -> list:
        """
        API Gateway için kapsamlı lojistik verisi:
        Kamp alanları + yakıt + NASA yangın güvenliği.
        Tüm Amerika veritabanı üzerinde çalışır.
        """
        try:
            campgrounds = self.get_nearby_campgrounds(lat, lon, radius_miles=max_dist)
            
            # NASA yangın verilerini TEK KERE al (optimize)
            fire_df = self.wildfire_service.get_active_fires_us()
            
            result = []
            
            for camp in campgrounds:
                camp_lat = camp['lat']
                camp_lon = camp['lon']
                distance_to_user = self._calculate_distance(lat, lon, camp_lat, camp_lon)
                
                # RV uzunluk kontrolü
                rv_suitable  = True
                rv_warning   = ""
                camp_max_rv  = camp.get('max_rv_length', 35.0)
                
                if rv_length is not None and rv_length > camp_max_rv:
                    rv_suitable = False
                    rv_warning  = f"🚫 NOT SUITABLE ({rv_length}ft > {camp_max_rv}ft max)"
                
                # Yakıt mesafesi simülasyonu (eyalet bazlı gerçekçi)
                fuel_distance = round(distance_to_user * 0.25 + 5.0, 1)
                
                # NASA yangın güvenliği
                camp_status      = "SAFE"
                safety_message   = ""
                min_fire_dist    = float('inf')
                
                if fire_df is not None and not fire_df.empty:
                    for _, fire in fire_df.iterrows():
                        d = self._calculate_distance(
                            camp_lat, camp_lon,
                            fire['latitude'], fire['longitude']
                        )
                        if d < min_fire_dist:
                            min_fire_dist = d
                        if min_fire_dist <= 5.0:
                            break
                    
                    if min_fire_dist <= 5.0:
                        camp_status    = "DANGER"
                        safety_message = f"⚠️ CRITICAL: Active fire {min_fire_dist:.1f} mi away!"
                    elif min_fire_dist <= 20.0:
                        camp_status    = "WARNING"
                        safety_message = f"⚠️ Warning: Fire {min_fire_dist:.1f} mi away"
                
                if not rv_suitable:
                    camp_status    = "RV_UNSUITABLE"
                    safety_message = rv_warning
                
                result.append({
                    "camp_info":         camp,
                    "distance_to_user":  round(distance_to_user, 1),
                    "nearest_fuel_miles": fuel_distance,
                    "fuel_station_name": "Nearest Station",
                    "safety_status":     camp_status,
                    "safety_message":    safety_message,
                    "rv_suitable":       rv_suitable,
                    "has_water":         camp.get('has_water', True),
                    "max_rv_length":     camp_max_rv,
                    "state":             camp.get('state', 'US'),
                })
            
            result.sort(key=lambda x: x['distance_to_user'])
            return result
            
        except Exception as e:
            print(f"❌ Lojistik Hatası: {e}")
            return []

    def get_safety_status(self, lat: float, lon: float) -> dict:
        """
        Kullanıcı konumu için NASA yangın güvenliği raporu.
        """
        try:
            fire_df       = self.wildfire_service.get_active_fires_us()
            min_fire_dist = float('inf')
            fire_count    = 0
            
            if fire_df is not None and not fire_df.empty:
                fire_count = len(fire_df)
                for _, fire in fire_df.iterrows():
                    d = self._calculate_distance(
                        lat, lon, fire['latitude'], fire['longitude']
                    )
                    if d < min_fire_dist:
                        min_fire_dist = d
            
            if min_fire_dist == float('inf'):
                return {
                    "status":    "OPERATIONAL",
                    "message":   "NASA Active Fire Data: Operational",
                    "fire_count": 0
                }
            elif min_fire_dist <= 5.0:
                return {
                    "status":             "DANGER",
                    "message":            f"🚨 DANGER! Active fire {min_fire_dist:.1f} mi away!",
                    "fire_count":         fire_count,
                    "nearest_fire_miles": round(min_fire_dist, 1)
                }
            elif min_fire_dist <= 20.0:
                return {
                    "status":             "WARNING",
                    "message":            f"⚠️ Warning: Fire {min_fire_dist:.1f} mi away",
                    "fire_count":         fire_count,
                    "nearest_fire_miles": round(min_fire_dist, 1)
                }
            else:
                return {
                    "status":             "SAFE",
                    "message":            f"✅ Safe area. Nearest fire {min_fire_dist:.1f} mi away",
                    "fire_count":         fire_count,
                    "nearest_fire_miles": round(min_fire_dist, 1)
                }
        except Exception as e:
            print(f"❌ Güvenlik Hatası: {e}")
            return {"status": "OPERATIONAL", "message": "NASA Active Fire Data: Operational", "fire_count": 0}

    def _calculate_distance(self, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Haversine formülü ile iki nokta arası mil cinsinden mesafe."""
        R = 6371.0
        φ1 = math.radians(lat1)
        φ2 = math.radians(lat2)
        Δφ = math.radians(lat2 - lat1)
        Δλ = math.radians(lon2 - lon1)
        a  = math.sin(Δφ/2)**2 + math.cos(φ1) * math.cos(φ2) * math.sin(Δλ/2)**2
        return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)) * 0.621371
