# Lessons — apep_0496 v1

## Discovery
- **Policy chosen:** France's REP education priority zone labels and housing prices
- **Data source:** DVF (Demandes de Valeurs Foncières) geocoded property transactions + school directory + REP status lists
- **Key insight:** DVF provides 4.6M geocoded transactions for free, making France one of the best countries for housing price research
- **Ideas rejected:** (1) CPGE proximity hedonic — no sharp identification; (2) Dédoublement DiD alone — parallel trends implausible; (3) ENS admission cutoff RDD — exam score data not public
- **Sign convention trap:** When constructing `dist_signed = dist_nearest_nonrep - dist_nearest_rep`, positive values mean REP side (closer to REP). Code comments initially said the opposite, causing pervasive labeling errors. Always verify running variable sign by tracing through the math.

## Review
- **Advisor review convergence:** Took many rounds (8+) to reach 3/4 PASS. GPT consistently fails on structural @CONTRIBUTOR_GITHUB placeholder (unavoidable). Gemini is hardest to satisfy — finds new issues each round, sometimes fabricating errors.
- **Sign convention was root cause:** The Gemini advisor kept flagging "sign inconsistency" — investigating deeply revealed a real, pervasive bug in code comments and paper text.
- **etable() appends:** fixest's `etable(..., file=)` appends to existing files rather than overwriting. Must manually write clean table files after adding new columns.
- **Proxy boundary limitation:** All three external referees flagged that equidistance loci ≠ true carte scolaire boundaries. Fundamental design limitation — be transparent from the start.
- **Commune FE result:** Adding commune FE produced coefficient of exactly zero, becoming the paper's strongest evidence. Always try the most demanding specification.

## Summary
- **What worked:** Large-scale DVF data assembly, transparent acknowledgment of RDD violations, progressive FE specification showing coefficient collapse, private school mechanism analysis
- **What didn't work:** Claiming causal identification with proxy boundaries and violated RDD assumptions. Paper was reframed as descriptive gradient analysis.
- **Key lesson:** In spatial/housing RDD, always run the most demanding geographic FE first — if the effect survives, you have something real; if it doesn't, lead with the null.
- **For future France papers:** DVF data has ~6-12 month publication lag. Partial-year data should be labeled explicitly in figures.
