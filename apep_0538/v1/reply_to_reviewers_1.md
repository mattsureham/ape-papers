# Reply to Reviewers

## Reviewer 1 (GPT-5.4 R1) — MAJOR REVISION

### CS-DiD design needs better justification
**Response:** We now explicitly state the identifying assumption: absent ZFE adoption, inside-boundary prices in treated cities would have evolved similarly to inside-boundary prices in not-yet-treated cities. We acknowledge that outside-boundary communes serving as never-treated controls creates a tension with the paper's critique of inside-outside comparisons. The CS-DiD dynamic effects (Figure 2, flat pre-trends) provide supportive evidence. We added a leave-one-city-out analysis showing the null is robust across all seven CS-DiD cities.

### Causal estimand unclear
**Response:** We now explicitly define the estimand: the ATT of ZFE adoption for inside-boundary communes in the seven cities adopting during 2020–2023, identified from cross-city variation in adoption timing. We distinguish this from the TWFE boundary effect.

### Treatment intensity too coarse
**Response:** We acknowledge this limitation. The binary first-adoption indicator may wash out heterogeneity, potentially attenuating estimates. We note this explicitly in the limitations section.

### Air quality first stage underpowered
**Response:** We added month-of-year fixed effects to address seasonality. We now describe the first stage as "suggestive rather than definitive" given the coarse CAMS resolution.

### "Precisely estimated null" too strong
**Response:** Changed throughout to "precisely estimated near-zero" and note the CI cannot exclude small-to-moderate effects of 2–3%.

## Reviewer 2 (GPT-5.4 R2) — MAJOR REVISION

### CS-DiD unit and treatment definition
**Response:** We rewrote Section 4.3 and the appendix to unambiguously define the CS-DiD unit (commune-quarter cell), treatment assignment (inside-boundary communes get city adoption quarter; outside get G=0), and control group (never-treated outside + not-yet-treated inside).

### Missing CS-DiD robustness
**Response:** Added leave-one-city-out CS-DiD robustness. ATT ranges from -0.031 to +0.026, all insignificant.

### Clustering concerns
**Response:** We acknowledge the treatment-at-city-level / clustering-at-commune-level mismatch. The RI exercise (applied to TWFE) and the CS-DiD leave-one-city-out analysis provide alternative inference. We note that city-level clustering is infeasible with 9 (TWFE) or 7 (CS-DiD) cities.

### Air quality specification
**Response:** Added month-of-year FE. Results are qualitatively unchanged.

## Reviewer 3 (Gemini) — MINOR REVISION

### Selection into treatment
**Response:** We note that DVF data start in 2020, limiting our ability to examine pre-2020 city-level trends. The CS-DiD pre-treatment dynamics (Figure 2) are flat, supporting parallel trends among the 2020–2023 adopters.

### Aggregation sensitivity
**Response:** The leave-one-city-out analysis shows the null is robust to individual city exclusion. The aggregation is necessary for CS-DiD tractability.

### Air quality resolution
**Response:** Added explicit caveat that the city-centroid CAMS data cannot capture within-city gradients.
