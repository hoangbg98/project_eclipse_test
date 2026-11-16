"""Prepare 3840x2160 parallax layers and a two-tile review composite.

Usage: python tools/stages/fit_backdrop.py art_review/stages/stage_01 bg_stage_01
Raw files must be named <prefix>_far_original.png, _mid_original.png, _near_original.png.
"""
from pathlib import Path
import sys
from PIL import Image, ImageOps, ImageDraw

TARGET = (3840, 2160)
SEAM = 128

def make_seamless(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    width, height = image.size
    seam = min(SEAM, width // 4)
    left = image.crop((0, 0, seam, height))
    right = image.crop((width - seam, 0, width, height)).transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    average = Image.blend(left, right, 0.5)
    ramp = Image.new("L", (seam, height))
    draw = ImageDraw.Draw(ramp)
    for x in range(seam):
        value = round(255 * x / max(1, seam - 1))
        draw.line((x, 0, x, height), fill=value)
    left_out = Image.composite(left, average, ramp)
    right_out = Image.composite(right, average, ramp).transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    image.paste(left_out, (0, 0))
    image.paste(right_out, (width - seam, 0))
    return image

def prepare_far(source: Path, output: Path) -> Image.Image:
    image = Image.open(source).convert("RGB")
    fitted = ImageOps.fit(image, TARGET, method=Image.Resampling.LANCZOS, centering=(0.5, 0.5)).convert("RGBA")
    fitted = make_seamless(fitted)
    fitted.putalpha(255)
    fitted.save(output, "PNG")
    return fitted

def prepare_alpha_layer(source: Path, output: Path) -> Image.Image:
    image = Image.open(source).convert("RGBA")
    width = TARGET[0]
    height = round(image.height * width / image.width)
    image = image.resize((width, height), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", TARGET, (0, 0, 0, 0))
    canvas.alpha_composite(image, (0, TARGET[1] - height))
    canvas = make_seamless(canvas)
    canvas.save(output, "PNG")
    return canvas

def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    root = Path(sys.argv[1])
    prefix = sys.argv[2]
    raw = root / "raw"
    paths = {
        "far": raw / f"{prefix}_far_original.png",
        "mid": raw / f"{prefix}_mid_original.png",
        "near": raw / f"{prefix}_near_original.png",
    }
    for path in paths.values():
        if not path.is_file():
            raise FileNotFoundError(path)
    far = prepare_far(paths["far"], root / f"{prefix}_far.png")
    mid = prepare_alpha_layer(paths["mid"], root / f"{prefix}_mid.png")
    near = prepare_alpha_layer(paths["near"], root / f"{prefix}_near.png")
    stack = Image.new("RGBA", (TARGET[0] * 2, TARGET[1]), (0, 0, 0, 255))
    for repeat in range(2):
        x = repeat * TARGET[0]
        stack.alpha_composite(far, (x, 0))
        stack.alpha_composite(mid, (x, 0))
        stack.alpha_composite(near, (x, 0))
    band_top = round(TARGET[1] * 0.82)
    overlay = Image.new("RGBA", stack.size, (0, 0, 0, 0))
    ImageDraw.Draw(overlay).rectangle((0, band_top, stack.width, stack.height), fill=(52, 49, 48, 112))
    stack.alpha_composite(overlay)
    preview = root / "_preview" / "stack.png"
    preview.parent.mkdir(parents=True, exist_ok=True)
    stack.convert("RGB").save(preview, "PNG")
    for label, image in (("far", far), ("mid", mid), ("near", near)):
        print(f"{label}: {image.width}x{image.height}, alpha={image.mode == 'RGBA'}")
    print(f"preview: {preview} ({stack.width}x{stack.height})")

if __name__ == "__main__":
    main()
