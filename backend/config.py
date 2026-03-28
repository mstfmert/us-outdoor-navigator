# config.py — US Outdoor Navigator Backend Configuration
# Ortam değişkenlerini yönetir (local .env + Railway/Render env vars)
import os

try:
    from dotenv import load_dotenv
    load_dotenv()  # .env dosyasını yükle (local geliştirme)
except ImportError:
    pass  # python-dotenv yüklü değilse geç (production'da env var olarak gelir)

# ── Ortam ─────────────────────────────────────────────────────────────────
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")
IS_PRODUCTION = ENVIRONMENT == "production"

# ── Veri Dizini ───────────────────────────────────────────────────────────
_BASE_DIR = os.path.dirname(__file__)
DATA_DIR = os.getenv(
    "DATA_DIR",
    os.path.join(_BASE_DIR, "..", "data_sources")
)

# ── NASA API ──────────────────────────────────────────────────────────────
NASA_API_KEY = os.getenv("NASA_API_KEY", "DEMO_KEY")

# ── CORS ──────────────────────────────────────────────────────────────────
_origins_env = os.getenv("ALLOWED_ORIGINS", "")
ALLOWED_ORIGINS = (
    [o.strip() for o in _origins_env.split(",") if o.strip()]
    if IS_PRODUCTION
    else ["*"]
)

# ── Port ──────────────────────────────────────────────────────────────────
PORT = int(os.getenv("PORT", "8000"))

# ── Dosya Yolları ─────────────────────────────────────────────────────────
MASTER_FILE  = os.path.join(DATA_DIR, "us_outdoor_master_final.json")
REPORTS_FILE = os.path.join(DATA_DIR, "reports.json")
HOST_FILE    = os.path.join(DATA_DIR, "host_spots.json")
SOS_LOG_FILE = os.path.join(DATA_DIR, "sos_log.json")

if __name__ == "__main__":
    print(f"ENVIRONMENT  : {ENVIRONMENT}")
    print(f"DATA_DIR     : {DATA_DIR}")
    print(f"MASTER_FILE  : {MASTER_FILE}")
    print(f"IS_PRODUCTION: {IS_PRODUCTION}")
    print(f"ALLOWED_ORIGINS: {ALLOWED_ORIGINS}")
