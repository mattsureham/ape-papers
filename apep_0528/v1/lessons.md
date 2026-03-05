## Discovery
- **Policy chosen:** Swiss cantonal energy law reforms (2010–2020) — 8 cantons adopted staggered comprehensive energy laws creating sharp tariff discontinuities at ~50 border pairs
- **Ideas rejected:** Wasserzins (limited cross-border rate variation), agricultural organic subsidies (weak treatment relative to federal baseline), TRAF commodity trading (impossible measurement — ~500 firms too few for RDD)
- **Data source:** ElCom SPARQL (745K observations, 2,712 municipalities, 2011–2026, 5 tariff components) + swissBOUNDARIES3D municipal boundaries — both open, no API keys
- **Key risk:** Utility/DSO coverage may not align with cantonal borders; border-level confounders (topography, urbanization) could bias spatial RDD

## Review
- **Advisor verdict:** 3 of 4 PASS (Grok, Gemini, Codex; GPT failed on aid-fee placebo logic)
- **Top criticism:** Design should be framed as "border-pair DiD with spatial controls" not pure RDD; inference with few treated clusters needs caution
- **Surprise feedback:** Aid fee is NOT perfectly uniform within year — small DSO-level reporting differences create residual variation that makes the placebo regression well-defined
- **What changed:** Reframed design as hybrid border-DiD/RDD; softened placebo claims to "necessary condition"; labeled variance decomposition as descriptive; added Sun & Abraham (2021) for event study; residualized binscatter against year FE; fixed BE-FR mixed pair inconsistency; downgraded border-pair significance to descriptive
