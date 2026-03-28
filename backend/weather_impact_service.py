"""
weather_impact_service.py — Weather Impact Score (Zemin Çamur Riski)
Yağış miktarı × Zemin tipi → Mud Risk Score (0–100)
"""
import logging
from typing import Optional

log = logging.getLogger("weather_impact")

# Zemin tipi katsayıları (mud_factor: yüksek = daha kolay çamurlanır)
GROUND_FACTORS = {
    "dirt":       1.0,    # Toprak — en kötü
    "gravel":     0.55,   # Çakıl
    "grass":      0.75,   # Çimen
    "sand":       0.40,   # Kum (drene eder)
    "paved":      0.05,   # Asfalt/Beton
    "concrete":   0.05,
    "asphalt":    0.05,
    "compacted":  0.45,   # Sıkıştırılmış toprak
    "ground":     0.85,   # Ormanlık zemin (ıslak yaprak)
    "mud":        1.0,    # Zaten çamur
    "unknown":    0.60,   # Bilinmiyor — orta risk
}

# Araç tipi çarpanı (yüksek = daha az etkilenir)
VEHICLE_CLEARANCE = {
    "4x4":      0.30,  # %30 azaltır
    "suv":      0.20,
    "rv":       0.10,  # RV kötü clearance, az azaltır
    "car":      0.00,
    "truck":    0.25,
}


def calculate_mud_risk(
    precipitation_mm: float,
    ground_type: str = "unknown",
    vehicle_type: str = "rv",
    slope_pct: float = 0.0,
    temp_celsius: float = 15.0,
    duration_hours: float = 1.0,
) -> dict:
    """
    Çamur riski hesapla.
    precipitation_mm: Son 24 saat yağış (mm)
    ground_type: 'dirt' | 'gravel' | 'paved' | ...
    vehicle_type: '4x4' | 'rv' | 'car' | ...
    slope_pct: Arazi eğimi %
    temp_celsius: Hava sıcaklığı (0°C altı = buz riski)
    duration_hours: Yağmur süresi
    """
    gt = ground_type.lower().strip()
    mud_factor = GROUND_FACTORS.get(gt, GROUND_FACTORS["unknown"])

    vt = vehicle_type.lower().strip()
    veh_clearance = VEHICLE_CLEARANCE.get(vt, 0.0)

    # Temel risk: yağış × zemin faktörü
    # 25mm yağış toprak zeminde → 100% risk
    base_risk = min(precipitation_mm * mud_factor * 4.0, 100.0)

    # Eğim çarpanı (her %10 eğim %15 ek risk)
    slope_mult = 1.0 + (slope_pct / 10.0) * 0.15

    # Süre çarpanı (5 saat üzeri %20 ek)
    dur_mult = 1.0 + (min(duration_hours, 24) / 24.0) * 0.20

    # Sıcaklık: 0°C altı → buz riski, çamur yerine donmuş zemin
    if temp_celsius < 0:
        base_risk *= 0.30  # Donmuş zemin = daha az çamur
        frost_warning = True
    elif temp_celsius < 5:
        base_risk *= 0.60
        frost_warning = True
    else:
        frost_warning = False

    raw_risk = min(base_risk * slope_mult * dur_mult * (1 - veh_clearance), 100.0)
    risk_pct = round(raw_risk, 1)

    # Seviye belirleme
    if risk_pct >= 80:
        level = "EXTREME"
        color = "0xFFFF1744"
        advice = f"🚫 {_get_ground_label(gt)} zemin — Geçiş önerilmez. Sadece ağır 4x4 araçlar."
        icon = "🚫"
    elif risk_pct >= 60:
        level = "HIGH"
        color = "0xFFFF6B00"
        advice = f"⚠️ Yüksek çamur riski ({_get_ground_label(gt)}) — Sadece 4x4 araçlar uygun."
        icon = "⚠️"
    elif risk_pct >= 35:
        level = "MODERATE"
        color = "0xFFFFD600"
        advice = f"🟡 Orta risk — {_get_ground_label(gt)} zemin ıslak. Dikkatli olun."
        icon = "🟡"
    elif risk_pct >= 15:
        level = "LOW"
        color = "0xFF00FF88"
        advice = f"✅ Düşük risk — {_get_ground_label(gt)} zemin hafif ıslak. Standart araç geçebilir."
        icon = "✅"
    else:
        level = "SAFE"
        color = "0xFF00FF88"
        advice = f"✅ Güvenli — {_get_ground_label(gt)} zemin kuru ve sağlam."
        icon = "✅"

    if frost_warning:
        advice = f"🧊 BUZLANMA RİSKİ! {advice}"

    return {
        "mud_risk_pct": risk_pct,
        "level": level,
        "color_hex": color,
        "icon": icon,
        "advice": advice,
        "ground_type": gt,
        "ground_label": _get_ground_label(gt),
        "precipitation_mm": precipitation_mm,
        "vehicle_type": vehicle_type,
        "frost_warning": frost_warning,
        "factors": {
            "mud_factor": mud_factor,
            "slope_pct": slope_pct,
            "duration_hours": duration_hours,
            "temp_celsius": temp_celsius,
        },
    }


def get_camp_ground_risk(
    camp_name: str,
    ground_type: str,
    precipitation_mm: float,
    temperature_c: float = 15.0,
    slope_pct: float = 2.0,
    rv_length_ft: float = 35.0,
) -> dict:
    """
    Kamp alanı için zemin riski hesapla.
    RV uzunluğu büyükse risk artar (dönüş/manevra zorluğu).
    """
    # RV uzunluk çarpanı (45ft+ için %10 ek)
    rv_factor = 1.0 + max(0.0, (rv_length_ft - 35) / 100.0)

    result = calculate_mud_risk(
        precipitation_mm=precipitation_mm,
        ground_type=ground_type,
        vehicle_type="rv",
        slope_pct=slope_pct,
        temp_celsius=temperature_c,
        duration_hours=6.0,
    )

    # RV faktörü uygula
    adjusted_risk = min(result["mud_risk_pct"] * rv_factor, 100.0)
    result["mud_risk_pct"] = round(adjusted_risk, 1)
    result["camp_name"] = camp_name
    result["rv_factor"] = rv_factor

    return result


def _get_ground_label(gt: str) -> str:
    labels = {
        "dirt": "Toprak",
        "gravel": "Çakıl",
        "grass": "Çimen",
        "sand": "Kum",
        "paved": "Asfalt",
        "concrete": "Beton",
        "asphalt": "Asfalt",
        "compacted": "Sıkıştırılmış",
        "ground": "Ormanlık Zemin",
        "mud": "Çamur",
    }
    return labels.get(gt, "Bilinmiyor")


# ─── Bulk scoring ─────────────────────────────────────────────────────────────
def score_multiple_camps(
    camps: list,
    precipitation_mm: float,
    temperature_c: float = 15.0,
) -> list:
    """
    Birden fazla kamp için toplu risk hesapla.
    camps: [{"id": ..., "name": ..., "ground_type": ..., "slope_pct": ...}]
    """
    results = []
    for camp in camps:
        r = get_camp_ground_risk(
            camp_name=camp.get("name", "Unknown"),
            ground_type=camp.get("surface", "unknown"),
            precipitation_mm=precipitation_mm,
            temperature_c=temperature_c,
            slope_pct=camp.get("slope_pct", 2.0),
        )
        r["camp_id"] = camp.get("id", "")
        results.append(r)
    return results
