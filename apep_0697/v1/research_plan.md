# Research Plan: apep_0697

## Research Question

Does banning foreign buyers from purchasing residential property reduce house prices, or does domestic substitution absorb the demand shock? We study New Zealand's 2018 Overseas Investment Amendment Act — the world's first national-level prohibition on foreign residential property purchases — exploiting cross-regional variation in pre-ban foreign buyer intensity across 67 territorial authorities.

## Why It Matters

Governments worldwide have adopted foreign buyer restrictions to address housing affordability: Vancouver (15% surcharge, 2016), Sydney (stamp duty surcharges, 2016), Singapore (ABSD up to 60%). The existing literature (Pavlov et al. 2024; Favilukis & Van Nieuwerburgh 2021) studies **taxes** — price mechanisms that create a wedge but still allow transactions. NZ's 2018 ban is qualitatively different: it eliminates the extensive margin entirely. If foreign buyers are marginal price-setters in local markets, a ban should have larger effects than a tax. If domestic buyers substitute one-for-one, even a ban may fail to reduce prices. This distinction — ban vs tax, quantity vs price restriction — is unresolved in the literature.

## Identification Strategy

**Primary design: Cross-regional continuous treatment intensity DiD**

- Unit: 67 territorial authorities (TAs), quarterly, Q4 2016 – Q4 2023 (~28 quarters)
- Treatment intensity: Pre-ban share of property transfers to overseas persons (varies from <0.5% in rural TAs to 5-10% in Auckland CBD/Queenstown)
- Treatment timing: Q4 2018 (ban effective October 2018)
- Estimator: TWFE with continuous treatment intensity (single treatment date, so no staggered adoption concern)
- Fixed effects: TA + quarter
- Clustering: TA level (67 clusters — sufficient for asymptotic inference; supplement with wild cluster bootstrap)

**Supplementary: Synthetic control at national level**

- BIS real house price indices for 15+ OECD countries
- This is supporting evidence only — NOT the main design (single treated unit = fragile)

## Key Identification Assumptions

1. **Parallel trends in treatment intensity:** Absent the ban, high-foreign-buyer and low-foreign-buyer TAs would have followed parallel price trends (conditional on TA and time FEs)
2. **No simultaneous TA-level shocks correlated with foreign buyer share:** Main threat is that high-foreign-buyer areas (Auckland, Queenstown) have different growth trajectories. Address with: pre-trends, placebo outcomes, controls for tourism/population growth
3. **SUTVA:** Ban in one TA doesn't affect prices in another. Some spatial spillovers possible (foreign buyers redirected to commercial property or different countries)

## Built-in Placebos

1. **Australian/Singaporean buyers:** Exempt from ban under FTA provisions. Their transaction share should NOT decline in treated TAs — tests whether decline is ban-specific
2. **Commercial property:** Not covered by the ban. Commercial prices in high-foreign-buyer TAs should be unaffected (or increase if foreign capital redirected)
3. **Pre-period placebo:** Assign fake treatment in 2017Q2, test for spurious effects

## Expected Effects

- **Prices:** Negative in high-foreign-buyer TAs relative to low-foreign-buyer TAs post-ban. Magnitude depends on substitution elasticity
- **Transaction volumes:** Should decline, especially foreign buyer transactions (mechanical)
- **Domestic substitution:** If domestic buyers absorb foreign demand, volume effects exceed price effects

## Data Sources

1. **Stats NZ Property Transfer Statistics:** Quarterly, by TA, from Q4 2016. Includes foreign buyer status (overseas person classification based on citizenship/visa and tax residency). This is the primary data source.
2. **FRED BIS house prices:** QNZR628BIS for NZ, plus 15+ donor countries. Quarterly, 1962-present. For supplementary SCM.
3. **Stats NZ population estimates:** By TA, annual. Control variable.
4. **RBNZ housing data:** National-level backup.

## Primary Specification

$$Y_{it} = \alpha_i + \gamma_t + \beta \cdot (\text{ForeignShare}_i \times \text{Post}_t) + \varepsilon_{it}$$

Where:
- $Y_{it}$: Log median transfer price (or price index) in TA $i$, quarter $t$
- $\alpha_i$: TA fixed effects
- $\gamma_t$: Quarter fixed effects
- $\text{ForeignShare}_i$: Pre-ban (2017) share of transfers to overseas persons
- $\text{Post}_t$: Indicator for $t \geq$ 2018Q4
- Cluster SEs at TA level

## Robustness

1. Event study: Replace $\text{Post}_t$ with quarter dummies relative to treatment
2. Wild cluster bootstrap (67 clusters)
3. Alternative treatment intensity measures (binary high/low split)
4. Placebo outcomes (Australian/Singaporean buyer transactions)
5. Leave-one-out (drop Auckland, drop Queenstown)
6. Alternative post-period windows
