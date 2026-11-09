# Swallowing difficulties in older US adults: NHIS 2022 and 2025

Reproducible analyses of National Health Interview Survey (NHIS) public-use Sample Adult data. This study compares reported swallowing difficulties in the preceding 12 months among adults aged 65 years and older, including a prespecified subgroup with a history of stroke.

## Current manuscript and downloads

The current manuscript is **Swallowing Difficulties in Older US Adults: Higher Prevalence Among Stroke Survivors in 2025 Than in 2022**, formatted for **BMC Geriatrics** on 9 November 2026.

- [Current BMC Geriatrics manuscript with live Zotero fields](outputs/bmc_geriatrics/Manuscript_BMC_Geriatrics_Zotero.docx)
- [BMC manuscript and four separate submission figures](outputs/bmc_geriatrics/BMC_Geriatrics_Manuscript_and_Figures.zip)
- [Plain-text manuscript](outputs/bmc_geriatrics/Manuscript_BMC_Geriatrics.txt)
- [Current references and Zotero style](outputs/bmc_geriatrics/)
- [Original-data manifest and download links](outputs/data_original/original_data_manifest.tsv)
- [Download the entire current repository](https://github.com/benlabeit/nhis-swallowing-2022-2025/archive/refs/heads/main.zip)

The Word manuscript contains 42 live Zotero citation fields, one live bibliography with 34 references, three editable tables and four figure legends. Its four submission figures are separate PNG files in [outputs/bmc_geriatrics/figures/](outputs/bmc_geriatrics/figures/). Install the supplied [Zotero style](outputs/bmc_geriatrics/nhis-bmc-geriatrics.csl) before refreshing the document on another computer. Scientific text, results and figure content were not changed by the journal-format conversion or this repository update.

Superseded Dysphagia manuscripts and static research packages have been removed from the current file tree. Earlier versions remain available in Git history. The whole-repository download above always reflects the current branch and avoids distributing an outdated manuscript inside an older archive.

## Findings and interpretation

The primary directly age-standardized overall prevalence difference, 2025 minus 2022, was +0.57 percentage points (95% CI -0.40 to +1.55). The stroke-history subgroup difference was +6.27 points (1.08 to 11.47). In the confirmed-self-response sensitivity analysis, the stroke-group difference was +4.53 points (-0.42 to +9.48), or +4.05 points (-0.78 to +8.88) after additional age/sex model standardization. The subgroup finding is exploratory and sensitive to the responding population.

These are repeated cross-sections, not individual follow-up observations. Reported swallowing difficulties are not clinically confirmed dysphagia, and stroke history does not establish the cause of swallowing symptoms. The target population excludes institutionalized adults. The 2025 collection interruption, changed sampling design and asymmetric respondent-status classification limit comparisons. The analyses do not establish causal effects or a continuous temporal trend.

## Repository contents

| Location | Contents |
|---|---|
| `outputs/bmc_geriatrics/` | Current Word and text manuscript, separate figures, 34-reference export, citation style and verification |
| `outputs/Analysis_Plan.txt` | English translation of the original analysis plan, with provenance linking to the frozen original |
| `outputs/Analysis_Plan_Addendum.txt` | Original English addendum for exploratory age/sex adjustment and self-response analyses |
| `outputs/*.R` | Data preparation, survey estimation, validation and figure scripts |
| `outputs/*.tsv` | Aggregate results, sample flow, variable definitions, checksums and software versions |
| `outputs/extensions/` | Adjustment and self-response sensitivity results, cell counts and validation |
| `outputs/figures/` | English analysis plots, numeric plotting inputs, combined PDF and figure checks |
| `outputs/literature/` | Historical literature-search evidence and first-draft Zotero exports; the current 34-reference bibliography is under `outputs/bmc_geriatrics/` |
| `outputs/data_original/` | Source-data manifest and provenance instructions |
| `work/raw/` | Unchanged CDC data archives for both survey years |
| `work/build_figure_bundle.py` | Assembly of the four analysis-figure PDF pages |

Repository documentation and plot labels are in English. Proper names, reference metadata and original machine-generated software identifiers are preserved. The translation of the original plan does not alter its historical freeze record; see [analysis_plan_frozen.txt](outputs/analysis_plan_frozen.txt).

## Reproduce the analyses

Run from the repository root with R 4.6.0 or a compatible installation:

```sh
python -m pip install -r requirements-python.txt
Rscript outputs/00_setup.R
Rscript outputs/01_prepare.R
Rscript outputs/02_analyse.R
Rscript outputs/03_validate.R
Rscript outputs/06_extensions.R
Rscript outputs/05_figures.R
Rscript outputs/07_extension_figure.R
python work/build_figure_bundle.py
```

Setup installs missing R packages in `work/Rlib`, downloads the six official CDC codebooks, variable summaries and Survey Descriptions into `work/docs`, and extracts their text. Network access is needed for missing dependencies or documentation. The original data ZIPs are included; preparation extracts them and creates a separate working dataset. No original records are overwritten.

The main analysis uses `WTFA_A` weights, `PSTRAT` strata and `PPSU` clusters, with the design declared on all adult records before domain restrictions. Annual weights and public-use design identifiers are retained across years. Direct standardization uses the US 2000 population within ages 65+, with age groups 65-74, 75-84 and 85+. The model-based sensitivity margins use the same age weights crossed with 50% male and 50% female in each age group; these are fixed comparison margins rather than actual population prevalences.

`03_validate.R` independently checks estimates and covariance. `06_extensions.R` produces the exploratory additional analyses. The figure scripts plot saved results without refitting models. The Python assembly step requires `pypdf` and combines the original three-page figure PDF with Figure 4. Run it after both figure scripts to retain all four pages. Captions and figure documentation are maintained separately.

`04_report.R` was removed because it generated only an obsolete German feasibility report and was not used by the current analysis or figure workflow. The variable dictionary it formerly produced is retained in English as [variable_mapping.tsv](outputs/variable_mapping.tsv).

Exact recorded versions are in [package_versions.tsv](outputs/package_versions.tsv), [session_analysis.txt](outputs/session_analysis.txt), and [session_extensions.txt](outputs/extensions/session_extensions.txt). Setup installs available CRAN versions rather than a locked package snapshot. No compiled dependencies or derived individual-record datasets are committed. The scripts reproduce analyses and analysis plots; they do not overwrite the author-edited BMC manuscript.

## Result units

Results retain full numeric precision in the TSV files. Estimates and differences in `standardized_results.tsv` and `extensions/additional_results.tsv` use a 0-1 scale; multiply by 100 for percentages or percentage points. `extensions/manuscript_summary_percent_units.tsv` already uses percentage and percentage-point units. Secondary endpoints, subgroup contrasts and sensitivity analyses are exploratory without multiplicity adjustment. Project precision flags do not replace the complete NCHS Data Presentation Standards.

## Original data

| Survey year | Adult records | CSV columns | Unchanged source archive |
|---|---:|---:|---|
| 2022 | 27,651 | 637 | [adult22csv.zip](work/raw/adult22csv.zip) |
| 2025 | 24,215 | 577 | [adult25csv.zip](work/raw/adult25csv.zip) |

- [CDC NHIS 2022 documentation](https://www.cdc.gov/nchs/nhis/documentation/2022-nhis.html)
- [CDC NHIS 2025 documentation](https://www.cdc.gov/nchs/nhis/documentation/2025-nhis.html)
- [Official 2022 Adult CSV download](https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2022/adult22csv.zip)
- [Official 2025 Adult CSV download](https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2025/adult25csv.zip)

The [manifest](outputs/data_original/original_data_manifest.tsv) records source URLs, byte sizes, record counts and SHA-256 hashes for the archives and their unchanged CSV entries. The large CSVs are not duplicated in Git; preparation extracts them from the original ZIPs. `HHX` is a within-year identifier and must not be interpreted as a longitudinal person identifier.

## Source, data use and rights

Source: National Center for Health Statistics, National Health Interview Survey, 2022 and 2025 public-use data. Analyses, interpretations and conclusions are those of the project authors and do not represent NCHS positions. NHIS data-use terms apply, including the prohibition on attempted identification or linkage to identifiable records. No submission, journal acceptance or external endorsement is implied. No additional license for the manuscript or project materials is asserted here; official data-use terms and third-party rights remain applicable.
