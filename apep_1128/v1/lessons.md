## Discovery
- **Idea selected:** idea_1928 — Non-compete bans and racial worker mobility gap using QWI
- **Data source:** Azure QWI (derived/qwi/rh/ns/*.parquet) — flawless download, 51 states
- **Key risk:** Only 5 treatment-state clusters → WCB inference couldn't run with high-dim FEs

## Execution
- **What worked:** Azure data pipeline, DDDD specification isolating racial differential, clean pre-trends
- **What didn't:** BigQuery ADC not configured (forced pivot from idea_2103); fwildclusterboot incompatible with fixest `^` FE notation; Kimi review API failed
- **Review feedback adopted:** Expanded limitations section with MDE calculation, explicit WCB caveat, cell-level data limitation acknowledgment
- **Surprise finding:** Earnings effect (3.8%, p=0.022) was significant while separation effect was null — "bargaining dividend" framing emerged from the data, not from the original idea manifest
