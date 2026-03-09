# Reply to Reviewers

## Reviewer 1 (GPT-5.4 R1) — REJECT AND RESUBMIT

### 1. Identification: commodity-specific confounds
**Concern:** High-CMI and low-CMI groups differ on many dimensions beyond cash mediation (seasonality, exchange rate exposure, storability, etc.).
**Response:** We added three new robustness checks. (1) **CMI × month seasonality controls** (β = 0.151, p < 0.001) — adding commodity-group × calendar-month interactions strengthens the result. (2) **Cereals-only comparison** (β = -0.160, p < 0.001) — within the narrower cereals category, the sign reversal is consistent with supply disruption. (3) We softened all causal language throughout the paper.

### 2. RI results undermine claims
**Concern:** RI p-values of 0.41 and 0.44 conflict with conventional p < 0.001.
**Response:** We restructured the abstract, introduction, and conclusion to present findings as "suggestive evidence consistent with" rather than "causal estimates." The inferential limitation is now prominently acknowledged in the abstract itself.

### 3. Claims too strong
**Concern:** "First causal estimates" and "demonstrates" are too strong.
**Response:** Replaced throughout with "first evidence," "suggests," "consistent with," and "suggestive evidence."

### 4. Rice mechanism overstated
**Concern:** "Isolates the supply disruption channel" is too strong.
**Response:** Changed to "consistent with the supply disruption channel."

### 5. Extended window interpretation
**Concern:** Feb-Dec 2023 mixes many shocks beyond cash scarcity.
**Response:** Added a note in the results discussion that the extended window should be interpreted more cautiously.

### 6. Additional placebos needed
**Concern:** Single 2021 placebo insufficient.
**Response:** Acknowledged as limitation. The available pre-period data constrains the number of independent placebos.

### 7. Welfare calculation too precise
**Concern:** Back-of-envelope welfare appears over-precise.
**Response:** Reframed as "illustrative only" with explicit caveat about underlying inferential limitations.

## Reviewer 2 (GPT-5.4 R2) — MAJOR REVISION

### 1. Inference problem (same as R1)
**Response:** Same as above — all claims softened throughout.

### 2. Commodity grouping validation
**Concern:** Binary CMI conflates local/imported with many other features.
**Response:** Added commodity classification table (Appendix D) for full transparency. Added cereals-only specification as within-category test. The seasonality control specification confirms the result survives commodity-group × month interactions.

### 3. Spatial variation in cash shortage
**Concern:** Design treats crisis as homogeneous, but cash shortage varied across states.
**Response:** Acknowledged as a limitation. State-level cash shortage proxies would strengthen the design but are not available in the current data.

### 4. External validity
**Concern:** WFP markets concentrated in humanitarian areas.
**Response:** Added explicit caveat about geographic concentration in WFP-monitored markets, primarily in the North-East humanitarian corridor.

## Reviewer 3 (Gemini-3-Flash) — MAJOR REVISION

### 1. Wild cluster bootstrap
**Concern:** Standard remedy for few clusters.
**Response:** Previously attempted but failed due to singleton FE structure. This limitation is noted in the paper.

### 2. Balanced panel
**Concern:** Ensure results aren't driven by markets dropping out.
**Response:** Added balanced-panel specification (β = 0.221, SE = 0.055). Only 1,663 obs/2 states survive the restriction, so inference is fragile, but the direction is consistent.

### 3. Perishable vs storable split
**Concern:** Formalize the commodity-level heterogeneity.
**Response:** The cereals-only specification addresses this partially by showing that within storable staples, the supply disruption channel dominates.

### 4. Commodity classification table
**Concern:** List every commodity and its CMI assignment.
**Response:** Added as Appendix D (Table A.1).
