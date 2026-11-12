# Dementia sensitivity analysis

This post-hoc extension implements Cinja's requested assessment of adjustment
for reported physician-diagnosed dementia. It does not replace the original
primary or self-response analyses. Only DEMENEV_A was added; VSLBRAIN_A and
other comorbidities were not added.

Run from the repository root:

```sh
Rscript outputs/07_dementia_sensitivity.R
```

Requires R, survey and numDeriv, and the existing
`outputs/extensions/additional_results.tsv` for baseline validation. The script
reads/downloads official adult CSV files under `work/raw/`; it writes only
aggregate outputs into this directory. No individual records are committed.
The executed environment was R 4.5.3, survey 4.5 and numDeriv 2016.8-1.1.

## Results

All differences below are percentage points, 2025 minus 2022, with 95% CIs.

| Model | Stroke history | No stroke history | Additive interaction |
|---|---|---|---|
| Original age/sex model, reproduced | 5.84 (0.80 to 10.88) | 0.18 (-0.77 to 1.12) | 5.66 (0.52 to 10.80) |
| Age/sex, dementia-complete cases | 5.96 (0.91 to 11.01) | 0.18 (-0.76 to 1.13) | 5.78 (0.64 to 10.92) |
| Age/sex plus dementia, same cases | 5.84 (0.87 to 10.80) | 0.21 (-0.74 to 1.16) | 5.63 (0.57 to 10.69) |

The dementia-complete model includes 16,654 adults and 1,336 swallowing events;
12 people are excluded relative to the baseline stroke-comparison model.
Stroke-group denominators are 671 (2022) and 589 (2025), with 98 and 108 events.
Proxy and ambiguous response statuses remain included. The point estimate
remains positive after adjustment, but does not establish independence from
unmeasured causes, dementia severity/timing, reporting or selection mechanisms.
Dementia can itself follow stroke, so no causal direct effect is identified.

## Estimation and checks

See Analysis_Plan.txt, fixed before fitting the new models. The model is
`any ~ year * stroke_group + agegroup + sex + dementia` using svyglm with
quasibinomial variance. The full adult survey design is created before domain
restriction; weights and public strata/PSU identifiers retain original coding.
Marginal estimates use US 2000 age weights, 50:50 sex within age groups, and
the pooled survey-weighted dementia distribution conditional on age/sex in
the complete-case domain, common to every year and stroke group. This is a
fixed hypothetical reference: uncertainty in estimated reference proportions
is not propagated. Intervals use full coefficient covariance and residual
survey degrees of freedom. Prevalence CIs are logit transformed; contrasts
are linear. Analytic gradients agree with numerical gradients to <1e-7.

The script fails unless the original age/sex subgroup estimates, SEs and CI
limits reproduce the stored results within 1e-8. All three models converged
with full rank and finite covariance. Sparse dementia-stratified cells are
documented; no dementia interactions or separate dementia-subgroup year
effects are claimed. Results are exploratory without multiplicity correction.

- results.tsv: proportions and differences on a 0-1 scale.
- results_percent_units.tsv: percentages and percentage-point differences.
- sample_flow.tsv and cell_counts.tsv: unweighted denominators and events.
- fixed_reference.tsv: exact common standardization distribution.
- model_audit.tsv, validation.txt and sessionInfo.txt: numerical checks/runtime.
- *_coefficients.tsv, *_coefficient_covariance.tsv and *margin_covariance.tsv:
  model and marginal estimates' covariance for reproducibility.

## Source verification

Original CSV SHA-256 checksums matched the existing repository manifest:

- 2022: `2e814050ea06ca1ffed356f51979b87c20d6242b0453c928249a29bd5f1f29f1`
- 2025: `011b46e814e619acd970a1449a7f7d6a97f52c7ffe07e955c753f791da23d12b`

DEMENEV_A wording, universe and codes agree in the official codebooks:
[2022, page 125](https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/2022/adult-codebook.pdf)
and [2025, page 128](https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/2025/adult-codebook.pdf).
The additional manuscript explanation for selecting years was checked against
the 2025 codebook page 486 (VSL previously fielded in 2022) and the absence of
the required swallowing items in the
[2023](https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/2023/adult-codebook.pdf)
and [2024](https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/2024/adult-codebook.pdf)
Sample Adult codebooks. This is absence of the relevant module, not absence
of public NHIS data for those years.
