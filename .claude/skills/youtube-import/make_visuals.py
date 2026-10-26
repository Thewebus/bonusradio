"""Builds myBonus posters from YouTube thumbnails, in the style of the
existing series art (warm cinematic grade, brush series name, bold title,
"— SAISON 1 —" / "— ÉPISODE N —" line).

Usage: python3 make_visuals.py <batch.json> <out_dir>
Writes, per video: <yt>_portrait.jpg (940x1672) and <yt>_landscape.jpg
(1600x900); per new series: series_<slug>_portrait/landscape.jpg; and
contact_sheet.jpg to review everything at once. Thumbnails are cached in
<out_dir>/thumbs.
"""
import json
import os
import re
import sys
import unicodedata
import urllib.request

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ANTON = os.path.join(HERE, "fonts", "Anton-Regular.ttf")
MARKER = os.path.join(HERE, "fonts", "PermanentMarker-Regular.ttf")
PORTRAIT = (940, 1672)
LANDSCAPE = (1600, 900)
YELLOW, ORANGE = (255, 214, 64), (245, 130, 32)


def slug(text):
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")


def thumb(yt, cache):
    os.makedirs(cache, exist_ok=True)
    path = os.path.join(cache, yt + ".jpg")
    if not os.path.exists(path):
        for name in ("maxresdefault", "sddefault", "hqdefault"):
            try:
                urllib.request.urlretrieve(f"https://i.ytimg.com/vi/{yt}/{name}.jpg", path)
                break
            except Exception:
                continue
    return Image.open(path).convert("RGB")


def grade(img):
    img = ImageEnhance.Color(img).enhance(1.25)
    img = ImageEnhance.Contrast(img).enhance(1.12)
    warm = Image.new("RGB", img.size, (255, 150, 60))
    return Image.blend(img, warm, 0.12)


