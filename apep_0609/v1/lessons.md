## Discovery
- **Idea selected:** idea_0085 — Wayfair economic nexus laws and retail-warehouse employment reallocation
- **Data source:** QWI via Azure Blob Storage (DuckDB Parquet queries) — worked well, 40K obs fetched
- **Key risk:** Compressed treatment timing (32/46 states adopted within 6 months) limits effective variation

## Execution
- **What worked:** Azure DuckDB integration for QWI data was smooth once file paths sorted. Null result was clear and consistent across all specifications.
- **What didn't:** HonestDiD failed due to sunab coefficient structure mismatch. County-level analysis was planned in the manifest but state-level was used for tractability.
- **Review feedback adopted:** Softened causal claims throughout (GPT-5.4 flagged overstatement), added marketplace facilitator bundling caveat, expanded limitations to acknowledge NAICS 48-49 breadth, added power/CI discussion, restrained conclusion from "tax channel doesn't matter" to "no large additional effects detected."
- **Key lesson:** For staggered DiD with nationally simultaneous shocks, the effective identification is thinner than it appears — nearly all states adopt in the same 6-month window, leaving little timing variation. Future papers should flag this upfront.
