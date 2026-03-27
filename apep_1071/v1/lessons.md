## Discovery
- **Idea selected:** idea_0818 — Portugal's Golden Visa creating existing-new dwelling price divergence. A DDD design exploiting the within-market segmentation between dwelling types.
- **Data source:** Eurostat prc_hpi_q — free quarterly HPI data by dwelling type, 25 EU/EEA countries, no authentication needed.
- **Key risk:** Few-cluster inference (country-level clustering). Addressed by expanding from 4 to 25 countries and supplementing with RI.

## Execution
- **What worked:** The existing-new price split in Eurostat HPI is genuinely novel identifying variation. The event study shows a clean pre-trend and monotonically growing post-treatment effect, which is textbook-perfect for a demand accumulation story.
- **What didn't:** Initial 4-country design had no RI power (min p = 0.25). Expanding to 25 countries helped but RI one-sided p is still 0.24 — Portugal ranks 6th. The 2023 suspension "reversal test" backfired: the gap widened further, contrary to the simple mechanism prediction.
- **Review feedback adopted:** Added supply elasticity discussion (Kimi concern), elaborated 2023 lock-in mechanism (all three reviews), named the 5 higher-RI countries to contextualize RI result (Codex/Qwen), added Eurostat harmonization footnote (Qwen). Could not address sub-national data request (Kimi) since Eurostat doesn't provide dwelling-type-specific sub-national HPI.
