NHIS 2022 AND 2025 SWALLOWING DIFFICULTIES AMONG ALL ADULTS
Revised primary analysis dated 8 November 2026

Current question
The primary population is all surveyed adults aged 18 years or older with known
age, followed by a separate central analysis among adults with stroke history.
The prior analysis restricted to ages 65 years or older is historical. This
change followed inspection of those earlier results and is not a preregistration.
Analysis_Plan.txt was frozen before weighted adult outcome estimates were seen;
Analysis_Plan_Freeze.txt records its timestamp and SHA-256 checksum.

Main findings
Age-standardized swallowing-difficulty prevalence decreased overall from 6.11%
in 2022 to 5.18% in 2025 (difference -0.93 percentage points, 95% CI -1.43 to -0.42).
In the stroke population the estimate increased from 12.49% to 21.15%, but the
directly standardized difference was imprecise (+8.66 points, 95% CI -1.03 to 18.35).
Only 5 and 11 affected stroke respondents were aged 18-44 in 2022 and 2025. That age
group receives 53.1% of the common adult standard population weight. Crude stroke
prevalence was 14.02% and 19.22%; its difference was +5.20 points (0.89 to 9.52).
Self-response restrictions attenuated the stroke difference. These are two
cross-sectional surveys, not longitudinal follow-up or evidence of causation.

Source data
The source is the NHIS Sample Adult public-use CSV table for each year. Both
unmodified tables are provided in outputs/data_original. The source manifest
records their dimensions, original download links, sizes and SHA-256 checksums.
2022: 27,651 rows, 637 columns; 2025: 24,215 rows, 577 columns. Original downloads:
https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2022/adult22csv.zip
https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2025/adult25csv.zip

Reproduction from a fresh extracted package
Keep the outputs/all_adults and outputs/data_original paths beneath a single
project root. Set the R working directory to that root. The first script uses
base R only. The second requires the survey and numDeriv R packages, plus their
dependencies. No codebook PDF, previous manuscript, or previous results are
needed to calculate the adult analyses. Codebooks remain necessary to understand
the measures and the NHIS survey documentation should be consulted for methods.

The validated environment was R 4.6.0, survey 4.5 and numDeriv 2016.8-1.1.
Install survey and numDeriv in your standard R library if necessary:
  install.packages(c("survey", "numDeriv"))
Then run, in this order:
  source("outputs/all_adults/00_prepare_all_adults.R")
  source("outputs/all_adults/01_analyse_all_adults.R")
Alternatively invoke both scripts sequentially with Rscript from the project
root. The local work/Rlib package library is used when present. Re-running
overwrites the adult result tables with regenerated values. Original source
tables and historical older-adult results remain unchanged. An existing
work/prepared.rds is verified against fresh source parsing rather than silently
replaced; a mismatch stops preparation. A fresh extraction needs no prepared RDS.

Methods and interpretation
All survey records enter the sampling design before domain restrictions.
WTFA_A, PSTRAT and PPSU are used with Taylor linearization; public-use strata are
not prefixed by year, in accordance with NCHS 2025 guidance. Both year-to-year and
between-group covariance are retained. Records with unknown age (64 in 2022 and
60 in 2025) are excluded from age-based primary estimates. A crude sensitivity
including those adults is also supplied. Unknown stroke status does not exclude
records from the overall analysis. Missing outcomes are excluded from the main
estimate and considered in explicit extreme-assignment sensitivities.

Direct standardization uses the projected US 2000 adult population and age groups
18-44, 45-64, 65-74, 75-84 and 85+. The same reference is used for every group and year.
Standardized stroke levels describe a hypothetical common age distribution;
crude levels describe the annual weighted respondent population. The age-sex
sensitivity additionally uses a fixed 50:50 sex distribution. Separate overall,
stroke and no-stroke survey logistic regressions contain year, age group and sex.
A joint model with stroke-specific age/sex associations supplies the supporting
interaction. Logistic margins impose a common year odds ratio across age/sex
within each population, unlike the direct standardization.

The self-response sensitivity uses different available status variables in each
year and does not identify exactly equivalent populations. The quarters 1-3
sensitivity retains annual weights without separate recalibration. The 2025
collection interruption, sparse younger stroke cells and missing responses
limit interpretation. Precision flags denote n<30, fewer than 10 events or
nonevents in any contributing cell, or prevalence relative SE>30%. They do not
constitute all formal NCHS reliability criteria. All intervals and p values are
nominal; supporting and secondary comparisons are exploratory.

Files
Analysis_Results.csv and manuscript_summary_percent_units.tsv contain the
principal complete comparisons in percentages and percentage-point differences.
all_results.tsv contains every numerical estimate at full precision. Estimate,
SE and confidence-limit columns in all_results.tsv and other result TSVs are
proportions; multiply by 100 for percentages or percentage points. Rows identify
analysis method, population, outcome, age group and estimate type.
standardized_results.tsv: primary direct estimates and secondary outcomes.
primary_comparison_all_methods.tsv: primary outcome across main/sensitivity methods.
crude_results.tsv: unstandardized estimates, including unknown-age sensitivity.
age_specific_results.tsv: five age groups and broad 18-64/65+ descriptive comparisons.
cell_counts.tsv: unweighted denominators, events, missingness and precision flags;
select proxy_status=all for primary domain counts.
sample_flow.tsv: raw, excluded, eligible and outcome/stroke sample counts.
weighted_demographics.tsv: age, sex and response-status composition.
age_standard.tsv and age_sex_reference.tsv: fixed reference distributions.
model_audit.tsv: formulas, sample sizes, ranks, degrees of freedom and convergence.
Files ending in covariance.tsv retain covariance matrices used for contrasts.
validation_and_methods.txt records numerical checks and methodological details.
Independent_Primary_Validation files independently check primary estimates and
standard errors by direct PSU influence calculations from source data.
Preparation_Validation.txt verifies fresh source parsing and source-file hashes.
session_analysis.txt records the computational environment.

English manuscript and figure artifacts in this directory use these revised
adult results. Historical files elsewhere in the repository retain their older
scope and must not be substituted for the current adult estimates.
