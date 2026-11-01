from PIL import Image, ImageDraw
import json
import os

import numpy as np

ROOT = r'D:\dsh\dsh工作区\yiri'
SOURCE = os.path.join(ROOT, 'design', 'app_icon_source.jpg')
BG = (250, 250, 248, 255)
DARK = (28, 28, 30, 255)

source = Image.open(SOURCE).convert('RGB')

# Full-bleed icon: keep the supplied artwork composition.
def full_icon(size):
    return source.resize((size, size), Image.LANCZOS).convert('RGB')

# Legacy Android icon: off-white rounded square with the artwork.
def rounded_icon(size):
    rounded = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    mask = Image.new('L', (size, size), 0)
    draw = ImageDraw.Draw(mask)
    radius = int(size * 0.22)
    draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    rounded.paste(source.resize((size, size), Image.LANCZOS).convert('RGBA'), (0, 0), mask)
    return rounded

# Extract the black brush strokes as a transparent foreground.  Ignore the
# few stray JPEG marks at the edges when finding the main glyph bounds.
gray = np.asarray(source.convert('L'))
ink = gray < 100
rows = np.where(ink.sum(axis=1) > 5)[0]
cols = np.where(ink.sum(axis=0) > 5)[0]
min_x, max_x = int(cols.min()), int(cols.max())
min_y, max_y = int(rows.min()), int(rows.max())

alpha = Image.new('L', source.size, 0)
alpha_data = alpha.load()
pixels = source.load()
for y in range(source.height):
    for x in range(source.width):
        r, g, b = pixels[x, y]
        luminance = (r * 299 + g * 587 + b * 114) // 1000
        value = 0 if luminance > 235 else min(255, int((235 - luminance) * 255 / 210))
        alpha_data[x, y] = value

glyph = Image.new('RGBA', source.size, (0, 0, 0, 0))
glyph.putalpha(alpha)
glyph = glyph.crop((min_x, min_y, max_x + 1, max_y + 1))
print('glyph bbox', (min_x, min_y, max_x, max_y), 'size', glyph.size)

# Adaptive foreground 432x432: glyph inside 66% safe zone.
foreground = Image.new('RGBA', (432, 432), (0, 0, 0, 0))
target = 250
scale = min(target / glyph.width, target / glyph.height)
glyph_resized = glyph.resize(
    (max(1, int(glyph.width * scale)), max(1, int(glyph.height * scale))),
    Image.LANCZOS,
)
foreground.alpha_composite(
    glyph_resized,
    ((432 - glyph_resized.width) // 2, (432 - glyph_resized.height) // 2),
)
foreground_path = os.path.join(
    ROOT, 'android', 'app', 'src', 'main', 'res', 'drawable-nodpi',
    'ic_launcher_foreground.png',
)
os.makedirs(os.path.dirname(foreground_path), exist_ok=True)
foreground.save(foreground_path)

# Android legacy mipmaps.
for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
    folder = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res', f'mipmap-{density}')
    os.makedirs(folder, exist_ok=True)
    rounded_icon(size).save(os.path.join(folder, 'ic_launcher.png'))
    rounded_icon(size).save(os.path.join(folder, 'ic_launcher_round.png'))

# iOS AppIcon sizes from Contents.json.
appicon = os.path.join(ROOT, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
with open(os.path.join(appicon, 'Contents.json'), encoding='utf-8-sig') as handle:
    contents = json.load(handle)
for item in contents['images']:
    filename = item.get('filename')
    if not filename:
        continue
    size = float(item['size'].split('x')[0])
    scale = int(item['scale'].replace('x', ''))
    pixel_size = int(round(size * scale))
    full_icon(pixel_size).save(os.path.join(appicon, filename), format='PNG')
print('icons generated')
