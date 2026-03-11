## Discovery
- **Policy chosen:** Nigeria's 2019 land border closure — sudden, unanticipated, nationwide shock creating a clean natural experiment for trade barrier effects
- **Ideas rejected:** N/A (pinned idea from idea database)
- **Data source:** WFP HDX food prices — free, no auth, 57K+ observations with geo-coordinates. HDX resource URLs changed (404 on original URLs from idea manifest); had to fetch current URLs from HDX dataset pages.
- **Key risk:** Spatial variation might be insufficient if all Nigerian markets are well-integrated. This risk materialized — the effect is nationally uniform.

## Execution
- **Critical data issue:** WFP data has prices in DIFFERENT units (KG, 2.7 KG, 2.8 KG, 50 KG, 100 KG). Initial analysis without unit normalization produced nonsensical results with massive variance. After normalizing to price-per-kg and restricting to retail prices, the standard errors dropped by 3x and pre-trends became much cleaner.
- **Non-tradeable placebo unavailable:** Firewood/charcoal/fuel are sold in non-weight units (bundles, bags) that can't be normalized to per-kg. Had to use local rice (domestically produced) as an alternative within-commodity placebo.
- **Result:** The border closure has no statistically significant differential effect on border vs. interior market prices (+4.5%, SE = 6.3%, p = 0.48). The null spatial gradient is consistent with integrated domestic supply chains compressing border-interior price differentials.
- **Summary stats bug:** The `price` column vs `price_per_kg` mismatch in Table 1 caused ln(1121) ≈ 7.02 vs reported 6.0. Always verify that summary statistics use the SAME variable as the regression outcome.

## Review
- **Advisor verdict:** 3 of 4 PASS (round 4; rounds 1-3 failed on data consistency issues)
- **Top criticism:** All 3 reviewers flagged that the paper's causal claims exceed the design. DiD with month FE identifies *differential* effects, not national aggregate effects. Reframed throughout.
- **Surprise feedback:** Reviewers wanted imported-vs-local rice analysis (which was in appendix) elevated to main text as the strongest mechanism test.
- **What changed:** (1) Reframed all claims from "national effect" to "spatial gradient/differential." (2) Fixed summary stats (price_per_kg vs price). (3) Removed invalid 250km threshold and wild cluster bootstrap claims. (4) Clarified Post variable includes post-reopening period. (5) Elevated imported-vs-local rice to main text.
