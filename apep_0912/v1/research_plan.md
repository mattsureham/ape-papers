# Research Plan: When the Rice Stopped Flowing

## Research Question

How did India's July 2023 ban on non-basmati white rice exports — which removed 40% of global rice trade overnight — propagate through local food markets across 88 countries? What is the pass-through elasticity from this supply shock to retail rice prices, and how does it vary with pre-ban Indian import dependence?

## Identification Strategy

**Within-market, across-commodity difference-in-differences** with continuous treatment intensity.

- **Treatment:** Rice prices in markets located in countries with high pre-ban Indian rice import dependence
- **Control commodity:** Non-rice staples (maize, wheat, millet, sorghum, beans) in the *same* market-month
- **Treatment intensity:** Country-level share of rice imports sourced from India (2020–2022 average, from UN COMTRADE)
- **Fixed effects:** Market × time FE absorb all local shocks (currency, transport, local demand, weather)
- **Identifying variation:** Differential price change of rice vs. non-rice commodities within the same market, scaled by pre-ban Indian import dependence

**Key identification assumptions:**
1. Absent the ban, rice and non-rice prices would have evolved similarly within markets (parallel trends in commodity price gaps)
2. Pre-ban Indian import share is not correlated with unobserved country-level shocks to rice demand post-July 2023
3. No contemporaneous shocks differentially affected rice vs. non-rice commodities in high-dependence countries

**Built-in placebos:**
- Rice-exporting countries (Thailand, Vietnam, Pakistan) — should see zero or negative pass-through
- Basmati rice (not banned) vs. non-basmati (banned) where WFP distinguishes rice types
- India's wheat export ban (May 2022) as a separate event for falsification
- Pre-ban placebo event study (fake treatment dates in 2022)

**Built-in reversal:** October 2024 partial lifting with MEP mechanism — test for symmetric unwinding.

## Expected Effects and Mechanisms

- **Primary:** Positive pass-through of the export ban to retail rice prices in import-dependent countries, increasing in Indian import share
- **Magnitude:** Based on smoke test, ~10-14% price increase in high-dependence countries within 6 months
- **Mechanism:** Supply disruption → wholesale price increase → retail pass-through; imperfect substitution across rice varieties prevents full arbitrage
- **Heterogeneity:** Larger pass-through in landlocked countries (higher transport costs), countries without alternative suppliers (Thailand/Vietnam capacity constraints), and markets further from ports

## Primary Specification

```
log(price_imc,t) = β × (Rice_c × Post_t × IndiaShare_i) + γ × (Rice_c × Post_t)
                   + δ × (IndiaShare_i × Post_t) + α_mt + ε_imc,t
```

Where:
- i = country, m = market, c = commodity, t = month
- Rice_c = 1 if commodity is rice
- Post_t = 1 if t ≥ July 2023
- IndiaShare_i = pre-ban share of rice imports from India (continuous, 0-1)
- α_mt = market × month fixed effects
- Standard errors clustered at country level

β is the pass-through elasticity: a 10pp increase in Indian import dependence increases rice prices by β×10% more than non-rice commodities after the ban.

**Dynamic specification:** Replace Post_t with event-time dummies (6 months pre, 12 months post) to test parallel trends and trace out the price adjustment path.

## Data Sources

1. **WFP Food Price Monitoring** (primary): Monthly retail food prices from 3,000+ markets across 98 countries, 2002–2026. ~2M total observations, ~250K rice-specific. Available via HDX (Humanitarian Data Exchange) API.

2. **UN COMTRADE** (treatment construction): Bilateral trade flows for HS 1006 (rice), 2020–2022. Used to construct country-level Indian rice import dependence.

3. **USDA PSD** (robustness): Production, Supply, and Distribution data for global rice trade.

## Fetch Strategy

1. Download WFP global food price dataset from HDX
2. Query COMTRADE for bilateral rice trade (HS 1006) to construct import dependence
3. Merge at country level; construct treatment intensity variable
4. Validate against smoke test values from idea manifest
