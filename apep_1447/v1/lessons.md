## Discovery
- **Idea selected:** idea_1448 — Indonesia's PP78/2015 formula-based minimum wage reform. Clean natural experiment with mechanical variation.
- **Data source:** BPS Statistik Indonesia yearbooks (published province-level aggregates). World Bank API timed out; had to construct all data manually.
- **Key risk:** Province-level analysis (34 units) severely underpowered vs. the manifest's district-level plan (500 units).

## Execution
- **What worked:** The Kaitz index construction is clean — the formula used national CPI + GDP, so cross-province variation is plausibly exogenous. Data construction from yearbook tables was straightforward.
- **What didn't:** Event study pre-trends for unemployment (significant at k=-4, k=-3) undermine the parallel trends assumption. Province-level aggregates can't capture formality transitions — the core policy margin.
- **Review feedback adopted:** Softened "clean identification" language; added MDE calculation showing the null can't rule out moderate effects (1-3 pp); better framed the province-level limitation and inability to speak to formality margins.
