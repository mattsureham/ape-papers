## Discovery
- **Idea selected:** idea_1971 — CRP acreage cap reduction (2014 Farm Bill) and land-use transitions. Chosen for sharp national policy lever with county-level dose variation, first-order environmental outcome, and large sample (2,476 counties).
- **Data source:** FSA CRP enrollment Excel (county-level, 1986-2024) + NASS QuickStats crop acreage API. FSA site required browser user-agent for downloads. CRP enrollment is NOT in NASS — it's a separate FSA product.
- **Key risk:** The idea manifest promised satellite CDL data as the primary outcome. I pivoted to NASS survey data for feasibility — all three reviewers flagged this as the biggest weakness.

## Execution
- **What worked:** The continuous-treatment DiD is clean and the corn result is robust (significant at 5%, survives all LOO, placebo passes). The "corn conversion" narrative is vivid and memorable.
- **What didn't:** Total planted acreage is insignificant — the real story is crop composition change, not total expansion. The dose-response by quartile is also weak. Without satellite data, can't confirm whether this is extensification (CRP→corn) or intensification (wheat→corn on existing cropland).
- **Review feedback adopted:** (1) Changed title to remove satellite framing, (2) Clarified crop substitution vs. extensification distinction in new "Crop Substitution or Extensification?" subsection, (3) Added explicit event study coefficients and p-values to text, (4) Added honest acknowledgment of NASS vs. CDL limitation in the contribution discussion.
