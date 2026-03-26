# Research Plan: Pouring Risk — Raw Milk Legalization and Foodborne Illness

## Research Question
Does legalizing raw (unpasteurized) milk sales increase foodborne illness outbreaks? The existing literature (Whitten et al. 2022; Whitehead & Lake 2018) uses cross-sectional methods and reaches contradictory conclusions. This paper provides the first causal estimate using modern staggered difference-in-differences.

## Identification Strategy
**Staggered DiD (Callaway & Sant'Anna 2021).** Approximately 30 US states expanded legal access to raw milk sales between 2004 and 2023. Treatment is defined as the year a state first legalized or expanded raw milk sales channels (retail, on-farm, herdshare, or farmers market). States that never legalized serve as the never-treated comparison group.

**Key design features:**
- CS estimator avoids TWFE bias from staggered adoption
- 50 state clusters for inference (wild cluster bootstrap as robustness)
- Built-in placebo: non-dairy foodborne outbreaks (unaffected by raw milk laws)
- Dose-response: retail sales (broad access) vs. on-farm only (limited access)

## Expected Effects and Mechanisms
**Primary hypothesis:** Legalization increases raw dairy outbreaks by expanding consumer access to unpasteurized products that carry elevated pathogen risk (Campylobacter, E. coli O157, Salmonella, Listeria).

**Expected direction:** Positive — legalization → more consumption → more outbreaks. Prior cross-sectional evidence suggests OR ≈ 3.87 (Whitten et al. 2022).

**Mechanism:** Sales channel type should predict effect magnitude. Retail sales (supermarkets, stores) reach broader populations than on-farm sales, which require consumers to travel to farms. Herdshare arrangements serve very small populations.

**Heterogeneity:** Effects may be larger in states with higher dairy production, more farms, or more developed farmers market infrastructure.

## Primary Specification
Poisson pseudo-maximum likelihood (PPML) with Callaway-Sant'Anna group-time ATTs:

Y_{st} = count of unpasteurized dairy outbreaks in state s, year t
Treatment_{st} = 1 if state s has legalized raw milk sales by year t
Fixed effects: state + year
Clustering: state level

For event study: estimate dynamic treatment effects τ(g,t) by cohort g and calendar year t, aggregate to event-time ATTs.

## Data Sources

### 1. CDC NORS (National Outbreak Reporting System)
- **Source:** Socrata API, dataset ID 5xkq-dg7x
- **Coverage:** 1998-2023, all US states
- **Key fields:** state, year, etiology (pathogen), commodity (food vehicle), illnesses, hospitalizations, deaths
- **Filter:** Commodity containing "dairy" or "milk" + etiology associated with raw dairy
- **Size:** 66,713 total outbreak records; ~215 identified as unpasteurized dairy

### 2. Raw Milk Legalization Dates
- **Source:** Compiled from NCSL database, Farm-to-Consumer Legal Defense Fund, CDC Public Health Law Program, and academic literature (Whitten et al. 2022)
- **Coding:** Year each state first legalized/expanded each sales channel (retail, on-farm, herdshare, farmers market)
- **Treatment variable:** Binary indicator for any legalization event

### 3. State Covariates (controls/heterogeneity)
- **USDA NASS:** Dairy production, number of dairy farms by state-year
- **Census population estimates:** State population for per-capita rates
- **CDC surveillance capacity:** Reporting completeness indicators

## Exposure Alignment
The treatment (legal status change) is assigned at the state level and affects all residents who might consume raw milk in that state. The key exposure mechanism is consumer access: legalization enables purchases through newly authorized channels (retail, on-farm, herdshare), increasing the population exposed to unpasteurized dairy products. The treatment is absorbing (once legalized, states do not re-ban), and we code treatment at the state-year level matching the annual NORS reporting. States with pre-existing legalization (24 states) are "always treated" and do not contribute to the identifying variation in the CS estimator.

## Robustness Checks
1. Poisson vs. negative binomial vs. OLS on log(1+count)
2. Wild cluster bootstrap p-values (50 clusters)
3. Randomization inference (permute treatment timing)
4. Placebo outcome: non-dairy outbreaks
5. Placebo treatment: neighboring states' legalization
6. HonestDiD sensitivity analysis for pre-trend violations
7. Leave-one-state-out jackknife
8. Alternative treatment coding: restrict to retail legalization only
