## Discovery
- **Idea selected:** idea_0905 — EU Deposit Return Schemes, staggered adoption 2002-2023
- **Data source:** Eurostat cei_wm020 (recycling rates by material), 2000-2023. Clean API, no key needed.
- **Key risk:** Low power from country-level clustering with only 10 treated units

## Execution
- **What worked:** Material-level triple-difference (targeted plastic/metal vs untargeted paper/wood) is a clean identification strategy — built-in placebo within the same municipal collection system. Eurostat data fetched easily via R package. The "deposit illusion" framing gives the null result a named mechanism.
- **What didn't:** Balanced panel construction was tricky — many countries have sparse early data, forcing restriction to 2005-2022 for CS. The DDD specification initially had collinearity due to `i()` factor syntax in fixest — needed numeric 0/1 interaction instead. Pre-trends messy at long horizons in CS event study.
- **Review feedback adopted:** Added power analysis / MDE quantification, dilution bounding exercise (beverage container share → implied effect), and strengthened CI interpretation to distinguish "no evidence of large effect" from "evidence of no effect." All three reviewers flagged these same issues.
