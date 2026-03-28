"""
auth_service.py — US Outdoor Navigator  ★ JWT Auth & Rate Limiting ★
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Basit HMAC-SHA256 tabanlı JWT (python-jose'ye gerek yok)
Production upgrade: Auth0 / Firebase Auth / Supabase Auth

AKIŞ:
  1. RevenueCat satın alma onaylar
  2. Flutter app /auth/token endpoint'ine uid + rc_token gönderir
  3. Backend RC token'ı doğrular, JWT döner
  4. Flutter sonraki isteklerde Authorization: Bearer <jwt> header'ı gönderir
  5. is_premium otomatik belirlenir — query param gerekmez
"""
import os, json, hmac, hashlib, base64, time, datetime
from typing import Optional, Dict
from fastapi import Header, HTTPException, Request
from database import check_rate_limit

# ── Gizli Anahtar ─────────────────────────────────────────────────────────────
_JWT_SECRET = os.environ.get(
    "JWT_SECRET",
    "us-outdoor-nav-2026-change-in-production-railway-env"
)

# ── Twilio Yapılandırma Durumu ─────────────────────────────────────────────────
TWILIO_CONFIGURED = all([
    os.environ.get("TWILIO_ACCOUNT_SID", "").startswith("AC"),
    os.environ.get("TWILIO_AUTH_TOKEN", "") != "",
    os.environ.get("TWILIO_FROM_NUMBER", "").startswith("+")
])

# ══════════════════════════════════════════════════════════════════════════════
#  TOKEN OLUŞTURMA / DOĞRULAMA
# ══════════════════════════════════════════════════════════════════════════════
def create_token(user_id: str, is_premium: bool = False,
                 expires_hours: int = 168) -> str:
    """
    HMAC-SHA256 ile imzalı token oluştur.
    expires_hours=168 → 7 gün geçerli (RevenueCat subscription süresiyle sync)
    """
    payload = {
        "uid": user_id,
        "pro": is_premium,
        "exp": int(time.time()) + expires_hours * 3600,
        "iat": int(time.time()),
        "ver": "1"
    }
    data_b64 = base64.urlsafe_b64encode(
        json.dumps(payload, separators=(",", ":")).encode()
    ).decode().rstrip("=")
    sig = hmac.new(
        _JWT_SECRET.encode(), data_b64.encode(), hashlib.sha256
    ).hexdigest()
    return f"{data_b64}.{sig}"

def verify_token(token: str) -> Optional[Dict]:
    """
    Token doğrula. Başarılıysa payload dict döner.
    Başarısızsa None döner.
    """
    if not token or "." not in token:
        return None
    try:
        data_b64, sig = token.rsplit(".", 1)
        expected = hmac.new(
            _JWT_SECRET.encode(), data_b64.encode(), hashlib.sha256
        ).hexdigest()
        if not hmac.compare_digest(sig, expected):
            return None
        # Padding restore
        padding = 4 - len(data_b64) % 4
        data_b64_padded = data_b64 + "=" * (padding % 4)
        payload = json.loads(base64.urlsafe_b64decode(data_b64_padded))
        if payload.get("exp", 0) < time.time():
            return None  # Süresi dolmuş
        return payload
    except Exception:
        return None

def get_token_from_header(authorization: Optional[str]) -> Optional[Dict]:
    """
    Authorization: Bearer <token> header'ından payload çıkar.
    Geçersizse None döner (hata fırlatmaz — opsiyonel auth için).
    """
    if not authorization:
        return None
    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        return None
    return verify_token(parts[1])

def is_premium_from_header(authorization: Optional[str]) -> bool:
    """
    Header'dan premium durumunu tespit et.
    Token yoksa veya geçersizse False (ücretsiz tier).
    """
    payload = get_token_from_header(authorization)
    if payload:
        return bool(payload.get("pro", False))
    return False

# ══════════════════════════════════════════════════════════════════════════════
#  RATE LIMITING DECORATOR
# ══════════════════════════════════════════════════════════════════════════════
def rate_limit_check(request: Request, max_per_minute: int = 30):
    """
    IP bazlı rate limiting kontrolü.
    Aşılırsa HTTPException(429) fırlatır.
    """
    client_ip = request.client.host if request.client else "unknown"
    endpoint  = request.url.path
    key       = f"{client_ip}:{endpoint}"
    
    if not check_rate_limit(key, max_per_minute):
        raise HTTPException(
            status_code=429,
            detail={
                "error": "rate_limit_exceeded",
                "message": f"Çok fazla istek. Dakikada en fazla {max_per_minute} istek.",
                "retry_after_seconds": 60
            }
        )

# ══════════════════════════════════════════════════════════════════════════════
#  SOS BETA DURUMU
# ══════════════════════════════════════════════════════════════════════════════
def get_sos_status() -> Dict:
    """SOS özelliğinin mevcut durumunu döner."""
    if TWILIO_CONFIGURED:
        return {
            "active": True,
            "mode": "production",
            "sms_enabled": True,
            "message": "SOS aktif — acil durum SMS gönderilir."
        }
    return {
        "active": True,  # Kayıt hâlâ çalışıyor
        "mode": "beta",
        "sms_enabled": False,
        "beta_notice": (
            "⚠️ BETA: SOS koordinatları kaydediliyor ancak otomatik SMS "
            "henüz aktif değil. Acil durumlarda 911'i arayın. "
            "Twilio entegrasyonu yakında aktif olacak."
        ),
        "emergency_fallback": "911"
    }

# ══════════════════════════════════════════════════════════════════════════════
#  FREE vs PRO FEATURE SINIFLANDIRMASI
# ══════════════════════════════════════════════════════════════════════════════
FEATURE_TIERS = {
    # ── GÜVENLİK (Apple/Google politikası gereği HEP ÜCRETSİZ) ──────────────
    "wildfire":         "free",
    "weather_alerts":   "free",
    "sos":              "free",
    "night_weather":    "free",
    "get_reports":      "free",
    "report_submit":    "free",
    "camp_basic":       "free",       # CA, AZ, UT kampları
    
    # ── KONFOR / PRO ÖZELLIKLER (Abonelik gerekli) ────────────────────────────
    "all_states":       "pro",        # 50 eyalet kampları
    "offline_maps":     "pro",
    "starlink_ar":      "pro",
    "digital_level":    "pro",
    "fuel_saver":       "pro",
    "rv_guard":         "pro",
    "host_network":     "pro",
    "solar_estimate":   "pro",
}

def check_feature_access(feature: str, is_premium: bool) -> Dict:
    """
    Özelliğe erişim kontrolü.
    Returns: {"allowed": bool, "tier": str, "upgrade_msg": str}
    """
    tier = FEATURE_TIERS.get(feature, "pro")
    if tier == "free" or is_premium:
        return {"allowed": True, "tier": tier}
    return {
        "allowed": False,
        "tier": "pro",
        "feature": feature,
        "upgrade_msg": f"'{feature}' özelliği Pro abonelik gerektirir.",
        "upgrade_url": "usoutdoor://paywall"
    }
