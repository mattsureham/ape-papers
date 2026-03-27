## Discovery
- **Idea selected:** idea_1479 — Two-shock natural experiment (GE score publication + rollback) to separate information from regulation. Selected for clean identification, many treated units (~400), and program-level data availability.
- **Data source:** GE D/E Rates (Wayback Machine archive of ed.gov XLS) + IPEDS DuckDB (local). OPEID crosswalk required careful format conversion.
- **Key risk:** Temporal conflation between publication (Jan 2017) and rollback (Jun 2017) within the same academic year.

## Execution
- **What worked:** The two-shock design produced clean results. Log specification is the strongest finding (-17.4% publication, -25.9% post-rollback, both significant). Event study shows textbook pre-trends. The "scarlet score" framing makes the contribution memorable.
- **What didn't:** Level specification is noisy due to variance from large programs. GE data required Wayback Machine retrieval. Minority share analysis showed null compositional effect, which actually improved the paper's nuance.
- **Review feedback adopted:** Added event study table (all 3 reviewers), acknowledged timing conflation (kimi), added minority share regression (deepseek/kimi) which changed the equity narrative from "displacement" to "pipeline shrinkage."
