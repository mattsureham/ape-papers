## Discovery
- **Idea selected:** idea_1400 — Moldova's "stolen billion" banking crisis with Soviet-era bank branch network as identification. Chose over Brazil MCMV (too few pre-periods) and Indonesia minimum wage (national-level data only).
- **Data source:** Moldova NBS StatBank PxWeb API — worked flawlessly, returned 35 raions × 20 years. No API key required.
- **Key risk:** Treatment proxy measures banking market thinness, not BEM branch counts directly. Attenuation bias likely.

## Execution
- **What worked:** Clean supply-side shock, strong institutional story ("Soviet inheritance trap"), robust main result (-8.3% employment, p=0.003). Leave-one-out, wild bootstrap, and RI all confirm. The opposite-direction pre-trend strengthens rather than weakens the causal interpretation.
- **What didn't:** No direct BEM branch data available via API. Financial enterprise share is a noisy proxy. Kimi review API timed out.
- **Review feedback adopted:** Expanded treatment proxy discussion (acknowledged measurement error → attenuation bias). Strengthened pre-trends interpretation (opposite direction = conservative estimate). Added explicit limitations about missing micro-level credit channel evidence.
