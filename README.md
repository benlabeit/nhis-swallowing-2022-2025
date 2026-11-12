# Swallowing difficulties in older US adults: NHIS 2022 and 2025

Reproducible analyses of NHIS public-use Sample Adult data on reported swallowing difficulties among adults aged 65 years and older, including a subgroup with a history of stroke.

## Manuscript and results

- [Current BMC Geriatrics manuscript with live Zotero fields](outputs/bmc_geriatrics/Manuscript_BMC_Geriatrics_Zotero.docx)
- [Manuscript and four submission figures](outputs/bmc_geriatrics/BMC_Geriatrics_Manuscript_and_Figures.zip)
- [Plain-text manuscript](outputs/bmc_geriatrics/Manuscript_BMC_Geriatrics.txt)
- [References, citation style and manuscript instructions](outputs/bmc_geriatrics/)

The age-standardized prevalence difference (2025 minus 2022) was +0.57 percentage points (95% CI -0.40 to +1.55) overall and +6.27 points (1.08 to 11.47) among stroke survivors. The subgroup finding is exploratory and sensitive to respondent selection; its confidence interval included zero in the confirmed-self-response analysis. These repeated cross-sections do not establish individual change or causal effects. See the manuscript for methods and limitations.

## Reproduce the analyses

Run from the repository root with R 4.6.0 or a compatible installation:

```sh
python -m pip install -r requirements-python.txt
Rscript outputs/00_setup.R
Rscript outputs/01_prepare.R
Rscript outputs/02_analyse.R
Rscript outputs/03_validate.R
Rscript outputs/04_extensions.R
Rscript outputs/05_figures.R
Rscript outputs/06_extension_figure.R
python work/build_figure_bundle.py
```

Setup installs missing R packages under `work/Rlib` and downloads CDC documentation. Preparation automatically downloads missing data ZIPs directly from the CDC into `work/raw/`, extracts them and creates a separate working dataset. Internet access is required for downloads. Source records are not overwritten; downloaded data and derived individual-record datasets are excluded from version control. The scripts reproduce analyses and figures without overwriting the author-edited manuscript.

## Data sources and use

The current repository does not bundle the original data archives. Obtain them directly from the CDC, either through the preparation script above or these links:

| Survey year | Adult records | Official data | Documentation |
|---|---:|---|---|
| 2022 | 27,651 | [Adult CSV ZIP](https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2022/adult22csv.zip) | [CDC documentation](https://www.cdc.gov/nchs/nhis/documentation/2022-nhis.html) |
| 2025 | 24,215 | [Adult CSV ZIP](https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2025/adult25csv.zip) | [CDC documentation](https://www.cdc.gov/nchs/nhis/documentation/2025-nhis.html) |

The [source-data manifest](outputs/data_original/original_data_manifest.tsv) records URLs, SHA-256 checksums, sizes and record counts for reproducibility. See the [data notes](outputs/data_original/README.txt) for handling details. Earlier Git revisions still contain the archives; the existing history has been preserved.

Source: NCHS, National Health Interview Survey, 2022 and 2025 public-use data. NHIS data-use terms apply, including the prohibition on attempted identification or linkage to identifiable records. Analyses and conclusions are those of the authors and do not represent NCHS positions. Official data-use terms and third-party rights remain applicable; no additional license for the manuscript or project materials is asserted here.

## Repository guide

- `outputs/00_setup.R` through `06_extension_figure.R`: setup, preparation, analysis, validation and figures.
- [Analysis plan](outputs/Analysis_Plan.txt) and [addendum](outputs/Analysis_Plan_Addendum.txt): prespecified and exploratory methods.
- `outputs/*.tsv` and `outputs/extensions/`: aggregate results, checks and sensitivity analyses. Prevalence estimates and differences in `standardized_results.tsv` and `extensions/additional_results.tsv` use a 0–1 scale; multiply by 100 for percentages or percentage points.
- `outputs/figures/`: analysis plots and captions; `outputs/bmc_geriatrics/`: current manuscript and submission materials.
- [Package versions](outputs/package_versions.tsv): recorded software versions. Setup uses available CRAN packages rather than a locked environment.

## Additional dementia sensitivity analysis

The [dementia sensitivity analysis](outputs/dementia_sensitivity/README.md) adds reported physician-diagnosed dementia to the age- and sex-adjusted year-by-stroke model, retaining proxy responses. Run `Rscript outputs/07_dementia_sensitivity.R` separately from the original pipeline. Code, complete-case comparisons, aggregate results and validation checks are provided; the primary analysis is unchanged.

