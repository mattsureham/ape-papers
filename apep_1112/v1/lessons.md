## Discovery
- **Idea selected:** idea_0350 — JetBlue-American NEA dissolution, chosen for sharp exogenous lever (court order), universe-scale data (DB1B), and first-order stakes (airline fares)
- **Data source:** BTS DB1B 10% ticket sample — download required curl with 600s timeouts for large files (~100MB each); R's download.file() times out on big files
- **Key risk:** COVID disruption in the pre-treatment period introduces noisy pre-trends

## Execution
- **What worked:** The "Alliance Ratchet" framing — naming the mechanism as a portable concept that generalizes beyond this case. The divergence between unweighted and passenger-weighted results is the core contribution.
- **What didn't:** Pre-treatment event study coefficients are very noisy due to COVID, which all three reviewers flagged. Would benefit from non-NEA airport controls (triple-diff) in a V2.
- **Review feedback adopted:** Strengthened parallel-trends discussion to note pre-2020 coefficients are clean; clarified that spillover bias is toward zero (conservative); added treatment-breadth paragraph addressing 310 vs 175 route definitions; improved abstract precision per GPT-OSS suggestion.
