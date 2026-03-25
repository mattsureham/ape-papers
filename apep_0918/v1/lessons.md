## Discovery
- **Idea selected:** idea_1799 — London ULEZ expansion and NO2, station-level DiD
- **Data source:** LAQN via openair R package — initial LAQN API was unreliable, openair `importKCL()` was dramatically better
- **Key risk:** COVID-era differential traffic changes confounding inner/outer London comparison

## Execution
- **What worked:** The openair package made bulk data download fast and reliable. 77 stations with good coverage produced a clean panel. The basic TWFE specification ran smoothly.
- **What didn't:** Borough-based treatment classification is too coarse for the actual ULEZ boundary (which follows roads, not borough lines). The COVID period created a significant placebo failure that undermines the simple parallel trends assumption.
- **Review feedback adopted:** Toned down claims about "first econometric evaluation." Added honest discussion of treatment classification limitations and attenuation bias. Improved sample flow documentation. Acknowledged specification sensitivity explicitly in the conclusion.
- **Key insight:** The ULEZ expansion effect operates at the boundary of statistical detection — specification choices (COVID exclusion, borough trends) can flip the sign. This is a genuine finding about the policy, not just a power issue: high pre-expansion compliance meant the marginal geographic expansion had limited additional bite.
