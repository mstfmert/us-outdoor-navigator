#!/usr/bin/env python3
"""
generate_app_icon.py — US Outdoor Navigator App Icon Generator
Koyu Lacivert (#0D1526) + Fosforlu Yeşil (#00FF88) tema
1024x1024 ana ikon + 432x432 Android adaptive foreground oluşturur.

Gereksinim: pip install Pillow
Çalıştır:   python tools/generate_app_icon.py
"""

import math
import os
import sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("❌ Pillow bulunamadı. Kur: pip install Pillow")
    sys.exit(1)

# ── Renkler ─────────────────────────────────────────────────────────────────
BG_DARK   = (13, 21, 38)        # #0D1526 — Koyu Lacivert
NEON_GRN  = (0, 255, 136)       # #00FF88 — Fosforlu Yeşil
WHITE     = (255, 255, 255)
DARK_BG2  = (10, 14, 23)        # #0A0E17 — Daha koyu lacivert
STAR_CLR  = (180, 220, 255)     # Yıldız rengi (açık mavi-beyaz)

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "frontend", "assets", "icons")
os.makedirs(OUTPUT_DIR, exist_ok=True)


def draw_tent_icon(draw: ImageDraw.ImageDraw, cx: int, cy: int,
                   size: int, color: tuple, outline: tuple = None):
    """Kamp çadırı ikonu çiz (üçgen + kapı)"""
    half  = size // 2
    # Ana çadır üçgeni
    pts = [(cx, cy - half), (cx - half, cy + half // 2), (cx + half, cy + half // 2)]
    draw.polygon(pts, fill=color)
    if outline:
        draw.polygon(pts, outline=outline, width=max(2, size // 30))
    # Kapı (küçük yarı daire / dikdörtgen)
    door_w = size // 6
    door_h = size // 5
    door_x = cx - door_w // 2
    door_y = cy + half // 2 - door_h
    draw.rounded_rectangle(
        [door_x, door_y, door_x + door_w, door_y + door_h],
        radius=door_w // 3,
        fill=DARK_BG2
    )


def draw_mountain_silhouette(draw: ImageDraw.ImageDraw, width: int, height: int):
    """Alt kısımda dağ silüeti çiz"""
    base_y = int(height * 0.72)
    # Sol dağ
    m1 = [(int(width * 0.0), height),
          (int(width * 0.0), int(height * 0.58)),
          (int(width * 0.28), int(height * 0.38)),
          (int(width * 0.48), int(height * 0.58)),
          (int(width * 0.48), height)]
    # Sağ dağ
    m2 = [(int(width * 0.40), height),
          (int(width * 0.40), int(height * 0.52)),
          (int(width * 0.65), int(height * 0.28)),
          (int(width * 0.88), int(height * 0.52)),
          (int(width * 1.0), int(height * 0.48)),
          (int(width * 1.0), height)]
    # Dağ rengi — lacivertten biraz açık
    mtn_color = (20, 35, 65)
    draw.polygon(m1, fill=mtn_color)
    draw.polygon(m2, fill=mtn_color)


def draw_stars(draw: ImageDraw.ImageDraw, width: int, height: int,
               count: int = 12, max_r: int = 3):
    """Gece gökyüzü yıldızları"""
    import random
    random.seed(42)  # Sabit seed — tutarlı yıldız konumları
    sky_h = int(height * 0.55)
    for _ in range(count):
        x = random.randint(int(width * 0.05), int(width * 0.95))
        y = random.randint(int(height * 0.05), sky_h)
        r = random.randint(1, max_r)
        alpha = random.randint(150, 255)
        color = (STAR_CLR[0], STAR_CLR[1], STAR_CLR[2], alpha)
        draw.ellipse([x - r, y - r, x + r, y + r], fill=color[:3])


def draw_neon_glow(draw: ImageDraw.ImageDraw, cx: int, cy: int,
                   size: int, color: tuple, layers: int = 4):
    """Neon glow efekti — dışa doğru artan yarıçap, azalan opaklık"""
    for i in range(layers, 0, -1):
        r = size + i * (size // 4)
        alpha = int(80 * (1 - i / (layers + 1)))
        glow = (*color, alpha)
        draw.ellipse(
            [cx - r, cy - r, cx + r, cy + r],
            fill=glow[:3] if alpha > 30 else None,
            outline=(*color[:3],),
            width=1
        )


def draw_compass_rose(draw: ImageDraw.ImageDraw, cx: int, cy: int,
                      r: int, color: tuple):
    """Küçük pusula rozeti"""
    for angle in range(0, 360, 45):
        rad = math.radians(angle)
        tip_len = r if angle % 90 == 0 else r * 0.6
        tip_x = cx + tip_len * math.sin(rad)
        tip_y = cy - tip_len * math.cos(rad)
        draw.line([(cx, cy), (tip_x, tip_y)], fill=color, width=max(1, r // 8))
    # Merkez nokta
    draw.ellipse([cx - r // 5, cy - r // 5, cx + r // 5, cy + r // 5], fill=color)


def create_app_icon(size: int = 1024) -> Image.Image:
    """Ana uygulama ikonu oluştur"""
    img  = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # ── Arka Plan (Yuvarlak köşeli kare) ──────────────────────────────
    radius = size // 5
    draw.rounded_rectangle([0, 0, size, size], radius=radius, fill=BG_DARK)

    # ── Gradient efekti (üst yarı daha açık) ──────────────────────────
    for y in range(size // 2):
        alpha = int(15 * (1 - y / (size // 2)))
        draw.rectangle([0, y, size, y + 1], fill=(30, 60, 100, alpha)[:3])

    # ── Yıldızlar ─────────────────────────────────────────────────────
    draw_stars(draw, size, size, count=18, max_r=size // 200)

    # ── Dağ Silüeti ───────────────────────────────────────────────────
    draw_mountain_silhouette(draw, size, size)

    # ── Neon Çadır ────────────────────────────────────────────────────
    tent_size  = size // 3
    tent_cx    = size // 2
    tent_cy    = int(size * 0.56)
    # Glow efekti
    for i in range(5, 0, -1):
        glow_alpha = int(40 * (1 - i / 6))
        glow_color = (*NEON_GRN, glow_alpha)
        draw_tent_icon(draw, tent_cx, tent_cy, tent_size + i * (size // 40),
                       glow_color[:3])
    # Ana çadır
    draw_tent_icon(draw, tent_cx, tent_cy, tent_size, NEON_GRN,
                   outline=WHITE)

    # ── Alt Neon Çizgisi ──────────────────────────────────────────────
    line_y  = int(size * 0.72)
    line_x1 = int(size * 0.12)
    line_x2 = int(size * 0.88)
    draw.line([(line_x1, line_y), (line_x2, line_y)],
              fill=NEON_GRN, width=max(2, size // 80))

    # ── Pusula Rozeti (sağ üst) ───────────────────────────────────────
    comp_r  = size // 14
    comp_cx = int(size * 0.82)
    comp_cy = int(size * 0.18)
    draw_compass_rose(draw, comp_cx, comp_cy, comp_r, NEON_GRN)

    # ── "US" Yazısı (sol üst, küçük) ─────────────────────────────────
    font_size = size // 12
    try:
        font = ImageFont.truetype("arial.ttf", font_size)
    except Exception:
        font = ImageFont.load_default()
    draw.text(
        (int(size * 0.10), int(size * 0.10)),
        "US",
        fill=NEON_GRN,
        font=font,
    )

    return img


def create_adaptive_foreground(size: int = 432) -> Image.Image:
    """
    Android Adaptive Icon ön katmanı.
    Şeffaf arka plan üzerinde sadece çadır + pusula.
    Safe zone: merkez 72dp = %66 alanında kalın.
    """
    img  = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Safe zone: %33'er kenar boşluğu
    safe = size // 4
    inner = size - 2 * safe

    # Çadır
    tent_size = int(inner * 0.85)
    tent_cx   = size // 2
    tent_cy   = size // 2
    # Glow
    for i in range(4, 0, -1):
        draw_tent_icon(draw, tent_cx, tent_cy, tent_size + i * (size // 30),
                       (*NEON_GRN, int(30 * (1 - i / 5))))
    draw_tent_icon(draw, tent_cx, tent_cy, tent_size, NEON_GRN, outline=WHITE)

    # Alt çizgi
    lw   = max(2, size // 60)
    ly   = int(size * 0.72)
    draw.line([(safe, ly), (size - safe, ly)], fill=NEON_GRN, width=lw)

    return img


def create_splash_logo(width: int = 512, height: int = 512) -> Image.Image:
    """Splash screen için şeffaf arka planlı logo"""
    img  = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    tent_size = int(min(width, height) * 0.45)
    cx, cy = width // 2, height // 2

    # Glow
    for i in range(6, 0, -1):
        draw_tent_icon(draw, cx, cy, tent_size + i * (width // 35),
                       (*NEON_GRN, int(25 * (1 - i / 7))))
    draw_tent_icon(draw, cx, cy, tent_size, NEON_GRN, outline=WHITE)

    # Alt çizgi
    lw = max(2, width // 50)
    ly = int(height * 0.73)
    draw.line([(int(width * 0.2), ly), (int(width * 0.8), ly)],
              fill=NEON_GRN, width=lw)

    return img


def main():
    print("🎨 US Outdoor Navigator — App Icon Generator")
    print("━" * 50)

    # ── 1024x1024 Ana İkon ────────────────────────────────────────────
    icon = create_app_icon(1024)
    icon_path = os.path.join(OUTPUT_DIR, "app_icon.png")
    icon.save(icon_path, "PNG")
    print(f"✅ Ana ikon     → {icon_path}")

    # ── 432x432 Android Adaptive Foreground ──────────────────────────
    fg = create_adaptive_foreground(432)
    fg_path = os.path.join(OUTPUT_DIR, "app_icon_foreground.png")
    fg.save(fg_path, "PNG")
    print(f"✅ Adaptive FG  → {fg_path}")

    # ── 512x512 Splash Logo ───────────────────────────────────────────
    splash = create_splash_logo(512, 512)
    splash_dir = os.path.join(os.path.dirname(__file__), "..", "frontend", "assets", "images")
    os.makedirs(splash_dir, exist_ok=True)
    splash_path = os.path.join(splash_dir, "splash_logo.png")
    splash.save(splash_path, "PNG")
    print(f"✅ Splash logo  → {splash_path}")

    print()
    print("━" * 50)
    print("🚀 Sonraki adımlar:")
    print("   cd frontend")
    print("   dart run flutter_launcher_icons")
    print("   dart run flutter_native_splash:create")
    print()
    print("📱 Play Store için:")
    print("   Hi-res icon: app_icon.png (1024x1024)")
    print("   Feature graphic: 1024x500 ayrıca gerekli")


if __name__ == "__main__":
    main()
