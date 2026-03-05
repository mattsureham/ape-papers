# Reply to Reviewers — Revision 1

## Overview

All three referees recommended MAJOR REVISION. The key concerns were: (1) the Sun-Abraham vs TWFE standard error divergence, (2) the failing wood placebo test, (3) the 2016–2020 data gap and its implications for the estimand, (4) the opening paragraph, and (5) limited power analysis. I address each below.

---

## Changes Made

### 1. Power Analysis / MDE (All reviewers)

**Concern:** Wide confidence intervals include economically meaningful effects; no formal power calculation.

**Response:** Added MDE calculation to the Limitations section: "The TWFE standard error of 0.0081 implies a minimum detectable effect (MDE) of approximately 1.6 percentage points at 80% power and α = 0.05 (MDE ≈ 2.8 × SE)." This makes explicit that the design can detect effects of ~1.6pp but not smaller ones, contextualizing the null.

### 2. Sun-Abraham vs TWFE SE Divergence (All reviewers)

**Concern:** The Sun-Abraham SE (0.00094) is nearly an order of magnitude smaller than the TWFE SE (0.0081), which is "highly unusual" (Gemini) and raises questions about inference validity.

**Response:** Substantially expanded the Sun-Abraham discussion (Section 5.1) to explain three contributing factors: (a) cohort-specific estimation reduces variance when some cohorts contribute clean comparisons; (b) TWFE pooling across heterogeneous exposure lengths inflates variance; (c) the positive semi-definite VCOV correction may produce optimistic SEs. Added explicit caveat: "The Sun-Abraham significance should not be taken at face value given the VCOV correction and the fact that wild cluster bootstrap and randomization inference (applied to the TWFE specification) cannot reject zero." Recommended readers weight both estimates jointly.

### 3. Wood Placebo as Limitation (All reviewers)

**Concern:** The significant wood placebo failure (−2.2pp, p=0.02) "strongly suggests that adopting cantons were already on differential environmental trajectories" and "undermines the causal interpretation of the fossil fuel results."

**Response:** Rewrote the wood placebo discussion to explicitly frame it as a limitation that weakens the fossil/gas causal claims. New text: "I treat the wood placebo failure as a limitation that weakens the causal interpretation of the fossil fuel and gas results specifically. The gas coefficient (−1.6 pp, p = 0.04) and the fossil fuel coefficient (−1.4 pp, p = 0.03) may partly reflect confounding from correlated cantonal policies rather than a pure MuKEn 2014 effect." Explained why the heat pump result is more robust to this concern.

### 4. Opening Paragraph (Prose review)

**Concern:** "The opening reads like a policy brief overview rather than an empirical paper in a top economics journal."

**Response:** Rewrote the first paragraph to lead with the puzzle — the striking fact that heat pump adoption doubled while being largely uncorrelated with code adoption timing. The new opening follows Shleifer-style writing: a vivid empirical observation that immediately creates reader curiosity.

### 5. Data Gap Estimand (GPT-5.2, Grok)

**Concern:** The paper "frames the estimates as effects 'of adoption' rather than effects of being treated by 2021–2022" and the estimand needs clarification given the 2016–2020 gap.

**Response:** Substantially expanded the Limitations section with three specific consequences of the data gap: (a) the estimand is the effect on 2021–2022 stock shares of cumulative exposure, not a dynamic adoption effect; (b) parallel trends cannot be tested during 2015–2021; (c) conventional event studies with leads/lags are infeasible. Elevated the long-difference specification as "arguably the most honest representation of what the data can identify."

---

## Changes NOT Made (with rationale)

### Micro-level building data (GPT-5.2, Grok)
Reviewers suggested using building-level GWR data to separate new construction vs. retrofits. This would require a fundamentally different data pipeline using restricted-access microdata that is not available through the public BFS statistics used here. Noted as future research direction.

### Green party vote share controls (Gemini)
Controlling for time-varying cantonal politics (e.g., Green vote shares) would require assembling a separate cantonal political dataset. This is a valuable extension but beyond the scope of the current revision. The wood placebo discussion now explicitly acknowledges confounding from political orientation.

### Synthetic control / IFE methods (GPT-5.2)
These alternative estimators (generalized synthetic control, interactive fixed effects) represent a different methodological approach. The current paper's contribution is the staggered DiD evaluation; alternative methods are noted as future work in limitations.

### Wild bootstrap for Sun-Abraham (GPT-5.2)
Few-cluster-robust inference for the Sun-Abraham estimator is not straightforward to implement and would require custom coding beyond standard fixest functionality. The paper now includes explicit caveats about Sun-Abraham precision.

### Anticipation effects analysis (Gemini)
Testing for builder anticipation of the code would require permit-level data with heating system specifications, which is not available in the aggregate statistics. Discussed qualitatively in the policy implications section.
