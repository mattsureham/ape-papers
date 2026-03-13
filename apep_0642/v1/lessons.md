## Discovery
- **Idea selected:** idea_0642 — Cross-media pollution substitution from CAA inspections; novel facility-level causal test with linked EPA data
- **Data source:** EPA ICIS-Air + TRI via ECHO bulk downloads — TRI column name prefixes (e.g., "1. YEAR") required stripping; FCE filter is COMP_MONITOR_TYPE_CODE not ACTIVITY_TYPE_CODE
- **Key risk:** Non-air pre-trends and confounding from simultaneous CWA enforcement

## Execution
- **What worked:** Triple-difference design cleanly identified substitution; mechanism test (CAA vs non-CAA chemicals) strongly supports strategic avoidance interpretation; pre-trends clean (Wald p=0.33)
- **What didn't:** Event study with full FE (facility-chemical + year) produced collinear estimates with enormous SEs; had to drop year FE for the event study. modelsummary latex output returns tinytable objects not character strings — had to write tables manually.
- **Review feedback adopted:** Expanded medium decomposition discussion to explain water decrease; added non-air pre-trend evidence to identification section; added explicit Limitations paragraph on missing CWA controls and TRI reporting thresholds; fixed erroneous "Figure" reference in appendix
