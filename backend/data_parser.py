import json
import os

def parse_raw_camps(input_file, output_file):
    """
    Karmaşık NASA/RIDB verilerini ayıklayıp uygulama formatına sokar.
    """
    if not os.path.exists(input_file):
        print(f"Hata: {input_file} bulunamadı!")
        return

    with open(input_file, 'r', encoding='utf-8') as f:
        raw_data = json.load(f)

    clean_campgrounds = []

    for item in raw_data:
        # Karavancı için hayati olan 4 temel bilgiyi süzüyoruz
        clean_item = {
            "id": item.get("FacilityID"),
            "name": item.get("FacilityName"),
            "lat": item.get("FacilityLatitude"),
            "lon": item.get("FacilityLongitude"),
            "price_per_night": 25.0, # Varsayılan, ileride detaydan çekilecek
            "max_rv_length": 35.0,    # Varsayılan
            "amenities": ["Check Official Site"],
            "has_water": True
        }
        
        # Koordinatı olmayan hatalı verileri eliyoruz (Güvenlik için şart!)
        if clean_item["lat"] and clean_item["lon"]:
            clean_campgrounds.append(clean_item)

    # Temizlenmiş veriyi kaydediyoruz
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(clean_campgrounds, f, indent=4, ensure_ascii=False)

    print(f"✅ Ayıklama Tamamlandı! {len(clean_campgrounds)} temiz veri '{output_file}' konumuna yazıldı.")

if __name__ == "__main__":
    parse_raw_camps('data_sources/ca_camps_raw.json', 'data_sources/ca_camps_clean.json')