## Discovery
- **Idea selected:** idea_0125 — Seguro Popular cause-specific infant mortality (selected for first-order stakes, massive N, built-in placebo design)
- **Data source:** INEGI/Secretaria de Salud death microdata — free public CSV, 7.6M records. Birth microdata (SINAC) unavailable before 2008; used estimated births from death-based population proxy
- **Key risk:** Denominator construction from total deaths × national vital rates introduces non-classical measurement error

## Execution
- **What worked:** Cause-specific decomposition cleanly separates amenable from non-amenable mortality. The built-in placebo (congenital malformations + external causes) shows flat effects, as predicted. Perinatal conditions drive the amenable component, consistent with SP's benefits package design.
- **What didn't:** State-level treatment assignment discards within-state variation that the idea manifest originally proposed. Municipality-level enrollment dates would dramatically improve identification but weren't readily available.
- **Review feedback adopted:** Softened causal language throughout (results are suggestive, not definitive). Added explicit discussion of denominator limitations and the mechanical correlation between numerator and denominator. Acknowledged that confidence intervals are wide and include zero. Removed unfulfilled robustness promise (infant share of deaths).
