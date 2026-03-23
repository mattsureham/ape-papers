## Discovery
- **Idea selected:** idea_1391 — SCI Backlash extension to Sweden (parent: idea_1368, Connected Backlash atlas)
- **Data source:** SCB PxWeb API (elections), Kolada API (demographics), HUMDATA SCI (social connections)
- **Key risk:** Only 21 NUTS3 counties for the SCI Bartik; small-cluster inference

## Execution
- **What worked:** The SCI Bartik construction produced strong, significant results. The network exposure coefficient (1.30, WCB p=0.017) survived aggressive inference with 20 clusters. The placebo (2010–2014) was clean. The non-EU/EFTA foreign-born distinction was critical — total foreign-born had zero effect.
- **What didn't:** SCB PxWeb API was finicky — dimension codes require exact metadata lookup (labels vs codes vs indices). The foreign-born table `UtlSvworgin` returned 400 errors with guessed dimension codes; switching to Kolada solved this instantly. The `fetch_scb_tidy` helper needed a `use_codes` flag because JSON-stat2 returns labels by default, breaking joins. Municipality metadata from `content(resp, "parsed")` returns lists, not vectors — must unlist before creating tibbles.
- **Surprise finding:** The 2018→2022 reversal (network effect flips to -1.42, p<0.01) was completely unexpected. It transforms the narrative from "social networks amplify backlash" to "social networks amplify AND then attenuate backlash."
- **Review feedback adopted:** Softened causal language (realized foreign-born ≠ assigned quotas), acknowledged SCI–geography confound explicitly, tempered 2022 reversal interpretation, added discussion of suppression pattern in horse-race specification.
