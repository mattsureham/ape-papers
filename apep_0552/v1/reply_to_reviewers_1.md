# Reply to Reviewers — apep_0552 v1

## Response to Internal Review (Claude Code)

**R1.1: Add RDD covariate balance table.**
Acknowledged as a useful addition. The current paper includes donut RDD and polynomial sensitivity but lacks a formal covariate smoothness test. This is a limitation of the current version.

**R1.2: Power analysis for RDD and triple-difference.**
Acknowledged. The imprecision of these designs is an important limitation. The paper now frames these results as exploratory/suggestive rather than definitive.

**R1.3: Consider CS or Sun-Abraham estimator.**
Not critical given single-timing treatment (all properties face the same July 2021 reform date). Staggered ban dates (G:2025, F:2028, E:2034) affect anticipated severity but treatment timing is common.

---

## Response to GPT-5.4 R2 (Reject and Resubmit)

**R2.1: Reframe core claim away from "clean decomposition."**
**ACCEPTED.** Abstract, introduction, and conclusion have been substantially rewritten. The paper no longer claims to be "the first clean experiment" for separating information from regulation. Instead, it frames the contribution as: (a) documenting post-reform price penalties with evidence that multiple channels contribute, and (b) providing novel evidence of strategic manipulation at regulatory thresholds.

**R2.2: Treatment definition in RDD (energy only, ignoring emissions).**
Acknowledged as a valid concern. The RDD uses the energy consumption threshold (420 kWh/m²/year) as the running variable, which is the primary determinant for the vast majority of properties. The paper frames RDD results as suggestive/descriptive rather than sharp causal evidence.

**R2.3: Address manipulation as identification failure, not just attenuation.**
**ACCEPTED.** The paper already frames the RDD and DiDisc results as suggestive evidence compromised by manipulation. The manipulation finding is now elevated as a co-equal contribution alongside the price penalty.

**R2.4: Validate DVF-DPE match temporally.**
Acknowledged. The paper emphasizes that French law requires DPE before listing (loi n°2006-872), making pre-sale certification the legal norm. Temporal restriction to narrow pre-sale windows would reduce sample size and is left for future work.

**R2.5: Diagnose selection into matched sample.**
Acknowledged as a valid concern. Match rates differ pre/post, which could affect composition. The paper notes this as a limitation.

**R2.6: Stop treating event study as parallel trends evidence.**
**ACCEPTED.** Text now explicitly states: "a formal test of parallel trends—which requires at least two non-reference pre-treatment periods—is not feasible."

**R2.7-11: High-value improvements (better rental proxy, anticipation modeling, grade comparability, energy price salience).**
Partially addressed. The paper now acknowledges energy-price salience as an alternative explanation (new limitation paragraph). Better rental proxies and grade comparability checks are acknowledged as important future work.

---

## Response to Gemini-3-Flash (Major Revision)

**R3.1: Address heterogeneity reversal (houses > apartments).**
**ACCEPTED.** The paper now prominently features this finding in the abstract, introduction, and discussion. The heterogeneity pattern is interpreted as evidence that renovation costs and informational salience, not the rental ban alone, drive the discount.

**R3.2: Selection on unobservables in matching.**
Acknowledged. The 50m threshold is a pragmatic balance; narrower matching would reduce sample size substantially. This is noted as a limitation.

**R3.3: Decomposition of methodology change.**
Acknowledged as an important future research direction. Subsetting to 3CL-only properties would reduce sample size and is methodologically complex.

**R3.4: Dynamic puzzle (discount reversal by 2024).**
Already discussed in the event study section (partial reversion paragraph). The paper suggests manipulation, renovation, and market correction as possible explanations.
