## Discovery
- **Idea selected:** idea_1475 — NZ mortgage interest deductibility removal with new-build exemption. Within-market natural experiment with treatment + reversal.
- **Data source:** Stats NZ Building Consents + MBIE Tenancy Bond Registry. Bond data ends Oct 2020 (before policy), requiring pivot to building consents as outcome.
- **Key risk:** Short pre-period (9 months) for the dwelling-type specification; can't observe rental supply directly.

## Execution
- **What worked:** The dwelling-type DiD (multi-unit vs houses) produces clean, large, significant results. The staggered phase-out (25→50→75% tax wedge) generates dosage variation. The 2024 reversal provides symmetric identification.
- **What didn't:** Cross-TA specification using rental intensity as exposure shows null results — the incentive is national, not geographically differentiated. Post-2020 tenancy bond data blocked by bot protection.
- **Review feedback adopted:** Added wild cluster bootstrap (p<0.001 for main coefficient, p=0.007 for reversal); clarified composition-vs-quantity framing; added data-choice justification for tenancy bond → building consent pivot; fixed dosage scaling interpretation (0-0.75 scale not 0-100).
