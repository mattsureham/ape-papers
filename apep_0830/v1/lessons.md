## Discovery
- **Idea selected:** idea_0596 — VAT receipt lotteries across EU member states. Cross-country staggered DiD with cancellation reversals.
- **Data source:** Eurostat API (gov_10a_taxag, nama_10_gdp) — zero friction, no API keys needed, fast download.
- **Key risk:** Only 9 treated countries = borderline power for country-level DiD.

## Execution
- **What worked:** Eurostat API via `eurostat` R package was seamless. Panel construction straightforward. Sun-Abraham event study produced clean pre-trends and a significant immediate effect (0.22*** at t=0).
- **What didn't:** DIDmultiplegtDYN package wouldn't load on macOS (rgl/OpenGL dependency). fwildclusterboot also unavailable for this R version. Cancellation reversal test came out wrong-signed — COVID contamination and only 4 cancelling countries made it uninterpretable.
- **Key finding:** Aggregate null (TWFE: 0.14, p=0.64) but sharp heterogeneity — low-compliance countries see 0.54* pp increase, high-compliance countries see nothing. The "compliance frontier" mechanism is the paper's contribution.
- **Review feedback adopted:** Added event study table (all 3 reviewers wanted to see coefficients), added paragraph justifying VAT/GDP over CASE VAT gap as outcome, strengthened heterogeneity discussion. Reviewers also wanted CASE VAT gap data — flagged as limitation.
