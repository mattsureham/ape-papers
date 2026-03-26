# Research Plan: Love Lessons or Lost Revenue? Premarital Education Promotion and Divorce

## Research Question

Do state policies that incentivize premarital counseling via marriage license fee reductions reduce divorce rates? Ten US states adopted such policies between 1998–2018, offering $20–60 fee discounts or waiting period waivers for couples completing 4–8 hours of counseling. Despite widespread adoption, no economics paper has evaluated their causal effect on marital stability.

## Identification Strategy

**Staggered Difference-in-Differences** using Callaway and Sant'Anna (2021).

- **Treatment:** Binary indicator for state adoption of a premarital education promotion policy.
- **Treated states (10):** FL (1998), OK (1999), MD (2001), MN (2001), TN (2002), GA (2004), SC (2006), TX (2007), WV (2012), UT (2018).
- **Control states:** ~40 never-treated states + DC.
- **Parallel trends assumption:** Divorce rates in treated states would have followed the same trajectory as untreated states absent the policy. Testable with 2–8 years of pre-treatment data per cohort.

**Key threats:**
1. Secular divorce decline (national trend) — absorbed by year fixed effects.
2. Correlated state policies (e.g., covenant marriage, no-fault divorce reform) — robustness check excluding Louisiana, Arizona, Arkansas (covenant marriage states).
3. Small number of treated clusters (10 states) — wild cluster bootstrap inference.

## Expected Effects and Mechanisms

**Mechanism 1 (Information):** Counseling teaches communication and conflict resolution, reducing divorce. Expect negative effect on divorce rates (SDE: −0.05 to −0.15).

**Mechanism 2 (Selection):** Fee reduction attracts couples who would have married anyway. Marginal couples deterred by license cost are those least committed. Policy shifts composition toward more committed couples. Expect smaller effect on marriage rates, negative effect on divorce.

**Mechanism 3 (Null/De minimis):** $20–60 is too small an incentive to change behavior. Couples who want counseling already get it. Expect null effect (SDE: −0.005 to +0.005).

## Primary Specification

$$Y_{st} = \alpha_s + \gamma_t + \delta_{g,t} + \epsilon_{st}$$

where $Y_{st}$ is the divorce rate in state $s$ at year $t$, $\alpha_s$ are state FE, $\gamma_t$ are year FE, and $\delta_{g,t}$ are group-time ATTs estimated via Callaway-Sant'Anna.

Aggregate to: (1) overall ATT, (2) dynamic event-study coefficients, (3) group-specific ATTs.

**Inference:** Cluster at state level. Wild cluster bootstrap (Webb weights) with 999 iterations given 10 treated clusters.

## Data Sources

### Primary: CDC NVSS State Divorce Rates
- Source: CDC National Center for Health Statistics
- Years: 1990–2023
- Unit: State-year
- Variables: Divorces per 1,000 population
- Note: Georgia missing 2004–2016 → exclude GA from primary CDC analysis

### Secondary: ACS 1-Year Estimates
- Source: Census Bureau ACS API
- Years: 2008–2022
- Tables: B12501 (marital events past 12 months), B12001 (marital status)
- Unit: State-year
- Allows heterogeneity by education, race, age

### Controls (robustness)
- State unemployment rate (BLS LAUS)
- Median household income (ACS B19013)
- Population (Census PEP)

## Fetch Strategy

1. **CDC divorce rates:** Download Excel from NVSS website, parse all states 1990–2023.
2. **ACS tables:** Census API with key, tables B12501 and B12001, all states, 2008–2022.
3. **BLS LAUS:** BLS API for state unemployment rates.

## Analysis Pipeline

1. `01_fetch_data.R` — Download CDC Excel, query ACS API, query BLS API
2. `02_clean_data.R` — Merge datasets, construct treatment indicators, create panel
3. `03_main_analysis.R` — Callaway-Sant'Anna DiD, event study, wild cluster bootstrap
4. `04_robustness.R` — Placebo tests, drop GA, covenant marriage states, HonestDiD bounds
5. `05_tables.R` — All tables including SDE appendix
