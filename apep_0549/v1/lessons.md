## Discovery
- **Policy chosen:** Online sports betting legalization → alcohol-involved fatal crashes — cross-domain mechanism (gambling → alcohol → driving deaths) with first-order welfare stakes and universe-scale admin data (FARS)
- **Ideas rejected:** Civil asset forfeiture reform (UCR/NIBRS data transition problems, arrest counts too indirect), Panama Canal drought (short shock, limited ports, overlapping shipping disruptions)
- **Data source:** NHTSA FARS (2015-2023), freely downloadable, exact date/hour/county/alcohol involvement for every fatal crash in the US
- **Key risk:** COVID-era confounding (2020-2021 overlap with major legalization wave); mitigated by NFL game-day triple-diff design which differences out state-level pandemic trends

## Review
- **Advisor verdict:** 4 of 4 PASS
- **Top criticism:** All three referees flagged the absence of a modern staggered DiD estimator (CS-DiD) — TWFE alone is insufficient given staggered online betting legalization across 20+ states. Fixed by implementing Callaway-Sant'Anna with corrected group variable (time_id scale, not %Y%m).
- **Surprise feedback:** Saturday placebo DDD showed a *larger* negative coefficient than Sunday (−0.344 vs −0.254), complicating the narrow NFL-Sunday channel interpretation. Required reframing the mechanism as "broader sports-betting" rather than NFL-specific.
- **What changed:** (1) CS-DiD now co-equal estimator with DDD, (2) 6 new robustness checks (Poisson, exposure normalization, alt controls, measured-BAC, Saturday placebo, CS-DiD), (3) systematic language softening ("precise null" → "null", mechanism → "hypothesis"), (4) welfare section reframed as "illustrative," (5) 3 figures moved to main text per exhibit review, (6) prose improvements per writing review (hook, removed throat-clearing, removed roadmap)
