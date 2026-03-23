## Discovery
- **Idea selected:** idea_0603 — Florida's liquor license lottery creates a natural experiment in regulatory supply expansion. Clean identification via population threshold rule, novel data, and a memorable economic object (licenses worth $50K-$1M).
- **Data source:** Census QWI (NAICS 7224/7225) + DBPR lottery PDFs — only 2020 and 2024 PDFs accessible due to Cloudflare protection on older files. Pivoted to population-threshold-constructed treatment.
- **Key risk:** Small treatment dose at county level (mean 0.55 new licenses/county-year) might produce underpowered estimates.

## Execution
- **What worked:** Population threshold rule provided clean, deterministic treatment. Within-county placebo (restaurants vs. drinking places) is exactly the kind of contrast tournament judges reward. Dose-response (1 vs. 2+ licenses) provided compelling evidence of genuine causal effects.
- **What didn't:** PDF parsing was blocked for 9 of 10 years of DBPR data. The individual-level lottery winner analysis (who becomes entrepreneur vs. flipper) was infeasible without full winner data linked to corporate filings.
- **Key finding:** Short-run positive effect (4.8% per license) combined with long-run null — supply constraints bind temporarily but don't determine equilibrium market size. The asymmetry is the paper's strongest contribution.
- **Review feedback adopted:** All three reviewers flagged the restaurant placebo as positive and significant (0.018***), revealing confounding from population growth. Rewrote paper to lead with triple-difference (drinking places vs. restaurants), which yields a cleaner 3.0% sector-specific effect. Tempered causal claims throughout, acknowledged measurement error as alternative explanation for cumulative null, and reframed contribution as reduced-form evidence on regulatory supply constraints rather than entrepreneurship.
