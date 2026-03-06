## Discovery
- **Policy chosen:** France's staggered encadrement des loyers (rent control) — 10+ cities adopting 2019-2025 provides rich staggered DiD variation with universe-scale DVF data
- **Ideas rejected:** Loi Pacte firm-size thresholds (data too coarse — only binned size categories, not exact employee counts); SRU penalty increase (DVF starts 2014 but reform was January 2013 — almost no pre-treatment data for property prices)
- **Data source:** DVF (Demandes de Valeurs Foncières) — confirmed open access on data.gouv.fr, ~5M transactions/year since 2014
- **Key risk:** COVID overlap with earliest adopters (Paris July 2019, Lille March 2020); mitigated by triple-difference design and later adopters (Lyon, Bordeaux, Montpellier — 2021-2022) that are post-COVID

## Review
- **Advisor verdict:** 3 of 4 PASS (after 7 rounds of iteration — GPT R1, GPT R2, Codex PASS; Gemini FAIL)
- **Top criticism:** Controls sensitivity — significance only appears with controls that include room count, which overlaps with investment-type classification. Addressed by showing surface-only controls give identical result (-0.094 vs -0.093).
- **Surprise feedback:** Reviewers flagged that DVF is a rolling window (start date moves forward) — future releases won't extend pre-treatment data for Paris/Lille. Had originally claimed they would.
- **What changed:** Reframed abstract/intro to foreground Bordeaux concentration and RI non-rejection; added surface-only controls, stacked DDD+controls, RI on controlled spec; fixed 21→22 treated commune count, [-3,+3]→[-2,+3] event study bins, DVF rolling window claims.

## Summary
- **Honest result:** Rent control depresses investment property values in Bordeaux (-16%) but not convincingly in other French cities. The pooled effect (-9.3% with controls) is significant but fragile.
- **Strongest evidence:** The within-apartment size gradient (studios most negative, 3-room positive) is the most convincing mechanism test.
- **Key limitation:** Only 5 treated city groups and short pre-treatment window = underpowered design. RI cannot distinguish the result from random timing.
