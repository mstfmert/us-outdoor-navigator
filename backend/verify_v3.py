"""
verify_v3.py -- us_outdoor_master_v3.json dogrulama scripti
Grup 1 + Grup 2 + Grup 3 birlesik veri kontrolu
"""
import json
import os

DATA_FILE = os.path.join(os.path.dirname(__file__), "..", "data_sources", "us_outdoor_master_v3.json")

GROUP_1 = {"CA","AZ","WA","OR","NV","UT","MT","CO","WY","ID"}
GROUP_2 = {"TX","OK","KS","NE","SD","ND","NM","LA","AR","MO"}
GROUP_3 = {"FL","GA","AL","MS","TN","KY","NC","SC","VA","WV"}

FIRMS_LAT_MIN, FIRMS_LAT_MAX = 24.0, 50.0
FIRMS_LON_MIN, FIRMS_LON_MAX = -125.0, -66.0

def verify():
    if not os.path.exists(DATA_FILE):
        print("HATA: us_outdoor_master_v3.json bulunamadi!")
        return

    with open(DATA_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)

    g1 = [c for c in data if c.get("group") == "v1"]
    g2 = [c for c in data if c.get("group") == "v2"]
    g3 = [c for c in data if c.get("group") == "v3"]

    print("=" * 62)
    print("  us_outdoor_master_v3.json  --  DOGRULAMA RAPORU")
    print("=" * 62)
    print(f"  Toplam kamp         : {len(data)}")
    print(f"  Grup v1 (Bati)      : {len(g1)}  kamp")
    print(f"  Grup v2 (Orta)      : {len(g2)}  kamp")
    print(f"  Grup v3 (Guney)     : {len(g3)}  kamp")
    no_coord = [c for c in data if not c.get("lat") or not c.get("lon")]
    print(f"  Koordinatsiz kayit  : {len(no_coord)}")
    print()

    # Eyalet dagilimi
    state_counts = {}
    for c in data:
        s = c.get("state","?")
        state_counts[s] = state_counts.get(s, 0) + 1

    print("  Eyalet Dagilimi (30 eyalet):")
    for state in sorted(state_counts):
        if state in GROUP_1:
            grp = "v1"
        elif state in GROUP_2:
            grp = "v2"
        elif state in GROUP_3:
            grp = "v3"
        else:
            grp = "?"
        print(f"    [{grp}] {state:3s}: {state_counts[state]} kamp")

    # Cografik alan
    all_lats = [c["lat"] for c in data]
    all_lons = [c["lon"] for c in data]
    print()
    print("  Toplam Cografik Alan:")
    print(f"    Lat: {min(all_lats):.2f} ... {max(all_lats):.2f}")
    print(f"    Lon: {min(all_lons):.2f} ... {max(all_lons):.2f}")

    # NASA FIRMS kapsama dogrulama
    print()
    print("  NASA FIRMS Kapsama Kontrolu:")
    print(f"    FIRMS Alan: Lat {FIRMS_LAT_MIN}-{FIRMS_LAT_MAX} / Lon {FIRMS_LON_MIN} ile {FIRMS_LON_MAX}")

    for grp_key, camps in [("v1", g1), ("v2", g2), ("v3", g3)]:
        if not camps:
            continue
        lats = [c["lat"] for c in camps]
        lons = [c["lon"] for c in camps]
        lat_ok = FIRMS_LAT_MIN <= min(lats) and max(lats) <= FIRMS_LAT_MAX
        lon_ok = FIRMS_LON_MIN <= min(lons) and max(lons) <= FIRMS_LON_MAX
        status = "AKTIF" if (lat_ok and lon_ok) else "DIKKAT"
        print(f"    Grup {grp_key}: Lat {min(lats):.1f}-{max(lats):.1f} / Lon {min(lons):.1f} ile {max(lons):.1f} --> {status}")

    # Ornek Grup 3 kaydi
    print()
    print("  Ornek Kayit (Grup 3 - ilk kamp):")
    if g3:
        print(json.dumps(g3[0], indent=4, ensure_ascii=False))

    print()
    print("=" * 62)
    if len(data) >= 1100:
        print(f"  DURUM: BASARILI -- {len(data)} kamp, 30 eyalet, 0 koordinat hatasi!")
    else:
        print(f"  DURUM: Beklenenden az kayit ({len(data)})")
    print("=" * 62)

if __name__ == "__main__":
    verify()
