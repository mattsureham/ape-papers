## Discovery
- **Idea selected:** idea_0148 — Nigeria FX exclusion list as invisible tariff, clean product-level DiD setting
- **Data source:** UN Comtrade API (v1) — worked smoothly for all 4 countries x 13 years, ~214K observations
- **Key risk:** HS2-level treatment mapping too coarse; reviewers strongly urged HS6-level concordance

## Execution
- **What worked:** DDD with saturated FE (product×country, country×year, product×year) cleanly recovers the treatment effect masked in simple DiD. The finding that banned products *grew* in control countries was key to the story.
- **What didn't:** Simple within-Nigeria DiD is essentially null because global trade trends in banned product categories were positive, confounding the Nigeria-specific decline. This makes the paper rely heavily on the DDD.
- **Review feedback adopted:** Softened welfare/tariff-equivalent claims, acknowledged concurrent policies as confounders (reduced-form of policy bundle), added nuanced HS2 mapping caveat, fixed intensive margin overstatement.
- **Review feedback deferred for V2:** HS6-level treatment concordance from CBN circular text, incorporating parallel-market premium as time-varying treatment intensity, BACI bilateral data, FAO domestic production mechanism test, PPML estimation.

## Key Numbers
- DDD (saturated FE): -0.325 log points (p=0.031)
- Pre-trends: F=0.46, p=0.63 (clean)
- N treated HS6: 1,435; N control: 4,111; Panel: 196,857 obs
