"""Development evidence only. Requires PyMuPDF (pip install PyMuPDF).
Run after: dart run tool/probe_persian_pdf.dart
Exit 0 means evidence captured, NOT that the PDF feature passed acceptance.
"""
from pathlib import Path
import json
import unicodedata
import pymupdf

folder = Path('docs/validation/stage17/pdf')
doc = pymupdf.open(folder / 'persian-probe.pdf')
visual_lines = []
for i, page in enumerate(doc):
    # Rasterize every page, not only the first-page preview.
    page.get_pixmap(matrix=pymupdf.Matrix(1.5, 1.5)).save(folder / f'page-{i+1}.png')
    if i == 0:
        for block in page.get_text('rawdict')['blocks']:
            for line in block.get('lines', []):
                chars = [c for span in line['spans'] for c in span['chars']]
                ordered = sorted(chars, key=lambda c: c['bbox'][0])
                visual_lines.append(unicodedata.normalize('NFKC', ''.join(c['c'] for c in ordered)))

temperature_lines = [line for line in visual_lines if 'F' in line and 'C' in line]
broken_temperature_units = any('F°' in line or 'C°' in line for line in temperature_lines)
report = {
    'candidate': 'pdf 3.13.1; default use_bidi=true; local Vazirmatn Regular/Bold',
    'renderer': f'PyMuPDF {pymupdf.VersionBind}',
    'pages': len(doc),
    'all_pages_rasterized': True,
    'temperature_visual_lines_left_to_right': temperature_lines,
    'temperature_unit_direction_failure': broken_temperature_units,
    'manual_review': 'page-1.png: Persian glyphs are mostly joined, but F°/C° reversed, negative/percent and ROI parentheses misordered; mixed NPV/amount/currency association is unreliable.',
    'application_pdf_export_enabled': False,
    'gate': 'FAIL: mixed-direction correctness required, not merely joined letters',
    'first_page_visual_glyph_order': visual_lines,
}
(folder / 'render-report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n')
print(json.dumps({k:v for k,v in report.items() if k!='first_page_visual_glyph_order'}, ensure_ascii=False, indent=2))
if not broken_temperature_units:
    raise SystemExit('Expected repro not observed: repeat human review; do not automatically enable PDF.')
