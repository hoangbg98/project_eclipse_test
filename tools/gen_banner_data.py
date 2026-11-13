"""Sinh banner chiêu mộ (data/banners/*.tres) và lượt x10 miễn phí đầu tiên (data/tutorial/starter_pull.tres)
theo câu trả lời của owner ngày 2026-11-12 và 2026-11-13 (OWNER_ASSET_CHECKLIST A1, A2).
Chạy: python -X utf8 tools/gen_banner_data.py   (ghi đè các file này)

Tỉ lệ, pity, giá là SỐ CỦA OWNER — không tự đổi. Những gì Claude tự chọn ghi rõ "Claude chọn" bên dưới.
"""
import io
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "data", "banners")
OUT_TUTORIAL = os.path.join(ROOT, "data", "tutorial")

# --- Owner: giá 1 lượt 280, 10 lượt 2520 (tiền tệ trong game = Ngọc) ---
COST_SINGLE, COST_MULTI, MULTI = 280, 2520, 10

# --- Owner: banner nhân vật ---
#   S 1.5% (chỉ 1 nhân vật rate-up), A 16.3%, B 10.874%, phần còn lại là nguyên liệu tăng cấp nhân vật,
#   nguyên liệu nâng bậc vũ khí, vàng. Pity cứng S 100 lượt; từ lượt 80 tỉ lệ S +10% (một lần, owner xác nhận
#   2026-11-13). 10 lượt chắc chắn ≥ 1 nhân vật A. Pity chuyển sang banner nhân vật kế tiếp (chung nhóm "char").
#   Hạng (owner 2026-11-13, tạm): S = Enkiba, Iwagane; A = Hikarine, Yomigari; B = Raikiba, Kazeyumi (CharacterDef.rank).
CHAR_RATES = {"S": 0.015, "A": 0.163, "B": 0.10874}
# Owner 2026-11-13: banner đầu tiên đề cử Iwagane — Thần Kiếm Nham Thạch (char_earth_01).
FEATURED = "char_earth_01"
CHAR_BANNERS = [("banner_char_terra", "BANNER_CHAR_TERRA", FEATURED)]
# Claude chọn: mảnh khi trùng nhân vật; vàng mỗi lần ra; nguyên liệu chia đều trong bậc.
DUP_FRAGMENTS = {"S": 25, "A": 10, "B": 5}
MATERIALS = ["item:mat_exp_small", "item:mat_exp_medium", "item:mat_exp_large", "item:mat_enhance_ore",
             "item:mat_enhance_crystal", "gold:2000"]

# --- Owner: tiếp tế vũ khí + vết thánh (dùng chung một banner) ---
#   Vũ khí 4★ 2.87%; vết thánh 4★ 14%; vũ khí 3★ 10.7%; vết thánh 3★ 13% → owner 2026-11-13: "tăng vết thánh 3★
#   cho khớp 100%" = 14.43%; nguyên liệu bồi dưỡng + thông dụng 58%. Mỗi số là tổng cả nhóm (3 ô Đầu / Thân / Chân).
#   Pity cứng vũ khí 4★: 60. 10 lượt chắc chắn 1 vũ khí / vết thánh 4★, ưu tiên vết thánh.
#   Rate-up: vũ khí 4★ và bộ vết thánh 4★ đề cử của nhân vật đang đề cử.
EQUIP_RATES = {"W4": 0.0287, "S4": 0.14, "W3": 0.107, "S3": 0.1443}   # còn lại 0.58 = nguyên liệu
EQUIP_BANNERS = [("banner_equip_terra", "BANNER_EQUIP_TERRA",
                  ["equip:eq_weapon_greatsword_magma"],
                  ["equip:eq_stigma_top_bedrock", "equip:eq_stigma_mid_bedrock", "equip:eq_stigma_bot_bedrock"])]
# Claude chọn: khi ra vết thánh 4★, 50% là món trong bộ đề cử.
STIGMA_FEATURED_RATE = 0.5

# --- Owner 2026-11-13: lượt x10 miễn phí đầu tiên (hướng dẫn) BẮT BUỘC có 1 Raikiba, còn lại nguyên liệu tăng cấp ---
STARTER_CHARACTER = "char_lightning_01"
STARTER_MATERIALS = ["item:mat_exp_small", "item:mat_exp_medium", "item:mat_exp_large"]


