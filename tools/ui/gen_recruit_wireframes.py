"""Wireframe banner Chiêu mộ để owner vẽ ảnh banner trong Photoshop (owner 2026-11-15).

Chạy: python -X utf8 tools/ui/gen_recruit_wireframes.py
Ghi vào docs/design/wireframes/recruit/:
  {banner}_overlay_1590x1080.png  — nền trong suốt, đúng kích thước ảnh banner: đặt làm layer trên cùng trong PTS.
  {banner}_screen_1920x1080.png   — cả màn Chiêu mộ (danh sách trái, thanh trên) để xem tổng thể.
Số đo đọc từ data/ui/recruit_screen_layout.json (khung thiết kế 1920×1080), nên chạy lại sau khi sửa bố cục.
Font chữ trên wireframe chỉ để chú thích (Segoe UI / Arial của Windows), không vào game.
"""
import json
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
L = json.load(open(os.path.join(ROOT, "data/ui/recruit_screen_layout.json"), encoding="utf-8"))
OUT = os.path.join(ROOT, "docs/design/wireframes/recruit")
PANEL_X = L["panel"]["rect"][0]                     # 330: ảnh banner bắt đầu ở x này
BW, BH = 1590, 1080

COL = {  # loại vùng → màu (RGB)
    "text": (64, 170, 255), "button": (255, 200, 40), "wish": (255, 140, 0), "art": (60, 210, 120),
    "top": (200, 90, 255), "list": (150, 150, 160),
}


def font(size):
    for f in ("C:/Windows/Fonts/segoeuib.ttf", "C:/Windows/Fonts/segoeui.ttf", "C:/Windows/Fonts/arial.ttf"):
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


def r(path, d=None):
    node = L
    for k in path.split("."):
        node = node[k]
    return list(node["rect"] if isinstance(node, dict) else node)


def zones(kind):
    """Vùng của một loại banner trên khung 1920×1080: (nhãn, [x, y, w, h], loại màu)."""
    z = [
        ("Trở về", r("top.back_button"), "top"), ("Chiêu mộ (tên màn)", r("top.title"), "top"),
        ("Vàng", r("top.gold_pill"), "top"), ("Ngọc", r("top.gems_pill"), "top"), ("+", r("top.gems_plus"), "top"),
    ]
    o, it, step = L["list"]["origin"], L["list"]["item"], L["list"]["step"]
    for i, name in enumerate(("Banner nhân vật", "Banner trang bị 5 sao", "Banner trang bị thường")):
        z.append((name, [o[0], o[1] + i * step, it[0], it[1]], "list"))
    side = ["Chơi thử", "Cửa hàng", "Chi tiết", "Lịch sử"] if kind == "char" else ["Chi tiết", "Lịch sử"]
    so, si, ss = L["bottom"]["side"]["origin"], L["bottom"]["side"]["item"], L["bottom"]["side"]["step"]
    y0 = so[1] + (4 - len(side)) * ss
    for i, name in enumerate(side):
        z.append((name, [so[0], y0 + i * ss, si[0], si[1]], "button"))
    z += [("Chiêu mộ ×1", r("bottom.wish_1"), "wish"), ("Chiêu mộ ×10", r("bottom.wish_10"), "wish")]
    if kind in ("char", "star5"):
        z += [("Còn N lượt chắc chắn có … (pity)", r("panel.pity_box"), "text"),
              ("Mỗi 10 lượt chắc chắn … (bảo đảm)", r("bottom.guarantee_note"), "text")]
    if kind in ("equip", "star5"):
        z += [("Nhãn loại banner", r("panel.kind_tag"), "text"), ("Tiêu đề banner (≤ 2 dòng)", r("panel.title"), "text")]
    if kind == "star5":
        ic = L["panel"]["icons"]
        for i in range(4):
            z.append(("Icon %d" % (i + 1), [ic["origin"][0] + i * ic["step"], ic["origin"][1], ic["size"], ic["size"]], "button"))
        z += [("Thời gian còn lại", r("panel.time"), "text"), ("Túi quà", r("panel.gift_card"), "button"),
              ("Chú thích vũ khí đề cử", r("panel.callout_1"), "text"),
              ("Chú thích bộ vết thánh", r("panel.callout_2"), "text")]
    if kind == "equip":
        sc = L["panel"]["showcase"]
        for i in range(len(sc["slots"])):
            z.append(("Ảnh vũ khí %d (màn vẽ)" % (i + 1), sc["slots"][i], "art"))
            z.append(("Tên vũ khí %d" % (i + 1), sc["bars"][i], "text"))
    return z


