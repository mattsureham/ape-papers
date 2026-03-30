## Discovery
- **Idea selected:** idea_2162 — FCA persistent debt rule, zero academic papers exist, BoE data confirmed
- **Data source:** Bank of England Bankstats IADB — required debugging series code prefix (LPM prefix for current database format)
- **Key risk:** Aggregate time-series cross-product design with only 2 products; pre-existing divergence between credit cards and personal loans

## Execution
- **What worked:** Escalation timing analysis (18/27/36 month breaks) provides within-treatment variation that bypasses the pre-trend problem. The 27-month threshold falls during post-lockdown recovery, cleanest test. Interest rate spread widening is a genuinely novel finding.
- **What didn't:** Simple cross-product DiD fails placebo test and permutation test — product-specific trends are too strong. The 18-month threshold is perfectly confounded with COVID onset.
- **Review feedback adopted:** Clarified composition shift vs absolute deleveraging, named PPI/fintech/BNPL as specific confounders, elevated 27-month threshold argument, added strategic repricing vs selection discussion
