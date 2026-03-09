# Reply to Reviewers — Round 1

## Overview

All three reviewers identified the same core issue: the parallel trends assumption fails, and the paper cannot credibly identify the causal effect of the Loi 2003. We agree completely. The revision fundamentally reframes the paper as a **measurement/diagnostic contribution** rather than a causal policy evaluation.

Key changes:
1. **New abstract and introduction** — all causal language removed; paper framed as documenting a measurement problem
2. **Department-specific linear trends** — added as the most important robustness check; shows baseline association disappears (β = -0.36, SE = 1.61)
3. **Region × year FE and narrow window** — added as additional robustness specifications
4. **Full PPML decomposition** — now in main robustness table; confirms minor/severe pattern directionally even in count models
5. **Literature update** — added Roth (2022), Rambachan and Roth (2023), Goldsmith-Pinkham et al. (2020), Borusyak et al. (2022), de Chaisemartin and D'Haultfoeuille (2020), Johnson (2020)
6. **Title change** — from "Inspectors or Inspections?" to "Detection or Deterrence? A Measurement Problem in Enforcement-Generated Safety Data"
7. **Conclusion rewritten** — moderate all policy claims, acknowledge power limitations

---

## Point-by-Point Responses

### Reviewer 1 (GPT-5.4 R1) — REJECT AND RESUBMIT

**1. Reframe away from causal estimate of Loi 2003 (Must-fix)**
- **Done.** Abstract, introduction, results, and conclusion completely rewritten. The paper now explicitly states: "The paper therefore cannot identify the causal effect of the Loi 2003" and frames the contribution as a measurement diagnostic.

**2. Validate treatment intensity with actual enforcement data (Must-fix)**
- **Acknowledged as limitation.** Department-level inspector allocation data are not publicly available. The paper now states this clearly and narrows mechanism claims to "reporting/detection expansion" rather than specifically "inspector detection."

**3. Replace current Seveso counts with historical pre-period counts (Must-fix)**
- **Acknowledged as limitation.** Historical Georisques snapshots are not available. The paper discusses this as a source of classical measurement error and notes it would attenuate estimates toward zero.

**4. Address pre-trend problem with design-based sensitivity analysis (Must-fix)**
- **Done.** Added: (a) department-specific linear trends, which eliminate the effect; (b) narrow window (1998-2006); (c) region × year FE. Added citations to Roth (2022) and Rambachan-Roth (2023).

**5. Resolve estimator choice and center count-appropriate models (Must-fix)**
- **Done.** Full PPML decomposition (total, minor) now in robustness table. Paper explicitly discusses the OLS/PPML discrepancy and presents it as substantive, not incidental.

**6-12. High-value and optional improvements**
- Timing structure: acknowledged in discussion; cannot distinguish AZF salience from Loi 2003 given pre-trends.
- Mechanism claims narrowed throughout.
- "Precise zero" language replaced with "no evidence of an effect" plus power discussion.
- Literature substantially expanded per recommendations.

### Reviewer 2 (GPT-5.4 R2) — REJECT AND RESUBMIT

**1. Redesign identification strategy (Must-fix)**
- **Reframed.** Paper now explicitly presents results as associations/descriptive patterns, not causal estimates. Department trend specification confirms the association reflects pre-existing trends.

**2-3. Historical treatment data and first-stage demonstration (Must-fix)**
- **Acknowledged as limitations.** Not feasible with public data. Paper now states these data gaps clearly.

**4. Recalibrate all causal language (Must-fix)**
- **Done throughout.** Abstract uses "association," intro says "cannot identify the causal effect," conclusion uses "the paper therefore cannot identify the effect of the Loi 2003."

**5-9. High-value improvements**
- Trend-adjusted specifications: done (dept trends, region×year, narrow window).
- Count models: PPML decomposition added.
- Alternative mechanisms: section rewritten to list all channels without privileging inspector detection.
- Severe = detection-inelastic: acknowledged as assumption, not established.

### Reviewer 3 (Gemini-3-Flash) — MAJOR REVISION

**1. Address pre-trend violation (Must-fix)**
- **Done.** Department-specific trends eliminate the effect. Paper reframed accordingly.

**2. Reconcile OLS and Poisson (Must-fix)**
- **Done.** Full PPML decomposition in Table 3 Panel C. Discrepancy discussed substantively.

**3. Exploit within-department variation (High-value)**
- **Acknowledged as future work.** Plant-level linkages would require non-public data. Paper discusses this in the conclusion.
