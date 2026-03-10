# Revision Plan 1

## Overview
Comprehensive revision addressing feedback from 3 external referees (GPT-5.4 R1: R&R, GPT-5.4 R2: R&R, Gemini: Major Revision) plus exhibit and prose reviews.

## Key Changes

### 1. Narrowed Claims (All 3 reviewers)
- Changed all references from "trade adjustment" to "extra-EU import substitution"
- Abstract, introduction, and conclusion explicitly acknowledge intra-EU margin is unobserved
- Policy implications softened with appropriate caveats

### 2. Production Event Study Robustness (GPT R1, R2)
- Added country×month FE specification to 04_robustness.R
- Result: coefficient strengthens from -9.5 to -11.2 (SE widens from 3.3 to 6.4)
- Added to paper text as robustness check

### 3. Mechanism Language (All 3 reviewers)
- Reframed demand-destruction from "demonstrated" to "hypothesis consistent with evidence"
- Added paragraph listing alternative explanations (intra-EU substitution, macro contraction, price effects)
- Mechanism section now explicitly notes design cannot uniquely identify the channel

### 4. Placebo Interpretation (GPT R1, R2)
- Rewrote placebo section to acknowledge that significant placebo effects WEAKEN energy-intensity-specific identification
- Framed as diagnostic warning rather than supportive evidence

### 5. Limitations Strengthened (All 3 reviewers)
- Added two priority limitation paragraphs: (a) intra-EU trade, (b) values vs. quantities
- These appear FIRST in the limitations section

### 6. Rambachan-Roth Relabeled (GPT R1, R2)
- Renamed section to "Sensitivity to Parallel Trends Violations"
- Added note that bounds are analytical approximations, not formal HonestDiD

### 7. Table 11 Removed (Advisor rounds)
- Removed production DiD table with contradictory positive coefficients
- Fixed all cross-references to the removed table

## Not Addressed (Beyond Scope)
- Intra-EU trade data analysis (requires new data pipeline)
- Quantity/volume trade measures (Eurostat availability constraints)
- HS4/HS6 granular product data (coverage limitations for 2023-24)
- Downstream IO linkages (requires national IO tables matched to trade data)
- Formal HonestDiD implementation (requires reworking the R pipeline)

These are acknowledged as limitations and directions for future work.
