## Discovery
- **Idea selected:** idea_1900 — UK sugar tax (SDIL) and childhood dental health via reformulation mechanism
- **Data source:** OHID Fingertips API (dental decay survey, IMD deprivation, childhood obesity) — all public, no API keys needed
- **Key risk:** Pre-existing convergence in dental health across deprivation groups would confound the intensity-based DiD

## Execution
- **What worked:** Data fetch from Fingertips was clean and fast (5 indicators, all returned data). The "reformulation dividend" framing gave the paper a memorable mechanism name. Writing the null result as a substantive finding rather than a failure was the right call.
- **What didn't:** Hospital Episode Statistics (tooth extractions) were unavailable through the public Fingertips API at the local authority level, forcing a pivot to dental decay prevalence. The biennial survey frequency (only 4 pre-treatment waves) limits pre-trend testing power. The pre-existing convergence pattern made the DiD coefficient uninterpretable as causal.
- **Review feedback adopted:** Added explicit justification for outcome choice (decay vs extractions), strengthened Rambachan-Roth framing, added limitations paragraph on outcome margin. Softened MDE overclaim language.
- **Key insight:** Deprivation-based continuous treatment designs are fragile when outcomes exhibit secular convergence. Product-level data (matching reformulated products to local purchasing) would be the path to sharper identification.
