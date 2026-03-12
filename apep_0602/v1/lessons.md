## Discovery
- **Idea selected:** idea_0039 — First RDD at the federal 30% CDR threshold for for-profit colleges
- **Data source:** College Scorecard API + IPEDS DuckDB (Azure) — API rate limiting required retry logic with delays
- **Key risk:** Null result (confirmed) — three-consecutive-year rule dilutes immediate threshold effect

## Execution
- **What worked:** Clean RDD setup, smooth density, good covariate balance. IPEDS DuckDB from Azure provided rich institutional outcomes. Framing a null as informative ("the cliff that didn't bite") worked well.
- **What didn't:** IPEDS column names required extensive schema querying (names differ from documentation). Closure variable required creative construction (currently_active=3 + disappearance). College Scorecard API has aggressive rate limits — need 1.5s delays.
- **Review feedback adopted:** (1) Clarified treatment estimand — first-crossing signal vs actual sanction; (2) Added power/MDE discussion for closure and enrollment; (3) Better explained donut-hole sign reversal as extrapolation artifact; (4) Softened null interpretation to "no evidence of large effects" rather than definitive zero.
- **Review feedback deferred:** Fuzzy RDD for third-consecutive-crossing (requires larger sample, good V2 idea). RD plots (V1 format prohibits figures). Panel event-study RDD (substantial additional analysis).
