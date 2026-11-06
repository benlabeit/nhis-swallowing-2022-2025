NHIS post-hoc analysis extensions - 6 November 2026

Scope: requested analyses 1 (additional sex adjustment) and 2 (self-response sensitivity).
All analyses concern the primary 12-month swallowing-problem endpoint. Original primary analyses are unchanged.

Main result files
additional_results.tsv: full-precision additional estimates, standard errors, 95% CIs, df, counts and exploratory p values. Estimates are proportions/differences on a 0-1 scale.
manuscript_summary_percent_units.tsv: same results in percent and percentage points, with event counts and valid denominators.
primary_comparison_all_methods.tsv: original primary age-standardized results and all additional methods in one file. Source rows marked main are unchanged.
proxy_cell_counts.tsv: unweighted sample/event/missingness counts by year, population group, age group and proxy classification.
proxy_raw_code_audit.tsv: exact observed raw proxy-code combinations and conservative harmonization.
fixed_reference_distribution.tsv: six fixed age-by-sex target cells for model-based predictions.
model_audit.tsv: formula, sample size, events, design df, residual df, rank, convergence and fitted-value range.
*_model.txt, *_coefficients.tsv, *_coefficient_covariance.tsv, *_margin_covariance.tsv: audit materials for all four fitted survey models.
validation_and_methods.txt: analytic/numerical prediction-gradient agreement, predict() agreement, independently reproduced covariance of direct age-domain means, and data checksums.
addendum_frozen.txt: SHA-256 and timestamp of the plan saved before additional inference.
session_extensions.txt: R environment.

Method labels
age_sex_adjusted: all eligible reports, model-standardized to US 2000 age weights within 65+ and a fixed 50:50 male:female distribution in each age group.
self_direct_age_standardized: confirmed self-reports, original direct age standardization, without sex adjustment.
self_age_sex_adjusted: confirmed self-reports, same age-and-sex model standardization.
The all-population model is separate from the stroke/no-stroke model; its margin includes people with unknown stroke status. Overall margins therefore need not equal a weighted average of the two subgroup margins.

Interpretation
The balanced-sex target is hypothetical, not the actual older US population. Compare years/groups within a method; retain original direct age-standardized estimates for population reporting. The sensitivity analyses are post-hoc and exploratory; intervals are not multiplicity-adjusted.
Proxy exclusion changes the population toward participants able to respond for themselves and does not correct all measurement or participation bias. In 2022, AVAIL_A=1 with PROXY_A blank is required for confirmed self-response; other nonproxy combinations are unknown. This deliberately conservative criterion is stricter than simply treating all blank PROXY_A values as self-response. In 2025, PROXYFLAG_A=2 defines self-response.

Core numerical findings, percentage points
Age/sex-adjusted stroke-group difference: +5.84 (95% CI +0.80 to +10.88).
Self-only direct age-standardized stroke-group difference: +4.53 (-0.42 to +9.48).
Self-only age/sex-adjusted stroke-group difference: +4.05 (-0.78 to +8.88).
The point estimates remain positive, but the self-only confidence intervals include zero. This is attenuation and increased uncertainty, not proof that proxy reports caused the original signal or proof of no change.

Reproduce from project root after outputs/01_prepare.R:
Rscript outputs/06_extensions.R
Requires survey and numDeriv in work/Rlib (both already installed by the project setup).
The addendum and its frozen record must be retained; do not rewrite them after inspecting results.
