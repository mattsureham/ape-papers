# Revision Plan — Round 2 (Fresh External Reviews)

## Key Concerns Addressed

### 1. Food identification: production geography confound (R1 #1, R2 #1)
- Added explicit acknowledgment that terminal distance correlates with production geography
- Added new Limitation paragraph honestly stating the identification limitation
- Reframed cereal coefficient as "reduced-form geographic differential" throughout
- Softened mechanisms language: "consistent with" rather than "confirms"
- Added geopolitical-zone-by-month FE robustness (β = 0.0709 vs 0.0704 baseline — virtually unchanged)
- Attempted excluding northeast states; documented that this eliminates identifying variation (honest about leverage)

### 2. Inference with few clusters (R1 #2, R2 #2)
- Added Conley SE at multiple cutoffs (100km and 200km)
- Noted that Conley-based inference should be preferred for food results
- Acknowledged the four-fold gap between state-clustered and Conley SEs for cereals

### 3. RI relabeling (R2 #3)
- Relabeled "Randomization Inference" to "Permutation Placebo" throughout
- Added explicit caveat that distance is not randomly assigned
- Cited Young (2019) on proper framing

### 4. Claims recalibration (R1 #3, R2 #5)
- Abstract: "geographic price heterogeneity" instead of "pass-through"; added "reduced-form patterns"
- Introduction: Added qualification that food results are "reduced-form geographic differentials"
- Conclusion: Presented petrol as "short-run phenomenon"; food as needing stronger design to isolate fuel channel
- Welfare calculation: Added "upper bound" qualification and noted it treats reduced-form as structural

### 5. Cereal magnitude (R1 #4, R2 #4)
- Strengthened the "Reconciling Magnitudes" section with honest acknowledgment
- Added zone-by-month FE as strongest test of spatial confounding

### Not Changed (with justification)
- No road distance data available (noted correlation > 0.9)
- Cannot add IV/2SLS fuel→food: different paper scope; would require first-stage from same markets
- Wild cluster bootstrap: failed due to fixest singleton handling (documented; Conley SEs substituted)
- Northeast exclusion: eliminates identifying variation (documented as limitation)
