# Research Plan: Tapping into Labor — Craft Beverage Self-Distribution Deregulation and Manufacturing Employment

## Research Question

Do self-distribution laws — which exempt small breweries from mandatory use of wholesale distributors under the three-tier system — cause measurable employment growth in beverage manufacturing? The three-tier system (manufacturer → distributor → retailer) has governed US alcohol markets since Prohibition's repeal. Starting in the 2000s, states began exempting small craft producers, allowing them to sell directly to retailers. This paper estimates whether this deregulation drove employment creation, firm entry, and wage changes in beverage manufacturing, and decomposes effects by worker demographics.

## Identification Strategy

**Callaway-Sant'Anna staggered DiD** at the county×quarter level. Treatment: state-quarter of self-distribution law enactment (or substantive expansion of production/distribution limits). Approximately 15–20 states adopted or significantly expanded self-distribution rights between 2008 and 2019, with ~15 never-treated states as controls.

**Triple-difference extension:** NAICS 312 (Beverage Manufacturing, treated industry) vs. NAICS 311 (Food Manufacturing, placebo) within the same state-quarter, to absorb state-level trends in manufacturing employment unrelated to the beverage-specific policy.

**Key assumptions:**
- Parallel trends in NAICS 312 employment across treated and control states in the absence of self-distribution laws
- No contemporaneous state-level policies differentially affecting beverage vs. food manufacturing
- Pre-trends testable: QWI panel begins 1990s, providing 10+ years of pre-treatment data

**Placebo tests:**
1. NAICS 311 (Food Manufacturing) — should show no effect
2. NAICS 325 (Chemical Manufacturing) — alternative placebo
3. Pre-treatment falsification: assign treatment 4 quarters early

**Heterogeneity:**
- Worker education (less than HS, HS, some college, BA+)
- Worker age (young 22-34 vs. prime-age 35-54)
- County pre-treatment NAICS 312 presence (extensive vs. intensive margin)

## Expected Effects and Mechanisms

Self-distribution reduces barriers to entry for small breweries by eliminating the need to secure a distributor willing to carry small-volume products. Expected effects:
1. **Employment growth** in NAICS 312, driven by entry of new small establishments
2. **More new hires** (extensive margin of employment growth)
3. **Ambiguous earnings effect** — new entrants may pay less than established large beverage manufacturers, pulling average earnings down even as total employment rises
4. **Demographic composition shift** — craft brewing may attract younger and more educated workers compared to traditional beverage manufacturing

## Primary Specification

Y_{c,t} = α + β × SelfDist_{s(c),t} + γ_c + δ_t + ε_{c,t}

Where:
- Y is county-quarter employment (or hiring, separations, earnings, turnover) in NAICS 312
- SelfDist is a binary indicator for self-distribution law in effect in state s at quarter t
- γ_c are county fixed effects
- δ_t are quarter-of-year × calendar-year fixed effects
- Standard errors clustered at the state level

## Data Source and Fetch Strategy

**QWI on Azure:** `az://derived/qwi/{demo}/n3/*.parquet`
- Demographics: sa (sex×age), se (sex×education), rh (race×ethnicity)
- Industry: NAICS 312 (Beverage Manufacturing) + NAICS 311 (Food Manufacturing, placebo)
- Coverage: county × quarter × demographic cells, 2001–2024
- ~4.4M rows for NAICS 312 alone

**Treatment variable:** Compiled from Brewers Association state regulatory database and Colmenares (2024, Contemporary Economic Policy). State-quarter of self-distribution law enactment or significant expansion.

**State FIPS crosswalk:** Standard Census FIPS codes for state identification from QWI geography field.
