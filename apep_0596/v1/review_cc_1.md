# Internal Review — Round 1
**Paper:** APEP-0596 — Panama Canal Drought and US Port Trade Diversion
**Reviewer:** Claude Code (Internal)
**Date:** 2026-03-11

## Overall Assessment

**Verdict: Minor Revision**

This is a well-executed null result paper with a clean identification strategy. The continuous treatment DiD exploiting differential Canal dependence across US ports is credible, the institutional background is thorough, and the null result is economically informative. The paper makes a genuine contribution by documenting trade infrastructure resilience — contrasting with Feyrer's (2021) Suez closure findings.

## Strengths

1. **Clean identification.** The canal_share = asian_share × is_canal_coast construction is clever and well-motivated. West Coast ports serve as a natural control because their Asian imports bypass the Canal entirely via direct Pacific routes.

2. **Comprehensive robustness.** Wild cluster bootstrap, randomization inference, leave-one-out, timing placebo, European-origin placebo, alternative specifications, and Houthi crisis controls. The battery is thorough.

3. **Well-framed null.** The discussion section does not apologize for the null result but rather explains it through three mechanisms: shipping rerouting, inventory buffers, and gradual onset. This turns the null into a contribution.

4. **Triple difference.** Canal-dependent vs European origins at the same ports is a strong within-port placebo that adds credibility.

## Issues to Address

### Methodology (Priority: High)

1. **Pre-trend visualization needs attention.** The event study figure should show whether pre-treatment coefficients are jointly insignificant. Consider adding an F-test for joint pre-trend significance and reporting the p-value in the text.

2. **Effective sample size concern.** With 186 ports and port-level clustering, the number of clusters is adequate. However, the paper should state explicitly how many ports have non-zero canal_share (i.e., how many actually receive "treatment"). If treatment is concentrated in a small number of ports, effective power may be lower than 186 clusters suggests.

3. **Interpretation of canal-origin import result.** The SDE for canal-origin imports is -0.011 ("small negative"). This deserves more discussion — it suggests some effect on the composition of imports even if total volumes are unaffected. Is this consistent with the rerouting hypothesis?

### Writing (Priority: Medium)

4. **Introduction could be sharper.** The hook about $5T in US-Asia trade is good but the transition to the specific research question could be tighter. Consider making the Canal drought more vivid — the 51% reduction in daily transits is a striking number that should appear earlier.

5. **Results narration.** Some tables are narrated column-by-column rather than telling a story. The main results section should lead with the key finding (null for total imports, small negative for Canal-origin) and then discuss robustness.

6. **Discussion section.** The comparison to Feyrer (2021) is well done but could go further. The key insight — that a partial restriction (reduced transits) differs fundamentally from a complete closure (Suez 1967-1975) — should be stated more crisply.

### Technical (Priority: Low)

7. **SDE table completeness.** The SDE appendix reports only two outcomes. Consider adding the triple-difference coefficient and the diversion test coefficient as additional rows for completeness.

8. **Figure quality.** Figures are clean but some could benefit from annotation — e.g., marking the drought onset on the time series plots, adding reference lines for pre/post periods.

## Recommendation

Proceed with external review after addressing items 1-3 (methodology) and 5-6 (writing). The paper is fundamentally sound.
