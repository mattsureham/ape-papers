## Discovery
- **Idea selected:** idea_0452 — Coal mine safety regulation (MINER Act) as a natural experiment in disaster-driven regulation. Selected for first-order stakes (employment/wages), clean timing (sudden Sago disaster → rapid legislation), and QWI data already in Azure.
- **Data source:** Census QWI via Azure Parquet files — fast, reliable, no API issues.
- **Key risk:** NAICS 212 includes all mining (not just coal), but in coal states this is dominated by coal.

## Execution
- **What worked:** Two-event specification cleanly separates MINER Act (null) from post-UBB/gas revolution (significant decline). Regional decomposition (Appalachian vs Western) is the key mechanism test.
- **What didn't:** Pre-trends at t-3 are marginally significant, creating some identification concern. The post-2010 decline confounds UBB enforcement with natural gas revolution — honest about this limitation.
- **Review feedback adopted:** Tempered rhetorical overstatement (GPT-5.4), added NAICS 212 measurement limitation (all three), added joint F-test for pre-trends and clustering caveat (Codex-Mini, GPT-5.4), noted compositional effects on earnings (Mistral), moderated conclusion language throughout.
