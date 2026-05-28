#!/usr/bin/env python3

from __future__ import annotations

import math
import os
import shutil
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
PACKAGING = ROOT / "Packaging"
ASSETS = PACKAGING / "Assets"
RESOURCES = PACKAGING / "Resources"
ICONSET = ASSETS / "AppIcon.iconset"


def rgba(hex_value: int, alpha: int = 255) -> tuple[int, int, int, int]:
    return (
        (hex_value >> 16) & 0xFF,
        (hex_value >> 8) & 0xFF,
        hex_value & 0xFF,
        alpha,
    )


def lerp(a: int, b: int, t: float) -> int:
    return int(round(a + (b - a) * t))


def gradient(size: tuple[int, int], stops: list[tuple[float, tuple[int, int, int, int]]]) -> Image.Image:
    width, height = size
    img = Image.new("RGBA", size)
    px = img.load()
    for y in range(height):
        t = y / max(height - 1, 1)
        lower = stops[0]
        upper = stops[-1]
        for idx in range(len(stops) - 1):
            if stops[idx][0] <= t <= stops[idx + 1][0]:
                lower = stops[idx]
                upper = stops[idx + 1]
                break
        span = max(upper[0] - lower[0], 0.0001)
        local = min(max((t - lower[0]) / span, 0), 1)
        color = tuple(lerp(lower[1][i], upper[1][i], local) for i in range(4))
        for x in range(width):
            px[x, y] = color
    return img


def rounded_mask(size: int, radius: int, inset: int = 0) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle(
        (inset, inset, size - inset, size - inset),
        radius=radius,
        fill=255,
    )
    return mask


def cubic(
    p0: tuple[float, float],
    p1: tuple[float, float],
    p2: tuple[float, float],
    p3: tuple[float, float],
    steps: int = 44,
) -> list[tuple[float, float]]:
    pts: list[tuple[float, float]] = []
    for i in range(steps + 1):
        t = i / steps
        mt = 1 - t
        x = mt**3 * p0[0] + 3 * mt**2 * t * p1[0] + 3 * mt * t**2 * p2[0] + t**3 * p3[0]
        y = mt**3 * p0[1] + 3 * mt**2 * t * p1[1] + 3 * mt * t**2 * p2[1] + t**3 * p3[1]
        pts.append((x, y))
    return pts


def draw_arrow(
    draw: ImageDraw.ImageDraw,
    points: list[tuple[float, float]],
    fill: tuple[int, int, int, int],
    width: int,
) -> None:
    draw.line(points, fill=fill, width=width, joint="curve")
    start = points[-2]
    end = points[-1]
    angle = math.atan2(end[1] - start[1], end[0] - start[0])
    length = width * 2.45
    spread = math.pi * 0.78
    left = (
        end[0] - math.cos(angle - spread / 2) * length,
        end[1] - math.sin(angle - spread / 2) * length,
    )
    right = (
        end[0] - math.cos(angle + spread / 2) * length,
        end[1] - math.sin(angle + spread / 2) * length,
    )
    draw.polygon([end, left, right], fill=fill)


def render_with_supersampling(size: tuple[int, int], draw_fn, scale: int = 4) -> Image.Image:
    large_size = (size[0] * scale, size[1] * scale)
    img = Image.new("RGBA", large_size, (0, 0, 0, 0))
    draw_fn(img, scale)
    return img.resize(size, Image.Resampling.LANCZOS)


def draw_app_icon_on(img: Image.Image, scale: int) -> None:
    size = img.size[0]
    s = size
    draw = ImageDraw.Draw(img)
    inset = int(s * 0.035)
    radius = int(s * 0.225)

    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    shadow_mask = rounded_mask(s, radius, inset).filter(ImageFilter.GaussianBlur(int(s * 0.025)))
    shadow_color = Image.new("RGBA", img.size, rgba(0x0D1640, 72))
    shadow.alpha_composite(shadow_color)
    img.alpha_composite(Image.composite(shadow, Image.new("RGBA", img.size, (0, 0, 0, 0)), shadow_mask), (0, int(s * 0.012)))

    mask = rounded_mask(s, radius, inset)
    bg = gradient(
        img.size,
        [
            (0.0, rgba(0x3847D7)),
            (0.55, rgba(0x4C8DFF)),
            (1.0, rgba(0x86F4FF)),
        ],
    )
    img.alpha_composite(Image.composite(bg, Image.new("RGBA", img.size, (0, 0, 0, 0)), mask))

    # Trackpad.
    trackpad = (int(s * 0.18), int(s * 0.53), int(s * 0.82), int(s * 0.81))
    draw.rounded_rectangle(trackpad, radius=int(s * 0.06), fill=rgba(0xF7FBFF, 246), outline=rgba(0xFFFFFF, 216), width=max(1, int(s * 0.014)))
    draw.rounded_rectangle(
        (int(s * 0.24), int(s * 0.70), int(s * 0.76), int(s * 0.745)),
        radius=int(s * 0.022),
        fill=rgba(0x7B91C8, 96),
    )

    # Mouse.
    mouse = (int(s * 0.365), int(s * 0.17), int(s * 0.635), int(s * 0.53))
    draw.rounded_rectangle(mouse, radius=int(s * 0.135), fill=rgba(0xFFFFFF, 250), outline=rgba(0xFFFFFF, 226), width=max(1, int(s * 0.012)))
    draw.rounded_rectangle(
        (int(s * 0.485), int(s * 0.245), int(s * 0.515), int(s * 0.325)),
        radius=int(s * 0.015),
        fill=rgba(0x5262D9, 200),
    )
    draw.line(
        [(int(s * 0.5), int(s * 0.36)), (int(s * 0.5), int(s * 0.51))],
        fill=rgba(0x5B6BD7, 62),
        width=max(1, int(s * 0.008)),
    )

    draw_arrow(
        draw,
        cubic(
            (s * 0.27, s * 0.39),
            (s * 0.14, s * 0.49),
            (s * 0.16, s * 0.66),
            (s * 0.29, s * 0.70),
        ),
        rgba(0xFFFFFF, 230),
        max(2, int(s * 0.028)),
    )
    draw_arrow(
        draw,
        cubic(
            (s * 0.73, s * 0.61),
            (s * 0.86, s * 0.51),
            (s * 0.84, s * 0.34),
            (s * 0.71, s * 0.30),
        ),
        rgba(0xFFC05A, 250),
        max(2, int(s * 0.028)),
    )


