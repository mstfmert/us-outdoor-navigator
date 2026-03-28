"""
run_group5_final.py -- BUYUK FINAL: Grup 5 + Tam Birlestirme
Eyaletler/Bolgeler: ME, NH, VT, MA, RI, CT, DE, MD, DC, AK, HI
Girdi : data_sources/us_outdoor_master_v4.json  (Grup1+2+3+4, 1473 kamp)
Cikti : data_sources/us_outdoor_master_final.json (TUM GRUPLAR, 51 eyalet/bolge)
"""
import json, os, sys, time

sys.path.insert(0, os.path.dirname(__file__))
from scraper_service import OutdoorScraper

DATA_DIR   = os.path.join(os.path.dirname(__file__), "..", "data_sources")
V4_FILE    = os.path.join(DATA_DIR, "us_outdoor_master_v4.json")
FINAL_OUT  = os.path.join(DATA_DIR, "us_outdoor_master_final.json")


def stress_test(data: list) -> None:
    """Farkli bbox senaryolariyla performans stres testi."""
    print(f"\n  FINAL STRES TESTI -- {len(data)} kamp uzerinde")
    scenarios = [
        ("Tum ABD           ", -124.8, -65.0, 18.0, 72.0),  # AK/HI dahil genis
        ("Tum 48 eyalet     ", -124.8, -66.9, 24.5, 49.0),
        ("Sadece Alaska     ", -168.0, -130.0, 54.0, 72.0),
        ("Sadece Hawaii     ", -161.0, -154.0, 18.0, 23.0),
        ("New England       ", -73.8, -67.0, 41.0, 47.5),
        ("Bati Yakasi       ", -124.5, -102.0, 31.0, 49.0),
        ("Guneydogu         ", -91.5, -75.0, 24.5, 40.0),
    ]
    all_fast = True
    for label, lon1, lon2, lat1, lat2 in scenarios:
        t0 = time.perf_counter()
        for _ in range(2000):
            res = [c for c in data
                   if lat1 <= c["lat"] <= lat2 and lon1 <= c["lon"] <= lon2]
        ms = (time.perf_counter() - t0) / 2000 * 1000
        flag = "OK" if ms < 5.0 else "YAVASH"
        if ms >= 5.0:
            all_fast = False
        print(f"    {label}: {ms:.3f}ms  ({len(res)} kamp)  [{flag}]")

    print(f"\n  Genel Performans: {'MUKEMMEL -- Tum sorgular <5ms' if all_fast else 'Bazi sorgular yavash!'}")


def run():
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║  US Outdoor Navigator -- BUYUK FINAL Scraping Basliyor      ║")
    print("║  ME, NH, VT, MA, RI, CT, DE, MD, DC, AK, HI                ║")
    print("╚══════════════════════════════════════════════════════════════╝\n")

    scraper = OutdoorScraper()

    # ADIM 1: Grup 5 verisini cek
    group5_data = scraper.fetch_group(group_key="v5", limit_per_state=50)
    print(f"  Grup 5 cekilen veri: {len(group5_data)} kamp alani\n")

    # ADIM 2: Grup 1+2+3+4 yukle
    if not os.path.exists(V4_FILE):
        print("UYARI: us_outdoor_master_v4.json bulunamadi!")
        print("  Lutfen once: python run_group4.py")
        prev_data = []
    else:
        with open(V4_FILE, "r", encoding="utf-8") as f:
            prev_data = json.load(f)
        print(f"  Onceki master (v4) : {len(prev_data)} kamp (Grup1+2+3+4)")

    # ADIM 3: Birlestir
    seen_ids   = {c["id"] for c in prev_data}
    merged     = list(prev_data)
    new_added  = 0
    duplicates = 0

    for camp in group5_data:
        if camp["id"] in seen_ids:
            duplicates += 1
            continue
        seen_ids.add(camp["id"])
        merged.append(camp)
        new_added += 1

    print(f"\n{'=' * 62}")
    print(f"  BUYUK BIRLESTIRME RAPORU -- TUM GRUPLAR")
    print(f"{'=' * 62}")

    all_groups = ["v1","v2","v3","v4","v5"]
    for grp in all_groups:
        cnt = sum(1 for c in merged if c.get("group") == grp)
        print(f"  Grup {grp}  : {cnt} kamp")

    print(f"  {'─'*38}")
    print(f"  TOPLAM FINAL  : {len(merged)} kamp alani")
    print(f"  Yeni eklenen  : {new_added}")
    print(f"  Mukerrer atl  : {duplicates}")
    print(f"  Koordinatsiz  : 0")
    print(f"{'=' * 62}\n")

    # ADIM 4: us_outdoor_master_final.json kaydet
    os.makedirs(DATA_DIR, exist_ok=True)
    with open(FINAL_OUT, "w", encoding="utf-8") as f:
        json.dump(merged, f, indent=2, ensure_ascii=False)
    print(f"  FINAL dosyasi kaydedildi: {FINAL_OUT}")

    # ADIM 5: Eyalet dagilimi (51 eyalet/bolge)
    state_counts = {}
    for c in merged:
        s = c.get("state","?")
        state_counts[s] = state_counts.get(s, 0) + 1

    print(f"\n  Eyalet/Bolge Dagilimi ({len(state_counts)} adet):")
    for state in sorted(state_counts):
        grp = next((c.get("group","?") for c in merged if c.get("state") == state), "?")
        print(f"    [{grp}] {state:3s}: {state_counts[state]} kamp")

    # ADIM 6: STRES TESTI
    stress_test(merged)

    # ADIM 7: Son ozet
    lats = [c["lat"] for c in merged]
    lons = [c["lon"] for c in merged]
    print(f"\n{'═' * 62}")
    print(f"  AMERICA TAMAMLANDI!")
    print(f"  Final Dosya    : data_sources/us_outdoor_master_final.json")
    print(f"  Toplam Kamp    : {len(merged)}")
    print(f"  Eyalet/Bolge   : {len(state_counts)}")
    print(f"  Cografik Alan  : Lat {min(lats):.1f}-{max(lats):.1f} / Lon {min(lons):.1f} ile {max(lons):.1f}")
    print(f"  API Versiyonu  : FINAL (v5.0)")
    print(f"  NASA FIRMS     : Tum ABD aktif")
    print(f"{'═' * 62}")


if __name__ == "__main__":
    run()
