# api_gateway.py — US Outdoor Navigator  ★ SURVIVAL & COMFORT EDITION ★
# v6.0.0 | 1577 kamp | 49 eyalet/bolge | AK+HI dahil
# ─────────────────────────────────────────────────────────────────────────────
# YENİ SERVİSLER:
#   /get_night_weather   → NOAA/NWS Gece Hava Durumu + Sesli/Gorsel Alarm
#   /get_weather_alerts  → Aktif hava durumu uyarilari
#   /get_rv_logistics    → RV-Friendly yakıt + Dump Station + Temiz Su
#   /sos                 → PANIC butonu + SOS kaydı
#   /checkin             → Dead Man's Switch check-in
#   /get_camp_rules      → Kamp kurallari (ates yasagi, alkol, evcil hayvan)
#   /get_solar_estimate  → Gunes paneli verimlilik tahmini
#   /get_host_spots      → Boondocking / Yerel host noktalari
# ─────────────────────────────────────────────────────────────────────────────
from fastapi import FastAPI, Query, HTTPException, Request, Header
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
from typing import Optional
from wildfire_service import NASAWildfireService
from logistics_service import LogisticsService
from overpass_service import OverpassService
from weather_service import WeatherService
from sos_service import SOSService
from rv_routing_service import get_route as _rv_get_route
from weather_impact_service import calculate_mud_risk, get_camp_ground_risk
import database as db
import auth_service as auth
import uvicorn, datetime, uuid, math, json, os

