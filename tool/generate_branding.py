"""Generate final launcher assets from the existing project logo; no network.
Requires Pillow (development tool only). --check never modifies files.
"""
import argparse
from io import BytesIO
from pathlib import Path
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parent.parent
BACKGROUND = (234, 246, 246, 255)


def render_assets():
    logo = Image.open(ROOT / 'assets/branding/logo.png').convert('RGBA')
    r, g, b, _ = logo.split()
    mask = ImageChops.multiply(r.point(lambda x: 255 if x < 80 else 0),
                              g.point(lambda x: 255 if x < 120 else 0))
    mask = ImageChops.multiply(mask, b.point(lambda x: 255 if x < 180 else 0))
    bounds = mask.getbbox()
    if bounds is None:
        raise ValueError('Existing navy logo cannot be located')
    left, top, right, bottom = bounds
    mark = logo.crop((max(0, left - 8), max(0, top - 8),
                      min(logo.width, right + 8), min(logo.height, bottom + 8)))

    def canvas(size, ratio, transparent=False):
        output = Image.new('RGBA', (size, size), (0, 0, 0, 0) if transparent else BACKGROUND)
        image = mark.copy()
        edge = round(size * ratio)
        image.thumbnail((edge, edge), Image.Resampling.LANCZOS)
        output.alpha_composite(image, ((size - image.width) // 2, (size - image.height) // 2))
        return output

    result = {}

    def png(path, image):
        data = BytesIO()
        image.save(data, format='PNG', optimize=False)
        result[path] = data.getvalue()

    for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                          ('xxhdpi', 144), ('xxxhdpi', 192)]:
        png(f'android/app/src/main/res/mipmap-{density}/ic_launcher.png', canvas(size, .72))
    png('android/app/src/main/res/drawable-nodpi/ic_launcher_foreground.png', canvas(432, 48 / 108, True))
    png('android/app/src/main/res/drawable-nodpi/splash_logo.png', canvas(768, .44, True))
    png('android/app/src/main/res/drawable-nodpi/legacy_splash_logo.png', canvas(512, .72, True))
    data = BytesIO()
    canvas(256, .78).save(data, format='ICO', sizes=[(s, s) for s in [16, 24, 32, 48, 64, 128, 256]])
    result['windows/runner/resources/app_icon.ico'] = data.getvalue()
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    stale = []
    for name, data in render_assets().items():
        file = ROOT / name
        if args.check:
            if not file.is_file() or file.read_bytes() != data:
                stale.append(name)
        else:
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_bytes(data)
    if stale:
        parser.exit(1, 'Stale branding files: ' + ', '.join(stale) + '\n')
    print('Branding assets verified' if args.check else 'Branding assets generated from the preserved local logo')


if __name__ == '__main__':
    main()
