## Discovery
- **Idea selected:** idea_0984 — GP practice closures and A&E utilization in England. First causal study of this question.
- **Data source:** NHS ODS API (GP closures) + NHS England A&E monthly statistics (scraped from year-pages)
- **Key risk:** Treatment validity — ODS "inactive" status conflates genuine closures with administrative mergers

## Execution
- **What worked:** NHS ODS API returns rich practice data with postcodes and dates. Postcodes.io batch geocoding is fast and reliable. The staggered DiD design with 154 treated trusts and 107 controls provides strong statistical power.
- **What didn't:** A&E data acquisition was harder than expected — no consolidated timeseries file, had to scrape 78 individual monthly XLS files. The 2023 spike (75% of all closures) is almost certainly administrative reorganization, not genuine primary care contraction.
- **Review feedback adopted:** Reframed the contribution from "hard null on GP closures → A&E" to "administrative practice deactivations don't predict A&E demand + ODS register conflates genuine closures with code retirements." Added three explicit interpretations in the Discussion (measurement, absorption, aggregation). This is more honest and the paper is stronger for it.
- **Key lesson for V2:** Validate treatment using patient list data, workforce counts, or CQC records. The path from "suggestive null" to "compelling contribution" requires distinguishing real closures from administrative events.
