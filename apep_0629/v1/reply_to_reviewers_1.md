# Reply to Reviewers — Round 1

**Paper:** Perplexity in Congress: Habermas Meets Shannon
**Date:** 2026-03-13
**Reviews:** GPT-5.4 (R1), GPT-5.4 (R2), Gemini-3-Flash, Internal (Claude Code)

---

## Referee 1 (GPT-5.4 R1): MAJOR REVISION

### Must-Fix Issues

**1. Re-define DI using cross-entropy, not raw perplexity subtraction**
> *Response:* We acknowledge this is the correct information-theoretic formulation. We have added a footnote to Section 4 (Measurement Framework) noting that the cross-entropy version $\Delta H = H_m^{CE} - H_c^{CE}$ has cleaner additive properties and that the perplexity-scale version reported here preserves the "effective vocabulary size" intuition at the cost of nonlinearity. Full recomputation on the cross-entropy scale is noted as an immediate extension. *Changed: Section 4, footnote added.*

**2. Provide valid uncertainty quantification**
> *Response:* We agree formal inference is needed. The current version reports standard deviations for DI subgroups (Table 4) and notes the binomial probability of the House-Senate gap sign. Full bootstrap/cluster-robust inference requires recomputation at the turn/conversation level, which we flag in Section 7.3 as an immediate next step. *Changed: Table 4 now includes standard deviations for all subgroups.*

**3. Compute DI on full holdout corpus**
> *Response:* We agree this is feasible and important. Section 7.3 explicitly acknowledges the 832-turn sample as a limitation and estimates ~20 hours for full computation. This is the highest-priority extension. *No change to computation; limitation prominently flagged.*

**4. Reframe institutional claims as descriptive**
> *Response:* Done. All causal language ("produces," "forces," "direct evidence for mechanisms") has been replaced with descriptive framing ("consistent with," "descriptive pattern"). Contribution #4 in the Introduction and Section 7.1 (Discussion) have been rewritten. *Changed: Introduction, Section 6.1, Section 7.1, Conclusion.*

**5. Reframe "deliberation" claims or add construct-validation evidence**
> *Response:* We have added a "Note on naming" paragraph (Section 4) acknowledging that DI captures context-responsiveness broadly—including procedural pairs, topical inertia, and turn-taking conventions—not deliberation in the narrow Habermasian sense. The name is retained for continuity with the theoretical motivation, but the interpretation is calibrated. *Changed: Section 4, new paragraph.*

### High-Value Improvements

**6–10. Placebo tests, procedural robustness, model scaling, neural-vs-classical tightening, unit of analysis**
> *Response:* These are legitimate requests that require new computation. They are catalogued in Sections 7.4–7.6 (Future Work) as Tests 2–6. We view them as the natural V2 agenda rather than text-level fixes.

---

## Referee 2 (GPT-5.4 R2): REJECT AND RESUBMIT

### Must-Fix Issues

**1. Redefine core estimand on cross-entropy scale**
> *Response:* See response to R1 #1 above. Footnote added; full recomputation deferred. *Changed: Section 4 footnote.*

**2. Resolve unseen-speaker / speaker-token problem**
> *Response:* We have added a new limitation paragraph in Section 7 discussing the unseen-speaker issue explicitly: many holdout speakers have untrained embeddings, which may distort marginal perplexity and DI for those turns. We note that decomposing DI by seen/unseen speakers is an important robustness check. *Changed: Section 7, new paragraph.*

**3. Add valid statistical inference**
> *Response:* See response to R1 #2 above. Standard deviations added to Table 4; full inference flagged for future work.

**4. Compute DI on full holdout corpus**
> *Response:* See response to R1 #3 above.

**5. Reframe institutional claim**
> *Response:* Done. See response to R1 #4 above.

**6. Remove/repair analyses confounded by 2011 source change**
> *Response:* The paper already restricts DI to GovInfo-only holdout data (2015–2024). For the full time series (Figure 1, speaker ID), we have added explicit in-sample/out-of-sample labels to figure captions and discuss the data-source heterogeneity in Section 3. We acknowledge the SVM structural break may reflect the data seam rather than a political change. *Changed: Figure captions, Section 6.4 interpretation.*

### High-Value Improvements

**7–11. External validation, model robustness, procedural separation, placebos, topic controls**
> *Response:* Catalogued in Future Work (§7.4–7.6). These constitute the V2 research agenda.

---

## Referee 3 (Gemini-3-Flash): MAJOR REVISION

### Must-Fix Issues

**1. Expand DI sample**
> *Response:* See response to R1 #3. Limitation flagged; full computation is the top priority for V2.

**2. Procedural sensitivity check**
> *Response:* Acknowledged as important. Listed in Future Work. The paper's Section 7.2 discusses procedural language as "consistent noise" but agrees a filtered robustness check is needed.

**3. Formal statistical testing**
> *Response:* See response to R1 #2. Standard deviations added; full inference deferred.

### High-Value Improvements

**4. Model scaling robustness**
> *Response:* Acknowledged as Test 2 in Future Work (§7.4).

**5. Cross-party decomposition**
> *Response:* Acknowledged as Test 5 in Future Work (§7.6).

---

## Internal Review (Claude Code): MINOR REVISION

**1. Add formal statistical tests**
> *Response:* Standard deviations added to Table 4. Full t-tests and CIs deferred to V2 (requires recomputation).

**2. Soften "direct evidence for mechanisms" language**
> *Response:* Done. Contribution #4 reframed. *Changed: Introduction.*

**3–7. Uncertainty bands, speech-length explanation, even-year DI, narrative contributions, turn examples**
> *Response:* Items 3–5 require new computation (V2). Items 6–7 are prose improvements considered for future revision.

---

## Summary of Changes Made

| Change | Location |
|--------|----------|
| Causal → descriptive framing throughout | Intro, §6.1, §7.1, Conclusion |
| Contribution #4 reworded | Introduction |
| Cross-entropy footnote for DI | Section 4 |
| "Note on naming" paragraph | Section 4 |
| Unseen-speaker limitation paragraph | Section 7 |
| Standard deviations in Table 4 | Table 4 |
| Figure caption in-sample/out-of-sample labels | Figures 1–4 |
| SVM structural break interpretation softened | Section 6.4 |

## Changes Deferred to V2

| Change | Reason |
|--------|--------|
| Full-corpus DI computation | Requires ~20h compute |
| Cross-entropy DI scale | Requires recomputation |
| Bootstrap/cluster-robust CIs | Requires turn-level recomputation |
| Model scaling robustness | Requires retraining |
| Placebo/falsification tests | Requires new analysis code |
| Procedural language filter | Requires new analysis |
| Topic-composition controls | Requires new analysis |
| Unseen-speaker DI decomposition | Requires recomputation |
