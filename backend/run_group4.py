"""
run_group4.py -- Grup 4 (Kuzeydogu & Goller Bolgesi) scraping + birlestirme
Eyaletler: NY, PA, OH, MI, IN, IL, WI, MN, IA, NJ
Girdi    : data_sources/us_outdoor_master_v3.json  (Grup1+2+3, 1188 kamp)
Cikti    : data_sources/us_outdoor_master_v4.json  (Grup1+2+3+4)

Performans Notu:
  ~1500 kayit icin lineer bounding box taramas Python'da <5ms surmektedir.
  Ek indeksleme gerekmiyor -- basit liste dongusu yeterli.
"""
import json
import os
import sys
import time

sys.path.insert(0, os.path.dirname(__file__))
from scraper_service import OutdoorScraper

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data_sources")
V3_FILE  = os.path.join(DATA_DIR, "us_outdoor_master_v3.json")
V4_OUT   = os.path.join(DATA_DIR, "us_outdoor_master_v4.json")


def benchmark_query(data: list, iterations: int = 1000) -> float:
    """
    Bounding box sorgu performansini olcer.
    ABD ortasi koordinatlari kullanarak simule eder.
    """
    min_lat, max_lat = 35.0, 48.0
    min_lon, max_lon = -100.0, -80.0

    start = time.perf_counter()
    for _ in range(iterations):
        results = [
            c for c in data
            if min_lat <= c["lat"] <= max_lat and min_lon <= c["lon"] <= max_lon
        ]
    elapsed = (time.perf_counter() - start) / iterations * 1000
    return elapsed, len(results)


def run():
    print("╔══════════════════════════════════════════════════════════╗")
    print("║   US Outdoor Navigator -- Grup 4 Scraping Basliyor      ║")
    print("║   NY, PA, OH, MI, IN, IL, WI, MN, IA, NJ               ║")
    print("╚══════════════════════════════════════════════════════════╝\n")

    scraper = OutdoorScraper()

    # -- ADIM 1: Grup 4 verisini cek ------------------------------------------
    group4_data = scraper.fetch_group(group_key="v4", limit_per_state=50)
    print(f"  Grup 4 cekilen veri: {len(group4_data)} kamp alani\n")

    # -- ADIM 2: Grup 1+2+3 verisini yukle ------------------------------------
    if not os.path.exists(V3_FILE):
        print("UYARI: us_outdoor_master_v3.json bulunamadi!")
        print("  Lutfen once: python run_group3.py")
        prev_data = []
    else:
        with open(V3_FILE, "r", encoding="utf-8") as f:
            prev_data = json.load(f)
        print(f"  Onceki master (v3) : {len(prev_data)} kamp (Grup1+2+3)")

    # -- ADIM 3: Birlestir -----------------------------------------------------
    seen_ids   = {c["id"] for c in prev_data}
    merged     = list(prev_data)
    new_added  = 0
    duplicates = 0

    for camp in group4_data:
        if camp["id"] in seen_ids:
            duplicates += 1
            continue
        seen_ids.add(camp["id"])
        merged.append(camp)
        new_added += 1

    print(f"\n{'=' * 58}")
    print(f"  BIRLESTIRME RAPORU")
    print(f"{'=' * 58}")
    print(f"  Onceki (v3) kamp sayisi   : {len(prev_data)}")
    print(f"  Grup 4 (v4) kamp sayisi   : {len(group4_data)}")
    print(f"  Yeni eklenen (benzersiz)  : {new_added}")
    print(f"  Mukerrer atlanan          : {duplicates}")
    print(f"  TOPLAM BILESIK KAMP       : {len(merged)}")
    print(f"{'=' * 58}\n")

    # -- ADIM 4: Kaydet --------------------------------------------------------
    os.makedirs(DATA_DIR, exist_ok=True)
    with open(V4_OUT, "w", encoding="utf-8") as f:
        json.dump(merged, f, indent=2, ensure_ascii=False)
    print(f"Kaydedildi: {V4_OUT}")

    # -- ADIM 5: Grup dagilimi ozeti -------------------------------------------
    group_counts = {}
    for c in merged:
        g = c.get("group", "?")
        group_counts[g] = group_counts.get(g, 0) + 1

    print("\n  Grup Dagilimi (v4 -- tum gruplar):")
    for grp in sorted(group_counts):
        print(f"    Grup {grp}: {group_counts[grp]} kamp")

    # -- ADIM 6: Eyalet dagilimi -----------------------------------------------
    state_counts = {}
    for c in merged:
        s = c.get("state", "?")
        state_counts[s] = state_counts.get(s, 0) + 1

    print("\n  Eyalet Dagilimi (v4 -- 40 eyalet):")
    for state in sorted(state_counts):
        camp = next((x for x in merged if x.get("state") == state), None)
        grp  = camp.get("group","?") if camp else "?"
        print(f"    [{grp}] {state:3s}: {state_counts[state]} kamp")

    # -- ADIM 7: PERFORMANS KONTROLU -------------------------------------------
    print(f"\n{'=' * 58}")
    print("  PERFORMANS KONTROLU -- get_camps_in_view Bounding Box")
    print(f"{'=' * 58}")
    print(f"  Veri seti: {len(merged)} kamp alani")

    avg_ms, hit_count = benchmark_query(merged, iterations=2000)
    print(f"  1000 sorgu ortalamasi  : {avg_ms:.3f} ms/sorgu")
    print(f"  Ornek sorgu sonuclari  : {hit_count} kamp (ABD ortasi bbox)")

    if avg_ms < 5.0:
        perf_status = "MUKEMMEL (< 5ms)"
    elif avg_ms < 15.0:
        perf_status = "IYI (< 15ms)"
    else:
        perf_status = "YAVASH -- optimizasyon gerekebilir"

    print(f"  Performans durumu      : {perf_status}")
    print(f"{'=' * 58}")

    print(f"\n  GRUP 4 TAMAMLANDI!")
    print(f"  Master Dosya : data_sources/us_outdoor_master_v4.json")
    print(f"  Toplam       : {len(merged)} benzersiz kamp (Grup1+2+3+4)")
    print(f"  Eyalet Sayisi: 40")
    print(f"\n  Final Grup 5 icin komut bekleniyor...")


if __name__ == "__main__":
    run()
