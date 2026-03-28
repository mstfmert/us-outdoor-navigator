"""
verify_v1.py — us_outdoor_master_v1.json doğrulama scripti
Grup 1 (Batı Yakası & Rockies) veri kontrolü
"""
import json
import os

DATA_FILE = os.path.join(os.path.dirname(__file__), "..", "data_sources", "us_outdoor_master_v1.json")

def verify():
    if not os.path.exists(DATA_FILE):
        print("❌ HATA: us_outdoor_master_v1.json bulunamadı!")
        return

    with open(DATA_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)

    print("=" * 55)
    print("  us_outdoor_master_v1.json — DOĞRULAMA RAPORU")
    print("=" * 55)
    print(f"  Toplam kamp alanı : {len(data)}")
    print()

    # Eyalet bazlı dağılım
    state_counts = {}
    for camp in data:
        s = camp.get("state", "?")
        state_counts[s] = state_counts.get(s, 0) + 1

    print("  Eyalet Dağılımı:")
    for state in sorted(state_counts):
        print(f"    {state}: {state_counts[state]} kamp")

    print()
    # Koordinat kontrolü
    missing_coords = [c for c in data if not c.get("lat") or not c.get("lon")]
    print(f"  Koordinatsız kayıt : {len(missing_coords)}")
    print(f"  Koordinatlı kayıt  : {len(data) - len(missing_coords)}")

    # Örnek kayıt
    print()
    print("  Örnek Kayıt (ilk kamp):")
    print(json.dumps(data[0], indent=4, ensure_ascii=False))
    print("=" * 55)
    print("  ✅ Doğrulama Tamamlandı!")
    print("=" * 55)

if __name__ == "__main__":
    verify()
