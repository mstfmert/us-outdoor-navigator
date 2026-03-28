"""
rv_routing_service.py — RV Dimension Guard + OSRM Routing
Kullanıcının RV boyutlarını (yükseklik/genişlik) OSM bridge/tunnel tag'leriyle
çakıştırarak tehlikeli geçişleri tespit eder.
"""
import requests
import logging
from typing import Optional

log = logging.getLogger("rv_routing")

# OSRM public demo server
OSRM_BASE = "http://router.project-osrm.org/route/v1/driving"

# Overpass API — köprü/tünel sorgulama
OVERPASS_URL = "https://overpass-api.de/api/interpreter"

def get_route(
    origin_lat: float, origin_lon: float,
    dest_lat: float, dest_lon: float,
    rv_height_ft: float = 13.5,
    rv_width_ft: float = 8.5,
) -> dict:
    """
    OSRM ile rota çek, ardından rota boyunca OSM bridge/tunnel clearance kontrol et.
    """
    try:
        # 1) OSRM rotası
        url = f"{OSRM_BASE}/{origin_lon},{origin_lat};{dest_lon},{dest_lat}"
        params = {
            "overview": "full",
            "geometries": "geojson",
            "annotations": "true",
            "steps": "true",
        }
        r = requests.get(url, params=params, timeout=15)
        if r.status_code != 200:
            return {"error": f"OSRM {r.status_code}"}

        data = r.json()
        if data.get("code") != "Ok":
            return {"error": data.get("message", "Route not found")}

        route = data["routes"][0]
        legs   = route.get("legs", [])
        total_dist_km = route["distance"] / 1000
        total_time_min = route["duration"] / 60

        # Rota üzerindeki tüm koordinatları topla
        coords = route["geometry"]["coordinates"]  # [[lon, lat], ...]

        # 2) Rota BBox → Overpass sorgusu
        warnings = _check_clearance_along_route(
            coords, rv_height_ft, rv_width_ft
        )

        return {
            "status": "ok",
            "distance_km": round(total_dist_km, 1),
            "duration_min": round(total_time_min, 0),
            "route_coords": coords,
            "clearance_warnings": warnings,
            "rv_profile": {
                "height_ft": rv_height_ft,
                "width_ft": rv_width_ft,
            },
            "steps": _parse_steps(legs),
        }
    except Exception as e:
        log.warning(f"Route error: {e}")
        return {"error": str(e)}


def _check_clearance_along_route(
    coords: list,
    rv_height_ft: float,
    rv_width_ft: float,
) -> list:
    """
    Rota boyunca alçak köprü ve dar tünelleri sorgula.
    """
    if not coords:
        return []

    # BBox hesapla
    lons = [c[0] for c in coords]
    lats = [c[1] for c in coords]
    s, n = min(lats), max(lats)
    w, e = min(lons), max(lons)

    # Biraz genişlet
    pad = 0.02
    query = f"""
    [out:json][timeout:25];
    (
      way["bridge"="yes"]({s-pad},{w-pad},{n+pad},{e+pad});
      way["tunnel"="yes"]({s-pad},{w-pad},{n+pad},{e+pad});
      way["maxheight"]({s-pad},{w-pad},{n+pad},{e+pad});
      way["maxwidth"]({s-pad},{w-pad},{n+pad},{e+pad});
    );
    out center tags;
    """
    try:
        r = requests.post(OVERPASS_URL, data={"data": query}, timeout=20)
        if r.status_code != 200:
            return []
        elements = r.json().get("elements", [])
    except Exception as e:
        log.warning(f"Overpass clearance check failed: {e}")
        return []

    warnings = []
    rv_h_m = rv_height_ft * 0.3048  # ft → m
    rv_w_m = rv_width_ft * 0.3048

    for el in elements:
        tags = el.get("tags", {})
        center = el.get("center", {})
        name = tags.get("name", tags.get("ref", "Unnamed Structure"))

        # Yükseklik kontrolü
        maxh = tags.get("maxheight")
        if maxh:
            try:
                h_m = _parse_measurement(maxh)
                if h_m and h_m < rv_h_m:
                    warnings.append({
                        "type": "LOW_CLEARANCE",
                        "severity": "CRITICAL" if h_m < rv_h_m - 0.3 else "WARNING",
                        "name": name,
                        "limit_ft": round(h_m / 0.3048, 1),
                        "rv_height_ft": rv_height_ft,
                        "lat": center.get("lat", 0),
                        "lon": center.get("lon", 0),
                        "message": (
                            f"⚠️ DÜŞÜK KÖPRÜ: {name} — "
                            f"Maks {round(h_m/0.3048,1)}ft, "
                            f"RV'niz {rv_height_ft}ft"
                        ),
                    })
            except Exception:
                pass

        # Genişlik kontrolü
        maxw = tags.get("maxwidth")
        if maxw:
            try:
                w_m = _parse_measurement(maxw)
                if w_m and w_m < rv_w_m:
                    warnings.append({
                        "type": "NARROW_PASSAGE",
                        "severity": "WARNING",
                        "name": name,
                        "limit_ft": round(w_m / 0.3048, 1),
                        "rv_width_ft": rv_width_ft,
                        "lat": center.get("lat", 0),
                        "lon": center.get("lon", 0),
                        "message": (
                            f"⚠️ DAR GEÇİŞ: {name} — "
                            f"Maks {round(w_m/0.3048,1)}ft genişlik, "
                            f"RV'niz {rv_width_ft}ft"
                        ),
                    })
            except Exception:
                pass

        # Bridge ise ama boyut tag'i yoksa genel uyarı
        if tags.get("bridge") == "yes" and not maxh and not maxw:
            warnings.append({
                "type": "BRIDGE",
                "severity": "INFO",
                "name": name,
                "lat": center.get("lat", 0),
                "lon": center.get("lon", 0),
                "message": f"🌉 Köprü: {name} — Boyut bilgisi eksik, dikkatli geçin",
            })

    return warnings[:20]  # Max 20 uyarı döndür


def _parse_measurement(val: str) -> Optional[float]:
    """
    '3.5', '3.5m', '11\'6"', '11 ft' gibi formatları metre cinsine çevir.
    """
    if not val:
        return None
    val = val.strip().lower()

    if "'" in val:
        # Feet/inches: 11'6" formatı
        parts = val.replace('"', '').split("'")
        try:
            feet = float(parts[0])
            inches = float(parts[1]) if len(parts) > 1 and parts[1] else 0
            return (feet * 12 + inches) * 0.0254
        except:
            return None

    if "ft" in val:
        try:
            return float(val.replace("ft", "").strip()) * 0.3048
        except:
            return None

    # Sadece sayı veya 'm' ile biten
    try:
        return float(val.replace("m", "").replace(",", ".").strip())
    except:
        return None


def _parse_steps(legs: list) -> list:
    steps = []
    for leg in legs:
        for step in leg.get("steps", []):
            maneuver = step.get("maneuver", {})
            steps.append({
                "instruction": step.get("name", ""),
                "distance_m": round(step.get("distance", 0)),
                "type": maneuver.get("type", ""),
                "modifier": maneuver.get("modifier", ""),
                "location": maneuver.get("location", [0, 0]),
            })
    return steps[:50]  # Max 50 adım
