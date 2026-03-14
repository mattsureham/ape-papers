## Discovery
- **Idea selected:** idea_0717 — Carbon tax pass-through and gas demand elasticity across Europe
- **Data source:** Eurostat nrg_pc_202 (decomposed gas prices), nrg_d_hhq (consumption), ilc_mdes01 (energy poverty)
- **Key risk:** Few treated countries (5) limits statistical power for clustered inference

## Execution
- **What worked:** Eurostat data fetched cleanly via the `eurostat` R package. Price decomposition is genuinely powerful — the tax component provides a natural instrument with F-stat of 29.
- **What didn't:** CS-DiD (`did` package) failed with the unbalanced country-level energy poverty panel — too few never-treated units after balancing. Used TWFE instead.
- **Key finding:** Pass-through 1.33 (over-shifting from VAT cascading); IV elasticity -0.45 (4.8x OLS). Energy poverty null.
- **Review feedback adopted:** Decomposed 133% pass-through into VAT mechanical (21pp) and residual markup (12pp). Added back-of-envelope ETS2 revenue calculation (€4B gap over 2027-2032). Clarified instrument is total tax wedge not isolated carbon tax. Strengthened few-clusters caveat with t(4) adjustment discussion.