app = FastAPI(
    title="US Outdoor Navigator — Survival & Comfort API",
    version="6.1.0",
    description="1577 kamp | 49 eyalet | SQLite | JWT Auth | Rate Limiting | NOAA | SOS Beta"
)
app.add_middleware(CORSMiddleware, allow_origins=["*"],
                   allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

# ── Startup: DB init + Camp Cache ─────────────────────────────────────────────
@app.on_event("startup")
async def on_startup():
    db.init_db()           # SQLite tabloları oluştur, JSON migrate et
    db.get_camps()         # Kamp cache'ini RAM'e yükle (sonraki istekler 0 disk I/O)
    print("🚀 API hazır — SQLite aktif, kamp cache yüklendi")

# ── Servisler ─────────────────────────────────────────────────────────────────
fire_service      = NASAWildfireService()
logistics_service = LogisticsService()
overpass_service  = OverpassService()
weather_service   = WeatherService()
sos_service       = SOSService()

# ── Dosya Yolları ─────────────────────────────────────────────────────────────
_BASE_DIR      = os.path.dirname(__file__)
_DATA_DIR      = os.path.join(_BASE_DIR, "..", "data_sources")
_MASTER_FILE   = os.path.join(_DATA_DIR, "us_outdoor_master_final.json")
_REPORTS_FILE  = os.path.join(_DATA_DIR, "reports.json")
_HOST_FILE     = os.path.join(_DATA_DIR, "host_spots.json")

# ── Eyalet Setleri ────────────────────────────────────────────────────────────
GROUP_1 = {"CA","AZ","WA","OR","NV","UT","MT","CO","WY","ID"}
GROUP_2 = {"TX","OK","KS","NE","SD","ND","NM","LA","AR","MO"}
GROUP_3 = {"FL","GA","AL","MS","TN","KY","NC","SC","VA","WV"}
GROUP_4 = {"NY","PA","OH","MI","IN","IL","WI","MN","IA","NJ"}
GROUP_5 = {"ME","NH","VT","MA","RI","CT","DE","MD","DC","AK","HI"}
ALL_STATES = GROUP_1|GROUP_2|GROUP_3|GROUP_4|GROUP_5

# ── Abonelik Kısıtlaması ──────────────────────────────────────────────────────
# Ücretsiz kullanıcılar sadece bu 3 eyaleti görebilir
FREE_TIER_STATES = {"CA", "AZ", "UT"}

GROUP_BBOXES = {
    "v1": {"min_lat":31.3,"max_lat":49.0,"min_lon":-124.8,"max_lon":-102.0},
    "v2": {"min_lat":25.8,"max_lat":49.0,"min_lon":-109.0,"max_lon":-89.0},
    "v3": {"min_lat":24.5,"max_lat":40.0,"min_lon":-91.5, "max_lon":-75.0},
    "v4": {"min_lat":36.0,"max_lat":48.5,"min_lon":-97.5, "max_lon":-73.5},
    "v5": {"min_lat":18.0,"max_lat":72.0,"min_lon":-168.0,"max_lon":-66.9},
}

# ── Kamp Kuralları Varsayılan Şablonu ─────────────────────────────────────────
DEFAULT_RULES = {
    "fire_ban":          False,
    "alcohol_allowed":   True,
    "pets_allowed":      True,
    "quiet_hours_start": "22:00",
    "quiet_hours_end":   "08:00",
    "max_stay_days":     14,
    "reservation_req":   False,
    "generator_hours":   "08:00-20:00",
    "source":            "Default — verify with campground"
}

# ── Yardımcı Fonksiyonlar ─────────────────────────────────────────────────────
def _load_camps():
    """In-memory cache'den kamp verisi döner — disk I/O yok."""
    return db.get_camps()

def _load_reports():
    """SQLite'dan tüm raporları döner (legacy compat)."""
    try:
        with db.get_db() as conn:
            rows = conn.execute("SELECT * FROM reports ORDER BY timestamp DESC").fetchall()
        return [dict(r) for r in rows]
    except Exception: return []

def _save_reports(r):
    """Legacy: Artık kullanılmıyor — db.insert_report() kullan."""
    pass

def _load_hosts():
    if not os.path.exists(_HOST_FILE): return []
    try:
        with open(_HOST_FILE,"r",encoding="utf-8") as f: return json.load(f)
    except: return []

def _haversine_m(la1,lo1,la2,lo2):
    p1,p2=math.radians(la1),math.radians(la2)
    dp,dl=math.radians(la2-la1),math.radians(lo2-lo1)
    a=math.sin(dp/2)**2+math.cos(p1)*math.cos(p2)*math.sin(dl/2)**2
    return 6_371_000*2*math.atan2(math.sqrt(a),math.sqrt(1-a))

def _detect_group(lat,lon):
    if lat>=54.0: return "v5"
    if lat<=23.0 and lon<=-154.0: return "v5"
    for g,b in GROUP_BBOXES.items():
        if b["min_lat"]<=lat<=b["max_lat"] and b["min_lon"]<=lon<=b["max_lon"]: return g
    return "unknown"

def _solar_efficiency(lat: float, lon: float, tree_cover: str = "open") -> dict:
    """
    Konuma gore gunes paneli verimlilik tahmini.
    tree_cover: 'open' | 'partial' | 'dense'
    """
    now    = datetime.datetime.now()
    month  = now.month
    # Gunes acisi tahmini (kuzey yarikusresi)
    sun_angle = 90 - abs(lat - 23.5 * math.sin(math.radians((month - 3) * 30)))
    sun_angle = max(10, min(90, sun_angle))
    base_eff  = sun_angle / 90.0  # 0-1 arasi

    tree_factor = {"open": 1.0, "partial": 0.65, "dense": 0.30}.get(tree_cover, 0.8)
    efficiency  = round(base_eff * tree_factor * 100, 1)

    if efficiency >= 70:
        label = "Mukemmel — Gunes paneli icin ideal"
    elif efficiency >= 45:
        label = "Iyi — Gunluk sarj mumkun"
    elif efficiency >= 20:
        label = "Kismi — Bulutlu/Golge bolgesi"
    else:
        label = "Dusuk — Gunes paneli verimli degil"

    return {
        "efficiency_pct": efficiency,
        "label":          label,
        "sun_angle_deg":  round(sun_angle, 1),
        "tree_cover":     tree_cover,
        "month":          month,
        "lat":            lat,
        "recommendation": "Generator tavsiye edilir" if efficiency < 30 else "Solar yeterli"
    }

# ══════════════════════════════════════════════════════════════════════════════
#  PYDANTIC MODELLER
# ══════════════════════════════════════════════════════════════════════════════
class UserLocation(BaseModel):
    lat: float; lon: float; user_id: str
    max_camp_price: float = 100.0; rv_length: float = None

class ReportInput(BaseModel):
    lat: float; lon: float; report_type: str
    description: str = ""; user_id: str = "anonymous"

class SOSInput(BaseModel):
    lat: float; lon: float; user_id: str
    emergency_contact: str = ""; user_name: str = "Unknown User"
    message: str = "PANIC BUTTON PRESSED"

class CheckinInput(BaseModel):
    lat: float; lon: float; user_id: str; next_checkin_hours: int = 24

class HostSpotInput(BaseModel):
    lat: float; lon: float
    host_name: str; description: str = ""
    max_rv_length: float = 35.0; price_per_night: float = 0.0
    contact: str = ""; amenities: list = []

# ══════════════════════════════════════════════════════════════════════════════
#  SAĞLIK KONTROLÜ
# ══════════════════════════════════════════════════════════════════════════════
@app.get("/")
def health():
    cache = db.get_cache_stats()
    sos_status = auth.get_sos_status()
    return {
        "status":       "online",
        "version":      "6.1.0",
        "edition":      "Production-Ready",
        "architecture": {"camp_store": "in_memory_cache", "reports": "sqlite", "sos": "sqlite"},
        "camp_count":   cache["camp_count"],
        "cache_load_ms": cache["load_ms"],
        "sos_mode":     sos_status["mode"],
        "sms_enabled":  sos_status["sms_enabled"],
        "safety_features_free": True,
        "endpoints": {
            "auth":     "POST /auth/token",
            "camps":    "GET /get_camps_in_view",
            "weather":  "GET /get_night_weather (FREE)",
            "alerts":   "GET /get_weather_alerts (FREE)",
            "sos":      f"POST /sos (FREE — {sos_status['mode'].upper()})",
            "report":   "POST /report (FREE)",
            "token":    "POST /auth/token"
        },
        "timestamp": datetime.datetime.now().isoformat()
    }

# ══════════════════════════════════════════════════════════════════════════════
#  JWT AUTH — Token Oluşturma
# ══════════════════════════════════════════════════════════════════════════════
class TokenRequest(BaseModel):
    user_id: str
    is_premium: bool = False
    rc_customer_id: str = ""  # RevenueCat customer ID (ileride doğrulama için)

@app.post("/auth/token")
async def create_auth_token(data: TokenRequest, request: Request):
    """
    JWT token oluştur.
    RevenueCat aboneliği onaylandıktan sonra Flutter app bu endpoint'i çağırır.
    Dönen token → Authorization: Bearer <token> header'ında kullanılır.
    """
    auth.rate_limit_check(request, max_per_minute=10)
    token = auth.create_token(data.user_id, data.is_premium)
    return {
        "status":     "ok",
        "token":      token,
        "user_id":    data.user_id,
        "is_premium": data.is_premium,
        "expires_in": "7 days",
        "usage":      "Authorization: Bearer <token>"
    }

@app.get("/auth/verify")
async def verify_auth_token(authorization: Optional[str] = Header(None)):
    """Token'ı doğrula — debug için."""
    payload = auth.get_token_from_header(authorization)
    if not payload:
        return {"valid": False, "is_premium": False}
    return {"valid": True, "is_premium": payload.get("pro", False),
            "user_id": payload.get("uid"), "expires": payload.get("exp")}

# ══════════════════════════════════════════════════════════════════════════════
#  KAMP SORGULAMA (BOUNDING BOX)
# ══════════════════════════════════════════════════════════════════════════════
@app.get("/get_camps_in_view")
async def get_camps_in_view(
    min_lat:float=Query(...),max_lat:float=Query(...),
    min_lon:float=Query(...),max_lon:float=Query(...),
    max_price:float=Query(None),rv_length:float=Query(None),
    state:str=Query(None),group:str=Query(None),limit:int=Query(200),
    is_premium:bool=Query(False)
):
    """
    Sinirsiz kesif modu — bbox icerisindeki tum kamplari doner.
    is_premium=False: sadece CA/AZ/UT eyaletleri gösterilir.
    is_premium=True:  tüm 50 eyalet açık.
    """
    camps = _load_camps()
    if not camps:
        return {"status":"no_data","message":"us_outdoor_master_final.json bulunamadi","count":0,"camps":[]}
    results = []
    locked_count = 0
    for c in camps:
        lat,lon = c.get("lat"),c.get("lon")
        if not (min_lat<=lat<=max_lat and min_lon<=lon<=max_lon): continue
        if max_price is not None and c.get("price_per_night",0)>max_price: continue
        if rv_length is not None and c.get("max_rv_length",9999)<rv_length: continue
        if state is not None and c.get("state","").upper()!=state.upper(): continue
        if group is not None and c.get("group","")!=group: continue
        # ── Eyalet Kilidi ────────────────────────────────────────────────
        camp_state = c.get("state","").upper()
        if not is_premium and camp_state not in FREE_TIER_STATES:
            locked_count += 1
            continue
        results.append(c)
        if len(results)>=limit: break
    return {
        "status":"ok",
        "count":len(results),
        "locked_count": locked_count,
        "is_premium": is_premium,
        "free_states": sorted(FREE_TIER_STATES),
        "bbox":{"min_lat":min_lat,"max_lat":max_lat,"min_lon":min_lon,"max_lon":max_lon},
        "camps":results
    }

# ══════════════════════════════════════════════════════════════════════════════
#  WEATHER SENTINEL — GECE HAVA DURUMU
# ══════════════════════════════════════════════════════════════════════════════
@app.get("/get_night_weather")
async def get_night_weather(lat:float=Query(...),lon:float=Query(...)):
    """
    NOAA/NWS Gece Hava Durumu Raporu.
    Sel, yildirim, firtina varsa CRITICAL/WARNING alarmı doner.
    play_sound_alert=True → Frontend sesli uyari calsin.
    """
    try:
        return weather_service.get_night_safety_report(lat, lon)
    except Exception as e:
        return {"alarm_level":"UNKNOWN","alarm_message":f"Hava verisi alinamadi: {e}","play_sound_alert":False,"show_visual_alert":False}

@app.get("/get_weather_alerts")
async def get_weather_alerts(lat:float=Query(...),lon:float=Query(...)):
    """Belirtilen koordinat icin aktif NWS uyarilarini doner."""
    try:
        alerts = weather_service.get_active_alerts(lat, lon)
        return {"status":"ok","count":len(alerts),"alerts":alerts,"timestamp":datetime.datetime.now().isoformat()}
    except Exception as e:
        return {"status":"error","count":0,"alerts":[],"error":str(e)}

@app.get("/get_hourly_forecast")
async def get_hourly_forecast(lat:float=Query(...),lon:float=Query(...)):
    """24 saatlik saatlik hava tahminini doner."""
    try:
        forecast = weather_service.get_hourly_forecast(lat, lon)
        return {"status":"ok","count":len(forecast),"forecast":forecast}
    except Exception as e:
        return {"status":"error","forecast":[],"error":str(e)}

# ══════════════════════════════════════════════════════════════════════════════
#  RV LOJISTIK — DUMP STATION + TEMIZ SU + RV YAKITI
# ══════════════════════════════════════════════════════════════════════════════
@app.get("/get_rv_logistics")
async def get_rv_logistics(
    lat:float=Query(...),lon:float=Query(...),
    radius_m:int=Query(80_000),
    include_fuel:bool=Query(True),
    include_dump:bool=Query(True),
    include_water:bool=Query(True)
):
    """
    RV Karavanci Lojistik Paketi:
    - rv_fuel:       RV/Kamyon dostu yakıt istasyonları (mavi ikon)
    - dump_station:  Pis su bosaltma istasyonlari (gri ikon)
    - potable_water: Temiz icme suyu noktalari (mavi/beyaz ikon)
    """
    result = {}
    try:
        # ── Paralel Overpass çağrıları (asyncio.gather) ──────────────────
        # 3 sıralı Overpass çağrısı (≈15sn) → paralel (≈4sn)
        import asyncio as _asyncio
        _loop = _asyncio.get_event_loop()

        _coros = {}
        if include_fuel:
            _coros["rv_fuel"] = _loop.run_in_executor(
                None, overpass_service.fetch, lat, lon, "rv_fuel", radius_m)
        if include_dump:
            _coros["dump_station"] = _loop.run_in_executor(
                None, overpass_service.fetch, lat, lon, "dump_station", radius_m)
        if include_water:
            _coros["potable_water"] = _loop.run_in_executor(
                None, overpass_service.fetch, lat, lon, "potable_water", radius_m)

        if _coros:
            _values = await _asyncio.gather(*_coros.values(), return_exceptions=True)
            for _key, _val in zip(_coros.keys(), _values):
                result[_key] = _val if not isinstance(_val, Exception) else []

        total = sum(len(v) for v in result.values())
        return {"status":"ok","total":total,"radius_m":radius_m,"categories":result}
    except Exception as e:
        return {"status":"error","total":0,"categories":{},"error":str(e)}

# ══════════════════════════════════════════════════════════════════════════════
#  KAMP KURALLARI
# ══════════════════════════════════════════════════════════════════════════════
@app.get("/get_camp_rules/{camp_id}")
async def get_camp_rules(camp_id: str):
    """
    Kamp ID'sine gore kural bilgisi doner.
    Ates yasagi, alkol, evcil hayvan, gurultu saatleri.
    """
    camps = _load_camps()
    camp  = next((c for c in camps if c.get("id") == camp_id), None)
    if not camp:
        raise HTTPException(status_code=404, detail=f"Kamp {camp_id} bulunamadi.")

    # Mevcut rules alani varsa kullan, yoksa varsayilan
    rules = camp.get("rules", DEFAULT_RULES.copy())
    rules.setdefault("fire_ban",          False)
    rules.setdefault("alcohol_allowed",   True)
    rules.setdefault("pets_allowed",      True)
    rules.setdefault("quiet_hours_start", "22:00")
    rules.setdefault("quiet_hours_end",   "08:00")
    rules.setdefault("max_stay_days",     14)
    rules.setdefault("reservation_req",   False)
    rules.setdefault("generator_hours",   "08:00-20:00")

    return {
        "status":    "ok",
        "camp_id":   camp_id,
        "camp_name": camp.get("name","?"),
        "state":     camp.get("state","?"),
        "rules":     rules,
        "icons": {
            "fire":     "fire_ban_icon" if rules.get("fire_ban") else "fire_allowed_icon",
            "alcohol":  "alcohol_icon"  if rules.get("alcohol_allowed") else "no_alcohol_icon",
            "pets":     "pets_icon"     if rules.get("pets_allowed")    else "no_pets_icon",
            "noise":    f"quiet_{rules.get('quiet_hours_start','22:00').replace(':','')}_icon"
        }
    }

@app.get("/get_camps_with_rules")
async def get_camps_with_rules(
    fire_ban:bool=Query(None), pets_allowed:bool=Query(None),
    alcohol_allowed:bool=Query(None), limit:int=Query(50)
):
    """Kural filtrelerine gore kamp listesi doner."""
    camps = _load_camps()
    results = []
    for c in camps:
        r = c.get("rules", DEFAULT_RULES)
        if fire_ban is not None and r.get("fire_ban",False) != fire_ban: continue
        if pets_allowed is not None and r.get("pets_allowed",True) != pets_allowed: continue
        if alcohol_allowed is not None and r.get("alcohol_allowed",True) != alcohol_allowed: continue
        results.append(c)
        if len(results) >= limit: break
    return {"status":"ok","count":len(results),"camps":results}

# ══════════════════════════════════════════════════════════════════════════════
#  GUNES PANELİ VERİMLİLİK TAHMİNİ
# ══════════════════════════════════════════════════════════════════════════════
@app.get("/get_solar_estimate")
async def get_solar_estimate(
    lat:float=Query(...),lon:float=Query(...),
    tree_cover:str=Query("open",description="open | partial | dense")
):
    """
    Kamp alaninin gunes paneli verimlilik tahmini.
    Koordinat, mevsim ve agaclik durumuna gore hesaplanir.
    """
    return _solar_efficiency(lat, lon, tree_cover)

# ══════════════════════════════════════════════════════════════════════════════
#  SOS — PANIC MODU + DEAD MAN'S SWITCH
# ══════════════════════════════════════════════════════════════════════════════
@app.post("/sos")
async def trigger_sos(data: SOSInput, request: Request):
    """
    PANIC BUTONU — ÜCRETSİZ güvenlik özelliği.
    Rate limit: dakikada 5 istek.
    Koordinatlar SQLite SOS loguna kaydedilir.
    BETA: SMS henüz aktif değil — Twilio entegrasyonu yakında.
    """
    auth.rate_limit_check(request, max_per_minute=5)
    sos_status = auth.get_sos_status()
    result = sos_service.trigger_panic(
        lat=data.lat, lon=data.lon, user_id=data.user_id,
        emergency_contact=data.emergency_contact,
        message=data.message, user_name=data.user_name
    )
    # Beta/Production durumunu response'a ekle
    result["sos_mode"]      = sos_status["mode"]
    result["sms_enabled"]   = sos_status["sms_enabled"]
    if not sos_status["sms_enabled"]:
        result["beta_notice"]  = sos_status.get("beta_notice", "")
        result["emergency_fallback"] = "911"
        result["instructions"].insert(0, "⚠️ SMS otomatik gönderilemedi — 911'i arayın!")
    return result

@app.post("/sos/resolve/{sos_id}")
async def resolve_sos(sos_id: str, resolved_by: str = Query("user")):
    """SOS durumunu cozuldu olarak isaretle."""
    return sos_service.resolve_sos(sos_id, resolved_by)

@app.post("/checkin")
async def user_checkin(data: CheckinInput):
    """
    Dead Man's Switch check-in.
    next_checkin_hours sure icinde tekrar check-in yapilmazsa uyari tetiklenir.
    """
    return sos_service.checkin(data.user_id, data.lat, data.lon, data.next_checkin_hours)

@app.get("/checkin/overdue")
async def check_overdue():
    """24 saatten uzun sure check-in yapmayan kullanicilari listele."""
    overdue = sos_service.check_overdue()
    return {"status":"ok","overdue_count":len(overdue),"overdue_users":overdue}

@app.get("/sos/active")
async def get_active_sos():
    """Aktif (cozulmemis) tum SOS kayitlarini doner."""
    logs = sos_service.get_active_sos_logs()
    return {"status":"ok","count":len(logs),"sos_logs":logs}

# ══════════════════════════════════════════════════════════════════════════════
#  HOST NETWORK — BOONDOCKING / YEREL HOST NOKTALARI
# ══════════════════════════════════════════════════════════════════════════════
@app.get("/get_host_spots")
async def get_host_spots(
    min_lat:float=Query(...),max_lat:float=Query(...),
    min_lon:float=Query(...),max_lon:float=Query(...),
    max_price:float=Query(None),rv_length:float=Query(None),
    limit:int=Query(50)
):
    """
    Boondocking / Yerel Host Noktalari (mor ikon).
    Bahcesini veya arazisini karavancilara acan yerel halk noktalari.
    """
    hosts = _load_hosts()
    results = []
    for h in hosts:
        lat,lon = h.get("lat"),h.get("lon")
        if not lat or not lon: continue
        if not (min_lat<=lat<=max_lat and min_lon<=lon<=max_lon): continue
        if max_price is not None and h.get("price_per_night",0)>max_price: continue
        if rv_length is not None and h.get("max_rv_length",9999)<rv_length: continue
        results.append(h)
        if len(results)>=limit: break
    return {"status":"ok","count":len(results),"host_type":"boondocking","icon_color":"purple","spots":results}

@app.post("/add_host_spot")
async def add_host_spot(data: HostSpotInput):
    """Yeni bir host/boondocking noktasi ekle."""
    hosts   = _load_hosts()
    spot_id = str(uuid.uuid4())[:8]
    spot = {
        "id":             spot_id,
        "host_name":      data.host_name,
        "lat":            data.lat,
        "lon":            data.lon,
        "description":    data.description,
        "max_rv_length":  data.max_rv_length,
        "price_per_night": data.price_per_night,
        "contact":        data.contact,
        "amenities":      data.amenities,
        "type":           "host_network",
        "icon_color":     "purple",
        "added_at":       datetime.datetime.now().isoformat()
    }
    hosts.append(spot)
    os.makedirs(_DATA_DIR, exist_ok=True)
    with open(_HOST_FILE,"w",encoding="utf-8") as f: json.dump(hosts,f,indent=2,ensure_ascii=False)
    return {"status":"ok","id":spot_id,"spot":spot}

# ══════════════════════════════════════════════════════════════════════════════
#  MEVCUT SERVİSLER (TAM RAPOR, POI, RAPORLAMA)
# ══════════════════════════════════════════════════════════════════════════════
@app.post("/get_full_report")
async def get_full_report(location: UserLocation):
    try:
        safety  = logistics_service.get_safety_status(location.lat, location.lon)
        nearby  = logistics_service.get_nearby_logistics(location.lat, location.lon, max_dist=50.0, rv_length=location.rv_length)
        weather = weather_service.get_night_safety_report(location.lat, location.lon)
        solar   = _solar_efficiency(location.lat, location.lon)
        return {
            "metadata": {"user_id":location.user_id,"timestamp":datetime.datetime.now().isoformat()},
            "safety": safety, "logistics": nearby,
            "night_weather": weather, "solar_estimate": solar,
            "feedback_summary": "Raporlar: /get_reports"
        }
    except Exception as e:
        return {"status":"SYSTEM_ERROR","message":str(e)}

@app.post("/report")
async def submit_report(data: ReportInput, request: Request):
    """
    Topluluk raporu gönder — ÜCRETSİZ (güvenlik özelliği).
    Rate limit: dakikada 10 istek (bot koruması).
    SQLite'a kaydedilir.
    """
    auth.rate_limit_check(request, max_per_minute=10)
    rid = str(uuid.uuid4())[:8]
    r = {"id": rid, "lat": data.lat, "lon": data.lon,
         "report_type": data.report_type, "description": data.description,
         "user_id": data.user_id,
         "timestamp": datetime.datetime.now().isoformat(),
         "group": _detect_group(data.lat, data.lon)}
    db.insert_report(r)
    return {"status": "ok", "id": rid, "report": r, "storage": "sqlite"}

@app.get("/get_reports")
async def get_reports(lat: float = Query(...), lon: float = Query(...),
                      radius_m: int = Query(100_000), group: str = Query(None)):
    """
    Yakın raporları döner — ÜCRETSİZ.
    SQLite bbox sorgusu ile hızlı veri çekimi.
    """
    deg = radius_m / 111_000.0
    rows = db.query_reports_by_bbox(lat - deg, lat + deg, lon - deg, lon + deg)
    nearby = []
    for r in rows:
        d = round(_haversine_m(lat, lon, r["lat"], r["lon"]))
        if d <= radius_m and (group is None or r.get("group_id") == group):
            nearby.append({"distance_m": d, **r})
    nearby.sort(key=lambda x: x["distance_m"])
    return {"status": "ok", "count": len(nearby), "reports": nearby, "source": "sqlite"}

@app.get("/get_all_reports")
async def get_all_reports(group: str = Query(None)):
    r = _load_reports()
    if group: r = [x for x in r if x.get("group_id") == group or x.get("group") == group]
    return {"status": "ok", "count": len(r), "reports": r, "source": "sqlite"}

@app.get("/get_poi")
async def get_poi(lat:float=Query(...),lon:float=Query(...),
                  poi_type:str=Query("fuel"),radius_m:int=Query(50_000)):
    try:
        pois = overpass_service.fetch(lat,lon,poi_type,radius_m)
        return {"poi_type":poi_type,"count":len(pois),"pois":pois}
    except Exception: return {"poi_type":poi_type,"count":0,"pois":[]}

@app.get("/get_all_poi")
async def get_all_poi(lat:float=Query(...),lon:float=Query(...),radius_m:int=Query(50_000)):
    try:
        all_pois = overpass_service.fetch_all(lat,lon,radius_m)
        return {"total":sum(len(v) for v in all_pois.values()),"categories":all_pois}
    except Exception: return {"total":0,"categories":{}}

# ══════════════════════════════════════════════════════════════════════════════
#  RV DIMENSION GUARD — OSRM ROUTING + BRIDGE/TUNNEL CLEARANCE
# ══════════════════════════════════════════════════════════════════════════════
@app.get("/get_route")
async def get_rv_route(
    origin_lat:  float = Query(...),
    origin_lon:  float = Query(...),
    dest_lat:    float = Query(...),
    dest_lon:    float = Query(...),
    rv_height_ft: float = Query(13.5, description="RV yüksekliği (feet)"),
    rv_width_ft:  float = Query(8.5,  description="RV genişliği (feet)"),
):
    """
    RV Dimension Guard:
    OSRM ile rota çek → rota boyunca OSM bridge/tunnel clearance kontrolü yap.
    Alçak köprü veya dar tünel tespit edilirse CRITICAL/WARNING uyarısı döner.
    """
    return _rv_get_route(
        origin_lat=origin_lat, origin_lon=origin_lon,
        dest_lat=dest_lat, dest_lon=dest_lon,
        rv_height_ft=rv_height_ft, rv_width_ft=rv_width_ft,
    )

# ══════════════════════════════════════════════════════════════════════════════
#  WEATHER IMPACT SCORE — ZEMIN ÇAMUR RİSKİ
# ══════════════════════════════════════════════════════════════════════════════
class GroundRiskInput(BaseModel):
    precipitation_mm: float = 0.0
    ground_type: str = "unknown"
    vehicle_type: str = "rv"
    slope_pct: float = 0.0
    temp_celsius: float = 15.0
    duration_hours: float = 1.0

@app.post("/ground_risk")
async def get_ground_risk(data: GroundRiskInput):
    """
    Weather Impact Score:
    Yağış miktarı × Zemin tipi → Mud Risk Score (0–100).
    Örnek: 'Zemin Çamur Riski: %85 — Sadece 4x4 araçlar için uygundur'
    """
    return calculate_mud_risk(
        precipitation_mm=data.precipitation_mm,
        ground_type=data.ground_type,
        vehicle_type=data.vehicle_type,
        slope_pct=data.slope_pct,
        temp_celsius=data.temp_celsius,
        duration_hours=data.duration_hours,
    )

@app.delete("/delete_account")
async def delete_account(user_id: str = Query("anonymous")):
    """
    Apple/Google Required: Hesap ve tüm kullanıcı verisini sil.
    - Reports → SQLite DELETE
    - SOS logs → SQLite DELETE
    GDPR & Apple App Store compliance.
    """
    deleted_reports = db.delete_reports_by_user(user_id)
    deleted_sos     = db.delete_sos_by_user(user_id)
    return {
        "status":    "ok",
        "message":   f"Account '{user_id}' ve tüm veriler silindi.",
        "deleted":   {"reports": deleted_reports, "sos_logs": deleted_sos},
        "timestamp": datetime.datetime.now().isoformat(),
        "gdpr_compliant":  True,
        "apple_required":  True,
        "storage_backend": "sqlite"
    }

@app.get("/camp_ground_risk/{camp_id}")
async def get_camp_risk(
    camp_id: str,
    precipitation_mm: float = Query(0.0),
    temp_celsius: float = Query(15.0),
    rv_length_ft: float = Query(35.0),
):
    """Belirli bir kamp için zemin çamur riski hesapla."""
    camps = _load_camps()
    camp = next((c for c in camps if c.get("id") == camp_id), None)
    if not camp:
        raise HTTPException(status_code=404, detail=f"Kamp {camp_id} bulunamadi.")
    return get_camp_ground_risk(
        camp_name=camp.get("name", "Unknown"),
        ground_type=camp.get("surface", "unknown"),
        precipitation_mm=precipitation_mm,
        temperature_c=temp_celsius,
        slope_pct=camp.get("slope_pct", 2.0),
        rv_length_ft=rv_length_ft,
    )

# ══════════════════════════════════════════════════════════════════════════════
#  LEGAL — Privacy Policy + Terms of Service (Apple/Google required)
# ══════════════════════════════════════════════════════════════════════════════
_PRIVACY_HTML = """<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Privacy Policy — US Outdoor Navigator</title>
<style>body{font-family:system-ui,sans-serif;max-width:800px;margin:40px auto;padding:0 20px;color:#222;line-height:1.7}h1{color:#0D1526}h2{color:#1a3a6e;margin-top:2em}a{color:#0066cc}</style>
</head><body>
<h1>🏕️ US Outdoor Navigator — Privacy Policy</h1>
<p><strong>Last Updated:</strong> March 2026 &nbsp;|&nbsp; <strong>Package:</strong> com.mert.usoutdoor</p>

<h2>1. Information We Collect</h2>
<p><strong>Location Data (Foreground Only):</strong> We collect your precise GPS location <em>only while the app is actively open</em> to find nearby campgrounds, calculate distances, and display wildfire alerts. We do <strong>not</strong> track your location in the background.</p>
<p><strong>Camera:</strong> Used only for the Starlink AR satellite-finder feature (Pro). Camera data is processed on-device and never transmitted.</p>
<p><strong>Motion Sensors:</strong> The digital leveling tool uses your device accelerometer. This data never leaves your device.</p>
<p><strong>Anonymous Usage:</strong> No account creation is required. If you choose to submit community reports (trail conditions, hazards), you may provide an optional username.</p>

<h2>2. How We Use Your Information</h2>
<ul>
  <li>Display campgrounds, wildfires, and weather alerts near your location</li>
  <li>Calculate distances to RV-friendly fuel, water, and dump stations</li>
  <li>Log SOS emergency coordinates if you press the panic button (stored locally)</li>
</ul>

<h2>3. Data Sharing</h2>
<p>We <strong>never</strong> sell, rent, or share your personal data with third parties for advertising or analytics purposes.</p>
<ul>
  <li><strong>NASA FIRMS API:</strong> We query NASA's public wildfire API using your coordinates. NASA's privacy policy applies.</li>
  <li><strong>NOAA/NWS API:</strong> Public weather data. No personal data is transmitted.</li>
  <li><strong>OpenStreetMap / Overpass API:</strong> Public map data. No personal data is transmitted.</li>
</ul>

<h2>4. Data Storage</h2>
<p>SOS logs and community reports are stored on our secure server (Railway.app) using SQLite. This data is associated with your anonymous user ID, not your name or identity.</p>

<h2>5. Account Deletion</h2>
<p>You can delete all your data at any time from <strong>Settings → Delete Account</strong> in the app. This permanently removes all reports and SOS logs associated with your user ID.</p>

<h2>6. Children's Privacy</h2>
<p>This app is not directed at children under 13. We do not knowingly collect data from children.</p>

<h2>7. Contact</h2>
<p>Questions? Email us: <a href="mailto:support@usoutdoor.app">support@usoutdoor.app</a></p>

<hr>
<p><em>© 2026 US Outdoor Navigator. All rights reserved.</em></p>
</body></html>"""

_TERMS_HTML = """<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Terms of Service — US Outdoor Navigator</title>
<style>body{font-family:system-ui,sans-serif;max-width:800px;margin:40px auto;padding:0 20px;color:#222;line-height:1.7}h1{color:#0D1526}h2{color:#1a3a6e;margin-top:2em}</style>
</head><body>
<h1>🏕️ US Outdoor Navigator — Terms of Service</h1>
<p><strong>Last Updated:</strong> March 2026 &nbsp;|&nbsp; <strong>Version:</strong> 1.0.0</p>

<h2>1. Acceptance</h2>
<p>By downloading or using US Outdoor Navigator, you agree to these Terms of Service. If you disagree, please uninstall the app.</p>

<h2>2. Safety Disclaimer</h2>
<p><strong>⚠️ CRITICAL:</strong> US Outdoor Navigator provides informational data only. Wildfire alerts, weather forecasts, and safety scores are sourced from public APIs and may be delayed, inaccurate, or incomplete. Always:</p>
<ul>
  <li>Follow official emergency service instructions</li>
  <li>Check official government sources before entering wilderness areas</li>
  <li>Do not rely solely on this app for life-safety decisions</li>
</ul>
<p>The SOS panic button logs your location but does NOT automatically contact emergency services. Always call 911 in a life-threatening emergency.</p>

<h2>3. Subscriptions</h2>
<p>Pro features require an active subscription (Explorer Weekly at $9.99/week or Nomad Pro Yearly at $59.99/year). Subscriptions auto-renew unless cancelled. 3-day free trial available. Cancel anytime in your App Store / Play Store account settings.</p>

<h2>4. Intellectual Property</h2>
<p>All app content, design, and code © 2026 US Outdoor Navigator. Map data provided by OpenStreetMap contributors (CC BY-SA).</p>

<h2>5. Limitation of Liability</h2>
<p>To the maximum extent permitted by law, US Outdoor Navigator shall not be liable for any damages arising from use of this app, including but not limited to navigation errors, inaccurate wildfire data, or SOS failures.</p>

<h2>6. Contact</h2>
<p>Questions? Email: support@usoutdoor.app</p>

<hr>
<p><em>© 2026 US Outdoor Navigator. All rights reserved.</em></p>
</body></html>"""

@app.get("/privacy", response_class=HTMLResponse, include_in_schema=False)
async def privacy_policy():
    """Privacy Policy — Apple/Google store requirement."""
    return HTMLResponse(content=_PRIVACY_HTML)

@app.get("/terms", response_class=HTMLResponse, include_in_schema=False)
async def terms_of_service():
    """Terms of Service — Apple/Google store requirement."""
    return HTMLResponse(content=_TERMS_HTML)

_SUPPORT_HTML = """<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Support — US Outdoor Navigator</title>
<style>
body{font-family:system-ui,sans-serif;max-width:700px;margin:40px auto;padding:0 20px;color:#222;line-height:1.7}
h1{color:#0D1526}h2{color:#1a3a6e;margin-top:2em}
a{color:#0066cc}
.card{background:#f5f8ff;border:1px solid #dde6f5;border-radius:8px;padding:16px 20px;margin:16px 0}
.badge{display:inline-block;background:#00b47a;color:#fff;padding:3px 10px;border-radius:12px;font-size:12px;font-weight:700}
</style>
</head><body>
<h1>🏕️ US Outdoor Navigator — Support</h1>
<p><span class="badge">v1.0.0</span> &nbsp; Package: <code>com.mert.usoutdoor</code></p>

<div class="card">
<h2 style="margin-top:0">📧 Contact Us</h2>
<p>For general support, bugs, or feedback:</p>
<p>✉️ <a href="mailto:support@usoutdoor.app">support@usoutdoor.app</a></p>
<p>🐛 Bug reports: <a href="mailto:bugs@usoutdoor.app">bugs@usoutdoor.app</a></p>
</div>

<h2>❓ Frequently Asked Questions</h2>

<p><strong>How do I cancel my subscription?</strong><br>
Go to your <strong>App Store</strong> (iOS) or <strong>Google Play</strong> (Android) account settings → Subscriptions → US Outdoor Navigator → Cancel.</p>

<p><strong>How do I restore my purchases after reinstalling?</strong><br>
Open the app → tap the paywall screen → tap <em>"Restore Purchases"</em>. Ensure you're signed in with the same Apple ID / Google account.</p>

<p><strong>Does SOS work without cell signal?</strong><br>
The SOS panic button stores your GPS coordinates locally. A cell signal is required to transmit your location. Always call <strong>911</strong> in a life-threatening emergency.</p>

<p><strong>Why is the wildfire map not showing fires?</strong><br>
Wildfire data comes from NASA FIRMS and updates every few hours. If no fires are displayed, it may mean no active fires are detected in your area or the backend is temporarily unavailable.</p>

<p><strong>How do I delete my account and data?</strong><br>
Open the app → Profile (top-right) → Danger Zone → <em>"Delete My Account &amp; Data"</em>. All community reports and SOS logs will be permanently erased.</p>

<p><strong>Which states are available for free?</strong><br>
California, Arizona, and Utah campgrounds are free forever. A Pro subscription unlocks all 50 US states including Alaska &amp; Hawaii.</p>

<h2>🔒 Privacy &amp; Legal</h2>
<p>
  <a href="/privacy">Privacy Policy</a> &nbsp;·&nbsp;
  <a href="/terms">Terms of Service</a>
</p>

<hr>
<p><em>© 2026 US Outdoor Navigator · support@usoutdoor.app</em></p>
</body></html>"""

@app.get("/support", response_class=HTMLResponse, include_in_schema=False)
async def support_page():
    """Support page — App Store Connect / Play Console zorunlu URL."""
    return HTMLResponse(content=_SUPPORT_HTML)

@app.get("/health")
async def health_check():
    """Railway/Render health check endpoint."""
    cache = db.get_cache_stats()
    return {
        "status": "healthy",
        "camp_count": cache["camp_count"],
        "timestamp": datetime.datetime.now().isoformat()
    }

# ══════════════════════════════════════════════════════════════════════════════
if __name__ == "__main__":
    print("═"*65)
    print("  US Outdoor Navigator API v6.0 — Survival & Comfort Edition")
    print("  us_outdoor_master_final.json (1577 kamp, 49 eyalet/bolge)")
    print("  YENI: Weather Sentinel | SOS/Panic | RV Logistics | Solar")
    print("  YENI: Kamp Kurallari | Host Network | Dead Man's Switch")
    print("  NASA FIRMS: Aktif | NOAA/NWS: Aktif | Overpass: Aktif")
    print("═"*65)
    uvicorn.run(app, host="0.0.0.0", port=8000)
