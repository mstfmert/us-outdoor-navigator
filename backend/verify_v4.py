"""
verify_v4.py -- us_outdoor_master_v4.json dogrulama + performans testi
Grup 1+2+3+4 (40 eyalet) birlesik veri kontrolu
"""
import json, os, time

DATA_FILE = os.path.join(os.path.dirname(__file__), "..", "data_sources", "us_outdoor_master_v4.json")

G1 = {"CA","AZ","WA","OR","NV","UT","MT","CO","WY","ID"}
G2 = {"TX","OK","KS","NE","SD","ND","NM","LA","AR","MO"}
G3 = {"FL","GA","AL","MS","TN","KY","NC","SC","VA","WV"}
G4 = {"NY","PA","OH","MI","IN","IL","WI","MN","IA","NJ"}

def verify():
    if not os.path.exists(DATA_FILE):
        print("HATA: us_outdoor_master_v4.json bulunamadi!")
        return

    with open(DATA_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)

    g1 = [c for c in data if c.get("group") == "v1"]
    g2 = [c for c in data if c.get("group") == "v2"]
    g3 = [c for c in data if c.get("group") == "v3"]
    g4 = [c for c in data if c.get("group") == "v4"]

    print("=" * 62)
    print("  us_outdoor_master_v4.json  --  DOGRULAMA RAPORU")
    print("=" * 62)
    print(f"  Toplam kamp         : {len(data)}")
    print(f"  Grup v1 (Bati)      : {len(g1)}")
    print(f"  Grup v2 (Orta)      : {len(g2)}")
    print(f"  Grup v3 (Guney)     : {len(g3)}")
    print(f"  Grup v4 (Kuzeydogu) : {len(g4)}")
    no_coord = [c for c in data if not c.get("lat") or not c.get("lon")]
    print(f"  Koordinatsiz kayit  : {len(no_coord)}")

    # Eyalet dagilimi
    state_counts = {}
    for c in data:
        s = c.get("state","?")
        state_counts[s] = state_counts.get(s, 0) + 1

    print(f"\n  Eyalet Dagilimi (40 eyalet):")
    for state in sorted(state_counts):
        grp = "v1" if state in G1 else ("v2" if state in G2 else ("v3" if state in G3 else ("v4" if state in G4 else "?")))
        print(f"    [{grp}] {state:3s}: {state_counts[state]} kamp")

    # Cografik alan
    lats = [c["lat"] for c in data]
    lons = [c["lon"] for c in data]
    print(f"\n  Toplam Cografik Alan:")
    print(f"    Lat: {min(lats):.2f} ... {max(lats):.2f}")
    print(f"    Lon: {min(lons):.2f} ... {max(lons):.2f}")

    # Performans testi
    print(f"\n  PERFORMANS TESTI -- Bounding Box Sorgusu")
    test_cases = [
        ("Tum ABD", -124.8, -73.5, 24.5, 49.0),
        ("Bati Yakasi", -124.5, -102.0, 31.0, 49.0),
        ("Orta ABD", -105.0, -87.0, 30.0, 48.0),
        ("Kuzeydogu", -97.5, -73.5, 36.0, 48.5),
    ]
    for label, lon1, lon2, lat1, lat2 in test_cases:
        start = time.perf_counter()
        for _ in range(1000):
            res = [c for c in data if lat1 <= c["lat"] <= lat2 and lon1 <= c["lon"] <= lon2]
        ms = (time.perf_counter() - start) / 1000 * 1000
        print(f"    {label:20s}: {ms:.3f}ms  ({len(res)} kamp bulundu)")

    print(f"\n  Grup 4 ornek kayit:")
    if g4:
        print(json.dumps(g4[0], indent=4, ensure_ascii=False))

    print(f"\n{'=' * 62}")
    ok = len(data) >= 1400 and len(no_coord) == 0
    if ok:
        print(f"  DURUM: BASARILI -- {len(data)} kamp, 40 eyalet, 0 hata!")
    else:
        print(f"  DURUM: Kontrol gerekli ({len(data)} kamp, {len(no_coord)} koordinatsiz)")
    print("=" * 62)

if __name__ == "__main__":
    verify()
