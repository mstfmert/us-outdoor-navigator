"""
verify_v2.py — us_outdoor_master_v2.json doğrulama scripti
Grup 1 + Grup 2 birleşik veri kontrolü
"""
import json
import os

DATA_FILE = os.path.join(os.path.dirname(__file__), "..", "data_sources", "us_outdoor_master_v2.json")

def verify():
    if not os.path.exists(DATA_FILE):
        print("HATA: us_outdoor_master_v2.json bulunamadi!")
        return

    with open(DATA_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)

    GROUP_1 = {"CA","AZ","WA","OR","NV","UT","MT","CO","WY","ID"}
    GROUP_2 = {"TX","OK","KS","NE","SD","ND","NM","LA","AR","MO"}

    g1 = [c for c in data if c.get("group") == "v1"]
    g2 = [c for c in data if c.get("group") == "v2"]

    print("=" * 58)
    print("  us_outdoor_master_v2.json  DOGRULAMA RAPORU")
    print("=" * 58)
    print(f"  Toplam kamp       : {len(data)}")
    print(f"  Grup 1 (v1) kamp  : {len(g1)}  (Bati Yakasi & Rockies)")
    print(f"  Grup 2 (v2) kamp  : {len(g2)}  (Orta Amerika)")

    # Koordinat bütünlüğü
    no_coord = [c for c in data if not c.get("lat") or not c.get("lon")]
    print(f"  Koordinatsiz kayit: {len(no_coord)}")
    print()

    # Eyalet bazlı dağılım
    state_counts = {}
    for c in data:
        s = c.get("state","?")
        state_counts[s] = state_counts.get(s, 0) + 1

    print("  Eyalet Dagilimi:")
    for state in sorted(state_counts):
        grp = "v1" if state in GROUP_1 else ("v2" if state in GROUP_2 else "?")
        print(f"    [{grp}] {state:3s}: {state_counts[state]} kamp")

    # Bounding box kontrolü
    lats = [c["lat"] for c in data]
    lons = [c["lon"] for c in data]
    print()
    print(f"  Cografik Alan:")
    print(f"    Lat: {min(lats):.2f} ... {max(lats):.2f}")
    print(f"    Lon: {min(lons):.2f} ... {max(lons):.2f}")

    print()
    print("  Ornek Kayit (son eklenen - Grup 2):")
    g2_camps = [c for c in data if c.get("group") == "v2"]
    if g2_camps:
        print(json.dumps(g2_camps[0], indent=4, ensure_ascii=False))

    print("=" * 58)
    if len(data) >= 700:
        print("  DURUM: BASARILI - 700+ kamp dogrulandi!")
    else:
        print(f"  DURUM: Beklenenden az kayit ({len(data)})")
    print("=" * 58)

if __name__ == "__main__":
    verify()
