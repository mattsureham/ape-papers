## Discovery
- **Policy chosen:** EU Mortgage Credit Directive (2014/17/EU) — massively staggered transposition (March 2015 to June 2019) across 24 member states, pre-COVID timing, first-order outcomes (mortgage rates, house prices), zero causal papers exist
- **Ideas rejected:** Geo-Blocking (single treatment date, thin product categories), European Arrest Warrant (2004 EU accession = fatal confounder), Posted Workers Directive (COVID overlap, only 8 countries in LCI data), 5th AMLD (too few observations, COVID overlap)
- **Data source:** ECB MIR (monthly mortgage rates/volumes, ~21 euro area countries) + Eurostat prc_hpi_q (quarterly house prices, 27 countries) + CELLAR SPARQL (transposition dates)
- **Key risk:** National macro-prudential policies changed concurrently in some countries (LTV caps, stress tests) — need to document and control for these

## Review
- **Advisor verdict:** 3 of 4 PASS (passed on 4th attempt after fixing critical quarterly aggregation bug)
- **Referee verdicts:** GPT R1 MAJOR, GPT R2 MAJOR, Gemini MINOR
- **Top criticism:** "Precise null" framing overstated — SA-IW SE of 0.638 does not support precision claims; MDE formula contradicted actual SEs
- **Surprise feedback:** Both GPT reviewers demanded country-specific linear trends — a specification I should have included from the start for any cross-country DiD
- **Critical bug found during advisor review:** Quarterly aggregation grouped by `treated`, splitting mid-quarter transposition countries into 49 rows instead of 48, excluding 5 countries from balanced panel
- **What changed in revision:** (1) Replaced "precise null" with "informative null" / "no evidence of large effects" throughout; (2) Removed back-of-envelope MDE, replaced with CI-based discussion; (3) Added balanced-sample TWFE and country-specific trends to robustness; (4) Softened title, abstract, conclusion; (5) Moved consumer placebo and RI figures to appendix; (6) Added Callaway-Sant'Anna and Roth et al. citations

## Summary
- **What went well:** ECB MIR data is clean and well-structured; staggered transposition provides genuine variation; Sun-Abraham implementation via fixest::sunab() worked smoothly
- **What went badly:** Quarterly aggregation bug was subtle and persistent — always check that grouped aggregation doesn't inadvertently create duplicate rows. Should have validated panel dimensions immediately after construction.
- **Key takeaway for future papers:** For cross-country DiD with <20 clusters, include country-specific trends from the start. Also: frame null results modestly — let the CI speak, don't overclaim precision.
