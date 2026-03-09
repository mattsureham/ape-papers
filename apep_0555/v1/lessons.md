## Discovery
- **Policy chosen:** Nigeria's 2022-2023 naira redesign — sharp demonetization in the world's most cash-dependent large economy, with Supreme Court reversal providing natural experiment within the experiment
- **Ideas rejected:** Border closure (idea_0029) — strong but fewer markets; Fuel subsidy (idea_0408) — NBS data may be PDFs requiring extraction; Electricity privatization (idea_0218) — only 11 distribution companies (too few treated units)
- **Data source:** WFP Food Price Monitoring via HDX — 57,884 obs, 68 markets, 43 commodities, free CSV download. Cross-border Benin/Niger data unavailable (HDX 404s). ACLED credentials not detected.
- **Key risk:** 14 state-level clusters is below standard threshold for cluster-robust inference. RI tests not significant (p=0.41-0.44).

## Execution
- **CMI classification expanded:** Initial pass classified only 36,000 of 58,000 obs. Adding local produce (tomatoes, onions, eggs, fish, bananas) and imports (bread, milk powder) raised classified obs to 56,000.
- **Dual-channel finding:** All-commodity DiD shows β=+0.088 (transaction costs); rice-only DiD shows β=-0.072 (supply disruption). Both channels operate simultaneously — which dominates depends on supply chain vulnerability.
- **RI limitation:** Neither time-permutation nor commodity-permutation RI produces significant results. This is an honest limitation reported in the paper. The tension between cluster-robust SEs (p=0.003) and RI (p=0.44) reflects the challenge of 14 clusters.

## Review
- **Advisor verdict:** 4 of 4 PASS (after 4 rounds; fixed state list, figure normalization, sample description)
- **Top criticism:** All 3 referees flagged the RI/inference problem as the paper's Achilles' heel. "Cannot have it both ways — strong causal language plus RI p=0.4."
- **Surprise feedback:** Cereals-only robustness shows β = -0.160 (sign flips), revealing that the positive all-commodity result is driven by non-cereals while cereals show supply disruption. This actually strengthens the mechanism story.
- **What changed:** Softened all causal claims (abstract, intro, discussion, conclusion). Added 3 new robustness specs (seasonality controls, balanced panel, cereals-only). Added commodity classification table. Reframed welfare calculation as illustrative. Added WFP geographic concentration caveat.
