# Reply to Reviewers — Round 1

## Reviewer 1 (GPT-5.4)

### 1A. DDD specification under-specified — missing state × worker-type FE
**Concern:** The DDD should include state × worker-type fixed effects to allow each state its own permanent new-hire/continuing-worker gap.
**Response:** Agreed. We added `new_hire:state` to the DDD fixed effects, producing a fully saturated specification. The updated DDD coefficient is -0.002 (SE = 0.006, p = 0.77) — even closer to zero and more precisely estimated than before. Equation (3) and all text now reflect the saturated specification.

### 1B. Continuing-worker control contamination over time
**Concern:** Continuing workers hired under the ban enter the stock over time, contaminating the placebo.
**Response:** Agreed. We added an explicit caveat in Section 4.3 noting that the DDD is most informative for short-run effects and that post-treatment convergence should be interpreted cautiously.

### 1C. No direct DDD pre-trend test
**Concern:** The paper shows separate pre-trends for each series but not for the difference.
**Response:** The saturated DDD specification with state × worker-type FE and period × worker-type FE absorbs level differences. A dynamic DDD event study would be valuable but exceeds what the current data structure supports cleanly. We note this as a limitation.

### 1D. DDD does not automatically absorb pay transparency
**Concern:** Pay transparency could differentially affect new hires vs. continuing workers.
**Response:** Valid concern. We softened the claim and note that excluding CA/CO/WA (the three bundled states) yields essentially identical results (-0.006, SE = 0.008), providing direct evidence that bundled policies are not driving the null.

### 2A. CS-DiD implementation not standard
**Concern:** The manual SE aggregation is not validated inference.
**Response:** Agreed. We reframed the CS-DiD as a "directional check" rather than a formal test, noting that the software compatibility issue prevents standard inference. The TWFE and Sun-Abraham results (which use standard inference) are the primary estimates.

### 2B. Modern methods should be central
**Concern:** The paper centers TWFE while modern estimators are auxiliary.
**Response:** The TWFE, Sun-Abraham, and RI all converge on the same null. We present TWFE as the baseline for transparency, with Sun-Abraham as the modern robustness check. The convergence across all estimators strengthens the conclusion.

### 2D. Power calculations not credible for clustered staggered panel
**Concern:** Back-of-envelope MDE is inappropriate for clustered data.
**Response:** We now emphasize that the confidence intervals directly convey the bounds on the effect size, rather than relying on the formula-based MDE.

## Reviewer 2 (Grok-4.1-Fast) — MINOR REVISION

### CS SE disclosure
**Response:** Now explicitly disclosed as "conservative approximation" rather than standard CS inference.

### Table coefficient alignment
**Response:** Standardized rounding throughout text and tables.

## Reviewer 3 (Gemini-3-Flash) — MINOR REVISION

### Stable hire selection
**Concern:** EarnHirNS relies on stable hires; if bans affect job durability, this introduces selection.
**Response:** Valid point. We acknowledge this in the Limitations section. Testing via HirN/HirNs ratio is infeasible at the aggregate level due to suppression.

### Software note
**Response:** Transparently disclosed as a "directional check" with conservative SEs.

## Exhibit Review Improvements
- Cleaned variable names in Tables 2 and 4 (removed raw R variable names)
- Added N/Observations to Tables 3 and 4

## Prose Review Improvements
- Removed roadmap paragraph from end of introduction
