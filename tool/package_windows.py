"""Validate and archive a COMPLETE x64 Windows Release folder, never an EXE alone.
Run on a Windows build host after `flutter build windows --release`.
No build, signing, system-DLL download, or installation is performed here.
"""
import argparse
import hashlib
import json
from pathlib import Path
import zipfile

REQUIRED = (
    'management_toolbox.exe', 'flutter_windows.dll',
    'share_plus_plugin.dll', 'url_launcher_windows_plugin.dll',
    'data/app.so', 'data/icudtl.dat',
    'data/flutter_assets/AssetManifest.bin',
    'data/flutter_assets/assets/branding/logo.png',
    'data/flutter_assets/assets/fonts/Vazirmatn-Regular.ttf',
    'data/flutter_assets/assets/fonts/Vazirmatn-Bold.ttf',
    'data/flutter_assets/assets/fonts/OFL.txt',
)

def validate_bundle(source):
    source = Path(source).resolve()
    if (source / 'bundle-manifest.json').exists():
        raise ValueError('Reserved bundle-manifest.json already exists; use a fresh Release tree')
    missing = [name for name in REQUIRED if not (source / name).is_file()]
    if missing:
        raise ValueError('Incomplete Release bundle; missing: ' + ', '.join(missing))
    files = sorted(p for p in source.rglob('*') if p.is_file())
    if any(not p.resolve().is_relative_to(source) for p in files):
        raise ValueError('Bundle contains a link to a file outside the Release directory')
    if any(p.is_symlink() for p in source.rglob('*')):
        raise ValueError('Bundle must contain real files, not symbolic links')
    if not any('sqlite3' in p.name.lower() and p.suffix.lower() == '.dll' for p in files):
        raise ValueError('SQLite native DLL is missing; do not publish an EXE-only bundle')
    if any(p.stat().st_size == 0 for p in files):
        raise ValueError('Bundle contains empty files; inspect build output before packaging')
    return files

def package(source, destination):
    source = Path(source).resolve()
    destination = Path(destination).resolve()
    if destination.is_relative_to(source):
        raise ValueError('Output ZIP must be outside the input Release folder')
    files = validate_bundle(source)
    inventory = [{'path': p.relative_to(source).as_posix(), 'bytes': p.stat().st_size,
                  'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in files]
    destination.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(destination, 'w', zipfile.ZIP_DEFLATED) as archive:
        for p in files:
            archive.write(p, 'management_toolbox/' + p.relative_to(source).as_posix())
        archive.writestr('management_toolbox/bundle-manifest.json', json.dumps({
            'architecture': 'windows-x64',
            'note': 'Includes the entire Release tree. Package validation is not execution or signature verification. Install the Microsoft VC++ x64 runtime on target machines when required.',
            'files': inventory,
        }, indent=2))
    digest = hashlib.sha256(destination.read_bytes()).hexdigest()
    destination.with_suffix(destination.suffix + '.sha256').write_text(digest + '  ' + destination.name + '\n')
    return inventory

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', default='build/windows/x64/runner/Release')
    parser.add_argument('--output', default='releases/management_toolbox-windows-x64.zip')
    args = parser.parse_args()
    try:
        inventory = package(args.source, args.output)
    except ValueError as error:
        parser.exit(1, str(error) + '\n')
    print(f'Complete Release tree packaged: {len(inventory)} files. Native launch/signature validation remains separate.')
