## Discovery
- **Idea selected:** idea_0219 — EU neonicotinoid ban with derogation variation as natural experiment
- **Data source:** Eurostat apro_cpsh1 via R eurostat package — reliable, fast, 380K rows
- **Key risk:** Derogations were sugar-beet-specific, limiting DDD interpretability for other crops

## Execution
- **What worked:** Triple-difference design with continuous PDR gradient. Clean pre-trends. Built-in ECJ reversal. Event study validates parallel trends assumption. 19 pre-treatment years.
- **What didn't:** Limited power for high-PDR crops (sunflower only crop at PDR=0.65). Binary derogation coding masks intensity variation. Only 13 crops (fruit/vegetable data in separate Eurostat dataset).
- **Review feedback adopted:** Added MDE/power analysis, area reallocation check, acknowledged derogation scope limitation, tempered null interpretation from "no effect" to "at most modest effects, but cannot rule out 2-5% losses."
