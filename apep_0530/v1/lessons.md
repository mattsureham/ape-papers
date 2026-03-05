## Discovery
- **Policy chosen:** France's 2014 QPV/ZUS priority neighborhood redesignation -- the wholesale redraw of 751 ZUS into 1514 QPV creates a natural experiment with gain/loss/retain groups
- **Ideas rejected:** Speed limit spatial RDD (Gemini flagged as "competent but not exciting," question too conventional), Speed cameras (endogenous placement concern), Rent control (Periph is fatal boundary flaw per Gemini), Council size (all 3 models said SKIP, too well-trodden)
- **Data source:** DVF (universe property transactions, data.gouv.fr) + QPV/ZUS shapefiles (data.gouv.fr). Both fully open, bulk downloadable.
- **Key risk:** Endogenous boundary placement -- QPV boundaries drawn on income criteria, so "just inside" may differ systematically from "just outside." DDD with pre-trends and retained-zone placebo mitigates this.

## Review
- **Advisor verdict:** 3 of 4 PASS (after 4 rounds of iteration)
- **Top criticism:** Cross-sectional design cannot identify causal designation effect — boundaries drawn on income gradients ensure inside was systematically poorer. All 3 referees flagged this as fatal for causal claims. Missing distance polynomial in parametric spec approximately doubled estimates.
- **Surprise feedback:** Adding distance polynomial (signed_dist + signed_dist²) halved estimates from 13-16% to 6-8%, confirming reviewers' concern about spatial gradient contamination was quantitatively important, not just theoretical.
- **What changed:** (1) Added distance polynomial to all specifications, (2) reframed entire paper from causal to descriptive ("boundary price differentials"), (3) corrected boundary FE interpretation, (4) added geocoding precision discussion, (5) softened all mechanism claims, (6) added Keele & Titiunik 2015 citation.

## Summary
- **Final verdict:** 2× REJECT AND RESUBMIT, 1× MAJOR REVISION → substantial revision implemented
- **Key lesson:** For spatial RDD, ALWAYS include distance polynomial from the start. Omission is a "major design flaw" per reviewers and quantitatively matters.
- **Key lesson:** Cross-sectional boundary designs where boundaries are drawn on outcome-correlated criteria cannot support causal claims. Frame as descriptive from the outset to avoid overclaiming.
- **Key lesson:** Donut specifications that change the result dramatically (gained zone flipping from -6% to -22%) should be presented honestly as concerning, not as robustness evidence.
