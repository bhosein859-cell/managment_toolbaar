"""Source resource validation only; NOT Android/Windows native execution."""
import re
import struct
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RES = ROOT / 'android/app/src/main/res'
ANDROID = '{http://schemas.android.com/apk/res/android}'


class FinalAssetsTest(unittest.TestCase):
    def test_launcher_png_sizes(self):
        for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                              ('xxhdpi', 144), ('xxxhdpi', 192)]:
            data = (RES / f'mipmap-{density}/ic_launcher.png').read_bytes()
            self.assertEqual(data[:8], b'\x89PNG\r\n\x1a\n')
            self.assertEqual(struct.unpack('>II', data[16:24]), (size, size))

    def test_ico_contains_all_final_sizes_and_is_wired(self):
        data = (ROOT / 'windows/runner/resources/app_icon.ico').read_bytes()
        reserved, kind, count = struct.unpack('<HHH', data[:6])
        self.assertEqual((reserved, kind, count), (0, 1, 7))
        sizes = set()
        for index in range(count):
            width, height, _, _, _, _, length, offset = struct.unpack(
                '<BBBBHHII', data[6 + index * 16:22 + index * 16])
            sizes.add((width or 256, height or 256))
            self.assertLessEqual(offset + length, len(data))
            self.assertGreater(length, 0)
        self.assertEqual(sizes, {(s, s) for s in [16, 24, 32, 48, 64, 128, 256]})
        rc = (ROOT / 'windows/runner/Runner.rc').read_text()
        self.assertIn('resources\\\\app_icon.ico', rc)
        self.assertIn('Hossein Bakhtiari', rc)

    def test_android_legacy_and_12_splashes_day_night(self):
        for density in ['drawable', 'drawable-v21']:
            tree = ET.parse(RES / density / 'launch_background.xml')
            bitmap = tree.find('.//bitmap')
            self.assertEqual(bitmap.attrib[ANDROID + 'src'], '@drawable/legacy_splash_logo')
        for folder in ['values', 'values-night', 'values-v31', 'values-night-v31']:
            tree = ET.parse(RES / folder / 'styles.xml')
            launch = tree.find("style[@name='LaunchTheme']")
            self.assertIsNotNone(launch)
            if 'v31' in folder:
                fields = {i.attrib['name']: i.text for i in launch.findall('item')}
                self.assertEqual(fields['android:windowSplashScreenAnimatedIcon'], '@drawable/splash_logo')
        for name in ['splash_logo.png', 'legacy_splash_logo.png', 'ic_launcher_foreground.png']:
            self.assertTrue((RES / 'drawable-nodpi' / name).is_file())

    def test_adaptive_icon_and_manifest_reference(self):
        icon = ET.parse(RES / 'mipmap-anydpi-v26/ic_launcher.xml')
        self.assertEqual(icon.getroot().tag, 'adaptive-icon')
        self.assertEqual(icon.find('foreground').attrib[ANDROID + 'drawable'], '@drawable/ic_launcher_foreground')
        manifest = ET.parse(ROOT / 'android/app/src/main/AndroidManifest.xml')
        self.assertEqual(manifest.find('application').attrib[ANDROID + 'icon'], '@mipmap/ic_launcher')
        gradle = (ROOT / 'android/app/build.gradle.kts').read_text()
        self.assertRegex(gradle, r'minSdk\s*=\s*26\b')

    def test_no_debug_print_calls_in_production_dart(self):
        for path in (ROOT / 'lib').rglob('*.dart'):
            self.assertIsNone(re.search(r'\b(?:print|debugPrint)\s*\(', path.read_text()), str(path))


if __name__ == '__main__':
    unittest.main()
