# Internal Review — Round 1

## PART 1: CRITICAL REVIEW

### Identification and Design
The boundary discontinuity design is credible and well-executed. The key identifying assumption—smooth potential outcomes at the boundary—is reasonable given QPV zones are defined by a 200m grid income formula rather than physical features. The paper honestly acknowledges covariate imbalance (inside properties are smaller, more apartments) and addresses it with controls.

**Weaknesses:**
- The commune-level classification of gained vs retained introduces measurement error. Without actual polygon overlap, some zones may be misclassified. The paper acknowledges this limitation clearly.
- The cross-sectional design (all post-reform data) cannot identify the causal effect of the 2015 reform per se—only the equilibrium boundary discontinuity. The paper appropriately softened claims about "rapid capitalization" but should be even more careful.

### Inference
- Standard errors clustered at boundary level with 1,236 clusters — adequate.
- rdrobust estimates with MSE-optimal bandwidths (17-27m) are very narrow, raising concerns about the number of observations driving those estimates. The RDD table reports N adequately.
- The donut analysis reveals meaningful instability for gained zones at 200m, which the paper now honestly discusses.

### Robustness
- Bandwidth sensitivity: robust across 200-2000m
- Donut: retained zones robust; gained zones unstable at 200m (honestly discussed)
- McCrary density test: passes
- Covariate balance: shows expected compositional differences, controlled for

### Contribution
The paper fills a genuine gap: boundary discontinuity estimates for France's QPV system. The comparison of gained vs retained boundaries adds value. The French setting (formulaic boundaries) is cleaner than U.S. enterprise zones.

### Results Interpretation
The Simpson's paradox discussion (raw prices higher inside for retained) is now properly explained. Claims about "rapid capitalization" have been appropriately softened to reflect the post-2020-only data limitation.

## PART 2: CONSTRUCTIVE SUGGESTIONS

1. **Add a map figure** showing representative QPV boundaries with transaction locations
2. **Heterogeneity by city size** — the QPV effect may differ in Paris vs provincial cities
3. **Consider instrumental variables** for the commune-level classification error

## DECISION: MINOR REVISION
