NHIS figures - English-only collection
Version: 6 November 2026

Figure 1: Age-standardized prevalence of swallowing difficulties, by stroke history.
Figure 2: Absolute prevalence differences (2025 minus 2022), by outcome and stroke history.
Figure 3: Sensitivity of the primary-outcome comparison to survey period and missing responses.
Figure 4: Stroke-group differences across primary, adjusted and confirmed-self-response analyses.

Open Figures.html for a preview. NHIS_Figures_EN.pdf contains Figures 1-3. Figure_4_Stroke_robustness.pdf provides Figure 4 separately.
Each figure is also provided as a 300 dpi PNG and a scalable SVG.
The separate Figure_captions_EN.txt provides manuscript captions, methods and limitations.
All figure text, captions and filenames in this collection are in English.

Reproduction
Extract the ZIP into an empty directory. From its root, run:
Rscript outputs/05_figures.R
Rscript outputs/07_extension_figure.R

Requires R, the included grid package, Cairo graphics support, and Arial or a substitute font.
Inputs: outputs/standardized_results.tsv, outputs/cell_counts.tsv and outputs/extensions/primary_comparison_all_methods.tsv, all included.
Outputs are written to outputs/figures/. No statistical analyses are rerun.
No network access or additional R packages are required for figure generation.
Software details and input checks are recorded in software_figures.txt and figure_validation.txt.

PNG width: 2700 pixels (9 inches at 300 dpi). Check readability when reducing size.
All four figure pages have been rendered and visually checked.
The English-only collection supersedes the bilingual collection for current use.

Source: NCHS, NHIS 2022 and 2025 public-use files; authors' calculations.
The underlying analysis remains a research working version, not an NCHS-certified release.
