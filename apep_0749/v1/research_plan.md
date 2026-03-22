# Research Plan: The Game-Day Externality — Online Sports Betting, Alcohol-Involved Fatal Crashes, and the Enforcement Gap

## Research Question

Does the legalization of online sports betting increase alcohol-involved fatal motor vehicle crashes? If so, does police DUI enforcement scale proportionally — or does a gap emerge between rising alcohol-impaired driving risk and lagging enforcement? Is the effect concentrated on game days, creating a predictable "game-day externality"?

## Identification Strategy

**Callaway-Sant'Anna staggered DiD.** 30 US states legalized online sports betting between June 2018 (New Jersey) and 2024, with ~20 states remaining never-treated through the sample period. Treatment date is the first month each state accepted legal online wagers.

Key identifying assumption: absent legalization, treated and control states would have followed parallel trends in alcohol-involved fatal crash rates. Testable with 5+ years of pre-treatment data (2013-2017).

**Mechanism test — game-day amplification (triple-difference):**
- Within treated states, compare alcohol-involved fatal crash rates on days with major professional sports events (NFL, NBA, MLB) vs. non-game days
- The triple-diff: state × game-day × post-legalization
- Non-game days serve as a within-state temporal placebo

**Enforcement elasticity:**
- If DUI arrest data is available (FBI CDE API): estimate DUI arrest rate response to legalization
- Enforcement gap = ΔFatalities / ΔArrests — if fatalities increase but arrests don't, enforcement is inelastic

## Expected Effects and Mechanisms

1. **Alcohol consumption channel:** Sports betting increases time spent watching sports at bars/restaurants, increasing alcohol consumption → more impaired driving. BRFSS evidence suggests sports betting raises binge drinking (Swanson 2023).

2. **Game-day concentration:** Effects should concentrate on game days (evenings/weekends when games are played and bets are active). This is the "game-day externality" — a predictable spike in alcohol-impaired driving risk.

3. **Enforcement response:** Police enforcement may not scale to match the increased risk because:
   - DUI enforcement requires proactive patrols (not reactive like 911 calls)
   - Police budgets are set annually, not adjusted for new risk patterns
   - Sports betting doesn't trigger visible disorder that prompts enforcement surges

## Primary Specification

```
Y_{st} = α_s + α_t + β · OSB_{st} + X_{st}γ + ε_{st}
```

Where Y_{st} is the alcohol-involved fatal crash rate per 100K population in state s, year-quarter t. OSB_{st} is a binary indicator for legal online sports betting. State and time fixed effects absorb level differences. Standard errors clustered at state level.

Using Callaway-Sant'Anna (2021) for heterogeneity-robust ATT estimates with never-treated states as comparison group.

## Data Sources and Fetch Strategy

### Primary: FARS (Fatality Analysis Reporting System)
- **Source:** NHTSA, downloadable as CSV/SAS files
- **Years:** 2013-2022 (10 years; latest publicly available)
- **Unit:** Individual fatal crash record with state, date, DRINKING variable
- **Key variable:** DRINKING (0=No, 1=Yes) or DRUNK_DR (number of drunk drivers)
- **Construction:** State-quarter alcohol-involved fatal crash rate per 100K population

### Secondary: FBI Crime Data Explorer
- **Source:** FBI CDE API (api.usa.gov/crime/cde)
- **Variable:** DUI arrests by state and year
- **Fallback:** If API unavailable, use published UCR tables or focus on fatality-side evidence only

### Treatment variable: Online Sports Betting legalization dates
- **Source:** American Gaming Association (AGA) state-by-state tracker, cross-referenced with legal gambling databases
- Well-documented dates for all 30+ states

### Controls
- State population (Census API)
- Unemployment rate (BLS/FRED)
- Per capita income (BEA)
- Total vehicle miles traveled (FHWA)

### Game-day data
- NFL, NBA, MLB regular season and playoff schedules
- Professional team locations by state (for home-game effects)

## Key Risks
1. **DUI arrest data access** — fallback: fatality-only paper with game-day mechanism
2. **COVID confound** — several states legalized during 2020-2021; address via CS-DiD structure (time FE absorb symmetric shocks) and explicit COVID-period sensitivity
3. **Concurrent policy changes** — some states changed DUI laws or alcohol regulations in same period; control for blood alcohol limit changes
