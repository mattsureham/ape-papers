# Research Plan: Locked Out of FHA

## Research Question

Does state recreational marijuana legalization reduce the share of government-backed (FHA) mortgages relative to conventional mortgages, by excluding cannabis-derived income from federal loan qualification?

## Identification Strategy

**Staggered difference-in-differences** exploiting the rollout of recreational marijuana legalization across 24 US states between 2012 and 2023. Estimator: Callaway and Sant'Anna (2021) group-time ATT with not-yet-treated states as controls.

**Key institutional detail:** HUD Handbook 4000.1 explicitly bars income "derived from the production or sale of marijuana" from qualifying for FHA-insured mortgages. The same exclusion applies to VA and USDA loans. Conventional conforming loans (Fannie Mae/Freddie Mac) accept legally earned cannabis income. This creates a sharp policy-induced substitution channel.

**Built-in counterfactual:** Conventional mortgage share should increase symmetrically with FHA share decline — a direct substitution test.

**Triple-difference:** (legalized vs. not) × (high-cannabis-employment counties vs. low) × (pre vs. post). Cannabis employment intensity proxied by QCEW NAICS codes 111998 (cannabis growing), 424590 (misc. nondurable goods wholesale), 453998 (misc. store retailers).

## Expected Effects and Mechanisms

- **Primary:** FHA share of purchase mortgage originations declines 1-3 percentage points in legalizing states relative to controls
- **Mechanism:** Cannabis workers excluded from FHA underwriting shift to conventional loans (higher rates, larger down payments)
- **Heterogeneity:** Effect concentrates among lower-income borrowers and counties with larger cannabis industries
- **Welfare:** Interest rate differential between FHA and conventional = annual cost of "legalization penalty" per cannabis worker

## Primary Specification

$$Y_{st} = \alpha_s + \gamma_t + \sum_g \sum_t \text{ATT}(g,t) \cdot \mathbb{1}[G_s = g] + \varepsilon_{st}$$

where $Y_{st}$ is FHA share of purchase originations in state $s$, year $t$; $G_s$ is the legalization cohort; ATT(g,t) are group-time treatment effects estimated via Callaway-Sant'Anna.

Clustering: state level (24 treated + 26 control = 50 clusters).

## Data Source and Fetch Strategy

**Primary data:** HMDA (Home Mortgage Disclosure Act) via CFPB Data Browser API
- URL: `https://ffiec.cfpb.gov/v2/data-browser-api/view/csv`
- Years: 2018-2023 (API); 2010-2017 (historic files from CFPB)
- Key fields: `loan_type` (1=conventional, 2=FHA, 3=VA, 4=USDA), `state_code`, `county_code`, `action_taken`, `loan_purpose`, `income`, `loan_amount`
- Volume: ~8-15 million originated loans per year

**Treatment timing:** Manually coded from state legislation. Key dates:
- 2012: CO, WA
- 2014: AK, OR, DC
- 2016: CA, NV, ME, MA
- 2018: VT, MI
- 2019: IL
- 2020: AZ, MT, NJ, SD
- 2021: NY, NM, CT, VA
- 2022: RI, MD, MO
- 2023: DE, MN, OH

**Controls:** State unemployment rate (BLS LAUS), FHFA HPI (house price index).

## Robustness

1. Event study with 5+ leads (pre-trend test)
2. Randomization inference (500 permutations)
3. VA loan share as placebo (also federally backed, similar exclusion)
4. Leave-one-out (drop CO, drop CA)
5. County-level border analysis (adjacent counties across state lines)
6. Bacon decomposition to check for negative-weight 2×2s
