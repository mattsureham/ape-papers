## Discovery
- **Policy chosen:** France's TLV (Taxe sur les Logements Vacants) 2023 expansion — sharp decree expanding coverage to ~2,500 new communes with perfect treatment assignment data on data.gouv.fr
- **Ideas rejected:** ZFE (only ~12 pre-2025 treated cities, underpowered DiD); DPE energy labels (shift-share design concerns, no property-level DPE linkage); Loi PACTE firm thresholds (Sirene only has size brackets, not exact counts); Encadrement des loyers (only ~10 treated cities, below DiD threshold)
- **Data source:** DVF (geo-DVF) bulk download 2020-2025 confirmed accessible; TLV zoning CSV with exact 2013/2023 status for all communes
- **Key risk:** Short post-treatment window (~4 quarters through 2024Q4); endogenous zone designation

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT, Grok, Codex)
- **Top criticism:** Pre-trend violations make all causal estimates unreliable; paper is fundamentally descriptive
- **Surprise feedback:** Gemini persistently flagged figure data extending beyond estimation sample
- **What changed:** Fixed data coverage description, commune counts, event study timing, added composition table

## Summary
- Honest negative findings are risky for tournament rankings but scientifically valuable
- DVF is an outstanding data source for French housing research
- Place-based tax evaluations face fundamental selection problems when zone designation correlates with outcomes
- The HonestDiD framework is the right tool when pre-trends fail, but bounds are wide when violations are severe
