## Discovery
- **Idea selected:** idea_0680 — Greece POS terminal mandates, chosen for staggered sector-level variation, zero prior Greece APEP papers, and portable mechanism (cash curtain)
- **Data source:** Eurostat SBS (3 datasets: sbs_na_ind_r2, sbs_na_dt_r2, sbs_na_1a_se_r2) — sector G (retail) lives in a separate "distributive trade" dataset, easy to miss
- **Key risk:** Low power from 10 national sectors; mitigated by supplementary 814-obs regional panel

## Execution
- **What worked:** Clean null finding across extensive and intensive margins; permutation inference (p=0.926) and MDE calculation (7.5%) strengthen credibility
- **What didn't:** LFS self-employment data unavailable via API (dimension mismatch); Eurostat SBS splits by sector type across multiple datasets requiring careful stitching
- **Review feedback adopted:** Added intensive-margin test (wages/employee), computed MDE, fixed heterogeneity table SEs (HC1 instead of degenerate cluster-robust with 6 sectors), softened "precisely zero" framing
- **Key lesson:** With few clusters (10 sectors), cluster-robust SEs can be degenerate — always cross-check with HC1 and permutation inference