def draw_zone(d, rect, label, kind, dx, fnt):
    x, y, w, h = rect
    x += dx
    c = COL[kind]
    d.rectangle([x, y, x + w, y + h], fill=c + (70,), outline=c + (255,), width=3)
    # Ô thấp: một dòng; ô hẹp: bỏ tọa độ (chỉ giữ cỡ).
    pos = "%d×%d @ %d,%d" % (w, h, x, y) if w >= 200 else "%d×%d" % (w, h)
    txt = ("%s  ·  %s" if h < 70 else "%s\n%s") % (label, pos)
    d.multiline_text((x + 6, y + 4), txt, fill=(255, 255, 255, 255), font=fnt, stroke_width=3,
                     stroke_fill=(0, 0, 0, 255), spacing=2)


def grid(d, w, h, step, dx=0):
    for gx in range(0, w + 1, step):
        d.line([gx + dx, 0, gx + dx, h], fill=(255, 255, 255, 40 if gx % (step * 5) else 90), width=1)
    for gy in range(0, h + 1, step):
        d.line([dx, gy, dx + w, gy], fill=(255, 255, 255, 40 if gy % (step * 5) else 90), width=1)


def guides(d, dx, fnt):
    # Hai dải làm tối nhẹ của màn (30% trái, 32% phải của vùng banner) và trục giữa ảnh.
    for x0, x1, name in ((0, int(BW * 0.3), "vùng làm tối nhẹ 30%"), (int(BW * 0.68), BW, "vùng làm tối nhẹ 32%")):
        d.rectangle([x0 + dx, 0, x1 + dx, BH], outline=(255, 80, 80, 200), width=2)
        d.text((x0 + dx + 8, BH - 40), name, fill=(255, 120, 120, 255), font=fnt, stroke_width=2, stroke_fill=(0, 0, 0, 255))
    d.line([dx + BW // 2, 0, dx + BW // 2, BH], fill=(255, 80, 80, 160), width=2)


def build(bid, kind, title):
    os.makedirs(OUT, exist_ok=True)
    f_small, f_title = font(18), font(30)
    # 1) Overlay trong suốt 1590×1080, tọa độ trên ảnh banner.
    ov = Image.new("RGBA", (BW, BH), (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    grid(d, BW, BH, 50)
    guides(d, 0, f_small)
    for label, rect, k in zones(kind):
        x, y, w, h = rect
        if x + w <= PANEL_X:          # nằm hẳn ngoài ảnh (danh sách trái, nút Trở về)
            continue
        draw_zone(d, rect, label, k, -PANEL_X, f_small)
    # Chú thích nhỏ ở khe trống đáy ảnh (giữa nút tròn trái và nút Chiêu mộ).
    d.multiline_text((420, 1005), "%s\n%d×%d · lưới 50 px" % (title, BW, BH),
                     fill=(255, 255, 255, 255), font=font(20), stroke_width=3, stroke_fill=(0, 0, 0, 255))
    ov.save(os.path.join(OUT, "%s_overlay_%dx%d.png" % (bid, BW, BH)))
    # 2) Cả màn 1920×1080 (tọa độ màn).
    sc = Image.new("RGBA", (1920, 1080), (27, 30, 43, 255))
    ImageDraw.Draw(sc).rectangle([PANEL_X, 0, 1920, 1080], fill=(58, 63, 85, 255))
    layer = Image.new("RGBA", (1920, 1080), (0, 0, 0, 0))   # vẽ lên lớp riêng rồi ghép để ô màu trong mờ
    d = ImageDraw.Draw(layer)
    # Chú thích ở cột trái dưới danh sách banner (vùng trống).
    d.multiline_text((16, 480), "%s\n\nẢnh banner %d×%d\nbắt đầu ở x = %d\n\nTọa độ theo màn\n1920×1080"
                     % (title, BW, BH, PANEL_X), fill=(230, 230, 240, 255), font=font(24), stroke_width=3,
                     stroke_fill=(0, 0, 0, 255))
    grid(d, BW, BH, 50, PANEL_X)
    guides(d, PANEL_X, f_small)
    for label, rect, k in zones(kind):
        draw_zone(d, rect, label, k, 0, f_small)
    sc = Image.alpha_composite(sc, layer)
    sc.convert("RGB").save(os.path.join(OUT, "%s_screen_1920x1080.png" % bid))


for bid, kind, title in (("banner_char_terra", "char", "Banner nhân vật"),
                         ("banner_star5_earth", "star5", "Banner trang bị 5 sao"),
                         ("banner_equip_terra", "equip", "Banner trang bị thường")):
    build(bid, kind, title)
print("ok:", OUT)
