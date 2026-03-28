import requests
import json
import os
from typing import List, Dict

# ══════════════════════════════════════════════════════════════════════════════
#  GRUP TANIMLARI
#  Sistem yükünü azaltmak için eyaletler 10'arlı gruplara bölündü.
#  Her grup ayrı bir JSON dosyasına kaydedilir.
# ══════════════════════════════════════════════════════════════════════════════
STATE_GROUPS = {
    "v1": {
        "label": "Batı Yakası & Rockies",
        "states": ["CA", "AZ", "WA", "OR", "NV", "UT", "MT", "CO", "WY", "ID"],
        "output_file": "us_outdoor_master_v1.json"
    },
    "v2": {
        "label": "Orta Amerika",
        "states": ["TX", "OK", "KS", "NE", "SD", "ND", "NM", "LA", "AR", "MO"],
        "output_file": "us_outdoor_master_v2.json"
    },
    "v3": {
        "label": "Guney & Guneydogu",
        "states": ["FL", "GA", "AL", "MS", "TN", "KY", "NC", "SC", "VA", "WV"],
        "output_file": "us_outdoor_master_v3.json"
    },
    "v4": {
        "label": "Kuzeydogu & Goller Bolgesi",
        "states": ["NY", "PA", "OH", "MI", "IN", "IL", "WI", "MN", "IA", "NJ"],
        "output_file": "us_outdoor_master_v4.json"
    },
    "v5": {
        "label": "New England, Mid-Atlantic, Alaska & Hawaii (FINAL)",
        "states": ["ME", "NH", "VT", "MA", "RI", "CT", "DE", "MD", "DC", "AK", "HI"],
        "output_file": "us_outdoor_master_v5_only.json"
    },
}


