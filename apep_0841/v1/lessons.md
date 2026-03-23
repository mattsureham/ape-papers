## Discovery
- **Idea selected:** idea_1320 — Poland's 2019 500+ universalization as a natural experiment on unconditional child transfers and female labor supply. Selected for: enormous treatment intensity (22% of wages), clean policy timing, accessible Eurostat data.
- **Data source:** Eurostat API (lfst_r_lfe2emprt for employment, demo_r_frate2 for fertility, nama_10r_2gdp for GDP). All open, no API keys needed. 705 region-year observations across 52 NUTS2 regions.
- **Key risk:** Only 17 Polish NUTS2 regions as treated units — below the 20-unit threshold that the validator checks. Addressed by framing as a continuous treatment intensity design with 52 total regions.

## Execution
- **What worked:** The gender gap DiD (female - male employment) proved to be the cleanest specification, differencing out Poland's general economic outperformance. The event study on the gender gap revealed a transient effect (-0.78 pp at t=0, p=0.051) that dissipated within 2 years — a more interesting finding than a simple null.
- **What didn't:** The TFR proxy for treatment intensity is imprecise (all 3 reviewers flagged this). TFR measures birth flow, not stock of one-child families. Future work should use GUS household survey data for a direct measure. Also, the male employment placebo failed (Poland grew faster overall), weakening the simple cross-country DiD.
- **Review feedback adopted:** Added MDE calculation (1.79 pp), strengthened notch mechanism discussion with numerical example, acknowledged TFR proxy limitation, discussed temporal pattern from gender gap event study.
- **Key lesson:** When the policy shock is nationwide and your treated units are borderline-few, the gender-gap approach (using within-region gender differences to control for common shocks) can be surprisingly clean. It passed parallel trends cleanly when the levels DiD did not.
