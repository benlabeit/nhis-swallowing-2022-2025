"""Combine the four generated figure pages and rebuild the English figure ZIP.

Run after outputs/05_figures.R and outputs/06_extension_figure.R. This operation
uses only saved figure files and tables; it performs no statistical estimation.
"""
from pathlib import Path
from pypdf import PdfReader, PdfWriter
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib

root = Path(__file__).resolve().parents[1]
figures = root / 'outputs/figures'
combined = figures / 'NHIS_Figures_EN.pdf'
fourth = figures / 'Figure_4_Stroke_robustness.pdf'
first = PdfReader(combined)
last = PdfReader(fourth)
assert len(first.pages) in (3, 4), 'Expected the original three figures, or an earlier four-page bundle.'
assert len(last.pages) == 1
writer = PdfWriter()
for page in first.pages[:3]:
    writer.add_page(page)
writer.add_page(last.pages[0])
writer.add_metadata({'/Title': 'NHIS 2022 and 2025: four English figures', '/Subject': 'Saved survey-analysis figures; no re-estimation'})
temporary = figures / '_combined_figures.tmp.pdf'
with temporary.open('wb') as stream:
    writer.write(stream)
first.close()
last.close()
temporary.replace(combined)
assert len(PdfReader(combined).pages) == 4

inputs = ['outputs/05_figures.R', 'outputs/06_extension_figure.R',
          'outputs/cell_counts.tsv', 'outputs/standardized_results.tsv',
          'outputs/extensions/primary_comparison_all_methods.tsv',
          'work/build_figure_bundle.py']
bundle = root / 'outputs/NHIS_Figures_EN.zip'
with ZipFile(bundle, 'w', compression=ZIP_DEFLATED, compresslevel=9) as archive:
    for rel in inputs:
        archive.write(root / rel, rel)
    for path in sorted(figures.iterdir()):
        if path.is_file() and not path.name.startswith('_'):
            archive.write(path, path.relative_to(root).as_posix())
with ZipFile(bundle) as archive:
    assert archive.testzip() is None
print(f'Combined PDF: 4 pages, {combined.stat().st_size:,} bytes')
print(f'Four-figure bundle: {bundle.stat().st_size:,} bytes; SHA256 {hashlib.sha256(bundle.read_bytes()).hexdigest()}')
