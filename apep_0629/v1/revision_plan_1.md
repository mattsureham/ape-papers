# Revision Plan — Round 1

**Date:** 2026-03-13
**Reviews received:** GPT-5.4 (R1): MAJOR REVISION; GPT-5.4 (R2): REJECT AND RESUBMIT; Gemini-3-Flash: MAJOR REVISION
**Internal review:** Claude Code: MINOR REVISION

---

## Consensus Issues Across Reviewers

1. **Causal over-claiming** (all 3 referees + internal): Paper uses causal language ("produces," "forces," "direct evidence") for what is a descriptive House-Senate comparison.
2. **DI construct validity** (all 3): "Deliberation Index" conflates multiple forms of context dependence (procedural, topical, deliberative).
3. **DI sample size** (all 3): 832 turns from 5 odd years is too small for the paper's central contribution.
4. **No formal statistical inference** (all 3 + internal): Missing SEs, CIs, p-values for main estimates.
5. **DI scale** (R1, R2): Perplexity-scale subtraction lacks clean information-theoretic interpretation; should use cross-entropy.
6. **No robustness to model specification** (all 3): Single 40.6M model, one training run.
7. **No placebo/falsification tests** (R1, R2): Cannot distinguish conversational coupling from topic continuity.
8. **Procedural language confound** (R1, R2, Gemini): House may have more formulaic text, mechanically lowering perplexity.
9. **Unseen speakers** (R2): Many holdout speakers absent from training; DI conditioning on speaker identity may be distorted.

---

## Revision Decisions

### Text-level fixes (implementable now)

| Issue | Action | Status |
|-------|--------|--------|
| Causal language throughout | Reframe to "consistent with" / descriptive | **DONE** |
| Contribution #4 causal claim | Reworded to descriptive evidence | **DONE** |
| Discussion §7.1 institutional design | Reframed as descriptive, not causal | **DONE** |
| DI naming concern | Added "A note on naming" paragraph acknowledging DI captures context-responsiveness broadly | **DONE** |
| DI scale footnote | Added footnote noting cross-entropy version has cleaner information-theoretic properties | **DONE** |
| Unseen speakers | Added limitation paragraph in Discussion | **DONE** |

### Analysis-level requests (noted for future work / V2 revision)

These require new computation and are beyond the scope of text-level revision:

| Issue | Disposition |
|-------|------------|
| Full-corpus DI (all holdout years) | Acknowledged in §7.3; feasible in ~20h; noted as immediate extension |
| Cross-entropy DI scale | Footnoted; full recomputation deferred to V2 |
| Statistical inference (CIs, p-values) | Requires recomputation; noted in §7.3 limitations |
| Model scaling robustness | Acknowledged in §7.4 as Test 2 |
| Placebo/falsification tests | Acknowledged in §7.6 as Test 4 |
| Procedural language filter | Acknowledged as important robustness check |
| Unseen speaker DI decomposition | Noted in limitation paragraph |
| Topic-composition controls | Acknowledged in §7.6 future work |

---

## Rationale for Partial Revision

This is a V1 publication of a methodology/measurement paper. The reviewers' analysis-level requests are legitimate and would strengthen the paper substantially. However, they require new computation (retraining models, rerunning DI on full corpus, implementing placebo tests) that constitutes a new research phase rather than a text revision.

The text-level fixes address the most critical framing issues:
- Causal language is removed throughout
- DI is explicitly acknowledged as measuring context-responsiveness, not deliberation specifically
- The cross-entropy scale issue is footnoted
- Unseen speakers are discussed as a limitation

The paper is positioned honestly as a first contribution with a clear roadmap for the extensions reviewers request.
