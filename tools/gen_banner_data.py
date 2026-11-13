"""Sinh banner chiêu mộ (data/banners/*.tres) theo câu trả lời của owner ngày 2026-11-12 (OWNER_ASSET_CHECKLIST A1).
Chạy: python -X utf8 tools/gen_banner_data.py   (ghi đè file banner)

Tỉ lệ, pity, giá là SỐ CỦA OWNER — không tự đổi. Những gì Claude tự chọn (ghi rõ bên dưới): chia đều phần nguyên liệu
trong bậc nguyên liệu, lượng vàng mỗi lần ra vàng, số mảnh khi trùng nhân vật, hạng tạm của từng nhân vật.
"""
import io
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "data", "banners")

# --- Owner: giá 1 lượt 280, 10 lượt 2520 (tiền tệ trong game = Ngọc) ---
COST_SINGLE, COST_MULTI, MULTI = 280, 2520, 10

# --- Owner: banner nhân vật ---
#   S 1.5% (chỉ 1 nhân vật rate-up), A 16.3%, B 10.874%, phần còn lại là nguyên liệu tăng cấp nhân vật,
#   nguyên liệu nâng bậc vũ khí, vàng. Pity cứng S 100 lượt; từ lượt 80 tỉ lệ S +10% (một lần).
#   10 lượt chắc chắn ≥ 1 nhân vật A. Pity chuyển sang banner nhân vật kế tiếp (chung nhóm "char").
CHAR_RATES = {"S": 0.015, "A": 0.163, "B": 0.10874}
# Claude chọn (chờ owner xác nhận): banner đầu đề cử Kael (ví dụ owner nêu), hạng lấy từ CharacterDef.rank.
CHAR_BANNERS = [("banner_char_kael", "BANNER_CHAR_KAEL", "char_lightning_01")]
# Claude chọn: mảnh khi trùng nhân vật; vàng mỗi lần ra; nguyên liệu chia đều trong bậc.
DUP_FRAGMENTS = {"S": 25, "A": 10, "B": 5}
MATERIALS = ["item:mat_exp_small", "item:mat_exp_medium", "item:mat_exp_large", "item:mat_enhance_ore",
             "item:mat_enhance_crystal", "gold:2000"]

# --- Owner: tiếp tế vũ khí + vết thánh (dùng chung) ---
#   Vũ khí 4★ 2.87%; vết thánh 4★ "mỗi cái 14%"; vũ khí 3★ 10.7%; vết thánh 3★ "mỗi cái 13%"; nguyên liệu 58%.
#   Pity cứng vũ khí 4★: 60. 10 lượt chắc chắn 1 vũ khí / vết thánh 4★, ưu tiên vết thánh.
#   CHƯA SINH: các số trên cộng lại khác 100% (đọc "mỗi cái" là cho từng ô Đầu / Thân / Chân thì tổng 152.57%;
#   đọc là tổng cả 3 ô thì 98.57%). Chờ owner xác nhận rồi đặt WEAPON_RATES_CONFIRMED = True.
WEAPON_RATES_CONFIRMED = False


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


def write_banner(file_id, name_key, tiers, guarantee_tiers, guarantee_pick, group, source):
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
              'metadata/source = "%s"' % source]
    os.makedirs(OUT, exist_ok=True)
    with io.open(os.path.join(OUT, file_id + ".tres"), "w", encoding="utf-8", newline="\n") as f:
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
    write_banner(file_id, name_key, tiers, ["S", "A"], ["A"], "char",
                 "Owner 2026-11-12: S 1.5%%, A 16.3%%, B 10.874%%, nguyên liệu phần còn lại; pity cứng S 100, "
                 "từ lượt 80 +10%%; 10 lượt chắc chắn A; giá 280 / 2520. Đề cử %s." % featured)
    print("viết", file_id, "A:", a_pool, "B:", b_pool)

if not WEAPON_RATES_CONFIRMED:
    print("bỏ qua banner tiếp tế vũ khí: chờ owner xác nhận tỉ lệ")
