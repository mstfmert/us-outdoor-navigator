"""
run_group3.py — Grup 3 (Guney & Guneydogu) scraping + v2+v3 birlestirme
Eyaletler: FL, GA, AL, MS, TN, KY, NC, SC, VA, WV
Girdi    : data_sources/us_outdoor_master_v2.json  (Grup1+Grup2, 778 kamp)
Cikti    : data_sources/us_outdoor_master_v3.json  (Grup1+Grup2+Grup3)

NASA FIRMS Guvenlik Notu:
  Bounding Box: -125,24,-66,50 → Tum ABD'yi kapsiyor.
  Grup 3 eyaletleri (FL~25N-31N, NC~34N-36N vb.) bu alan icinde.
  Entegrasyon ek ayar gerektirmiyor — otomatik aktif.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from scraper_service import OutdoorScraper

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data_sources")
V2_FILE  = os.path.join(DATA_DIR, "us_outdoor_master_v2.json")
V3_OUT   = os.path.join(DATA_DIR, "us_outdoor_master_v3.json")


def run():
    print("╔══════════════════════════════════════════════════════════╗")
    print("║   US Outdoor Navigator — Grup 3 Scraping Basliyor       ║")
    print("║   FL, GA, AL, MS, TN, KY, NC, SC, VA, WV               ║")
    print("╚══════════════════════════════════════════════════════════╝\n")

    scraper = OutdoorScraper()

    # ── ADIM 1: Grup 3 verisini cek ──────────────────────────────────────────
    group3_data = scraper.fetch_group(group_key="v3", limit_per_state=50)
    print(f"  Grup 3 cekilen veri: {len(group3_data)} kamp alani\n")

    # ── ADIM 2: Grup 1+2 verisini yukle ──────────────────────────────────────
    if not os.path.exists(V2_FILE):
        print("UYARI: us_outdoor_master_v2.json bulunamadi!")
        print("  Lutfen once: python run_group2.py")
        print("  Sadece Grup 3 verisiyle devam ediliyor...\n")
        prev_data = []
    else:
        with open(V2_FILE, "r", encoding="utf-8") as f:
            prev_data = json.load(f)
        print(f"  Onceki master (v2) : {len(prev_data)} kamp alani (Grup1+Grup2)")

    # ── ADIM 3: Birlestir (mukerrer ID kontrolu) ─────────────────────────────
    seen_ids   = {c["id"] for c in prev_data}
    merged     = list(prev_data)

    new_added  = 0
    duplicates = 0
    for camp in group3_data:
        if camp["id"] in seen_ids:
            duplicates += 1
            continue
        seen_ids.add(camp["id"])
        merged.append(camp)
        new_added += 1

    print(f"\n{'=' * 58}")
    print(f"  BIRLESTIRME RAPORU")
    print(f"{'=' * 58}")
    print(f"  Onceki (v2) kamp sayisi   : {len(prev_data)}")
    print(f"  Grup 3 (v3) kamp sayisi   : {len(group3_data)}")
    print(f"  Yeni eklenen (benzersiz)  : {new_added}")
    print(f"  Mukerrer atlanan          : {duplicates}")
    print(f"  TOPLAM BILESIK KAMP       : {len(merged)}")
    print(f"{'=' * 58}\n")

    # ── ADIM 4: us_outdoor_master_v3.json olarak kaydet ──────────────────────
    os.makedirs(DATA_DIR, exist_ok=True)
    with open(V3_OUT, "w", encoding="utf-8") as f:
        json.dump(merged, f, indent=2, ensure_ascii=False)
    print(f"Kaydedildi: {V3_OUT}")

    # ── ADIM 5: Grup bazli ozet ───────────────────────────────────────────────
    group_counts = {}
    for c in merged:
        g = c.get("group", "?")
        group_counts[g] = group_counts.get(g, 0) + 1

    print("\n  Grup Dagilimi (v3 — tum gruplar):")
    for grp in sorted(group_counts):
        print(f"    Grup {grp}: {group_counts[grp]} kamp")

    # ── ADIM 6: Eyalet dagilimi ───────────────────────────────────────────────
    state_counts = {}
    for c in merged:
        s = c.get("state", "?")
        state_counts[s] = state_counts.get(s, 0) + 1

    print("\n  Eyalet Dagilimi (v3 — 30 eyalet):")
    for state in sorted(state_counts):
        grp = c.get("group","?") if (c := next((x for x in merged if x.get("state")==state), None)) else "?"
        print(f"    [{grp}] {state:3s}: {state_counts[state]} kamp")

    # ── ADIM 7: NASA FIRMS kapsama dogrulama ─────────────────────────────────
    print(f"\n{'=' * 58}")
    print("  NASA FIRMS GUVENLIK ENTEGRASYONU DOGRULAMA")
    print(f"{'=' * 58}")
    print("  Bounding Box: -125,24,-66,50 (Tum ABD)")
    print("  Grup 3 Koordinat Aralik:")

    g3_camps = [c for c in merged if c.get("group") == "v3"]
    if g3_camps:
        lats = [c["lat"] for c in g3_camps]
        lons = [c["lon"] for c in g3_camps]
        print(f"    Lat: {min(lats):.2f} ... {max(lats):.2f}  (FIRMS kapsaminda: 24-50)")
        print(f"    Lon: {min(lons):.2f} ... {max(lons):.2f}  (FIRMS kapsaminda: -125 ile -66)")
        lat_ok = 24 <= min(lats) and max(lats) <= 50
        lon_ok = -125 <= min(lons) and max(lons) <= -66
        if lat_ok and lon_ok:
            print("  DURUM: FIRMS ENTEGRASYONU AKTIF - Tum Grup 3 koordinatlari kapsamda!")
        else:
            print("  UYARI: Bazi koordinatlar FIRMS kapsaminin disinda olabilir!")

    print(f"\n  GRUP 3 TAMAMLANDI!")
    print(f"  Master Dosya : data_sources/us_outdoor_master_v3.json")
    print(f"  Toplam       : {len(merged)} benzersiz kamp (Grup1+Grup2+Grup3)")
    print(f"  Eyalet Sayisi: 30")
    print(f"\n  Grup 4 icin komut bekleniyor...")


if __name__ == "__main__":
    run()
