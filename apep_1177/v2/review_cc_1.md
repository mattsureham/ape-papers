# Internal Review — Claude Code (CC1)
**Paper:** apep_1177 v2, "The Conviction Lottery"
**Date:** 2026-03-31
**Decision:** Proceed to external review

## Assessment

The paper presents a novel finding: drug trafficking conviction rates in São Paulo's Central courthouse are essentially uncorrelated with theft conviction rates across the same 31 courtrooms (r=0.10), while robbery and theft are strongly correlated (r=0.67). This "discretion decoupling" is formalized through a common severity factor decomposition.

## Issues Checked

1. Abstract word count: 128 words (under 150 limit) - PASS
2. Table labels resolve correctly - PASS (verified after fixing double-prefix bug)
3. References count: 20+ in references.bib - PASS (minimum 15 required)
4. Main text page count: 26 pages - PASS (minimum 25 required)
5. Figures present: 5 figures - PASS
6. SDE table present: tabF1_sde.tex - PASS
7. Sorteio coverage numbers consistent: 95.8-99.9% everywhere - PASS
8. Sample definition consistent: all three offenses restricted to resolved cases - PASS
9. Balance test: day-of-week passes (t=1.6), filing month noted as concern but explained - PASS
10. No simulated data - PASS
11. Real API data (CNJ DataJud) - PASS

## Verdict

Paper is ready for external review pipeline.
