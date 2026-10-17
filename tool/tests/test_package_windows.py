import hashlib
import json
from pathlib import Path
import tempfile
import unittest
import zipfile
from tool.package_windows import REQUIRED, package, validate_bundle

class WindowsPackageTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / 'Release'
        self.source.mkdir()

    def complete(self):
        for name in (*REQUIRED, 'sqlite3.dll', 'native_assets/extra.dll', 'readme.txt'):
            file = self.source / name
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_bytes(b'Synthetic test fixture, NOT an actual executable')

    def test_exe_alone_is_rejected(self):
        (self.source / 'management_toolbox.exe').write_bytes(b'not an executable')
        with self.assertRaisesRegex(ValueError, 'Incomplete'):
            validate_bundle(self.source)

    def test_complete_tree_is_preserved_with_checksums(self):
        self.complete()
        archive = self.root / 'bundle.zip'
        inventory = package(self.source, archive)
        with zipfile.ZipFile(archive) as z:
            names = set(z.namelist())
            for item in inventory:
                name = 'management_toolbox/' + item['path']
                self.assertIn(name, names)
                self.assertEqual(z.read(name), (self.source / item['path']).read_bytes())
                self.assertEqual(hashlib.sha256(z.read(name)).hexdigest(), item['sha256'])
            report = json.loads(z.read('management_toolbox/bundle-manifest.json'))
            self.assertEqual(report['files'], inventory)
            self.assertIn('management_toolbox/native_assets/extra.dll', names)
        checksum = archive.with_suffix('.zip.sha256').read_text().split()[0]
        self.assertEqual(hashlib.sha256(archive.read_bytes()).hexdigest(), checksum)

    def test_native_sqlite_is_required(self):
        self.complete()
        (self.source / 'sqlite3.dll').unlink()
        with self.assertRaisesRegex(ValueError, 'SQLite'):
            validate_bundle(self.source)

    def test_missing_assets_are_rejected(self):
        self.complete()
        (self.source / REQUIRED[-1]).unlink()
        with self.assertRaisesRegex(ValueError, 'Incomplete'):
            validate_bundle(self.source)

    def test_empty_dll_is_rejected(self):
        self.complete()
        (self.source / 'flutter_windows.dll').write_bytes(b'')
        with self.assertRaisesRegex(ValueError, 'empty'):
            validate_bundle(self.source)

    def test_output_inside_input_is_rejected(self):
        self.complete()
        with self.assertRaisesRegex(ValueError, 'outside'):
            package(self.source, self.source / 'recursive.zip')

    def test_reserved_manifest_collision_is_rejected(self):
        self.complete()
        (self.source / 'bundle-manifest.json').write_text('{}')
        with self.assertRaisesRegex(ValueError, 'Reserved'):
            package(self.source, self.root / 'bundle.zip')

    def test_symlink_is_rejected(self):
        self.complete()
        link = self.source / 'external-link.dll'
        external = self.root / 'secret-not-a-real-secret.txt'
        external.write_text('synthetic outside fixture')
        try:
            link.symlink_to(external)
        except (OSError, NotImplementedError):
            self.skipTest('Host disallows creating symbolic links')
        with self.assertRaisesRegex(ValueError, 'link'):
            validate_bundle(self.source)

if __name__ == '__main__':
    unittest.main()
