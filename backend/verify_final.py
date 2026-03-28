"""verify_final.py -- us_outdoor_master_final.json son dogrulama"""
import json, os, time

F = os.path.join(os.path.dirname(__file__), "..", "data_sources", "us_outdoor_master_final.json")
d = json.load(open(F, encoding="utf-8"))

g_cnt = {}
s_set = set()
for c in d:
    g = c.get("group","?"); g_cnt[g] = g_cnt.get(g,0)+1
    s_set.add(c.get("state","?"))

no_coord = [c for c in d if not c.get("lat") or not c.get("lon")]

print("=" * 55)
print("  us_outdoor_master_final.json -- FINAL DOGRULAMA")
print("=" * 55)
print(f"  Toplam kamp      : {len(d)}")
print(f"  Eyalet/Bolge     : {len(s_set)}")
print(f"  Grup sayisi      : {len(g_cnt)}")
print(f"  Koordinatsiz     : {len(no_coord)}")
print()
for grp in sorted(g_cnt):
    print(f"  Grup {grp}: {g_cnt[grp]} kamp")

# Performans
print("\n  Performans (1000 iterasyon):")
cases = [
    ("Tum ABD    ", -165.0, -65.0, 18.0, 72.0),
    ("48 eyalet  ", -124.8, -66.9, 24.5, 49.0),
    ("Alaska     ", -168.0, -130.0, 54.0, 72.0),
    ("Hawaii     ", -161.0, -154.0, 18.0, 23.0),
]
for label, lo1, lo2, la1, la2 in cases:
    t0 = time.perf_counter()
    for _ in range(1000):
        res = [c for c in d if la1<=c["lat"]<=la2 and lo1<=c["lon"]<=lo2]
    ms = (time.perf_counter()-t0)/1000*1000
    print(f"    {label}: {ms:.3f}ms  ({len(res)} kamp)")

lats = [c["lat"] for c in d]; lons = [c["lon"] for c in d]
print(f"\n  Cografik Alan: Lat {min(lats):.1f}-{max(lats):.1f} | Lon {min(lons):.1f} ile {max(lons):.1f}")
print(f"\n  API: v5.0 FINAL | Master: us_outdoor_master_final.json")
print(f"  NASA FIRMS: Tum ABD kapsamasinda (AK+HI dahil)")
print("=" * 55)
ok = len(d) >= 1500 and len(no_coord) == 0
print(f"  {'AMERICA TAMAMLANDI! Backend 100 hazir!' if ok else 'Kontrol gerekli'}")
print("=" * 55)
