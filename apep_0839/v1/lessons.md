## Discovery
- **Idea selected:** idea_1746 — First causal evaluation of the 2021 TFP revision on food security
- **Data source:** ACS 1-year estimates (Census API), FRED (unemployment, benefits), USDA FNS (EA timing)
- **Key risk:** Separating TFP effects from Emergency Allotment effects

## Execution
- **What worked:** The triple-difference using EA timing variation was the paper's strongest finding. The ACS panel (2014-2023) provided clean state-year data with 6 pre-periods. Wild cluster bootstrap for inference with 51 clusters.
- **What didn't:** Original plan to use CPS Food Security Supplement microdata proved infeasible for V1 — the data access was too complex. Pivoted to ACS poverty/SNAP rates. The poverty outcome turned out to be mechanically uninformative because SNAP is excluded from the Official Poverty Measure (OPM). Should have caught this ex ante.
- **Critical lesson:** Always verify that the outcome variable can mechanically respond to the treatment channel. ACS poverty (OPM) cannot directly respond to SNAP benefit changes — only SPM can.
- **Review feedback adopted:** (1) Added caveat about OPM excluding SNAP, (2) discussed political confound in EA timing, (3) strengthened take-up cliff framing as central contribution.
- **Pre-trends:** Poverty pre-trends failed badly (placebo p=0.023). SNAP pre-trends were clean (placebo p=0.656). The honest null on poverty is not a finding about the TFP — it's a finding about the limitations of ACS-OPM as an outcome.
