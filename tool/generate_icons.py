"""Regenerate platform icons from the selected AI-generated logo.
Run from project root after installing Pillow: python tool/generate_icons.py
This is a development tool, not a runtime dependency.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
image = Image.open(ROOT / 'assets/branding/logo.png').convert('RGBA')
image.thumbnail((1024, 1024), Image.Resampling.LANCZOS)
canvas = Image.new('RGBA', (1024, 1024), (244, 247, 250, 255))
canvas.alpha_composite(image, ((1024 - image.width) // 2, (1024 - image.height) // 2))
canvas.convert('RGB').save(ROOT / 'assets/branding/app_icon.png')
for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
    canvas.resize((size, size), Image.Resampling.LANCZOS).save(
        ROOT / f'android/app/src/main/res/mipmap-{density}/ic_launcher.png'
    )
canvas.save(ROOT / 'windows/runner/resources/app_icon.ico',
            sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
