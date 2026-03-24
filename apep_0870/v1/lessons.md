## Discovery
- **Idea selected:** idea_0708 — EU Copyright Directive Art. 17 staggered transposition; first causal study of upload filter mandates
- **Data source:** Eurostat LFS (lfst_r_lfe2en2) + CELLAR SPARQL for transposition dates — SPARQL returned predecessor NIMs requiring manual override with verified dates
- **Key risk:** NACE J aggregation dilutes treatment exposure; pre-trends at longer horizons

## Execution
- **What worked:** Eurostat R package fetched data cleanly; CS-DiD ran without issues on 219 NUTS2 regions; LOO extremely stable; triple-diff with NACE K provided strong placebo
- **What didn't:** CELLAR SPARQL linked NIMs from predecessor copyright directives (2001/29/EC) to the 2019 directive — needed hardcoded verified dates as fallback; HonestDiD and wild cluster bootstrap both failed (NA in event study base period, fwildclusterboot compatibility)
- **Review feedback adopted:** Added region-specific linear trends to TWFE (null unchanged); strengthened aggregation caveat in abstract, threats section, and discussion; clarified Poland's effective never-treated status in data section
