# Internal Review — Claude Code (Round 1)

**Role:** Self-review (Reviewer 2 mode)
**Paper:** Perplexity in Congress: Habermas Meets Shannon
**Timestamp:** 2026-03-13

---

## PART 1: CRITICAL REVIEW

### 1. Identification and Empirical Design

**Strengths:**
- The House-Senate comparison exploits plausibly exogenous institutional variation (different procedural rules, different chamber size). The within-year comparison absorbs political environment.
- The training/holdout temporal split (1994-2014 / 2015-2024) is clean and clearly described.
- The three-level decomposition (Hc, Hm, D) is well-motivated and provides complementary perspectives.

**Weaknesses:**
- This is fundamentally a descriptive/measurement paper, not a causal inference paper. The paper is honest about this ("necessary conditions, not sufficient ones"), but the contributions list on p.3 claims "direct evidence for mechanisms theorized by Persson-Tabellini," which overstates what a descriptive comparison can show.
- The Deliberation Index is computed on only 832 turns from 5 odd-numbered years. This is acknowledged but remains a limitation for the paper's core innovation.
- No formal statistical test of the House-Senate gap is reported (though the text mentions a binomial test probability < 0.1%).

### 2. Inference and Statistical Validity

**Weaknesses:**
- Table 4 reports means and standard deviations but no confidence intervals, p-values, or t-tests for key comparisons (House vs. Senate DI, overall DI ≠ 0).
- The perplexity time series (Figure 1) shows no uncertainty bands. Each year's perplexity is presumably an average over many turns — standard errors are computable.
- The 85% positive DI claim lacks a formal test against the null that D = 0.

### 3. Robustness and Alternative Explanations

**Strengths:**
- The honest accounting section (7.2) is unusually thorough for what perplexity captures vs. doesn't.
- The neural vs. classical comparison (Section 6.4) provides a compelling complementary perspective.

**Weaknesses:**
- No robustness to alternative model specifications (depth, context window, tokenizer). The paper acknowledges this but the scaling analysis is listed as future work.
- The claim that House's higher DI reflects procedural forcing of engagement is one interpretation. An alternative: House speeches are shorter, so context (relative to speech length) contributes more mechanically.

### 4. Contribution and Literature Positioning

**Strengths:**
- The literature review is comprehensive and well-positioned. The gap (autoregressive + from-scratch + measurement) is clearly identified.
- The connections to Habermas, Shannon, Persson-Tabellini are intellectually rich.

### 5. Results Interpretation

The paper is generally well-calibrated. The "counterintuitive" House DI > Senate DI finding is appropriately flagged. The one-shot/frontier framing is honest and effective.

---

## PART 2: CONSTRUCTIVE SUGGESTIONS

### Must-Fix
1. Add formal statistical tests: t-test for DI ≠ 0, confidence interval for House-Senate DI gap, p-value for the House-Senate perplexity gap.
2. Soften the "direct evidence for mechanisms" language in contributions — this is suggestive evidence consistent with theory, not a causal test.

### High-Value Improvements
3. Add uncertainty bands to the perplexity time series figure.
4. Discuss the mechanical speech-length explanation for House > Senate DI.
5. Report DI results for even-numbered years (2016, 2018, 2020, 2022, 2024) even if as robustness.

### Optional Polish
6. The contributions list could be woven into narrative per prose review suggestion.
7. Add a concrete turn example (high-DI vs low-DI) as the exhibit review suggests.

---

## 7. Overall Assessment

**Key strengths:** Novel measurement framework, clean exposition for social scientists, transparent about limitations, compelling institutional comparison, highly accessible methodology.

**Critical weaknesses:** Lack of formal statistical inference on core estimates, sampled DI (832 turns), no robustness across model specifications.

**Publishability:** This is a strong methodology paper with a clear contribution. With statistical tests added and the DI sample expanded (or the limitation more prominently flagged), it would be suitable for a computational social science venue or a methods-focused political economy outlet.

DECISION: MINOR REVISION
