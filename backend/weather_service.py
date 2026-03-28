"""
weather_service.py — NOAA/NWS Hava Durumu & Uyari Servisi
Kamp alanlari icin gece sel, yildirim, firtina uyarilarini ceker.
NWS API: api.weather.gov (ucretsiz, anahtar gerektirmez)
"""
import requests
import datetime
from typing import Dict, List

NWS_BASE    = "https://api.weather.gov"
HEADERS     = {"User-Agent": "USOutdoorNavigator/5.0 (contact@usoutdoor.app)", "Accept": "application/geo+json"}
TIMEOUT     = 15

# Kritik uyari tipleri (gece kamp guvenligini etkiler)
CRITICAL_EVENTS = {
    "Flash Flood Warning", "Flash Flood Watch", "Flood Warning",
    "Severe Thunderstorm Warning", "Severe Thunderstorm Watch",
    "Tornado Warning", "Tornado Watch",
    "Winter Storm Warning", "Blizzard Warning",
    "Hurricane Warning", "Hurricane Watch",
    "Excessive Heat Warning", "Red Flag Warning",
    "High Wind Warning", "Dense Fog Advisory"
}

NIGHT_DANGEROUS = {
    "Flash Flood Warning", "Flash Flood Watch",
    "Severe Thunderstorm Warning", "Tornado Warning",
    "Blizzard Warning", "Hurricane Warning"
}


