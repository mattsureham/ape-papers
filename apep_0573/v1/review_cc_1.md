# Internal Review - Claude Code (Round 1)

**Role:** Internal referee (Reviewer 2, skeptical)
**Timestamp:** 2026-03-10T13:20:00
**Paper:** Can Procedure Produce Competition? Evidence from EU Procurement Reform

---

## PART 1: CRITICAL REVIEW

### 1. Identification and Empirical Design

The paper exploits staggered transposition of EU Directive 2014/24/EU across 28 member states. The identification strategy is reasonable: the directive deadline was set exogenously at the EU level, and transposition delays reflect legislative capacity rather than procurement conditions. The paper correctly identifies the key threats (anticipation, composition, spillovers) and addresses them.

**Concern 1: Pre-trends.** The joint F-test yields p<0.001, which is a red flag. The paper handles this well by: (a) emphasizing the null survives even with trends, (b) showing small pre-trend magnitudes, (c) Rambachan-Roth sensitivity, and (d) RI p=0.995. The defense is adequate but should be more prominent.

**Concern 2: Treatment intensity.** The paper treats transposition as binary (0/1), but implementation quality and speed of actual adoption by contracting authorities likely varied within and across countries. The paper could benefit from a discussion of this measurement issue.

**Concern 3: C-S SME result.** The Callaway-Sant'Anna estimator finds a significant negative effect on SME shares (-0.202, SE 0.096) that the TWFE misses. This divergence deserves more attention — it could reflect heterogeneous treatment effects across cohorts that the TWFE averages away.

### 2. Inference and Statistical Validity

- Standard errors clustered at country level (28 clusters) — appropriate
- Pairs cluster bootstrap confirms the null (p=1.00)
- Randomization inference (1,000 permutations, p=0.995) — strong
- Sample sizes reported and coherent
- Goodman-Bacon decomposition (90.4% clean comparisons) supports TWFE credibility

**Minor issue:** The within-R² of 1.65×10⁻⁷ is correctly interpreted as the treatment having essentially zero explanatory power, but a brief note confirming this is not a computational artifact would strengthen confidence.

### 3. Robustness and Alternative Explanations

The robustness battery is comprehensive: RI, LOO, Bacon decomposition, C-S, Sun-Abraham event study, Rambachan-Roth, sector FE, alternative timing, placebo tests. This is a model robustness section for a null-result paper.

**Gap:** No dose-response test. Countries that transposed earlier get more "treatment exposure" — does the effect of years-since-transposition matter? This could distinguish "too early to tell" from "genuinely null."

### 4. Contribution and Literature Positioning

The paper positions itself well in three literatures. The key citations (Coviella & Mariniello, Palguta & Pertold, Szucs, Bosio et al., Cingano et al.) are appropriate. The distinction between procedural vs. structural barriers is the paper's main intellectual contribution.

### 5. Results Interpretation

The null is well-calibrated. The paper correctly identifies it as informative rather than disappointing. The mechanistic discussion (structural barriers > procedural barriers) is the paper's strongest section.

**Minor concern:** The award ratio result (-0.042, p=0.072) is discussed appropriately as "suggestive" but receives considerable attention for a marginally significant finding among five outcomes. Multiple testing is not discussed.

### 6. Actionable Revision Requests

**Must-fix:**
1. Harmonize the discussion of pre-trends — the raw trends section should not imply parallel trends when the F-test rejects.

**High-value:**
2. Add a dose-response / years-since-treatment analysis
3. Discuss multiple testing for the award ratio result
4. Expand the C-S SME discussion — this is the most interesting finding

**Optional:**
5. Consider consolidating Tables 3 and 4
6. Add a Bacon decomposition plot

## PART 2: CONSTRUCTIVE SUGGESTIONS

The paper's strongest asset is turning a null result into a genuine contribution through the structural-vs-procedural barriers framework. The writing in the Discussion section is excellent.

To increase impact:
- The heterogeneity analysis by administrative capacity is the right test. Consider adding heterogeneity by baseline competition level (countries with highest single-bidder rates should benefit most if the reform works).
- The award ratio finding, while marginally significant, could be developed further with a mechanism analysis (which procedure types drive it?).

## 7. Overall Assessment

**Strengths:** Credible identification, comprehensive robustness, strong data (10.9M contracts), excellent null-result framing, clear policy implications.

**Weaknesses:** Pre-trend concern (addressed but not eliminated), C-S SME divergence underexplored, limited mechanism analysis for the award ratio result.

**Publishability:** Suitable for AEJ: Economic Policy after minor revision. The null result is informative, well-executed, and policy-relevant.

DECISION: MINOR REVISION
