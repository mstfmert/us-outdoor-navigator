"""
database.py — US Outdoor Navigator  ★ Production Data Layer ★
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STRATEJI:
  • Kamp verisi (1577 statik kamp) → In-Memory Cache (startup'ta 1x yükle)
  • Reports / SOS / Checkins      → SQLite  (mutable, sık yazılan veri)

PRODUCTION UPGRADE YOLU:
  • SQLite → Supabase (PostgreSQL + PostGIS)
  • In-memory → Redis (distributed cache)
  
Bunu değiştirmek için sadece get_db() ve get_camps() fonksiyonlarını güncelle.
"""
import json, os, sqlite3, threading, time, datetime
from typing import List, Dict, Optional

_BASE_DIR   = os.path.dirname(__file__)
_DATA_DIR   = os.path.join(_BASE_DIR, "..", "data_sources")
_MASTER     = os.path.join(_DATA_DIR, "us_outdoor_master_final.json")
_FALLBACK   = os.path.join(_DATA_DIR, "ca_camps_clean.json")   # Production'da yoksa fallback
_DB_FILE    = os.path.join(_DATA_DIR, "outdoor_nav.db")
_REPORTS_JSON = os.path.join(_DATA_DIR, "reports.json")

_lock = threading.Lock()

# ══════════════════════════════════════════════════════════════════════════════
#  IN-MEMORY CAMP CACHE — Startup'ta 1x yükle, sonra hep RAM'den oku
# ══════════════════════════════════════════════════════════════════════════════
_camps_cache: List[Dict] = []
_camps_loaded: bool      = False
_load_time: float        = 0.0

def get_camps() -> List[Dict]:
    """
    Thread-safe lazy-load camp cache.
    İlk çağrıda diskten okur, sonraki tüm çağrılarda RAM'den döner.
    JSON dosyası yerine bu fonksiyonu kullan → 0 disk I/O.
    """
    global _camps_cache, _camps_loaded
    if not _camps_loaded:
        with _lock:
            if not _camps_loaded:
                _load_camps()
    return _camps_cache

def _load_camps():
    global _camps_cache, _camps_loaded, _load_time
    t0 = time.monotonic()

    # Önce master dosyasını dene, yoksa ca_camps_clean.json'u kullan
    source_file = None
    if os.path.exists(_MASTER):
        source_file = _MASTER
    elif os.path.exists(_FALLBACK):
        print(f"⚠️  master_final.json yok → fallback: ca_camps_clean.json kullanılıyor")
        source_file = _FALLBACK
    else:
        print("❌ Hiçbir kamp dosyası bulunamadı!")
        _camps_cache  = []
        _camps_loaded = True
        return

    try:
        with open(source_file, "r", encoding="utf-8") as f:
            data = json.load(f)
        # Eksik alanları normalize et (fallback verisi daha sade olabilir)
        normalized = []
        for c in data:
            c.setdefault("state", "CA")
            c.setdefault("group", "v1")
            c.setdefault("type", "campground")
            c.setdefault("description", "")
            c.setdefault("surface", "unknown")
            c.setdefault("slope_pct", 2.0)
            normalized.append(c)
        _camps_cache  = normalized
        _load_time    = time.monotonic() - t0
        _camps_loaded = True
        print(f"✅ Camp cache yüklendi: {len(_camps_cache)} kamp | {_load_time*1000:.0f}ms | kaynak: {os.path.basename(source_file)}")
    except Exception as e:
        print(f"❌ Camp cache yükleme hatası: {e}")
        _camps_cache  = []
        _camps_loaded = True

def reload_camps():
    """Admin: kamp verisini diskten yeniden yükle."""
    global _camps_loaded
    with _lock:
        _camps_loaded = False
    get_camps()

def get_cache_stats() -> Dict:
    return {
        "camp_count":  len(_camps_cache),
        "loaded":      _camps_loaded,
        "load_ms":     round(_load_time * 1000, 1),
        "source":      "in_memory_cache",
        "db_file":     _DB_FILE,
    }