def face_x(img):
    """Horizontal center (0-1) of the largest face, 0.5 if none/no OpenCV."""
    try:
        import cv2
        import numpy as np
    except ImportError:
        return 0.5
    gray = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2GRAY)
    det = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_default.xml")
    faces = det.detectMultiScale(gray, 1.1, 6, minSize=(img.height // 8, img.height // 8))
    if len(faces) == 0:
        return 0.5
    x, _, w, _ = max(faces, key=lambda f: f[2] * f[3])
    return (x + w / 2) / img.width


def cover(img, size, fx=0.5):
    w, h = size
    s = max(w / img.width, h / img.height)
    img = img.resize((round(img.width * s), round(img.height * s)), Image.LANCZOS)
    x = min(max(int(img.width * fx - w / 2), 0), img.width - w)
    y = (img.height - h) // 2
    return img.crop((x, y, x + w, y + h))


def shade(img, box, axis, start, end):
    """Black gradient over box, alpha going start→end along axis ('x'/'y')."""
    x0, y0, x1, y1 = box
    n = (x1 - x0) if axis == "x" else (y1 - y0)
    grad = Image.new("L", (n, 1) if axis == "x" else (1, n))
    grad.putdata([int(start + (end - start) * i / max(n - 1, 1)) for i in range(n)])
    grad = grad.resize((x1 - x0, y1 - y0))
    img.paste(Image.new("RGB", grad.size, "black"), (x0, y0), grad)


def vignette(img):
    w, h = img.size
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).ellipse((-w * 0.25, -h * 0.25, w * 1.25, h * 1.25), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(min(w, h) * 0.12))
    dark = Image.new("RGB", (w, h), "black")
    return Image.composite(img, Image.blend(img, dark, 0.55), mask)


def fit_font(path, lines, max_w, size):
    while size > 20:
        font = ImageFont.truetype(path, size)
        if all(font.getlength(line) <= max_w for line in lines):
            return font
        size -= 4
    return ImageFont.truetype(path, size)


def wrap(text, font_path, size, max_w, max_lines):
    words, lines = text.split(), [""]
    font = ImageFont.truetype(font_path, size)
    for word in words:
        trial = (lines[-1] + " " + word).strip()
        if font.getlength(trial) <= max_w or not lines[-1]:
            lines[-1] = trial
        else:
            lines.append(word)
    if len(lines) > max_lines:
        lines = lines[: max_lines - 1] + [" ".join(lines[max_lines - 1:])]
    return lines


def gradient_text(canvas, xy, text, font, top, bottom, anchor="ma", stroke=0):
    """Text filled with a vertical top→bottom gradient, with a drop shadow."""
    x, y = xy
    draw = ImageDraw.Draw(canvas)
    bbox = draw.textbbox((x, y), text, font=font, anchor=anchor, stroke_width=stroke)
    shadow = Image.new("L", canvas.size, 0)
    ImageDraw.Draw(shadow).text((x + 6, y + 8), text, font=font, anchor=anchor, fill=200, stroke_width=stroke)
    canvas.paste(Image.new("RGB", canvas.size, "black"), (0, 0), shadow.filter(ImageFilter.GaussianBlur(8)))
    mask = Image.new("L", canvas.size, 0)
    ImageDraw.Draw(mask).text((x, y), text, font=font, anchor=anchor, fill=255,
                              stroke_width=stroke, stroke_fill=255)
    h = max(bbox[3] - bbox[1], 1)
    fill = Image.new("RGB", (1, h))
    fill.putdata([tuple(int(top[c] + (bottom[c] - top[c]) * i / h) for c in range(3)) for i in range(h)])
    layer = Image.new("RGB", canvas.size, "black")
    layer.paste(fill.resize((bbox[2] - bbox[0], h)), (bbox[0], bbox[1]))
    canvas.paste(layer, (0, 0), mask)
    return bbox


def tag_line(canvas, cx, y, text, size):
    """'——  TEXT  ——' in spaced Anton, centered on cx."""
    font = ImageFont.truetype(ANTON, size)
    spaced = " ".join(text.upper())
    draw = ImageDraw.Draw(canvas)
    w = font.getlength(spaced)
    draw.text((cx, y), spaced, font=font, anchor="ma", fill=(245, 240, 230))
    mid = y + size * 0.62
    for sign in (-1, 1):
        a = cx + sign * (w / 2 + size * 0.6)
        draw.line((a, mid, a + sign * size * 2.2, mid), fill=(245, 240, 230), width=max(2, size // 12))


def text_block(canvas, cx, top, max_w, kicker, title, tag, scale, kicker_size=70):
    """kicker (brush, yellow) / TITLE (Anton, white→cream) / — tag —."""
    y = top
    if kicker:
        kf = fit_font(MARKER, [kicker], max_w, int(kicker_size * scale))
        b = gradient_text(canvas, (cx, y), kicker, kf, YELLOW, ORANGE)
        y = b[3] + int(14 * scale)
    lines = wrap(title.upper(), ANTON, int(150 * scale), max_w, 3) if title else []
    tf = fit_font(ANTON, lines, max_w, int(150 * scale))
    for line in lines:
        b = gradient_text(canvas, (cx, y), line, tf, (255, 255, 255), (236, 222, 196))
        y = b[3] + int(10 * scale)
    if tag:
        tag_line(canvas, cx, y + int(18 * scale), tag, int(46 * scale))
    return y


def block_height(kicker, title, tag, max_w, scale, kicker_size=70):
    probe = Image.new("RGB", (4000, 4000))
    end = text_block(probe, 2000, 0, max_w, kicker, title, tag, scale, kicker_size)
    return end + (int(80 * scale) if tag else 0)


def landscape(src, kicker, title, tag, kicker_size=70):
    w, h = LANDSCAPE
    img = vignette(grade(cover(src, LANDSCAPE)))
    text_left = face_x(src) >= 0.5
    if text_left:
        shade(img, (0, 0, int(w * 0.66), h), "x", 235, 0)
    else:
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
        shade(img, (0, 0, int(w * 0.66), h), "x", 235, 0)
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
    shade(img, (0, int(h * 0.5), w, h), "y", 0, 170)
    max_w = int(w * 0.44)
    hgt = block_height(kicker, title, tag, max_w, 0.9, kicker_size)
    cx = int(w * 0.27) if text_left else int(w * 0.73)
    text_block(img, cx, (h - hgt) // 2, max_w, kicker, title, tag, 0.9, kicker_size)
    return img


def portrait(src, kicker, title, tag, kicker_size=70):
    w, h = PORTRAIT
    fx = face_x(src)
    bg = grade(cover(src, PORTRAIT, fx)).filter(ImageFilter.GaussianBlur(28))
    bg = ImageEnhance.Brightness(bg).enhance(0.55)
    fg_h = int(h * 0.62)
    fg = vignette(grade(cover(src, (w, fg_h), fx)))
    mask = Image.new("L", (w, fg_h), 255)
    shade_mask = ImageDraw.Draw(mask)
    feather = 160
    for i in range(feather):
        a = int(255 * i / feather)
        shade_mask.line((0, i, w, i), fill=a)
        shade_mask.line((0, fg_h - 1 - i, w, fg_h - 1 - i), fill=a)
    bg.paste(fg, (0, int(h * 0.04)), mask)
    shade(bg, (0, int(h * 0.45), w, h), "y", 0, 225)
    max_w = int(w * 0.86)
    hgt = block_height(kicker, title, tag, max_w, 0.95, kicker_size)
    top = min(int(h * 0.60), h - hgt - 60)
    text_block(bg, w // 2, top, max_w, kicker, title, tag, 0.95, kicker_size)
    return bg


def main(batch_path, out):
    batch = json.load(open(batch_path, encoding="utf-8"))
    cache = os.path.join(out, "thumbs")
    made = []
    for name, mode in batch.get("categories", {}).items():
        if mode != "create":
            continue
        first = next(v for v in batch["videos"] if v.get("category") == name or v.get("series") == name)
        sq = vignette(grade(cover(thumb(first["yt"], cache), (512, 512), face_x(thumb(first["yt"], cache)))))
        shade(sq, (0, 160, 512, 512), "y", 0, 230)
        text_block(sq, 256, 330, 440, name, None, None, 1, 110)
        sq.save(os.path.join(out, "category_" + slug(name) + ".jpg"), quality=86)
    for s in batch["series"]:
        if s.get("existing"):
            continue
        src = thumb(s["poster_from"], cache)
        base = os.path.join(out, "series_" + slug(s["title"]))
        portrait(src, s["title"], None, "Saison 1", 170).save(base + "_portrait.jpg", quality=86)
        landscape(src, s["title"], None, "Saison 1", 150).save(base + "_landscape.jpg", quality=86)
        made.append(base)
    for v in batch["videos"]:
        src = thumb(v["yt"], cache)
        kicker = v.get("series")
        # "(partie N)" moves from the title to the tag line.
        title, part = v["title"], None
        m = re.search(r"\s*\((partie \d+)\)$", title, re.I)
        if m:
            title, part = title[: m.start()], m.group(1).capitalize()
        tag = f"Épisode {v['episode']}" if v.get("episode") else "Film"
        if part:
            tag += " · " + part
        base = os.path.join(out, v["yt"])
        portrait(src, kicker, title, tag).save(base + "_portrait.jpg", quality=86)
        landscape(src, kicker, title, tag).save(base + "_landscape.jpg", quality=86)
        made.append(base)

    # Contact sheet: one row per item, portrait + landscape side by side.
    ph, cols = 300, 4
    pw, lw = round(ph * PORTRAIT[0] / PORTRAIT[1]), round(ph * LANDSCAPE[0] / LANDSCAPE[1])
    cell = pw + lw + 30
    rows = (len(made) + cols - 1) // cols
    sheet = Image.new("RGB", (cell * cols, (ph + 20) * rows), (30, 30, 30))
    for k, base in enumerate(made):
        x, y = (k % cols) * cell, (k // cols) * (ph + 20)
        sheet.paste(Image.open(base + "_portrait.jpg").resize((pw, ph)), (x, y))
        sheet.paste(Image.open(base + "_landscape.jpg").resize((lw, ph)), (x + pw + 6, y))
    sheet.save(os.path.join(out, "contact_sheet.jpg"), quality=72)
    print(f"{len(made)} visuels générés → {out}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
