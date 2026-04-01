## Discovery
- **Idea selected:** idea_0187 — Workers' compensation and occupational risk-sorting using MLP linked panel. Selected for first-order stakes (birth of American welfare state), sharp staggered adoption (43 states, 8 timing cohorts), and unusually strong microdata (6.3M linked individuals).
- **Data source:** IPUMS MLP on Azure — fetched via DuckDB. Azure connection required manual .env parsing to avoid semicolon truncation in connection string.
- **Key risk:** Never-treated states are all Deep South (AR, FL, MS, NC, SC), raising North-South comparability concerns. Only 1 pre-treatment decade available from census data.

## Execution
- **What worked:** The MLP data delivered exactly as promised. 6.3M wage-employed men aged 18-50 in the treatment panel. Stacked cohort design was clean to implement. The null result was robust and precise.
- **What didn't:** The hypothesis that WC enables occupational upgrading was not supported. Pre-trend shows 2.7pp differential (future-treated states already more industrial). Memory limits (16GB) prevented individual-level robustness checks — had to collapse to state-cohort cells for some specifications.
- **Review feedback adopted:** All three reviewers flagged the pre-trend and control group. Most impactful fix: decomposing net ΔHazardous into gross entry and exit probabilities (Grok's suggestion). Entry probability DiD is null (-0.005), but exit probability is significantly positive (+0.018) — WC facilitated leaving dangerous jobs. Added this to the Results section.