class OutdoorScraper:
    def __init__(self):
        # Resmi RIDB API adresi
        self.api_url = "https://ridb.recreation.gov/api/v1/facilities"

        # Resmi RIDB API anahtarı
        self.headers = {
            "accept": "application/json",
            "apikey": "3a9a88aa-a18d-4ac3-8cc5-6673221ca464"
        }

        # Verilerin kaydedileceği klasörü hazırla
        self.output_dir = os.path.join(os.path.dirname(__file__), "..", "data_sources")
        if not os.path.exists(self.output_dir):
            os.makedirs(self.output_dir)

    # ──────────────────────────────────────────────────────────────────────────
    #  TEMEL ÇEKME FONKSİYONU
    # ──────────────────────────────────────────────────────────────────────────
    def fetch_campgrounds(self, state: str = "CA", limit: int = 50) -> List[Dict]:
        """
        Belirli bir eyaletteki kamp alanlarını RIDB API'den çeker.
        """
        params = {
            "state": state,
            "limit": limit,
            "full": "true",
            "activity": "CAMPING"
        }

        print(f"--- {state} Eyaleti İçin Veri Çekme İşlemi Başladı ---")

        try:
            response = requests.get(
                self.api_url,
                headers=self.headers,
                params=params,
                timeout=30
            )

            if response.status_code == 200:
                data = response.json()
                campgrounds = data.get('RECDATA', [])
                print(f"✅ {state}: {len(campgrounds)} kamp alanı bulundu.")
                return campgrounds
            else:
                print(f"❌ {state} Hatası: HTTP {response.status_code}")
                return []

        except Exception as e:
            print(f"🚨 Bağlantı Hatası ({state}): {e}")
            return []

    # ──────────────────────────────────────────────────────────────────────────
    #  GRUP BAZLI ÇEKME FONKSİYONU (YENİ)
    # ──────────────────────────────────────────────────────────────────────────
    def fetch_group(self, group_key: str = "v1", limit_per_state: int = 50) -> List[Dict]:
        """
        Belirtilen grubun tüm eyaletlerinden veri çeker ve
        us_outdoor_master_{group_key}.json olarak kaydeder.

        Parametreler:
            group_key       : STATE_GROUPS sözlüğündeki anahtar (örn: "v1")
            limit_per_state : Her eyalet için maksimum kayıt sayısı
        """
        if group_key not in STATE_GROUPS:
            raise ValueError(f"Bilinmeyen grup: {group_key}. Mevcut gruplar: {list(STATE_GROUPS.keys())}")

        group = STATE_GROUPS[group_key]
        states = group["states"]
        output_file = group["output_file"]

        print(f"\n{'═' * 60}")
        print(f"  GRUP {group_key.upper()} — {group['label']}")
        print(f"  Eyaletler: {', '.join(states)}")
        print(f"  Hedef Dosya: {output_file}")
        print(f"{'═' * 60}\n")

        all_campgrounds = []
        seen_ids = set()

        for state in states:
            raw_camps = self.fetch_campgrounds(state=state, limit=limit_per_state)

            for camp in raw_camps:
                facility_id = camp.get("FacilityID")
                lat = camp.get("FacilityLatitude")
                lon = camp.get("FacilityLongitude")

                # Koordinatı olmayan ve mükerrer kayıtları atla
                if not lat or not lon or facility_id in seen_ids:
                    continue

                seen_ids.add(facility_id)

                # Temizlenmiş ve standartlaştırılmış format
                clean_camp = {
                    "id":              str(facility_id),
                    "name":            camp.get("FacilityName", "Unknown Camp"),
                    "lat":             float(lat),
                    "lon":             float(lon),
                    "state":           state,
                    "group":           group_key,
                    "price_per_night": 25.0,
                    "max_rv_length":   35.0,
                    "amenities":       ["Check Official Site"],
                    "has_water":       True,
                    "description":     (camp.get("FacilityDescription", "") or "")[:200]
                }
                all_campgrounds.append(clean_camp)

        print(f"\n{'─' * 60}")
        print(f"🎯 Grup {group_key.upper()} Tamamlandı: {len(all_campgrounds)} benzersiz kamp alanı")

        # Grup JSON'ını kaydet
        master_path = os.path.join(self.output_dir, output_file)
        with open(master_path, "w", encoding="utf-8") as f:
            json.dump(all_campgrounds, f, indent=2, ensure_ascii=False)

        print(f"💾 Kaydedildi → {master_path}")
        print(f"{'─' * 60}\n")

        return all_campgrounds

    # ──────────────────────────────────────────────────────────────────────────
    #  ESKİ UYUMLU METODLAR (değiştirilmedi)
    # ──────────────────────────────────────────────────────────────────────────
    def fetch_all_states(self, states: List[str] = None, limit_per_state: int = 50) -> List[Dict]:
        """
        Birden fazla eyalet için kamp alanı verisini çeker (eski uyumlu versiyon).
        Yeni kod için fetch_group() kullanın.
        """
        if states is None:
            states = ["CA", "OR", "WA", "NV", "AZ", "UT", "MT"]

        print(f"🌎 Multi-State Scraping Başladı: {', '.join(states)}")
        print("=" * 60)

        all_campgrounds = []
        seen_ids = set()

        for state in states:
            raw_camps = self.fetch_campgrounds(state=state, limit=limit_per_state)

            for camp in raw_camps:
                facility_id = camp.get("FacilityID")
                lat = camp.get("FacilityLatitude")
                lon = camp.get("FacilityLongitude")

                if not lat or not lon or facility_id in seen_ids:
                    continue

                seen_ids.add(facility_id)

                clean_camp = {
                    "id":              str(facility_id),
                    "name":            camp.get("FacilityName", "Unknown Camp"),
                    "lat":             float(lat),
                    "lon":             float(lon),
                    "state":           state,
                    "price_per_night": 25.0,
                    "max_rv_length":   35.0,
                    "amenities":       ["Check Official Site"],
                    "has_water":       True,
                    "description":     (camp.get("FacilityDescription", "") or "")[:200]
                }
                all_campgrounds.append(clean_camp)

        print("=" * 60)
        print(f"🎯 Toplam: {len(all_campgrounds)} benzersiz kamp alanı toplandı.")

        # Eski master dosyasına da kaydet (geriye dönük uyumluluk)
        master_path = os.path.join(self.output_dir, "us_outdoor_navigator_master.json")
        with open(master_path, "w", encoding="utf-8") as f:
            json.dump(all_campgrounds, f, indent=2, ensure_ascii=False)

        print(f"💾 Master JSON kaydedildi: {master_path}")
        return all_campgrounds

    def fetch_single_state_and_save(self, state: str = "CA", limit: int = 50):
        """
        Tekil eyalet verisi çekip raw + clean formatında kaydet.
        """
        raw_camps = self.fetch_campgrounds(state=state, limit=limit)

        # Ham veriyi kaydet
        raw_path = os.path.join(self.output_dir, f"{state.lower()}_camps_raw.json")
        with open(raw_path, "w", encoding="utf-8") as f:
            json.dump(raw_camps, f, indent=2, ensure_ascii=False)
        print(f"💾 Ham veri kaydedildi: {raw_path}")

        # Temiz formata dönüştür
        clean_camps = []
        for camp in raw_camps:
            lat = camp.get("FacilityLatitude")
            lon = camp.get("FacilityLongitude")
            if lat and lon:
                clean_camps.append({
                    "id":              str(camp.get("FacilityID", "")),
                    "name":            camp.get("FacilityName", "Unknown"),
                    "lat":             float(lat),
                    "lon":             float(lon),
                    "state":           state,
                    "price_per_night": 25.0,
                    "max_rv_length":   35.0,
                    "amenities":       ["Check Official Site"],
                    "has_water":       True
                })

        clean_path = os.path.join(self.output_dir, f"{state.lower()}_camps_clean.json")
        with open(clean_path, "w", encoding="utf-8") as f:
            json.dump(clean_camps, f, indent=2, ensure_ascii=False)
        print(f"✅ {len(clean_camps)} temiz kayıt: {clean_path}")
        return clean_camps


# ══════════════════════════════════════════════════════════════════════════════
#  ANA ÇALIŞTIRMA — GRUP 1 (Batı Yakası & Rockies)
# ══════════════════════════════════════════════════════════════════════════════
if __name__ == "__main__":
    scraper = OutdoorScraper()

    print("╔══════════════════════════════════════════════════════════╗")
    print("║   US Outdoor Navigator — Grup 1 Scraping Başlıyor       ║")
    print("║   Eyaletler: CA, AZ, WA, OR, NV, UT, MT, CO, WY, ID    ║")
    print("╚══════════════════════════════════════════════════════════╝\n")

    # GRUP 1 — Batı Yakası & Rockies
    group1_data = scraper.fetch_group(
        group_key="v1",
        limit_per_state=50   # Eyalet başına maks 50 kayıt (API limiti)
    )

    print(f"\n✅ GRUP 1 TAMAMLANDI! Toplam {len(group1_data)} kamp alanı.")
    print("📁 Dosya: data_sources/us_outdoor_master_v1.json")
    print("\n⏳ Grup 2 için komut bekleniyor...")
