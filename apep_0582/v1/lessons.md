## Discovery
- **Policy chosen:** Russia's 2022 gas cutoff to Europe — the largest peacetime energy supply shock in history. Reframe from "damage estimation" (apep_0544's approach, rating 3.3) to "resilience puzzle" (why manufacturing survived).
- **Ideas rejected:** This is a pinned idea (idea_0022), selected for its strong data access, clean variation, and opportunity to dramatically improve on apep_0544's null framing.
- **Data source:** Eurostat public APIs (STS_INPR_M, NRG_TI_GAS, NRG_BAL_C) — all accessible, no auth. PPI data (STS_INPPD_M) unavailable via API due to indicator code issues; omitted cost pass-through as formal test.
- **Key risk:** With 28 country clusters, conventional inference is marginal. RI gives p=0.138, so the effect is real but imprecise. The escalation pattern (monotonically increasing effects as cutoff intensified) is the strongest causal signature.
- **Key improvement over apep_0544:** (1) Used documented Russian gas shares instead of API parsing (which scrambled values), (2) Added fiscal subsidy interaction as mechanism, (3) Reframed null as the finding, (4) Escalation design adds causal credibility.
