"""test_services.py -- Tum yeni servislerin import + init testi"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))

import datetime, math

print("="*55)
print("  SURVIVAL & COMFORT SERVIS TEST")
print("="*55)

# 1. Import testleri
try:
    from weather_service import WeatherService, CRITICAL_EVENTS, NIGHT_DANGEROUS
    print("  [OK] weather_service.py import")
except Exception as e:
    print(f"  [FAIL] weather_service: {e}")

try:
    from sos_service import SOSService
    print("  [OK] sos_service.py import")
except Exception as e:
    print(f"  [FAIL] sos_service: {e}")

try:
    from overpass_service import OverpassService
    svc = OverpassService()
    print(f"  [OK] overpass_service.py — {len(svc.QUERIES)} sorgu tipi: {list(svc.QUERIES.keys())}")
except Exception as e:
    print(f"  [FAIL] overpass_service: {e}")

try:
    from logistics_service import LogisticsService
    ls = LogisticsService()
    print(f"  [OK] logistics_service.py — veri: {ls.data_path.split(chr(92))[-1]}")
except Exception as e:
    print(f"  [FAIL] logistics_service: {e}")

# 2. Solar hesaplama testi
print()
print("  SOLAR VERİMLİLİK TESTİ:")
test_locs = [
    ("Joshua Tree, CA",  33.87, -115.90, "open"),
    ("Yellowstone, WY",  44.43, -110.59, "partial"),
    ("Olympic NP, WA",   47.97, -123.50, "dense"),
    ("Everglades, FL",   25.39,  -80.58, "open"),
    ("Denali, AK",       63.07, -151.01, "partial"),
]
month = datetime.datetime.now().month
for name, lat, lon, cover in test_locs:
    sa  = 90 - abs(lat - 23.5 * math.sin(math.radians((month - 3) * 30)))
    sa  = max(10, min(90, sa))
    tf  = {"open": 1.0, "partial": 0.65, "dense": 0.30}[cover]
    eff = round(sa / 90.0 * tf * 100, 1)
    print(f"    {name:25s}: {eff:5.1f}%  [{cover}]")

# 3. SOS servis testi
print()
print("  SOS SERVIS TESTİ:")
try:
    sos = SOSService()
    result = sos.trigger_panic(lat=36.5, lon=-118.0, user_id="test_user",
                                emergency_contact="", message="TEST PANIC")
    print(f"  [OK] Panic trigger — SOS ID: {result['sos_id']}")
    resolve = sos.resolve_sos(result['sos_id'])
    print(f"  [OK] Resolve — {resolve['message']}")
    ci = sos.checkin("test_user", 36.5, -118.0, next_checkin_hours=24)
    print(f"  [OK] Check-in — sonraki: {ci['next_due'][:16]}")
except Exception as e:
    print(f"  [FAIL] SOS: {e}")

# 4. API Gateway import testi (FastAPI import)
print()
print("  API GATEWAY TESTİ:")
try:
    import importlib.util
    spec = importlib.util.spec_from_file_location("api_gateway",
           os.path.join(os.path.dirname(__file__), "api_gateway.py"))
    mod  = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    print(f"  [OK] api_gateway.py v{mod.app.version} yuklendi")
    routes = [r.path for r in mod.app.routes]
    print(f"  [OK] {len(routes)} endpoint kayitli")
    new_eps = [r for r in routes if any(k in r for k in ["weather","sos","checkin","solar","host","rv_logistic","camp_rules"])]
    print(f"  [OK] Yeni endpoint sayisi: {len(new_eps)}")
    for ep in new_eps:
        print(f"        {ep}")
except Exception as e:
    print(f"  [FAIL] api_gateway: {e}")

print()
print("="*55)
print("  TUM TESTLER TAMAMLANDI")
print("="*55)
