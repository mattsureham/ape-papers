# Internal Review (Round 1)

**Verdict: MAJOR REVISION**

## Summary

Strong paper with a compelling research question, powerful first stage, and creative cohort placebo test. The shift-share IV design is well-executed and the institutional knowledge is excellent. However, there is a **critical integrity issue** with the randomization inference discussion, and several areas need improvement.

## Critical Issues

### 1. MISREPRESENTATION OF RANDOMIZATION INFERENCE (CRITICAL)

The paper text contains factually incorrect claims about the RI results:

- **Line ~347 (Robustness section):** "the observed coefficient lies well in the tail of the permutation distribution" — FALSE. With RI p = 0.446, the coefficient is near the CENTER of the distribution.
- **Same paragraph:** "The randomization inference p-value is consistent with the parametric inference from clustered standard errors" — FALSE. RI p = 0.446 vs. clustered p = 0.004 — these are wildly inconsistent.
- **Abstract:** Does not mention the RI p-value, but the robustness section text is misleading.
- **Appendix B, RI Details (line ~515):** "The observed coefficient lies in the tail of this distribution, with a p-value consistent with the parametric inference" — ALSO FALSE.

This must be corrected immediately. The honest interpretation: RI permutes destination shocks while holding shares fixed. A high RI p-value means that once you shuffle which destinations grow, the result disappears — the identification comes primarily from the share structure (consistent with Goldsmith-Pinkham et al. 2020 interpretation) rather than shock exogeneity alone. This is an important methodological nuance that should be discussed honestly, not hidden.

### 2. Abstract Length (~170 words, should be ≤150)

The abstract exceeds the 150-word target. Trim to fit on page 1 cleanly.

## Major Issues

### 3. Two-Way Clustering Weakens to p = 0.072

Under Adao-Kolesar-Morales two-way clustering, the main result is borderline significant (p = 0.072). This is honestly reported but the discussion doesn't adequately address what this means for inference. The paper should note that the one-way clustered SE (p = 0.004) is the primary inference and the two-way result reflects conservative adjustment for potential correlated shocks.

### 4. Cross-Sectional IV Is Uninformative (F = 2.4)

The cross-sectional specification has a first-stage F of 2.4 — well below any threshold for instrument relevance. The IV estimate of 4.81 is likely severely biased by weak instruments. This should be acknowledged more clearly as uninformative rather than presented as complementary evidence.

## Minor Issues

### 5. Employment Placebo Is Actually Significant (p = 0.024)

The paper describes the 25-64 employment effect as "weaker" (β = -4.39, p = 0.024), but p = 0.024 is statistically significant at 5%. This partially undermines the age-specificity argument. The discussion handles this with a "compositional spillover" story, which is reasonable, but should be framed more carefully.

### 6. Table Formatting

- Tab4 (placebo) column headers show "Tert 25-34" on a second row — could be cleaner.
- Some tables use \scriptsize while others use \footnotesize — inconsistent sizing.

### 7. Writing Polish

- The conclusion is strong but could be punchier.
- The last sentence of the paper ("The drain is real. The question is what Europe does about it.") is excellent.
- Institutional background section is thorough but slightly long — could be tightened by 1-2 paragraphs.

## Recommendation

Fix the RI misrepresentation (critical), trim the abstract, and discuss the RI findings honestly. The cohort placebo remains the strongest identification test regardless of the RI result. The paper is otherwise well-structured and compelling.
