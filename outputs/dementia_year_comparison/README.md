# Exploratory year comparison in dementia

Requested after the dementia-adjusted stroke sensitivity analysis. This asks
a different question: whether reported swallowing difficulties differ between
2022 and 2025 within the dementia group, and whether the year difference differs
from that in adults without dementia. The manuscript is not changed.

Run `Rscript outputs/08_dementia_year_comparison.R` from the repository root.
Requires survey and numDeriv. Uses unchanged original NHIS adult files with
the same eligibility/outcome/design coding as the existing analysis.

## Results

Model-standardized prevalences in adults aged 65+ with reported dementia:

| Model | 2022 | 2025 | Difference in percentage points (95% CI) |
|---|---:|---:|---|
| Age and sex | 12.43% | 16.29% | 3.86 (-2.42 to 10.14) |
| Age and sex, stroke-complete cases | 12.41% | 16.09% | 3.68 (-2.58 to 9.95) |
| Age, sex and stroke, same complete cases | 11.14% | 14.36% | 3.22 (-2.59 to 9.02) |

After stroke adjustment the year difference without dementia is 0.54 points
(-0.42 to 1.49). The additive interaction is 2.68 points (-3.17 to 8.53),
p=0.369. Thus neither a positive difference within dementia nor a larger
difference than without dementia is clearly established. This is not evidence
of no change: confidence intervals also include appreciable increases.

Unweighted counts before model exclusions: 292 respondents with dementia and
45 swallowing events in 2022; 249 and 54 in 2025. The small dementia sample and
sparse age-by-dementia-by-stroke cells limit precision. These are self-/proxy-
reported diagnoses and symptoms, not clinical confirmation or individual follow-up.

## Methods and validation

See Analysis_Plan.txt. Survey quasibinomial models include year*dementia group,
age group and sex; the last model additionally includes stroke as a main
effect. Stroke adjustment is descriptive and does not identify a causal effect.
The common hypothetical reference uses US 2000 age weights, 50:50 sex, and
pooled survey-weighted stroke proportions within age-sex cells across all
complete-case older adults. These proportions are treated as fixed. CIs use
full model covariance and residual survey df; uncertainty in estimated reference
proportions is not propagated. Proxies remain included. The analysis is post-hoc
with no multiplicity correction. No year*dementia*stroke interaction is fitted.

All model fits pass convergence, rank, finite covariance and independent
numerical-gradient/predict() checks. Model outputs use a 0-1 scale in results.tsv
and percentage/percentage-point units in results_percent_units.tsv. Direct
age-standardized and crude prevalences are provided separately; these use
different standardization from the model estimates and must not be mixed.
No individual-level records are included in the repository.
