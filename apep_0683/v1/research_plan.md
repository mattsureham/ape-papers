# Research Plan: The Vacancy Paradox — Punitive Property Taxation and Long-Term Empty Dwellings in England

## Research Question

Does escalating council tax premiums on long-term empty dwellings reduce housing vacancy? England introduced a 50% council tax premium on properties vacant 2+ years in April 2013, with staggered voluntary adoption across 305 local authorities. Subsequent legislation escalated premiums to 100% (2019), 200% for 5+ year empties (2020), and 300% for 10+ year empties (2021). Despite this escalation, aggregate long-term vacancies *rose* from ~200,000 (2016) to ~303,000 (2025). This paper provides the first causal estimate of whether these premiums reduce vacancy.

## Why It Matters

Over 300,000 dwellings sit empty for 2+ years in England while the country faces a severe housing affordability crisis. Vacancy taxes are spreading globally — Vancouver, Paris, Melbourne, Toronto, Washington DC — yet there is no credible causal evidence on whether punitive property taxation actually activates vacant housing stock. A well-identified null would be a decisive contribution: it would tell policymakers that financial penalties alone may not solve vacancy when the binding constraints are structural (probate, renovation costs, legal disputes).

## Identification Strategy

**Design A (Primary): Staggered DiD on initial adoption (2013-2014)**

- **Treated:** 244 LAs that adopted the 50% premium by October 2014
- **Control:** 61 LAs that did not adopt (never-treated or late-treated)
- **Pre-period:** 2004-2012 (9 years)
- **Post-period:** 2013-2025 (up to 12 years)
- **Estimator:** Callaway-Sant'Anna (2021) with never-treated controls
- **Clustering:** LA level

**Design B (Dose-response): Premium escalation intensity**

- Compare LAs charging maximum premiums vs lower rates after 2019 escalation
- Continuous treatment intensity: premium rate (50%, 100%, 200%, 300%)

**Parallel trends argument:** LA adoption was voluntary but driven primarily by political composition and revenue needs, not vacancy trends. The 9-year pre-period (2004-2012) provides extensive evidence on pre-treatment trends. We test for differential pre-trends and use HonestDiD bounds.

## Expected Effects and Mechanisms

**If premiums work:** Vacancy should decline in early-adopting LAs relative to non-adopters, with effects growing as premiums escalate. Mechanism: owners sell, rent, or renovate to avoid the premium.

**If premiums don't work (the vacancy paradox):** Premiums may fail because:
1. Most long-term vacants are in probate, derelict, or legally contested — owners can't respond to financial incentives
2. Premium revenues incentivize LAs to maintain the vacancy stock (perverse fiscal incentive)
3. Exemptions and discounts dilute the effective premium rate
4. The premium is too small relative to price appreciation in high-demand areas

**Heterogeneity predictions:**
- Stronger effects in areas with high housing demand (London, South East) where opportunity cost of vacancy is highest
- Weaker effects in areas with structural vacancy (North, former industrial areas) where renovation costs exceed property values
- Differential effects by property type if data permits

## Primary Specification

$$Y_{it} = \alpha_i + \gamma_t + \sum_{g} \sum_{t} ATT(g,t) \cdot \mathbf{1}[G_i = g] \cdot \mathbf{1}[T = t] + \varepsilon_{it}$$

Where:
- $Y_{it}$: Long-term vacant dwellings (or vacancy rate) in LA $i$, year $t$
- $\alpha_i$: LA fixed effects
- $\gamma_t$: Year fixed effects
- $ATT(g,t)$: Group-time average treatment effect (Callaway-Sant'Anna)
- $G_i$: Adoption cohort of LA $i$

## Data Sources

1. **MHCLG Table 615** (primary outcome): Long-term vacant dwellings by LA, 2004-2025 (378 LAs, 22 years). Already confirmed accessible as ODS file.

2. **Council Taxbase (CTB) data** (treatment assignment): LA-level premium adoption status and rates. CTB 2014 confirms 244 adopters vs 61 non-adopters. CTB 2025 confirms 291/296 LAs apply premium.

3. **HM Land Registry Price Paid Data** (mechanism/heterogeneity): Transaction volumes and prices by LA. Confirms ~1M transactions/year.

4. **MHCLG/DLUHC Live Table 100** (housing context): Total dwelling stock by LA.

5. **ONS mid-year population estimates** (controls).

## Robustness Checks

1. Event study with 9 pre-periods — visual and formal pre-trend tests
2. HonestDiD sensitivity analysis (Rambachan-Roth bounds)
3. Placebo outcome: total dwelling stock (should not be affected)
4. Alternative control groups: not-yet-treated vs never-treated
5. Excluding London boroughs (outlier vacancy dynamics)
6. Vacancy rate (vacants/total stock) instead of vacancy count
7. Goodman-Bacon decomposition of TWFE for diagnostics

## Deliverables

- 3-5 tables (summary stats, main results, event study, heterogeneity, robustness)
- Zero figures (V1 format)
- SDE appendix table
- AER: Insights format, 8-15 pages
