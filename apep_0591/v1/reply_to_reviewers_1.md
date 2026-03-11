# Reply to Reviewers (Round 1 — Internal Review)

## Critical Issue: RI Misrepresentation

> The paper incorrectly claims RI results "lie well in the tail" when p = 0.446.

**Fixed.** Completely rewrote the RI discussion in both the Robustness section and RI Appendix. The paper now:
- Reports the RI p-value of 0.446 honestly
- Interprets this as evidence that identification relies on share exogeneity (GPSS 2020) rather than shock quasi-randomness (BHJ 2022)
- Points to pre-trend tests and the cohort placebo as the primary validity evidence
- Updated RI figure notes to reflect the correct interpretation
- Added forward reference in the Identifying Assumptions section

## Abstract Length

> Abstract exceeds 150 words.

**Fixed.** Trimmed to ~130 words by removing redundant phrasing while preserving all key information.

## Cross-Sectional IV Weakness

> F = 2.4 makes the cross-sectional IV uninformative.

**Fixed.** Reworded to acknowledge that the cross-sectional IV is "unreliable" and "severely susceptible to weak-instrument bias." Added: "I include these results for transparency but do not draw inference from the cross-sectional IV."

## Employment Placebo Significance

> The 25-64 employment effect is significant (p = 0.024), partially undermining age-specificity.

**Fixed.** Rewrote to distinguish the human capital placebo (sharply age-specific) from the employment spillover (broader, consistent with compositional effects). Framed the employment spillover as a downstream consequence rather than evidence against the mechanism.
