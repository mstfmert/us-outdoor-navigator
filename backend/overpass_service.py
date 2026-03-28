"""
OverpassService — OpenStreetMap Overpass API üzerinden POI verisi çeker.
API anahtarı gerekmez. Yakıt, EV şarj, market, karavan tamir, ekipman mağazası.
"""
import requests
import math
import json
from typing import List, Dict, Optional

OVERPASS_URL = "https://overpass-api.de/api/interpreter"
TIMEOUT_SECONDS = 20


class OverpassService:

    # ── Overpass QL sorguları ───────────────────────────────────────────────
    QUERIES = {
        "fuel":          '[out:json][timeout:20]; node["amenity"="fuel"](around:{r},{lat},{lon}); out body;',
        "rv_fuel":       '[out:json][timeout:20]; (node["amenity"="fuel"]["hgv"="yes"](around:{r},{lat},{lon}); node["amenity"="fuel"]["hgv:lanes"](around:{r},{lat},{lon}); node["amenity"="fuel"]["truck"="yes"](around:{r},{lat},{lon});); out body;',
        "ev":            '[out:json][timeout:20]; node["amenity"="charging_station"](around:{r},{lat},{lon}); out body;',
        "market":        '[out:json][timeout:20]; (node["shop"="supermarket"](around:{r},{lat},{lon}); node["shop"="convenience"](around:{r},{lat},{lon});); out body;',
        "repair":        '[out:json][timeout:20]; (node["shop"="car_repair"](around:{r},{lat},{lon}); node["shop"="caravan"](around:{r},{lat},{lon});); out body;',
        "dump_station":  '[out:json][timeout:20]; (node["amenity"="sanitary_dump_station"](around:{r},{lat},{lon}); node["leisure"="camp_site"]["sanitary_dump_station"="yes"](around:{r},{lat},{lon}); node["sanitary_dump_station"="yes"](around:{r},{lat},{lon});); out body;',
        "potable_water": '[out:json][timeout:20]; (node["amenity"="drinking_water"](around:{r},{lat},{lon}); node["drinking_water"="yes"]["leisure"="camp_site"](around:{r},{lat},{lon}); node["man_made"="water_tap"](around:{r},{lat},{lon});); out body;',
    }

    def fetch(self, lat: float, lon: float, poi_type: str, radius_m: int = 50000) -> List[Dict]:
        """
        Belirli bir POI tipini Overpass API'den çeker.
        radius_m: metre cinsinden arama yarıçapı (varsayılan 50 km)
        """
        query_template = self.QUERIES.get(poi_type)
        if not query_template:
            return []

        query = query_template.format(r=radius_m, lat=lat, lon=lon)

        try:
            resp = requests.post(
                OVERPASS_URL,
                data={"data": query},
                timeout=TIMEOUT_SECONDS
            )
            if resp.status_code != 200:
                print(f"⚠️ Overpass {poi_type}: HTTP {resp.status_code}")
                return []

            raw = resp.json().get("elements", [])
            return [self._enrich(el, poi_type, lat, lon) for el in raw if el.get("lat")]

        except Exception as e:
            print(f"❌ Overpass {poi_type} hatası: {e}")
            return []

    def fetch_all(self, lat: float, lon: float, radius_m: int = 50000) -> Dict[str, List[Dict]]:
        """
        Tüm POI kategorilerini sırayla çeker ve birleştirir.
        """
        result = {}
        for poi_type in self.QUERIES:
            result[poi_type] = self.fetch(lat, lon, poi_type, radius_m)
        return result

    def _enrich(self, el: Dict, poi_type: str, user_lat: float, user_lon: float) -> Dict:
        """Overpass elementini uygulamaya uygun formata dönüştürür."""
        tags = el.get("tags", {})
        lat  = el["lat"]
        lon  = el["lon"]
        dist = self._haversine(user_lat, user_lon, lat, lon)

        return {
            "id":           str(el.get("id", "")),
            "type":         poi_type,
            "name":         tags.get("name") or tags.get("brand") or self._default_name(poi_type),
            "lat":          lat,
            "lon":          lon,
            "phone":        tags.get("phone") or tags.get("contact:phone") or "",
            "hours":        tags.get("opening_hours") or "",
            "address":      self._build_address(tags),
            "distance_miles": round(dist, 2),
            "brand":        tags.get("brand") or "",
            "operator":     tags.get("operator") or "",
        }

    def _default_name(self, poi_type: str) -> str:
        return {
            "fuel":   "Fuel Station",
            "ev":     "EV Charger",
            "market": "Market",
            "repair": "RV Repair",
        }.get(poi_type, "POI")

    def _build_address(self, tags: Dict) -> str:
        parts = [
            tags.get("addr:housenumber", ""),
            tags.get("addr:street", ""),
            tags.get("addr:city", ""),
            tags.get("addr:state", ""),
        ]
        return ", ".join(p for p in parts if p)

    def _haversine(self, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        R = 6371.0
        φ1 = math.radians(lat1)
        φ2 = math.radians(lat2)
        Δφ = math.radians(lat2 - lat1)
        Δλ = math.radians(lon2 - lon1)
        a  = math.sin(Δφ/2)**2 + math.cos(φ1) * math.cos(φ2) * math.sin(Δλ/2)**2
        return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)) * 0.621371


if __name__ == "__main__":
    svc = OverpassService()
    # Joshua Tree NP test
    results = svc.fetch_all(lat=33.8734, lon=-115.9010, radius_m=80000)
    for key, items in results.items():
        print(f"{key}: {len(items)} sonuç")
    # İlk yakıt istasyonunu yazdır
    if results.get("fuel"):
        print(json.dumps(results["fuel"][0], indent=2, ensure_ascii=False))