class WeatherService:

    def get_point_metadata(self, lat: float, lon: float) -> Dict:
        """NWS grid noktasini alir (offset endpoint icin)."""
        try:
            r = requests.get(f"{NWS_BASE}/points/{lat:.4f},{lon:.4f}",
                             headers=HEADERS, timeout=TIMEOUT)
            if r.status_code == 200:
                return r.json().get("properties", {})
        except Exception as e:
            print(f"  NWS points hatasi: {e}")
        return {}

    def get_active_alerts(self, lat: float, lon: float, radius_km: int = 50) -> List[Dict]:
        """
        Belirtilen koordinat cevresindeki aktif NWS uyarilarini getirir.
        radius_km: arama yaricapi (km)
        """
        try:
            url = f"{NWS_BASE}/alerts/active"
            params = {"point": f"{lat:.4f},{lon:.4f}", "status": "actual", "urgency": "Immediate,Expected"}
            r = requests.get(url, headers=HEADERS, params=params, timeout=TIMEOUT)

            if r.status_code != 200:
                # Koordinat bazli basarisizsa bolge bazli dene
                params2 = {"area": self._get_state_code(lat, lon)}
                r2 = requests.get(url, headers=HEADERS, params=params2, timeout=TIMEOUT)
                if r2.status_code == 200:
                    return self._parse_alerts(r2.json(), lat, lon)
                return []

            return self._parse_alerts(r.json(), lat, lon)

        except Exception as e:
            print(f"  NWS alerts hatasi: {e}")
            return []

    def get_hourly_forecast(self, lat: float, lon: float) -> List[Dict]:
        """Saatlik hava tahminini getirir (24 saat)."""
        try:
            meta = self.get_point_metadata(lat, lon)
            forecast_url = meta.get("forecastHourly", "")
            if not forecast_url:
                return []

            r = requests.get(forecast_url, headers=HEADERS, timeout=TIMEOUT)
            if r.status_code != 200:
                return []

            periods = r.json().get("properties", {}).get("periods", [])[:24]
            result = []
            for p in periods:
                result.append({
                    "time":          p.get("startTime", ""),
                    "temperature_f": p.get("temperature", 0),
                    "wind_speed":    p.get("windSpeed", ""),
                    "wind_dir":      p.get("windDirection", ""),
                    "short_desc":    p.get("shortForecast", ""),
                    "precip_pct":    p.get("probabilityOfPrecipitation", {}).get("value", 0) or 0,
                    "is_daytime":    p.get("isDaytime", True)
                })
            return result

        except Exception as e:
            print(f"  NWS forecast hatasi: {e}")
            return []

    def get_night_safety_report(self, lat: float, lon: float) -> Dict:
        """
        Gece kamp guvenlik raporu:
        - Aktif uyarilari kontrol et
        - Saatlik tahmin icindeki gece sartlarini degerlendir
        - Kritik uyari varsa ALARM seviyesi don
        """
        alerts   = self.get_active_alerts(lat, lon)
        forecast = self.get_hourly_forecast(lat, lon)

        # Gece saatlerini filtrele (18:00 - 08:00)
        night_forecast = []
        for f in forecast:
            if not f.get("is_daytime", True):
                night_forecast.append(f)

        # Kritik uyari kontrolu
        critical_alerts = [a for a in alerts if a.get("event") in CRITICAL_EVENTS]
        night_dangerous = [a for a in alerts if a.get("event") in NIGHT_DANGEROUS]

        # Yagis + yildirim riski gecede
        rain_risk = any(f.get("precip_pct", 0) >= 60 for f in night_forecast)
        storm_words = ["Thunder", "Lightning", "Storm", "Flood", "Tornado"]
        storm_risk = any(
            any(w.lower() in f.get("short_desc", "").lower() for w in storm_words)
            for f in night_forecast
        )

        # Gece min sicaklik
        night_temps = [f["temperature_f"] for f in night_forecast if "temperature_f" in f]
        min_temp = min(night_temps) if night_temps else None

        # Alarm seviyesi belirle
        if night_dangerous:
            alarm_level = "CRITICAL"
            alarm_msg   = f"KRITIK ALARM: {night_dangerous[0]['event']} uyarisi aktif!"
        elif critical_alerts or storm_risk:
            alarm_level = "WARNING"
            alarm_msg   = f"UYARI: {critical_alerts[0]['event'] if critical_alerts else 'Gece firtina riski'}"
        elif rain_risk:
            alarm_level = "CAUTION"
            alarm_msg   = "Dikkat: Gece yagis olasiligi %60+"
        else:
            alarm_level = "SAFE"
            alarm_msg   = "Gece hava kosullari: Guvenli"

        return {
            "alarm_level":        alarm_level,
            "alarm_message":      alarm_msg,
            "play_sound_alert":   alarm_level in ("CRITICAL", "WARNING"),
            "show_visual_alert":  alarm_level != "SAFE",
            "active_alerts":      critical_alerts[:5],
            "night_forecast":     night_forecast[:8],
            "min_night_temp_f":   min_temp,
            "rain_risk_60pct":    rain_risk,
            "storm_risk":         storm_risk,
            "timestamp":          datetime.datetime.now().isoformat(),
            "data_source":        "NOAA/NWS (api.weather.gov)"
        }

    def _parse_alerts(self, data: Dict, lat: float, lon: float) -> List[Dict]:
        """NWS alert JSON yapisini parse eder."""
        features = data.get("features", [])
        result = []
        for f in features:
            p = f.get("properties", {})
            result.append({
                "id":          p.get("id", ""),
                "event":       p.get("event", ""),
                "severity":    p.get("severity", ""),
                "urgency":     p.get("urgency", ""),
                "headline":    p.get("headline", ""),
                "description": (p.get("description", "") or "")[:300],
                "instruction": (p.get("instruction", "") or "")[:200],
                "onset":       p.get("onset", ""),
                "expires":     p.get("expires", ""),
                "is_critical": p.get("event", "") in CRITICAL_EVENTS,
                "is_night_dangerous": p.get("event", "") in NIGHT_DANGEROUS
            })
        return result

    def _get_state_code(self, lat: float, lon: float) -> str:
        """Koordinata gore tahmini eyalet kodu (NWS area parametresi icin)."""
        # Basit koordinat bazli tahmin (tam dogru degil ama yedek)
        if lat > 60:
            return "AK"
        if lat < 25 and lon < -154:
            return "HI"
        if lat < 30 and lon > -90:
            return "FL"
        if lon < -110:
            return "CA"
        if lon > -80:
            return "NC"
        return "TX"  # Varsayilan merkez


if __name__ == "__main__":
    svc = WeatherService()
    print("Yellowstone NP - Gece Guvenlik Raporu:")
    report = svc.get_night_safety_report(44.4280, -110.5885)
    import json
    print(json.dumps(report, indent=2, ensure_ascii=False))
