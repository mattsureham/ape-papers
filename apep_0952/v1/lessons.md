## Discovery
- **Idea selected:** idea_1878 — Australian stamp duty threshold bunching, chosen for free microdata (NSW Valuer General) and clean before-after design
- **Data source:** NSW Valuer General Property Sales Information — yearly ZIP archives contained only partial data (weekly batches, not full years), yielding 126K of ~500K+ expected transactions. But sufficient for bunching analysis.
- **Key risk:** Round-number bunching at $800K could mask the policy signal → addressed with difference-in-bunching design

## Execution
- **What worked:** The $650K validation was the killer test. Showing b̂ = 0.93 pre-reform → 0.00 post-reform proves the method detects stamp duty bunching when present. This makes the $800K null credible.
- **What didn't:** Multi-state design (QLD, VIC, WA) was planned but infeasible — no accessible bulk transaction data for those states. The property description field only contains "RESIDENCE" for all records, preventing house/unit decomposition.
- **Review feedback adopted:** Added footnote on concessional rate structure (exemption-to-concession, not exemption-to-full-tax). Added power/CI discussion for the null. Added FHB dilution context (28% of market). Clarified sample size discrepancy.
