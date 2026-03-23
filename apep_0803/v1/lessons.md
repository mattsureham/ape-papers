## Discovery
- **Idea selected:** idea_1347 — Medicaid expansion × racial healthcare employment. Chose for confirmed Azure data, massive sample, DDD design.
- **First idea failed:** idea_0651 (ALJ leniency → opioids) had fatal data access issues — SSA 403 blocks, ARCOS API dead.
- **Data source:** QWI race-ethnicity panel via Azure. R DuckDB has az:// URL bug; used Python DuckDB to extract.
- **Key risk:** State-level aggregation loses county variation; reviewers flagged this unanimously.

## Execution
- **What worked:** Python extraction from Azure fast and reliable (3 min for 6M+ rows). Sun-Abraham estimator delivered highly significant result (p=0.005) where TWFE was noisy.
- **What didn't:** Initially used annual sum instead of quarterly stock for baseline magnitude — off by 4x. Caught in review.
- **Review feedback adopted:** Fixed magnitude (3.1M not 12.2M Black workers), moderated "implicit racial inclusion mechanism" framing, noted county-level analysis as clear V2 direction.