# ══════════════════════════════════════════════════════════════════════════════
#  SQLITE — Reports, SOS, Checkins (mutable data)
# ══════════════════════════════════════════════════════════════════════════════
def get_db() -> sqlite3.Connection:
    """
    SQLite bağlantısı döner.
    Production: Bu fonksiyonu asyncpg (Supabase) ile değiştir.
    """
    os.makedirs(_DATA_DIR, exist_ok=True)
    conn = sqlite3.connect(_DB_FILE, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")   # Concurrent write performansı
    conn.execute("PRAGMA synchronous=NORMAL") # Performans/güvenlik dengesi
    return conn

def init_db():
    """Uygulama başlangıcında çağrıl — tabloları oluştur, JSON'dan migrate et."""
    with get_db() as conn:
        conn.executescript("""
            CREATE TABLE IF NOT EXISTS reports (
                id          TEXT PRIMARY KEY,
                lat         REAL NOT NULL,
                lon         REAL NOT NULL,
                report_type TEXT NOT NULL,
                description TEXT DEFAULT '',
                user_id     TEXT DEFAULT 'anonymous',
                timestamp   TEXT NOT NULL,
                group_id    TEXT DEFAULT 'unknown'
            );
            CREATE INDEX IF NOT EXISTS idx_reports_geo  ON reports(lat, lon);
            CREATE INDEX IF NOT EXISTS idx_reports_user ON reports(user_id);
            CREATE INDEX IF NOT EXISTS idx_reports_type ON reports(report_type);

            CREATE TABLE IF NOT EXISTS sos_logs (
                sos_id            TEXT PRIMARY KEY,
                user_id           TEXT NOT NULL,
                user_name         TEXT DEFAULT 'Unknown',
                lat               REAL NOT NULL,
                lon               REAL NOT NULL,
                message           TEXT DEFAULT '',
                emergency_contact TEXT DEFAULT '',
                status            TEXT DEFAULT 'ACTIVE',
                resolved          INTEGER DEFAULT 0,
                resolved_by       TEXT DEFAULT '',
                resolved_at       TEXT DEFAULT '',
                google_maps_url   TEXT DEFAULT '',
                timestamp         TEXT NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_sos_user   ON sos_logs(user_id);
            CREATE INDEX IF NOT EXISTS idx_sos_status ON sos_logs(status);

            CREATE TABLE IF NOT EXISTS checkins (
                user_id       TEXT PRIMARY KEY,
                last_lat      REAL,
                last_lon      REAL,
                last_checkin  TEXT,
                next_due      TEXT,
                overdue       INTEGER DEFAULT 0,
                checkin_count INTEGER DEFAULT 1,
                created_at    TEXT
            );

            CREATE TABLE IF NOT EXISTS rate_limits (
                key          TEXT PRIMARY KEY,
                count        INTEGER DEFAULT 0,
                window_start TEXT NOT NULL
            );
        """)
        conn.commit()
    print("✅ SQLite DB hazır:", _DB_FILE)
    _migrate_json_to_sqlite()

def _migrate_json_to_sqlite():
    """JSON reports.json → SQLite (tek seferlik migrasyon)."""
    if not os.path.exists(_REPORTS_JSON):
        return
    try:
        with open(_REPORTS_JSON, "r", encoding="utf-8") as f:
            reports = json.load(f)
        if not reports:
            return
        with get_db() as conn:
            migrated = 0
            for r in reports:
                try:
                    conn.execute(
                        "INSERT OR IGNORE INTO reports"
                        "(id,lat,lon,report_type,description,user_id,timestamp,group_id)"
                        " VALUES(?,?,?,?,?,?,?,?)",
                        (r.get("id",""), r.get("lat",0), r.get("lon",0),
                         r.get("report_type",""), r.get("description",""),
                         r.get("user_id","anonymous"), r.get("timestamp",""),
                         r.get("group",""))
                    )
                    migrated += 1
                except Exception:
                    pass
            conn.commit()
        if migrated:
            print(f"✅ Migrated {migrated} reports → SQLite")
    except Exception as e:
        print(f"⚠️  Report migration: {e}")

# ══════════════════════════════════════════════════════════════════════════════
#  REPORT CRUD — SQLite
# ══════════════════════════════════════════════════════════════════════════════
def insert_report(r: Dict) -> bool:
    try:
        with get_db() as conn:
            conn.execute(
                "INSERT INTO reports(id,lat,lon,report_type,description,user_id,timestamp,group_id)"
                " VALUES(?,?,?,?,?,?,?,?)",
                (r["id"], r["lat"], r["lon"], r["report_type"], r.get("description",""),
                 r.get("user_id","anonymous"), r["timestamp"], r.get("group","unknown"))
            )
            conn.commit()
        return True
    except Exception as e:
        print(f"❌ insert_report: {e}")
        return False

def query_reports_by_bbox(min_lat: float, max_lat: float,
                          min_lon: float, max_lon: float,
                          limit: int = 200) -> List[Dict]:
    try:
        with get_db() as conn:
            rows = conn.execute(
                "SELECT * FROM reports WHERE lat BETWEEN ? AND ? AND lon BETWEEN ? AND ? LIMIT ?",
                (min_lat, max_lat, min_lon, max_lon, limit)
            ).fetchall()
        return [dict(r) for r in rows]
    except Exception:
        return []

def query_reports_nearby(lat: float, lon: float,
                         radius_deg: float = 1.0, limit: int = 100) -> List[Dict]:
    """Basit bbox ile yakın raporları döner (approx ~111km per degree)."""
    return query_reports_by_bbox(
        lat - radius_deg, lat + radius_deg,
        lon - radius_deg, lon + radius_deg,
        limit
    )

def delete_reports_by_user(user_id: str) -> int:
    try:
        with get_db() as conn:
            cur = conn.execute("DELETE FROM reports WHERE user_id=?", (user_id,))
            conn.commit()
            return cur.rowcount
    except Exception:
        return 0

# ══════════════════════════════════════════════════════════════════════════════
#  SOS CRUD — SQLite
# ══════════════════════════════════════════════════════════════════════════════
def insert_sos(s: Dict) -> bool:
    try:
        with get_db() as conn:
            conn.execute(
                "INSERT OR REPLACE INTO sos_logs"
                "(sos_id,user_id,user_name,lat,lon,message,emergency_contact,"
                " status,resolved,google_maps_url,timestamp)"
                " VALUES(?,?,?,?,?,?,?,?,?,?,?)",
                (s["sos_id"], s["user_id"], s.get("user_name",""),
                 s["lat"], s["lon"], s.get("message",""),
                 s.get("emergency_contact",""), s.get("status","ACTIVE"),
                 0, s.get("google_maps_url",""), s["timestamp"])
            )
            conn.commit()
        return True
    except Exception as e:
        print(f"❌ insert_sos: {e}")
        return False

def resolve_sos_db(sos_id: str, resolved_by: str) -> bool:
    try:
        with get_db() as conn:
            conn.execute(
                "UPDATE sos_logs SET status='RESOLVED', resolved=1,"
                " resolved_by=?, resolved_at=? WHERE sos_id=?",
                (resolved_by, datetime.datetime.now().isoformat(), sos_id)
            )
            conn.commit()
        return True
    except Exception:
        return False

def get_active_sos() -> List[Dict]:
    try:
        with get_db() as conn:
            rows = conn.execute(
                "SELECT * FROM sos_logs WHERE resolved=0 ORDER BY timestamp DESC"
            ).fetchall()
        return [dict(r) for r in rows]
    except Exception:
        return []

def delete_sos_by_user(user_id: str) -> int:
    try:
        with get_db() as conn:
            cur = conn.execute("DELETE FROM sos_logs WHERE user_id=?", (user_id,))
            conn.commit()
            return cur.rowcount
    except Exception:
        return 0

# ══════════════════════════════════════════════════════════════════════════════
#  RATE LIMITING — SQLite tabanlı (production: Redis ile değiştir)
# ══════════════════════════════════════════════════════════════════════════════
def check_rate_limit(key: str, max_per_minute: int = 20) -> bool:
    """
    True  → istek geçebilir
    False → rate limit aşıldı (429)
    """
    now_str = datetime.datetime.now().isoformat()
    window_start = datetime.datetime.now().replace(second=0, microsecond=0).isoformat()
    try:
        with get_db() as conn:
            row = conn.execute(
                "SELECT count, window_start FROM rate_limits WHERE key=?", (key,)
            ).fetchone()
            if row is None:
                conn.execute(
                    "INSERT INTO rate_limits(key, count, window_start) VALUES(?,1,?)",
                    (key, window_start)
                )
                conn.commit()
                return True
            stored_window = row["window_start"]
            if stored_window != window_start:
                # Yeni dakika penceresi
                conn.execute(
                    "UPDATE rate_limits SET count=1, window_start=? WHERE key=?",
                    (window_start, key)
                )
                conn.commit()
                return True
            count = row["count"]
            if count >= max_per_minute:
                return False
            conn.execute(
                "UPDATE rate_limits SET count=count+1 WHERE key=?", (key,)
            )
            conn.commit()
            return True
    except Exception:
        return True  # DB hatası varsa bloklama
