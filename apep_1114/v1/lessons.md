## Discovery
- **Idea selected:** idea_0336 — Dutch piekbelasters (peak emitter) farm buyout, world's largest environmental buyout at EUR 1.5B. Selected for novel setting (no academic study), excellent CBS data (25 years), and portable adverse selection mechanism.
- **Data source:** CBS 80781ned (agriculture by municipality, 2000-2025) + PDOK Natura 2000 WFS. CBS API worked smoothly; PDOK atom feed was 404 but WFS worked.
- **Key risk:** Short post-treatment window (2 years post-buyout), municipality-level analysis may mask farm-level heterogeneity.

## Execution
- **What worked:** The "selection illusion" finding — apparent adverse selection (elasticity ratio 0.41) disappearing after detrending (ratio 0.91) — is a genuinely novel insight. The back-of-envelope ATT calculation (1,450 implied exits vs. 1,438 actual approvals) provides strong external validation.
- **What didn't:** The pre-trends in the event study are concerning and require municipality-specific linear trends, which all three reviewers flagged as potentially over-correcting. Future work needs quadratic trends or province × year FE.
- **Review feedback adopted:** Added magnitude translation (ATT for average high-exposure municipality), heterogeneity by livestock type (cattle vs. pig/poultry), expanded caveats on linear trends and spatial correlation.
