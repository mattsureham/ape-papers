## Discovery
- **Idea selected:** idea_1749 — First causal evidence on SNAP transitional benefits (the TANF-SNAP bureaucratic gap)
- **Data source:** Census ACS 1-year API (SNAP participation by state) — reliable but too aggregate
- **Key risk:** Signal dilution — TANF exiters are <3% of total SNAP, making aggregate state data a blunt instrument

## Execution
- **What worked:** ACS API fetched cleanly for 2005-2023; CS-DiD ran smoothly with 5 usable cohorts; pre-trends are flat
- **What didn't:** FNS and BEA admin data downloads failed (404 URLs); forced pivot from admin to survey data; 12 of 24 treated states adopted before ACS window (2005), severely limiting pre-treatment variation
- **Review feedback adopted:** Removed "precisely estimated zero" framing; reframed as "imprecisely estimated small positive"; acknowledged data limitation as central rather than peripheral
- **Key lesson:** When treated subpopulation is tiny relative to outcome denominator, aggregate data guarantee imprecision. The manifest's SNAP/TANF ratio from admin data was the right approach — future revisions should prioritize getting FNS monthly SNAP counts and ACF TANF caseloads.
