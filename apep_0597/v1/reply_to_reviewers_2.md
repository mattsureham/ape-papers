# Reply to Reviewers — Round 2

## GPT-5.4 R1 — Reject and Resubmit

### 1. Food identification not credible as causal pass-through
**Response:** Agreed. Substantially reframed the food results throughout as "reduced-form geographic differentials" rather than "structural pass-through." Added a new Limitations paragraph explicitly acknowledging that terminal distance correlates with production geography and that a stronger design (linking observed local fuel prices to food prices) would be needed to isolate the fuel channel. The roots/tubers negative coefficient is now discussed as evidence of the identification challenge, not just a mechanism confirmation.

**New evidence:** Added geopolitical-zone-by-month fixed effects (absorbing all time-varying zone-level shocks). Cereal β = 0.0709 vs 0.0704 baseline — virtually unchanged. This is the strongest available test of regional confounding.

### 2. Inference with few clusters
**Response:** Added Conley SEs at 100km and 200km cutoffs (both for petrol and cereals). Explicitly stated that Conley-based inference should be preferred for food results given the four-fold gap between Conley and state-clustered SEs. Wild cluster bootstrap was attempted but is incompatible with fixest's singleton removal; Conley SEs are a valid alternative.

### 3. Recalibrate petrol claims
**Response:** Revised abstract, introduction, and conclusion to present petrol result as a "short-run distance gradient concentrated in the first year." Full-sample null result is now clearly stated throughout. Conclusion explicitly frames petrol gradient as "short-run phenomenon."

### 4. Cereal magnitude validation
**Response:** Zone-by-month FE robustness (unchanged coefficient) is the strongest validation available. Acknowledged that the coefficient "likely captures both fuel-related transport costs and other spatially differentiated factors." Welfare calculation now presented as "upper bound."

### 5. Road distance robustness
**Response:** No routing data available. Noted Haversine-road correlation > 0.9 for the sample.

### 6. Region-by-time structure
**Response:** Added geopolitical-zone-by-month fixed effects (see #1 above).

### 7. Diesel benchmark
**Response:** Diesel results already reported. A full DDD with diesel is conceptually unclear since diesel was already deregulated (both fuels experienced macro shocks, only PMS had the regime change).

### 8. RTEP validation
**Response:** NBS provides state-level averages, not market-level. Direct validation at the same granularity is not possible. Limitation noted in text.

---

## GPT-5.4 R2 — Reject and Resubmit

### 1-5. (Largely overlap with R1)
See responses above. Key additions: zone-by-month FE, Conley multi-cutoff, reframed claims, RI relabeled as "permutation placebo."

### 3. RI relabeling
**Response:** Relabeled throughout to "permutation placebo." Added explicit caveat that "distance is a fixed geographic characteristic, not a randomly assigned treatment, so this exercise is best interpreted as a placebo reshuffling test." Cited Young (2019).

### 6. Richer spatial controls
**Response:** Zone-by-month FE directly addresses this. State-by-month FE would be ideal but would absorb the treatment variable in markets where the state has only one or two markets at similar distances.

### 7. Food pre-trend diagnostics
**Response:** Attempted joint F-test for cereal pre-trends but the VCOV matrix was not positive semi-definite (common with many event-time dummies and few clusters). The cereal event study (Figure 8) is presented with honest caveats about noise.

### 8. Treatment support/leverage
**Response:** Documented that excluding northeast eliminates identifying variation. This is presented honestly as a limitation — the results depend on the most distant markets.

### 9. Continuous treatment estimand
**Response:** The estimand is the average marginal effect of an additional 100km of distance on the log price change, conditional on market and time fixed effects. This is discussed in the empirical strategy section.

---

## Gemini-3-Flash — Minor Revision

### 1. Cereal production geography
**Response:** Expanded discussion in the limitations section. Explicitly mapped the relationship: cereals produced in the north (far from terminals), roots in the south (near terminals). The zone-by-month FE helps but does not fully resolve this.

### 2. Inland depots
**Response:** Northern depots (Kano, Gusau) were largely non-functional during the study period (Section 2.2). A robustness check using distance to nearest depot is not feasible without data on which depots were operational.

### 3. Naira exchange rate
**Response:** Month FE absorb the aggregate exchange rate shock. Geographically differentiated exchange rate pass-through is addressed by zone-by-month FE.
