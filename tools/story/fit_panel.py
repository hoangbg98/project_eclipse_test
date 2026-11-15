#!/usr/bin/env python3
"""Fit generated story panels to prompt dimensions and compose page previews."""
import argparse
import json
import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageOps

ROOT = Path(__file__).resolve().parents[2]
REVIEW_DIR = ROOT / "art_review/story/ch01"
PREVIEW_DIR = REVIEW_DIR / "_preview"
PROMPTS = ROOT / "docs/prompts/story/CH01_PANELS.md"


def target_sizes() -> dict[str, tuple[int, int]]:
    """Read each panel's 1x dimensions from the prompt sheet and return 2x sizes."""
    text = PROMPTS.read_text(encoding="utf-8")
    panel_blocks = re.findall(
        r"#### .*?— ô \d+ — `([^`]+)`\s*\n(.*?)(?=\n#### |\n### |\Z)",
        text,
        flags=re.DOTALL,
    )
    sizes: dict[str, tuple[int, int]] = {}
    for filename, block in panel_blocks:
        match = re.search(r"Kích thước ảnh:\*\*\s*(\d+)\s*×\s*(\d+)\s*px", block)
        if not match:
            raise ValueError(f"Không đọc được kích thước của {filename} trong {PROMPTS}")
        sizes[Path(filename).stem] = (int(match.group(1)) * 2, int(match.group(2)) * 2)
    if not sizes:
        raise ValueError(f"Không tìm thấy panel nào trong {PROMPTS}")
    return sizes


def clip_data(clip_id: str) -> dict:
    path = ROOT / "data/story" / f"{clip_id}.json"
    return json.loads(path.read_text(encoding="utf-8"))


def get_panel(clip_id: str, name: str) -> dict:
    data = clip_data(clip_id)
    return next(
        panel
        for page in data["pages"]
        for panel in page.get("panels", [])
        if panel["image"] == name
    )


def fit(source: Path, clip_id: str, name: str) -> None:
    panel = get_panel(clip_id, name)
    poly = panel["poly"]
    x0, y0 = min(p[0] for p in poly), min(p[1] for p in poly)
    x1, y1 = max(p[0] for p in poly), max(p[1] for p in poly)
    size = target_sizes()[name]
    ratio = size[0] / size[1]
    image = ImageOps.exif_transpose(Image.open(source)).convert("RGB")
    sw, sh = image.size
    if sw / sh > ratio:
        crop_w = round(sh * ratio)
        left = (sw - crop_w) // 2
        image = image.crop((left, 0, left + crop_w, sh))
    else:
        crop_h = round(sw / ratio)
        top = (sh - crop_h) // 2
        image = image.crop((0, top, sw, top + crop_h))
    image = image.resize(size, Image.Resampling.LANCZOS)
    image.save(REVIEW_DIR / f"{name}.png", optimize=True)

    # Mirror the game's UV mapping: fill the polygon bounding box, then mask by poly.
    box_size = (x1 - x0, y1 - y0)
    box_image = image.resize(box_size, Image.Resampling.LANCZOS)
    mask = Image.new("L", box_size, 0)
    local_poly = [(x - x0, y - y0) for x, y in poly]
    ImageDraw.Draw(mask).polygon(local_poly, fill=255)
    dark = Image.new("RGB", box_size, (4, 4, 7))
    masked = Image.composite(box_image, dark, mask.point(lambda value: 255 if value else 48))
    masked.save(PREVIEW_DIR / f"{name}_mask.png", optimize=True)


def compose_page(clip_id: str, page_number: int) -> Path:
    data = clip_data(clip_id)
    page_data = data["pages"][page_number - 1]
    page_size = tuple(data["design_size"])
    page = Image.new("RGB", page_size, (0, 0, 0))
    for panel in page_data.get("panels", []):
        name, poly = panel["image"], panel["poly"]
        x0, y0 = min(p[0] for p in poly), min(p[1] for p in poly)
        x1, y1 = max(p[0] for p in poly), max(p[1] for p in poly)
        texture = Image.open(REVIEW_DIR / f"{name}.png").convert("RGB")
        texture = texture.resize((x1 - x0, y1 - y0), Image.Resampling.LANCZOS)
        mask = Image.new("L", texture.size, 0)
        local_poly = [(x - x0, y - y0) for x, y in poly]
        ImageDraw.Draw(mask).polygon(local_poly, fill=255)
        page.paste(texture, (x0, y0), mask)
        closed = [(x + x0, y + y0) for x, y in local_poly + [local_poly[0]]]
        draw = ImageDraw.Draw(page)
        draw.line(closed, fill=(0, 0, 0), width=12, joint="curve")
        draw.line(closed, fill=(245, 245, 245), width=5, joint="curve")
    output = PREVIEW_DIR / f"page_{clip_id}_{page_number}.png"
    page.save(output, optimize=True)
    return output


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("source", nargs="?", type=Path, help="Ảnh gốc từ image_gen")
    parser.add_argument("panel", nargs="?", help="Tên panel, ví dụ ch01_open_01")
    parser.add_argument("--compose", nargs=2, metavar=("CLIP", "PAGE"), help="Ghép preview trang, số trang tính từ 1")
    args = parser.parse_args()
    if args.compose:
        out = compose_page(args.compose[0], int(args.compose[1]))
        print(out)
    elif args.source and args.panel:
        prefix = "_".join(args.panel.split("_")[:-1])
        fit(args.source, prefix, args.panel)
    else:
        parser.error("Dùng: fit_panel.py <ảnh_gốc> <panel_name> hoặc fit_panel.py --compose <clip> <trang>")
