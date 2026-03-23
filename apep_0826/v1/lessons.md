## Discovery
- **Idea selected:** idea_0475 — MSHA 2014 coal dust rule + QWI county employment
- **Data source:** Azure QWI (county × quarter × NAICS 3-digit), FRED commodity prices
- **Key risk:** Simultaneous oil price crash confounding the coal vs. oil/gas comparison

## Execution
- **What worked:** Azure QWI pipeline is reliable and fast (~230K records in seconds). FRED API works well for commodity prices. The 822-county panel with 477 coal-dominant is a strong sample.
- **What didn't:** The identification strategy was undermined by the oil price crash. Pre-trends fail because coal and oil/gas counties were on divergent paths before August 2014. The oil price collapsed from $107 to $26, overwhelming any regulatory signal. The Appalachian result (β = -0.23) is suggestive but statistically imprecise (SE = 0.21).
- **Review feedback adopted:** (1) Tempered language about Appalachian result from "experienced a 23% decline" to "point estimates are negative but statistically imprecise." (2) Added back-of-the-envelope cost calculation grounding the magnitude. (3) Reframed contribution around the methodological lesson about commodity confounding. (4) Acknowledged need for within-coal (underground vs. surface) design in future work.

## Key Lesson
In commodity-dependent sectors, standard DiD comparing regulated vs. unregulated subsectors is extremely vulnerable to asymmetric commodity price shocks. The 2014 oil crash was an order of magnitude larger than the dust rule's compliance cost. Future MSHA/coal papers should compare underground vs. surface coal mines within the same county/region, holding the commodity constant.
