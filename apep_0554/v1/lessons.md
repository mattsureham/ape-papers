## Discovery
- **Policy chosen:** South Korea's 52-hour workweek cap (2018 amendment) — theoretically ambiguous effect on fertility (time vs income), first-order stakes (world's lowest TFR), clean multi-cutoff design
- **Ideas rejected:** Indonesia Dana Desa (identification too close to rural-vs-urban comparison, 2 SKIPs from tri-model panel); Poland Family 500+ (Bartik exposure based on family composition not plausibly exogenous, mixed ranking)
- **Data source:** KLIPS micro-panel (Harvard Dataverse, 23,000 individuals) + World Bank API for aggregate context
- **Key risk:** Statistical power for birth outcomes (low base rate ~2%); mitigated by focusing on marriage as primary outcome (higher base rate ~5%) and supplementing with administrative data

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT R1, Gemini, Codex pass; GPT R2 fail on SCM fit consistency)
- **Top criticism:** Single-treated-unit inference (both GPT referees). Country-clustered SEs with N=1 treated produce misleading p-values. Cross-country DiD cannot isolate reform from concurrent Korea-specific forces.
- **Surprise feedback:** Both GPT referees flagged treatment timing — 2018 annual TFR cannot reflect a July 2018 reform. The immediate SCM gap is suspicious.
- **What changed:** Systematically softened causal language throughout (abstract, intro, mechanism, conclusion). Added inference caveat citing Conley-Taber. Added treatment timing paragraph. Changed "first causal evidence" to "new quasi-experimental evidence." Mechanism reframed as "plausible interpretation" rather than demonstrated fact.
