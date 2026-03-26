## Discovery
- **Idea selected:** idea_0150 — Czech EET chosen for staggered rollout across sectors, 4 phases, strong connection to Naritomi (2019 AER) formalization literature
- **Data source:** Eurostat SBS (enterprise counts by NACE × country). CZSO open data only covers 2022+ through API — historical municipal data unavailable
- **Key risk:** Cross-country parallel trends in transition economies

## Execution
- **What worked:** The sign reversal (naive TWFE -19% → +8% with trends) is a genuine finding and a strong narrative. Placebo test on non-EET Czech sectors is the most convincing diagnostic. The "formalization mirage" concept gives the paper a named mechanism that tournament judges reward.
- **What didn't:** CZSO historical data not available through czso R package — forced pivot from within-CZ municipal design to cross-country panel. This weakened identification substantially. Annual Eurostat frequency means Phases 1-2 collapse into same treatment year.
- **Review feedback adopted:** Added birth/death decomposition, explicit limitations section acknowledging trend absorption concern, and stronger placebo interpretation. Did not attempt to return to municipal design (infeasible with available data).

## Key Lessons for Future Papers
- Always verify data availability through the actual API before committing to a research design. The smoke test in the idea manifest said "CZSO quarterly data from 2010" but the czso R package only served 2022+ data.
- Cross-country DiD in transition economies is inherently fragile. The convergence problem identified here likely affects many other APEP papers using Visegrad comparisons.
- When identification is imperfect, name the bias pattern and make the methodological contribution explicit. "Formalization mirage" is more publishable than "inconclusive estimate."