def char_ranks():
    """CharacterDef.rank của mọi nhân vật trong data/characters (đọc thẳng file .tres)."""
    out = {}
    d = os.path.join(ROOT, "data", "characters")
    for f in sorted(os.listdir(d)):
        if not f.endswith(".tres") or f.endswith("_kit.tres"):
            continue
        text = io.open(os.path.join(d, f), encoding="utf-8").read()
        rank = ""
        for line in text.splitlines():
            if line.startswith('rank = "'):
                rank = line.split('"')[1]
        if rank:
            out[f[:-5]] = rank
    return out


def equip_by(rarity, stigma):
    """Trang bị trong data/equipment theo số sao và loại (vũ khí / vết thánh)."""
    out = []
    d = os.path.join(ROOT, "data", "equipment")
    for f in sorted(os.listdir(d)):
        if not f.endswith(".tres"):
            continue
        text = io.open(os.path.join(d, f), encoding="utf-8").read()
        r = slot = None
        for line in text.splitlines():
            if line.startswith("rarity = "):
                r = int(line.split("=")[1])
            if line.startswith('slot = "'):
                slot = line.split('"')[1]
        if r == rarity and (slot.startswith("stigma") if stigma else slot == "weapon"):
            out.append("equip:" + f[:-5])
    return out


def tier(sub_id, tier_id, rarity, rate, pool, label_key, featured=(), featured_rate=0.0, hard=0, soft_start=0,
         soft_step=0.0, soft_mode="step", dup_frag=0):
    arr = lambda xs: "PackedStringArray(%s)" % ", ".join('"%s"' % x for x in xs)
    return "\n".join([
        '[sub_resource type="Resource" id="%s"]' % sub_id, 'script = ExtResource("2")',
        "rarity = %d" % rarity, 'tier_id = "%s"' % tier_id, 'label_key = "%s"' % label_key,
        "base_rate = %s" % repr(float(rate)), "hard_pity = %d" % hard, "soft_pity_start = %d" % soft_start,
        "soft_pity_step = %s" % repr(float(soft_step)), 'soft_pity_mode = "%s"' % soft_mode,
        "pool = %s" % arr(pool), "featured = %s" % arr(featured), "featured_rate = %s" % repr(float(featured_rate)),
        "guarantee_after_miss = false", "duplicate_fragments = %d" % dup_frag, ""])


