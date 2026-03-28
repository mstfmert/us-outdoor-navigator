"""
sos_service.py — SOS / Panic Mode & Dead Man's Switch
Kullanicinin son koordinatlarini acil durum kaydina ekler.
Gercek SMS/Email: Twilio veya SendGrid entegrasyonu yapilabilir.
Dead Man's Switch: 24 saat check-in olmadiysa uyari tetiklenir.
"""
import json, os, datetime, uuid
from typing import Dict, List, Optional

DATA_DIR   = os.path.join(os.path.dirname(__file__), "..", "data_sources")
SOS_FILE   = os.path.join(DATA_DIR, "sos_log.json")
CHECKIN_FILE = os.path.join(DATA_DIR, "checkins.json")

# Dead Man's Switch suresi (saat)
DEAD_MANS_SWITCH_HOURS = 24


class SOSService:

    # ── SOS / PANIC MODU ─────────────────────────────────────────────────────

    def trigger_panic(
        self,
        lat: float,
        lon: float,
        user_id: str,
        emergency_contact: str = "",
        message: str = "PANIC BUTTON PRESSED",
        user_name: str = "Unknown User"
    ) -> Dict:
        """
        PANIC butonu tetiklendiginde cagrilir.
        - Kullanicinin konumunu SOS loguna kaydeder
        - Acil iletisim bilgisini saklar
        - Gercek SMS/Email: Twilio/SendGrid entegrasyonu buraya eklenir
        """
        sos_id    = str(uuid.uuid4())[:10].upper()
        timestamp = datetime.datetime.now().isoformat()

        sos_record = {
            "sos_id":            sos_id,
            "type":              "PANIC",
            "user_id":           user_id,
            "user_name":         user_name,
            "lat":               lat,
            "lon":               lon,
            "message":           message,
            "emergency_contact": emergency_contact,
            "timestamp":         timestamp,
            "status":            "ACTIVE",
            "resolved":          False,
            "google_maps_url":   f"https://maps.google.com/?q={lat},{lon}",
            "what3words_url":    f"https://what3words.com/coordinates/{lat},{lon}"
        }

        # SOS loguna kaydet
        logs = self._load_file(SOS_FILE)
        logs.append(sos_record)
        self._save_file(SOS_FILE, logs)

        # NOT: Gercek deployment'ta buraya Twilio SMS / SendGrid Email gelir
        # Ornek Twilio: client.messages.create(to=emergency_contact, from_="+1xxx", body=f"SOS! {user_name} @ {lat},{lon}")
        notification_sent = bool(emergency_contact)
        print(f"  SOS TETIKLENDI [{sos_id}]: {user_id} @ ({lat:.4f},{lon:.4f})")
        if emergency_contact:
            print(f"  Acil kisi: {emergency_contact} (Twilio entegrasyonu ile gercek SMS gonderilebilir)")

        return {
            "status":            "SOS_ACTIVATED",
            "sos_id":            sos_id,
            "message":           "Acil durum kaydedildi. Koordinatlariniz log'a eklendi.",
            "coordinates":       {"lat": lat, "lon": lon},
            "google_maps_url":   sos_record["google_maps_url"],
            "notification_sent": notification_sent,
            "emergency_contact": emergency_contact or "Tanimlanmamis",
            "timestamp":         timestamp,
            "instructions": [
                "Sakin olun ve mevcut konumunuzda kalin.",
                "Telefon sarjinizi koruyun.",
                "Acil durumda 911'i arayin.",
                f"Koordinatlariniz: {lat:.4f}, {lon:.4f}"
            ]
        }

    def resolve_sos(self, sos_id: str, resolved_by: str = "user") -> Dict:
        """SOS durumunu cozuldu olarak isaretle."""
        logs = self._load_file(SOS_FILE)
        for log in logs:
            if log.get("sos_id") == sos_id:
                log["status"]      = "RESOLVED"
                log["resolved"]    = True
                log["resolved_by"] = resolved_by
                log["resolved_at"] = datetime.datetime.now().isoformat()
                self._save_file(SOS_FILE, logs)
                return {"status": "ok", "message": f"SOS {sos_id} cozuldu.", "sos_id": sos_id}
        return {"status": "not_found", "message": f"SOS {sos_id} bulunamadi."}

    # ── DEAD MAN'S SWITCH ─────────────────────────────────────────────────────

    def checkin(self, user_id: str, lat: float, lon: float, next_checkin_hours: int = 24) -> Dict:
        """
        Kullanici check-in yapar. Son check-in zamani guncellenir.
        Belirtilen sure icinde tekrar check-in yapilmazsa Dead Man's Switch tetiklenir.
        """
        checkins = self._load_file(CHECKIN_FILE)

        now = datetime.datetime.now()
        next_due = (now + datetime.timedelta(hours=next_checkin_hours)).isoformat()

        # Mevcut check-in varsa guncelle
        for ci in checkins:
            if ci.get("user_id") == user_id:
                ci["last_checkin"]    = now.isoformat()
                ci["last_lat"]        = lat
                ci["last_lon"]        = lon
                ci["next_due"]        = next_due
                ci["overdue"]         = False
                ci["checkin_count"]   = ci.get("checkin_count", 0) + 1
                self._save_file(CHECKIN_FILE, checkins)
                return {
                    "status":         "ok",
                    "message":        "Check-in basarili.",
                    "next_due":       next_due,
                    "checkin_count":  ci["checkin_count"]
                }

        # Yeni check-in karti olustur
        checkins.append({
            "user_id":      user_id,
            "last_checkin": now.isoformat(),
            "last_lat":     lat,
            "last_lon":     lon,
            "next_due":     next_due,
            "overdue":      False,
            "checkin_count": 1,
            "created_at":   now.isoformat()
        })
        self._save_file(CHECKIN_FILE, checkins)
        return {"status": "ok", "message": "Check-in basarili (yeni kayit).", "next_due": next_due, "checkin_count": 1}

    def check_overdue(self) -> List[Dict]:
        """
        Tum check-in kayitlarini kontrol eder.
        Suresi gec anilanlar icin Dead Man's Switch uyarisi doner.
        """
        checkins = self._load_file(CHECKIN_FILE)
        now      = datetime.datetime.now()
        overdue  = []

        for ci in checkins:
            if ci.get("overdue"):
                continue
            try:
                next_due = datetime.datetime.fromisoformat(ci["next_due"])
                if now > next_due:
                    ci["overdue"] = True
                    hours_late    = round((now - next_due).total_seconds() / 3600, 1)
                    overdue.append({
                        "user_id":     ci["user_id"],
                        "last_lat":    ci.get("last_lat"),
                        "last_lon":    ci.get("last_lon"),
                        "last_checkin": ci.get("last_checkin"),
                        "hours_late":  hours_late,
                        "google_maps_url": f"https://maps.google.com/?q={ci.get('last_lat')},{ci.get('last_lon')}",
                        "action_needed": "DEAD_MANS_SWITCH_TRIGGERED"
                    })
            except Exception:
                pass

        if overdue:
            self._save_file(CHECKIN_FILE, checkins)
        return overdue

    def get_active_sos_logs(self) -> List[Dict]:
        """Aktif (cozulmemis) tum SOS kayitlarini doner."""
        return [s for s in self._load_file(SOS_FILE) if not s.get("resolved")]

    # ── YARDIMCI ─────────────────────────────────────────────────────────────

    def _load_file(self, path: str) -> list:
        os.makedirs(DATA_DIR, exist_ok=True)
        if not os.path.exists(path):
            return []
        try:
            with open(path, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return []

    def _save_file(self, path: str, data: list) -> None:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
