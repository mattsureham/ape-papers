# Research Plan: The Price of Attracting Firms

## Research Question

Does municipal tax competition crowd out public goods provision? Specifically, when Swiss municipalities cut corporate tax multipliers (Steuerfuss) to attract firms, do they reduce per-capita spending on education, social welfare, and infrastructure?

## Why This Matters

The normative case for OECD Pillar Two and global minimum taxation rests on the claim that tax competition erodes public goods. Zodrow and Mieszkowski (1986) predicted this theoretically, but no clean municipal-level causal test exists. Existing work estimates tax-setting reaction functions (Eugster & Parchet 2019 JPE) or tax base responses (Krapf & Staubli 2025), but not the downstream effect on public expenditure composition.

## Identification Strategy

**Design:** Municipality-year panel with municipality fixed effects and year fixed effects. Treatment is within-municipality changes in the corporate Steuerfuss (tax multiplier).

**Why this works:** Swiss municipalities set their own Steuerfuss annually through local democratic processes. The multiplier applies to cantonal base rates, creating genuine exogenous variation in effective corporate tax rates across municipalities and over time. Municipality FE absorb time-invariant characteristics; year FE absorb common shocks.

**Key threat:** Steuerfuss changes may respond to anticipated economic conditions. We address this with:
1. Event study around large discrete cuts (≥5 percentage points) to check pre-trends
2. Placebo test using natural-person (individual) Steuerfuss changes
3. Neighbor-rate IV following Parchet (2019) — instrument own rate with neighbors' rates
4. Heterogeneity by fiscal capacity (rich vs. poor municipalities)

## Primary Specification

Y_{it} = α_i + γ_t + β · CorporateSteuerfuss_{it} + X_{it}δ + ε_{it}

Where:
- Y_{it} = per-capita spending on education / social welfare / infrastructure
- α_i = municipality FE
- γ_t = year FE
- CorporateSteuerfuss_{it} = corporate tax multiplier (percentage of cantonal base rate)
- X_{it} = population, population growth (time-varying controls)
- Standard errors clustered at municipality level

## Expected Effects and Mechanisms

If Zodrow-Mieszkowski holds: β < 0 (lower tax rates → lower spending on public goods)

Mechanisms to test:
1. **Revenue channel:** Tax cuts reduce revenue mechanically → spending must fall
2. **Composition channel:** Municipalities cut discretionary spending (infrastructure) before mandatory (education)
3. **Base expansion:** If tax cuts attract enough firms, revenue may be maintained → no spending cuts
4. **Fee substitution:** Municipalities may raise user fees to offset lost revenue

## Data Sources

1. **Zurich Steuerfuss data** — Canton Zurich publishes annual corporate and natural-person tax multipliers for all ~160 municipalities (2010–2026). Available as CSV download.

2. **Zurich Jahresrechnungen** — Municipal financial accounts with 192 indicators per municipality-year (1995–2024). Functional categories: education, health, social welfare, transport/infrastructure, environment, administration. Available via opendata.swiss.

3. **BFS STATENT** — Federal establishment statistics by municipality (2011–2023). Used for mechanism test: do tax cuts actually attract firms? Available via PXWeb API.

4. **BFS population data** — Municipal population for per-capita normalization. Available via PXWeb API.

## Fetch Strategy

1. Download Zurich Steuerfuss CSV from opendata.swiss
2. Download Zurich Jahresrechnungen from opendata.swiss
3. Query BFS PXWeb for STATENT establishment counts by municipality
4. Query BFS PXWeb for population by municipality
5. Merge on BFS Gemeindenummer + year

## Sample

- ~160 Zurich municipalities × ~15–25 years
- ~120 municipalities with at least one corporate Steuerfuss change
- ~4,000 municipality-year observations (Steuerfuss panel)
- Spending data: up to 30 years depending on Jahresrechnungen availability

## Analysis Plan

1. **Descriptive statistics:** Distribution of Steuerfuss changes, spending patterns
2. **Main specification:** Panel FE regression of per-capita spending on Steuerfuss
3. **Event study:** Dynamic effects around large Steuerfuss cuts (≥5pp)
4. **Placebo:** Natural-person Steuerfuss → corporate spending (should be null if corporate channel is specific)
5. **Mechanism:** STATENT establishment growth response to Steuerfuss changes
6. **Heterogeneity:** By fiscal capacity, population size, urban/rural
7. **Robustness:** Neighbor-rate IV, alternative spending categories, different clustering
