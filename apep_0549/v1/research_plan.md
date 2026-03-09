# Initial Research Plan: Online Sports Betting and Alcohol-Involved Fatal Traffic Crashes

## Research Question
Does the legalization of online sports betting increase alcohol-involved fatal motor vehicle crashes? If so, through what mechanism — and can the effect be isolated to the gambling→alcohol consumption→impaired driving channel?

## Identification Strategy

### Primary Design: NFL Game-Day Triple-Difference
The core identification exploits three dimensions of variation:
1. **Cross-state:** States that legalized online sports betting vs. those that did not
2. **Within-week:** NFL game days (Sundays) vs. non-game days
3. **Pre/post:** Before vs. after each state's legalization date

This DDD absorbs:
- State × year FE (any state-level trends, including COVID effects)
- Day-of-week × year FE (national patterns in weekend drinking/driving)
- NFL season effects (national)

The identifying assumption is: absent online betting legalization, the gap between NFL Sunday alcohol crashes and non-game-day alcohol crashes would have evolved similarly across treated and control states.

### Supporting Design: Staggered DiD (Callaway-Sant'Anna)
State × month panel using CS (2021) estimator with never-treated and not-yet-treated comparison groups. 26 treated states, ~24 controls.

## Treatment Coding
| State | Online Launch | Source |
|-------|-------------|--------|
| NJ | June 2018 | First mover post-PASPA |
| PA | July 2019 | |
| IN | October 2019 | |
| CO | May 2020 | |
| IL | June 2020 | |
| MI | January 2021 | |
| VA | January 2021 | |
| WV | March 2021 | |
| TN | November 2020 | |
| AZ | September 2021 | |
| CT | October 2021 | |
| WY | September 2021 | |
| LA | January 2022 | |
| NY | January 2022 | |
| MD | November 2022 | |
| OH | January 2023 | |
| MA | March 2023 | |
| KS | September 2022 | |
| ME | November 2023 | |
| KY | September 2023 | |
| NC | March 2024 | |
| VT | January 2024 | |

(Complete list to be verified during data fetch.)

## Expected Effects and Mechanisms
- **Primary channel:** Online betting → increased alcohol consumption during sports viewing → impaired driving
- **Taylor et al. (2024):** Documents 20% increase in mass-market alcohol spending after legalization (the "first stage")
- **Expected magnitude:** 5-10% increase in alcohol-involved fatal crashes in treated states
- **Temporal pattern:** Effects concentrated on NFL Sundays and weekend evenings during football season
- **Geographic pattern:** Stronger in counties with NFL markets (viewing culture)

## Primary Specification

### DDD (Main)
$$Y_{sdt} = \beta \cdot \text{Legal}_{st} \times \text{NFLSunday}_{dt} + \gamma_1 \cdot \text{Legal}_{st} + \gamma_2 \cdot \text{NFLSunday}_{dt} + \alpha_s + \delta_t + \epsilon_{sdt}$$

Where $Y_{sdt}$ = count of alcohol-involved fatal crashes in state $s$ on day $d$ in year $t$.

### State-Month DiD (Supporting)
Callaway-Sant'Anna (2021) with state × month panel, alcohol-involved crash rate per 100K population.

## Placebo/Mechanism Tests
1. **Non-alcohol crashes:** Should show null (no mechanism linking betting to sober driving)
2. **Nighttime (8PM-3AM) vs. daytime:** Alcohol channel predicts nighttime concentration
3. **NFL season vs. off-season:** Effect should be stronger during football season (Sep-Jan)
4. **NFL-market counties:** Counties near NFL stadiums vs. rest of state
5. **Retail-only states:** States with only in-person sports betting — weaker/null effect expected

## Planned Robustness Checks
1. Excluding March-December 2020 (COVID lockdowns)
2. Rambachan-Roth (HonestDiD) sensitivity bounds
3. Goodman-Bacon decomposition (for annual specification)
4. Wild cluster bootstrap (state-level clustering, 50 clusters)
5. Leave-one-out (dropping each treated state)
6. Alternative crash severity: all police-reported alcohol crashes (not just fatal)
7. Controlling for Google Mobility Reports driving volume

## Welfare Calculation
VSL ($11.6M, 2023 DOT value) × excess alcohol fatalities per year = annual social cost. Compare to state gambling tax revenue from online sports betting (~$0.78/capita/month per Taylor et al.).

## Data Sources
1. **FARS 2015-2023:** NHTSA FTP, universe of fatal crashes, exact date/hour/county/alcohol involvement
2. **NFL Schedule:** ESPN API or pro-football-reference.com, game dates by team/venue
3. **Treatment dates:** State online sports betting launch dates (legal/regulatory databases)
4. **Population:** Census annual intercensal estimates by state
5. **Google Mobility:** County-level driving volume controls (2020-2022)

## Power Assessment
- 26 treated states, ~24 controls
- Pre-period: 2015-2017 (3+ years, all states untreated)
- ~8,800 alcohol-involved fatal crashes/year nationally
- At state-month level: ~600 state-months × ~15 alcohol crashes per state-month
- MDE at α=0.05, power=0.80 with state clustering: approximately 4-6% detectable effect
- DDD at daily level provides much finer variation and higher power
