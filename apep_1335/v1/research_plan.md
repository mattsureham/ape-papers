# Research Plan: The Equity Lottery Premium — Randomized Cannabis Licensing and Local Economic Renewal in Illinois

## Research Question

Do lottery-allocated cannabis dispensary licenses — distributed as part of Illinois's social equity program — generate measurable local economic gains in the counties where winners open stores? The lottery provides quasi-random variation in dispensary entry, allowing us to estimate the causal effect of new retail cannabis establishments on local employment, earnings, and business formation.

## Policy Background

Illinois legalized adult-use cannabis on January 1, 2020 (Cannabis Regulation and Tax Act, Public Act 101-0027). Rather than using merit-based licensing or first-come-first-served allocation, the state distributed 185 new dispensary licenses through three random lotteries:

1. **Qualifying Applicant Lottery** (July 29, 2021): 55 licenses
2. **Social Equity Justice Involved Lottery** (August 5, 2021): 55 licenses
3. **Tied Applicant Lottery** (August 19, 2021): 75 licenses

A fourth round (SECL, July 13, 2023) allocated 55 additional licenses from 2,676 applicants. IDFPR used the Illinois State Lottery's computer-based random number generator. By January 2026, 274 total adult-use dispensaries are active, including 134+ social equity lottery winners.

## Identification Strategy

**Design:** Staggered difference-in-differences (Callaway & Sant'Anna 2021) at the county-quarter level.

**Treatment:** Quarter in which the first lottery-allocated dispensary opens in a county. The lottery itself is genuinely random conditional on meeting an 85% scoring threshold, providing exogenous variation in which counties receive new dispensaries and when.

**Controls:** Later-treated and never-treated Illinois counties within the same BLS region.

**Key advantage:** Unlike standard DiD studies of cannabis legalization (which compare across states with different policy environments), we compare within Illinois — all counties face the same legal regime. The only variation is whether and when a lottery winner opens a dispensary in a given county.

## Expected Effects and Mechanisms

1. **Direct employment:** New dispensaries hire 15-30 workers each (budtenders, security, managers)
2. **Retail spillovers:** Foot traffic from dispensary customers may benefit neighboring businesses (food service, retail)
3. **Supply chain:** Cannabis cultivation, processing, and distribution create upstream employment
4. **Tax revenue:** Illinois cannabis tax revenue exceeded $1.5B cumulative by 2024; local municipalities receive shares

We expect moderate positive effects on retail employment and earnings, with larger effects in smaller counties where a single dispensary represents a more significant economic shock.

## Primary Specification

$$Y_{ct} = \alpha_c + \gamma_t + \sum_g \sum_{e \neq -1} \beta_{g,e} \cdot \mathbb{1}[G_c = g] \cdot \mathbb{1}[t - g = e] + X_{ct}'\delta + \varepsilon_{ct}$$

where:
- $Y_{ct}$: employment/earnings in county $c$, quarter $t$ (QWI)
- $\alpha_c$, $\gamma_t$: county and quarter fixed effects
- $G_c$: treatment cohort (quarter of first lottery dispensary opening)
- $X_{ct}$: time-varying controls (population, COVID controls)
- Clustered standard errors at the county level

ATT(g,t) estimated via Callaway-Sant'Anna with not-yet-treated as comparison group.

## Data Sources

1. **Treatment data:** IDFPR Adult-Use Dispensary License List (PDF) — dispensary names, addresses, license issue dates, social equity status
2. **Outcome data:** Census QWI via API — county × quarter × industry employment and earnings for Illinois (FIPS 17), NAICS 44-45 (Retail), 7225 (Food Services), total private
3. **County income:** BEA Regional Economic Accounts via API — county-level personal income
4. **Controls:** Census population estimates, BLS LAUS unemployment rates

## Fetch Strategy

1. Download IDFPR dispensary PDF → parse addresses → geocode to counties → identify lottery vs. pre-existing licenses → construct treatment timing
2. Query Census QWI API for IL counties, all quarters 2018Q1-2025Q4, NAICS 44-45, 7225, total private
3. Query BEA API for county personal income

## Exposure Alignment

The treatment is the arrival of a lottery-allocated dispensary in a county. The affected population is the county's labor force, specifically workers in retail trade, food services, and related sectors. The treatment unit (county) matches the outcome measurement unit (county-quarter QWI employment). The mechanism runs through: (1) direct dispensary employment (15-30 workers per store), (2) foot traffic spillovers to nearby businesses, and (3) supply chain demand. The county-level analysis captures aggregate effects but may dilute hyper-local spillovers concentrated near the dispensary location.

## Robustness Checks

1. **Pre-trend tests:** Event-study plot of CS ATT(g,t) estimates
2. **Placebo outcomes:** Manufacturing employment (NAICS 31-33, should not respond to dispensary openings)
3. **Heterogeneity:** Small vs. large counties (dispensary = bigger shock in small counties)
4. **Alternative treatment:** Use license award date instead of opening date
5. **Sensitivity:** HonestDiD bounds on pre-trend violations
