# Research Plan: Click to Incorporate

## Research Question

Do integrated online business registration portals increase new firm formation? Eleven US states adopted one-stop-shop portals (2008--2022) consolidating filings across Secretary of State, Revenue, Labor, and Licensing agencies. I exploit the staggered timing of portal adoption in a Callaway--Sant'Anna difference-in-differences design, using monthly Census Business Formation Statistics from FRED to estimate the causal effect on business applications.

## Policy Context

Starting a business in the US requires navigating multiple state agencies: Secretary of State (entity formation), Department of Revenue (tax ID), Department of Labor (employer registration), and often licensing boards. The sequential, paper-based process imposes a time cost estimated at 6+ hours per startup (Connecticut reports). States have progressively adopted integrated portals:

| State | Portal | Launch |
|-------|--------|--------|
| Virginia | VBOS | May 2008 |
| Kentucky | OneStop | Oct 2011 |
| Nevada | SilverFlume | Jun 2012 |
| Kansas | OneStop | Sep 2014 |
| Mississippi | BOSS | Oct 2015 |
| Wisconsin | OneStop | ~2017 |
| Pennsylvania | PA Login | 2018 |
| Delaware | OneStop | Aug 2019 |
| Connecticut | Business.CT | Summer 2020 |
| Texas | TxT | Early 2022 |
| Arizona | AZBiz | Nov 2022 |

This staggered adoption creates natural variation in administrative friction reduction.

## Identification Strategy

**Callaway--Sant'Anna (2021) staggered DiD.**

- **Treatment:** State month in which the integrated online business registration portal launched.
- **Outcome:** Monthly business applications (BA), high-propensity applications (HBA), and wage-planned applications (WBA) from the Census Bureau Business Formation Statistics.
- **Estimator:** `did` R package with group-time ATT, aggregated to event-study coefficients. Never-treated states (those without portals by end of sample) serve as the comparison group.
- **Inference:** Clustered at the state level.

**Mechanism tests:**
1. **Corporation vs. sole proprietorship applications:** Portals primarily reduce friction for entity formation (LLCs, corporations), which requires filing with the SoS. Sole proprietorships need no formation filing. If portals work through registration friction, the effect should be concentrated in incorporated business types.
2. **High-propensity vs. low-propensity applications:** HBA (applications likely to become employer businesses) should respond more than low-propensity BA if the friction deters serious entrepreneurs.

**Robustness:**
- Placebo: Test for pre-trends in the event study
- Leave-one-out: Drop each treated state sequentially
- Sun--Abraham (2021) interaction-weighted estimator as alternative
- Bacon decomposition for TWFE comparison

## Data Sources

### Primary: Census Business Formation Statistics (BFS) via FRED API
- Monthly state-level series: BA (all applications), HBA (high-propensity), WBA (wage-planned)
- FRED series IDs: `BA{ST}`, `BAHP{ST}`, `BAWP{ST}` (where ST = 2-letter state code)
- Coverage: 2004m7 -- present (~258 months)
- 51 jurisdictions (50 states + DC)

### Secondary: County-level BFS (Census direct)
- Annual county-level business applications
- For distance-to-capital heterogeneity test

### Treatment data
- Portal launch dates from state government press releases, legislative records, and Internet Archive verification
- Coded in R script as a state-month treatment panel

## Key Risks

1. **Concurrent policies:** Other business-friendly reforms may coincide with portal launches. Mitigate with state FE + event study checking for pre-trends.
2. **COVID contamination:** Connecticut (2020) and Texas/Arizona (2022) launch during/after COVID. CS DiD handles heterogeneous timing, and COVID affects all states symmetrically conditional on time FE.
3. **Fuzzy treatment:** Portal functionality varies (some are thinner). This attenuates estimates toward zero.
4. **Small N treated:** 11 states is above the 5-state danger zone but below ideal. Compensated by monthly data frequency.
