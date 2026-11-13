# Four-group swallowing comparison

Exploratory analysis requested 13 November 2026. No manuscript edits.
Adults aged 65+ are classified into mutually exclusive groups using reported
physician-diagnosed stroke (STREV_A) and dementia (DEMENEV_A). The outcome is
reported swallowing difficulties in the prior 12 months (VSLSWYR_A), not
clinically confirmed dysphagia. Proxy responses are retained.

Run from repository root: `Rscript outputs/09_four_group_comparison.R`.
Dependencies: survey and numDeriv. The script reads/downloads original NHIS CSVs
under work/raw. Only aggregate results are published.

## Results

Crude survey-weighted prevalence:

| Group | 2022 events/n | 2025 events/n | 2022 % | 2025 % | Difference pp (95% CI) |
|---|---|---|---|---|---|
| Neither | 514/7554 | 541/7411 | 6.81 | 6.93 | 0.12 (-0.82 to 1.05) |
| Stroke only | 90/618 | 93/538 | 13.82 | 20.11 | 6.28 (1.09 to 11.48) |
| Dementia only | 37/239 | 38/196 | 12.79 | 16.08 | 3.29 (-3.70 to 10.28) |
| Both | 8/53 | 15/51 | 17.86 | 23.46 | 5.59 (-12.76 to 23.95) |

Counts are unweighted; percentages use survey weights and are not events/n.

Age- and sex-adjusted marginal estimates:

| Group | 2022 % | 2025 % | Difference pp (95% CI) |
|---|---|---|---|
| Neither | 6.93 | 7.05 | 0.11 (-0.84 to 1.06) |
| Stroke only | 13.69 | 19.76 | 6.07 (0.91 to 11.22) |
| Dementia only | 11.63 | 14.79 | 3.16 (-3.37 to 9.69) |
| Both | 16.40 | 21.85 | 5.45 (-11.94 to 22.84) |

The stroke-only increase remains positive in both approaches. Thus the earlier
stroke result is not confined to respondents who also report dementia. This
does not identify a cause or show that change is specific to stroke.
The dementia-only and both-diagnoses intervals span zero and large increases;
these findings do not establish no change. The both-diagnoses group is very
small and the apparent rise is imprecise.

The joint additive heterogeneity test does not establish different year changes
across all four groups (adjusted F=1.961, df=3/1112, p=0.118; crude p=0.106).
The adjusted stroke-only versus neither change contrast is 5.95 pp (0.68 to
11.22), p=0.027, but is one of multiple uncorrected exploratory comparisons.
Stroke-only versus dementia-only change is not distinguishable (opposite
contrast dementia-only minus stroke-only: -2.90 pp, -11.28 to 5.47).
Different within-group significance does not itself demonstrate a group
difference. These results do not support a claim of synergistic year change
from having both conditions.

## Methods and validation

Analysis_Plan.txt was written before fitting. Full adult survey design is
constructed before domain restriction; original annual weights, strata and PSU
codes are retained, matching prior analyses. Invalid outcome/diagnosis codes
are missing. Crude estimates use jointly estimated year/group means and full
covariance. Age/sex adjustment uses survey quasibinomial logistic regression:
`any ~ year * group + agegroup + sex`. A common hypothetical reference crosses
the US 2000 age weights for ages 65-74, 75-84 and 85+ with 50:50 male/female.
This assumes common age/sex coefficients across the four groups. Six missing
sex observations are excluded only from the adjusted model, all in the
neither-diagnosis 2025 group. Adjusted model n=16,654; events=1,336.

Prevalence intervals are logit delta intervals; differences use linear t
intervals with full covariance, survey-domain df for crude results and model
residual survey df for adjusted results. The global additive change test uses
a joint 3-df Wald F contrast; pairwise additive contrasts are also provided.
All comparisons are post-hoc without multiplicity correction. Clinical severity,
timing, institutionalization, participation and reporting differences remain
limitations. No individual longitudinal or causal inference is made.

Checks passed: manual weighted means; saturated Gaussian survey covariance
agreement for crude estimates; adjusted convergence/full rank/finite covariance;
analytic gradients against numerical gradients and predict(). Sparse age/sex
cells are documented rather than treated as precise subgroup evidence.

- comparison_percent_units.tsv: group prevalences, changes and CIs, in %/pp.
- *_prevalence.tsv and *_covariance.tsv: unscaled prevalences and covariance.
- pairwise_change_contrasts.tsv and heterogeneity_tests.tsv: change comparisons.
- sample_flow.tsv and cell_counts.tsv: unweighted denominators and events.
- model_audit.tsv, validation.txt and sessionInfo.txt: reproducibility checks.
