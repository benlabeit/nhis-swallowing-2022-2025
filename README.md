# Swallowing difficulties in US adults in 2022 and 2025

The current primary analysis includes **all adults aged 18 years or older**, with the overall population comparison reported first and a separate central analysis of adults reporting a stroke history. This revision replaces the previous primary restriction to adults aged 65 years or older. NHIS consists of repeated cross-sectional surveys of the civilian noninstitutionalized US population; reported symptoms are not clinically confirmed dysphagia.

## Current findings

| Population | Age-standardized prevalence 2022 | Age-standardized prevalence 2025 | Difference in percentage points, 95% CI |
| --- | ---: | ---: | ---: |
| All adults | 6.11% | 5.18% | −0.93 (−1.43 to −0.42) |
| Adults with stroke history | 12.49% | 21.15% | +8.66 (−1.03 to +18.35) |
| Adults without stroke history | 5.91% | 4.88% | −1.03 (−1.53 to −0.53) |

The overall prevalence was lower in 2025. Stroke-group point estimates were higher, but the principal age-standardized change was imprecise and its confidence interval included zero. Crude stroke prevalence was 14.02% versus 19.22%, a difference of +5.20 points (0.89 to 9.52). The stroke estimate was sensitive to standardization and restriction to confirmed self-responses. Sparse younger stroke cells carry substantial weight in the common adult standard. These findings do not establish individual trajectories, clinical deterioration or causal effects.

## Current deliverables

- [Anonymized English manuscript](outputs/all_adults/manuscript/NHIS_All_Adults_Manuscript.docx), formatted for Dysphagia.
- [Identified master with live Zotero citations](outputs/all_adults/manuscript/NHIS_All_Adults_Zotero_Master.docx).
- [Author information](outputs/all_adults/manuscript/NHIS_All_Adults_Author_Information.docx).
- [Complete revised research package](outputs/all_adults/NHIS_All_Adults_Research_Package.zip), containing source data, reproducible analysis, figures, manuscript builders and citation exports.
- [Collected analysis results](outputs/all_adults/Analysis_Results.csv), with prevalence in percent and differences in percentage points.
- [Analysis specification](outputs/all_adults/Analysis_Plan.txt) and its dated checksum.
- [English figures](outputs/all_adults/figures), four main figures and one supplementary figure, with original numerical values in the complete package.

The identified master and research archive contain author information and are not anonymous reviewer files. No journal submission has been made. Existing author checks remain in `outputs/author_checks.txt`; author contributions, study-specific disclosures and the institutional ethics/consent determination require the authors' confirmation before submission.

## Revised analysis and reproducibility

The analysis hierarchy was revised on 8 November 2026 at the investigator's request after the earlier ≥65-year analysis and unweighted feasibility counts had been inspected. The new plan was hashed before weighted all-adult outcomes were examined. It is not an external preregistration. Earlier files under `outputs/dysphagia`, `outputs/extensions` and the repository root's `NHIS_Research_Package.zip` remain historical versions, not the current all-adult findings.

Extract the current research package to a new folder and run from its root with R and Python dependencies installed:

```text
Rscript outputs/all_adults/00_prepare_all_adults.R
Rscript outputs/all_adults/01_analyse_all_adults.R
Rscript work/all_adults/independent_primary_check.R
Rscript work/all_adults/build_figures.R
python work/all_adults/build_manuscript.py
```

R requires `survey` and `numDeriv`; the original run used R 4.6.0 and survey 4.5. Figure generation additionally requires R with Cairo graphics support and the Arial font. Substituting fonts can change the layout and requires renewed figure inspection. Python document work requires `python-docx`, `lxml`, `Pillow` and `pypdf`. The package preserves project-relative paths. See `outputs/all_adults/README.txt` and recorded session information for exact inputs and outputs. Run the supplied figure check helper after regenerating figures. Regenerated Word documents need renewed visual inspection, and the identified master should be refreshed with the Zotero Word add-in if citations are edited. Saved audit reports describe the delivered run, not a future regeneration.

The full survey design is declared before domain restrictions, using annual adult weights, public-use strata and PSUs without year prefixes, as instructed by NCHS. Direct age standardization uses the US 2000 adult population in five age groups: 18–44, 45–64, 65–74, 75–84 and 85+. The same standard is applied to both years and every stroke group. Crude estimates describe the actual weighted population composition. Age-and-sex model margins use the same age standard with a fixed 50:50 sex distribution and are hypothetical standardized estimates.

Unrounded estimates and covariance outputs are in `outputs/all_adults/`. Prevalence result tables use proportions, and temporal contrasts use differences in proportions; multiply either by 100 to obtain percentages or percentage points. Explicitly named percent-unit summaries and `Analysis_Results.csv` already apply this conversion. Logistic-regression coefficient files instead use log-odds, and covariance matrices use the squared units of their corresponding estimates. Primary estimates and standard errors were independently reproduced using weighted arithmetic and explicit PSU-level Taylor covariance, in addition to the main script's saturated-model and numerical-gradient checks. Counts, missing responses and precision flags are retained. The 2025 collection interruption, missing outcomes and different response-status classifications constrain comparison. The quarters 1–3 sensitivity retains annual weights without recalibration. Intervals are nominal; supporting comparisons and secondary outcomes are exploratory without multiplicity adjustment.

## Original data

The exact downloaded and extracted source tables are preserved unchanged in the complete package, before analytical exclusions:

| Year | Records | Variables | Official download |
| --- | ---: | ---: | --- |
| 2022 | 27,651 | 637 | [Original Adult CSV archive](https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2022/adult22csv.zip) |
| 2025 | 24,215 | 577 | [Original Adult CSV archive](https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2025/adult25csv.zip) |

Both downloads are also clickable in the manuscript. Source CSVs are under `outputs/data_original/`; unchanged ZIP archives are under `work/raw/`. `outputs/data_original/original_data_manifest.tsv` records SHA-256 checksums, sizes, dimensions and source URLs. The current package includes both survey-description PDFs. Full codebooks and variable summaries can be downloaded from the [2022 documentation](https://www.cdc.gov/nchs/nhis/documentation/2022-nhis.html) and [2025 documentation](https://www.cdc.gov/nchs/nhis/documentation/2025-nhis.html); they are not required to run the revised analysis from the included CSVs.

## Literature and Zotero

The manuscript retains 25 verified sources and 19 live citation clusters in the identified master. The anonymized copy has static Zotero-generated references. The targeted narrative literature search, evidence tables and native exports are included under `outputs/literature/`. The journal-specific citation export and CSL are in `work/dysphagia/` inside the package. The earlier source manuscript is retained solely as a formatting and citation-field input. Reference identifiers refer to the original Zotero library; another library requires importing and remapping references rather than reusing identifiers blindly. No unrelated source manuscript is included.

The repository is private. NHIS data-use conditions apply, including restrictions on attempted identification. Analyses and interpretations are those of the project authors, not official NCHS findings. No new license or external endorsement is asserted. The package manifest records every packaged file's size and checksum; software binaries and individual-record prepared RDS files are excluded.