def write_banner(out_dir, file_id, name_key, tiers, guarantee_tiers, guarantee_pick, group, source, starter=False):
    subs = [t[1] for t in tiers]
    arr = lambda xs: "PackedStringArray(%s)" % ", ".join('"%s"' % x for x in xs)
    lines = ['[gd_resource type="Resource" script_class="BannerDef" load_steps=%d format=3]' % (len(subs) + 3), "",
             '[ext_resource type="Script" path="res://scripts/gacha/banner_def.gd" id="1"]',
             '[ext_resource type="Script" path="res://scripts/gacha/gacha_tier_def.gd" id="2"]', ""]
    lines += subs
    lines += ["[resource]", 'script = ExtResource("1")', 'id = "%s"' % file_id, 'name_key = "%s"' % name_key,
              'tiers = Array[ExtResource("2")]([%s])' % ", ".join('SubResource("%s")' % t[0] for t in tiers),
              'cost_currency = "gems"', "cost_single = %d" % COST_SINGLE, "multi_count = %d" % MULTI,
              "cost_multi = %d" % COST_MULTI, 'pity_group = "%s"' % group,
              "multi_guarantee_tiers = %s" % arr(guarantee_tiers), "multi_guarantee_pick = %s" % arr(guarantee_pick),
              "starter_free_multi = %s" % ("true" if starter else "false"),
              'metadata/source = "%s"' % source]
    os.makedirs(out_dir, exist_ok=True)
    with io.open(os.path.join(out_dir, file_id + ".tres"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")


ranks = char_ranks()
for file_id, name_key, featured in CHAR_BANNERS:
    a_pool = ["char:" + c for c, r in ranks.items() if r == "A"]
    b_pool = ["char:" + c for c, r in ranks.items() if r == "B"]
    assert ranks.get(featured) == "S", "nhân vật đề cử phải hạng S"
    assert a_pool and b_pool, "cần ít nhất 1 nhân vật hạng A và 1 hạng B (CharacterDef.rank)"
    tiers = [
        ("t_s", tier("t_s", "S", 5, CHAR_RATES["S"], ["char:" + featured], "GACHA_TIER_CHAR_S",
                     featured=["char:" + featured], featured_rate=1.0, hard=100, soft_start=80, soft_step=0.10,
                     soft_mode="flat", dup_frag=DUP_FRAGMENTS["S"])),
        ("t_a", tier("t_a", "A", 4, CHAR_RATES["A"], a_pool, "GACHA_TIER_CHAR_A", dup_frag=DUP_FRAGMENTS["A"])),
        ("t_b", tier("t_b", "B", 3, CHAR_RATES["B"], b_pool, "GACHA_TIER_CHAR_B", dup_frag=DUP_FRAGMENTS["B"])),
        ("t_m", tier("t_m", "MAT", 1, 0.0, MATERIALS, "GACHA_TIER_MATERIALS")),
    ]
    write_banner(OUT, file_id, name_key, tiers, ["S", "A"], ["A"], "char",
                 "Owner 2026-11-12/13: S 1.5%%, A 16.3%%, B 10.874%%, nguyên liệu phần còn lại; pity cứng S 100, "
                 "từ lượt 80 +10%%; 10 lượt chắc chắn A; giá 280 / 2520. Đề cử %s." % featured)
    print("viết", file_id, "A:", a_pool, "B:", b_pool)

assert abs(sum(EQUIP_RATES.values()) + 0.58 - 1.0) < 1e-9, "tỉ lệ tiếp tế phải cộng lại 100%"
for file_id, name_key, weapons, stigmata in EQUIP_BANNERS:
    w4, s4 = equip_by(4, False), equip_by(4, True)
    w3, s3 = equip_by(3, False), equip_by(3, True)
    assert all(x in w4 for x in weapons) and all(x in s4 for x in stigmata), "món đề cử phải nằm trong bậc 4★"
    tiers = [
        ("t_w4", tier("t_w4", "W4", 4, EQUIP_RATES["W4"], w4, "GACHA_TIER_WEAPON_4", featured=weapons,
                      featured_rate=1.0 if len(weapons) == len(w4) else 0.5, hard=60)),
        ("t_s4", tier("t_s4", "S4", 4, EQUIP_RATES["S4"], s4, "GACHA_TIER_STIGMA_4", featured=stigmata,
                      featured_rate=1.0 if len(stigmata) == len(s4) else STIGMA_FEATURED_RATE)),
        ("t_w3", tier("t_w3", "W3", 3, EQUIP_RATES["W3"], w3, "GACHA_TIER_WEAPON_3")),
        ("t_s3", tier("t_s3", "S3", 3, EQUIP_RATES["S3"], s3, "GACHA_TIER_STIGMA_3")),
        ("t_m", tier("t_m", "MAT", 1, 0.0, MATERIALS, "GACHA_TIER_MATERIALS")),
    ]
    write_banner(OUT, file_id, name_key, tiers, ["W4", "S4"], ["S4"], "equip",
                 "Owner 2026-11-12/13: vũ khí 4★ 2.87%%, vết thánh 4★ 14%%, vũ khí 3★ 10.7%%, vết thánh 3★ 14.43%%, "
                 "nguyên liệu 58%%; pity cứng vũ khí 4★ 60; 10 lượt chắc chắn 4★ (ưu tiên vết thánh); giá 280 / 2520.")
    print("viết", file_id, "W4:", w4, "S4:", s4, "W3:", w3, "S3:", s3)

starter_tiers = [
    ("t_k", tier("t_k", "STARTER", 3, 0.0, ["char:" + STARTER_CHARACTER], "GACHA_TIER_CHAR_B",
                 dup_frag=DUP_FRAGMENTS["B"])),
    ("t_m", tier("t_m", "MAT", 1, 0.0, STARTER_MATERIALS, "GACHA_TIER_MATERIALS")),
]
write_banner(OUT_TUTORIAL, "starter_pull", "BANNER_STARTER", starter_tiers, [], [], "starter",
             "Owner 2026-11-13: lượt x10 miễn phí đầu tiên chắc chắn 1 Raikiba, 9 lượt còn lại là nguyên liệu tăng cấp.",
             starter=True)
print("viết starter_pull")
