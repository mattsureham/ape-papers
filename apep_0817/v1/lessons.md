## Discovery
- **Idea selected:** idea_0740 — FEMA declaration lag as continuous IV treatment; massive variation (1-247 days), no prior economic study
- **Data source:** OpenFEMA API — free, keyless, reliable. Paginated fetching required batched filtering by disaster number to avoid API limits
- **Key risk:** IV validity — concurrent disaster load instrument may not satisfy exclusion restriction

## Execution
- **What worked:** The data fetch was smooth. OpenFEMA provides rich city-level administrative data. The sample (364 disasters, 57K city-level obs) far exceeded the idea manifest estimate of 104 disasters
- **What didn't:** The concurrent disaster load IV is imperfectly balanced on damage severity (t=2.86). The disaster-level first stage is weak (F=3.4). The paper pivoted from finding a "delay tax" to documenting a severity confound
- **Surprise:** The OLS dose-response is textbook beautiful (monotonic, significant quartile gradient) but the IV completely nullifies it. This reversal became the paper's contribution
- **Review feedback adopted:** All three reviewers flagged IV overclaiming. Softened causal conclusions, acknowledged weak first stage and balance failure explicitly, reframed from "delays don't matter" to "OLS gradient is confounded, IV inconclusive." GPT-5.4 also flagged outcome mismatch (assistance ≠ recovery) and individual data underuse — added as caveats in discussion. First-stage sign reversal interpretation added to results section per Qwen review.
