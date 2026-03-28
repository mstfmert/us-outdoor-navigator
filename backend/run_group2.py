"""
run_group2.py — Grup 2 (Orta Amerika) scraping + v1+v2 birleştirme
Eyaletler: TX, OK, KS, NE, SD, ND, NM, LA, AR, MO
Çıktı    : data_sources/us_outdoor_master_v2.json  (Grup1 + Grup2 birleşik)
"""
import json
import os
import sys

# scraper_service aynı klasörde
sys.path.insert(0, os.path.dirname(__file__))
from scraper_service import OutdoorScraper

DATA_DIR  = os.path.join(os.path.dirname(__file__), "..", "data_sources")
V1_FILE   = os.path.join(DATA_DIR, "us_outdoor_master_v1.json")
V2_OUT    = os.path.join(DATA_DIR, "us_outdoor_master_v2.json")


def run():
    print("╔══════════════════════════════════════════════════════════╗")
    print("║   US Outdoor Navigator — Grup 2 Scraping Başlıyor       ║")
    print("║   TX, OK, KS, NE, SD, ND, NM, LA, AR, MO               ║")
    print("╚══════════════════════════════════════════════════════════╝\n")

    scraper = OutdoorScraper()

    # ── ADIM 1: Grup 2 verisini çek ──────────────────────────────────────────
    group2_data = scraper.fetch_group(group_key="v2", limit_per_state=50)
    print(f"  Grup 2 çekilen veri: {len(group2_data)} kamp alanı\n")

    # ── ADIM 2: Grup 1 verisini yükle ────────────────────────────────────────
    if not os.path.exists(V1_FILE):
        print("⚠️  us_outdoor_master_v1.json bulunamadı!")
        print("    Lütfen önce: python scraper_service.py")
        print("    Sadece Grup 2 verisiyle devam ediliyor...\n")
        group1_data = []
    else:
        with open(V1_FILE, "r", encoding="utf-8") as f:
            group1_data = json.load(f)
        print(f"  Grup 1 yüklenen veri : {len(group1_data)} kamp alanı")

    # ── ADIM 3: Birleştir (mükerrer ID kontrolü) ─────────────────────────────
    seen_ids   = {c["id"] for c in group1_data}
    merged     = list(group1_data)   # Grup 1 taban

    new_added  = 0
    duplicates = 0
    for camp in group2_data:
        if camp["id"] in seen_ids:
            duplicates += 1
            continue
        seen_ids.add(camp["id"])
        merged.append(camp)
        new_added += 1

    print(f"\n{'═' * 55}")
    print(f"  BİRLEŞTİRME RAPORU")
    print(f"{'═' * 55}")
    print(f"  Grup 1 (v1) kamp sayısı   : {len(group1_data)}")
    print(f"  Grup 2 (v2) kamp sayısı   : {len(group2_data)}")
    print(f"  Yeni eklenen (benzersiz)  : {new_added}")
    print(f"  Mükerrer atlanan          : {duplicates}")
    print(f"  TOPLAM BİRLEŞİK KAMP     : {len(merged)}")
    print(f"{'═' * 55}\n")

    # ── ADIM 4: us_outdoor_master_v2.json olarak kaydet ──────────────────────
    os.makedirs(DATA_DIR, exist_ok=True)
    with open(V2_OUT, "w", encoding="utf-8") as f:
        json.dump(merged, f, indent=2, ensure_ascii=False)

    print(f"💾 Birleşik master dosyası kaydedildi → {V2_OUT}")

    # ── ADIM 5: Eyalet dağılımı özeti ────────────────────────────────────────
    state_counts = {}
    for camp in merged:
        s = camp.get("state", "?")
        state_counts[s] = state_counts.get(s, 0) + 1

    print("\n  Eyalet Dağılımı (v2 — tüm gruplar):")
    for state in sorted(state_counts):
        grp = next((c.get("group","?") for c in merged if c.get("state")==state), "?")
        print(f"    [{grp}] {state}: {state_counts[state]} kamp")

    print(f"\n✅ GRUP 2 TAMAMLANDI!")
    print(f"📁 Master Dosya: data_sources/us_outdoor_master_v2.json")
    print(f"📊 Toplam: {len(merged)} benzersiz kamp alanı (Grup1 + Grup2)")
    print("\n⏳ Grup 3 için komut bekleniyor...")


if __name__ == "__main__":
    run()
