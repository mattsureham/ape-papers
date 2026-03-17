# Research Plan: Sports Betting Revenue Cannibalization

## Research Question
Does legalizing online sports betting generate net new state gambling tax revenue, or does it merely cannibalize existing gambling revenue streams (lottery, pari-mutuel, casino/amusement)?

## Identification Strategy
Callaway-Sant'Anna (2021) staggered DiD exploiting the staggered legalization of online sports betting across 39 U.S. states (2018-2025), with 11 never-treated states as controls. Treatment date: state's first month accepting legal online wagers.

## Expected Effects and Mechanisms
- **Direct effect:** Sports betting tax revenue should increase sharply (this is mechanical).
- **Cannibalization:** If gambling budgets are fixed, lottery sales/tax revenue and pari-mutuel revenue should decline after sports betting legalization.
- **Net fiscal effect:** Sum of all gambling revenue changes may be near zero.
- **Placebo:** General sales tax (T09) and tobacco tax (T16) should be unaffected.
- **Heterogeneity:** States with higher sports betting tax rates may see less cannibalization (higher-taxed bets capture more revenue per dollar cannibalized).

## Primary Specification
```
Y_{st} = α_s + γ_t + β × LegalSportsBetting_{st} + ε_{st}
```
Using CS-DiD with not-yet-treated and never-treated as controls.

Y includes: (1) total gambling tax revenue (T11), (2) pari-mutuel tax revenue (T20), (3) lottery revenue (from NASPL if available, otherwise from STC), (4) placebo: general sales tax (T09).

All outcomes in per-capita terms (divided by state population) or log-transformed.

## Exposure Alignment
Treatment is defined at the state-year level: a state is "treated" in and after the fiscal year when it first collects material online sports betting tax revenue. The treated population is the state's gambling market — all legal gambling operations (casinos, racetracks, lotteries) face potential revenue displacement when a new legal gambling product (sports betting) enters their market. The outcome (state tax revenue by category) directly measures the fiscal consequence at the level where treatment is assigned. There is no partial treatment or differential exposure within a state — all gambling operators in a state face the same competitive shock from sports betting legalization.

## Data Source and Fetch Strategy
**Primary:** Census Annual Survey of State Government Tax Collections (STC)
- URL: https://www.census.gov/programs-surveys/stc.html
- Flat files: www2.census.gov/govs/statetax/ (2000-2022)
- Variables: T11 (amusement/gambling tax), T20 (pari-mutuel), T10 (alcoholic beverage), T16 (tobacco), T09 (general sales)

**Treatment dates:** From American Gaming Association state tracker + news sources.
Key dates:
- NJ: June 2018 (first after Murphy v. NCAA)
- WV: Aug 2018, MS: Aug 2018, PA: Nov 2018
- RI: Nov 2018, IN: Sep 2019, IA: Aug 2019
- NH: Dec 2019, IL: Mar 2020, CO: May 2020
- MI: Jan 2021, VA: Jan 2021, TN: Nov 2020
- AZ: Sep 2021, CT: Oct 2021, NY: Jan 2022
- ...and more through 2025

**Population data:** FRED API for state population (to compute per-capita).

**Never-treated states:** AL, AK, CA, GA, HI, ID, MN, OK, SC, TX, UT