def app_icon(size: int) -> Image.Image:
    return render_with_supersampling((size, size), draw_app_icon_on, scale=4)


def draw_status_template_on(img: Image.Image, scale: int) -> None:
    s = img.size[0]
    draw = ImageDraw.Draw(img)
    ink = rgba(0x000000)
    stroke = max(3, int(s * 0.075))

    draw.rounded_rectangle(
        (int(s * 0.28), int(s * 0.12), int(s * 0.72), int(s * 0.46)),
        radius=int(s * 0.18),
        outline=ink,
        width=stroke,
    )
    draw.rounded_rectangle(
        (int(s * 0.47), int(s * 0.22), int(s * 0.53), int(s * 0.32)),
        radius=int(s * 0.03),
        fill=ink,
    )
    draw.rounded_rectangle(
        (int(s * 0.19), int(s * 0.57), int(s * 0.81), int(s * 0.82)),
        radius=int(s * 0.055),
        outline=ink,
        width=stroke,
    )
    draw_arrow(
        draw,
        cubic(
            (s * 0.2, s * 0.43),
            (s * 0.09, s * 0.27),
            (s * 0.25, s * 0.09),
            (s * 0.4, s * 0.18),
        ),
        ink,
        max(2, int(s * 0.055)),
    )
    draw_arrow(
        draw,
        cubic(
            (s * 0.8, s * 0.57),
            (s * 0.91, s * 0.73),
            (s * 0.72, s * 0.92),
            (s * 0.57, s * 0.84),
        ),
        ink,
        max(2, int(s * 0.055)),
    )


def status_template() -> Image.Image:
    return render_with_supersampling((36, 36), draw_status_template_on, scale=4)


def font(size: int, bold: bool = False, chinese: bool = False) -> ImageFont.FreeTypeFont:
    candidates = []
    if chinese:
        candidates += [
            "/System/Library/Fonts/Hiragino Sans GB.ttc",
            "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
            "/Library/Fonts/Arial Unicode.ttf",
        ]
    candidates += [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/HelveticaNeue.ttc",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for path in candidates:
        if os.path.exists(path):
            return ImageFont.truetype(path, size=size, index=0)
    return ImageFont.load_default(size=size)


def dmg_background() -> Image.Image:
    size = (720, 440)
    img = gradient(
        size,
        [
            (0.0, rgba(0xEAF0FF)),
            (1.0, rgba(0xF8FBFF)),
        ],
    )
    draw = ImageDraw.Draw(img)

    band = gradient(
        (720, 170),
        [
            (0.0, rgba(0x4D72F0, 218)),
            (1.0, rgba(0x84F0FF, 190)),
        ],
    )
    img.alpha_composite(band, (0, 0))

    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    odraw = ImageDraw.Draw(overlay)
    odraw.ellipse((488, -38, 830, 225), fill=rgba(0xFFFFFF, 54))
    odraw.ellipse((-135, -15, 235, 205), fill=rgba(0x2043B8, 30))
    img.alpha_composite(overlay)

    draw.text((40, 42), "NaturalScrollSwitcher", fill=rgba(0xFFFFFF), font=font(32, bold=True))
    draw.text((42, 86), "拖到 Applications 即可安装 / Drag to Applications to install", fill=rgba(0xFFFFFF, 226), font=font(15, chinese=True))

    # Install arrow between the two Finder icons.
    points = cubic((270, 275), (330, 230), (390, 230), (450, 275), steps=50)
    draw.line(points, fill=rgba(0x5064DF, 94), width=7, joint="curve")
    draw.polygon([(460, 275), (430, 257), (433, 294)], fill=rgba(0x5064DF, 94))

    draw.text((40, 392), "1. 打开 DMG   2. 拖拽安装   3. 授权输入监控", fill=rgba(0x405072, 184), font=font(14, chinese=True))
    return img


def main() -> None:
    ASSETS.mkdir(parents=True, exist_ok=True)
    RESOURCES.mkdir(parents=True, exist_ok=True)
    ICONSET.mkdir(parents=True, exist_ok=True)

    icon_files = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]
    for name, size in icon_files:
        app_icon(size).save(ICONSET / name)

    app_icon(1024).save(RESOURCES / "AppIconPreview.png")
    status_template().save(RESOURCES / "StatusTemplate.png")
    dmg_background().save(RESOURCES / "DMGBackground.png")

    icon_path = RESOURCES / "AppIcon.icns"
    subprocess.run(
        ["/usr/bin/iconutil", "-c", "icns", "-o", str(icon_path), str(ICONSET)],
        check=True,
    )
    print(f"Generated app icon, menu bar icon, and DMG background in {RESOURCES}")


if __name__ == "__main__":
    main()
