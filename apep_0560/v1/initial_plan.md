# Initial Research Plan — APEP-0560

## Research Question

Do tailings dam failures create negative stock market contagion across the global mining sector? Does the 2020 Global Industry Standard on Tailings Management (GISTM) reduce this contagion by changing investor beliefs about systemic vs. idiosyncratic risk?

## Identification Strategy

Event study methodology. Tailings dam failures are plausibly exogenous shocks to peer mining firms' stock prices in the short run — engineering failures, seismic triggers, and extreme rainfall are uncorrelated with peer firms' short-run fundamentals.

Key variation:
- **Within-event cross-sectional**: Firms with vs. without tailings dams (built-in placebo)
- **Commodity channel**: Same-commodity vs. cross-commodity peers
- **Temporal structural break**: Pre-GISTM vs. post-GISTM (August 2020)
- **Severity gradient**: Fatal/major vs. non-fatal events

## Expected Effects and Mechanisms

1. **Overall contagion** (H0): Negative CARs for peer mining firms following failures (regulatory risk channel — investors price increased probability of tighter regulation)
2. **Tailings exposure** (H1): Firms with tailings dams suffer larger losses than streaming/royalty companies (direct risk exposure)
3. **Commodity channel** (H2): Same-commodity peers suffer more (commodity-specific regulatory expectations)
4. **GISTM effect** (H4): Post-GISTM failures generate less contagion (voluntary standard reassures investors that risk is now idiosyncratic, not systemic)
5. **Severity scaling** (H5): Fatal failures generate larger contagion (stronger regulatory expectations)

## Primary Specification

1. **Market model estimation**: R_it = α_i + β_i × R_mt + ε_it, estimated over [-250, -31]
2. **Abnormal returns**: AR_it = R_it - (α̂ + β̂ × R_mt)
3. **CARs**: Cumulated over [-1, +5] (primary), [-1, +1] and [-1, +10] (robustness)
4. **Cross-sectional regression**: CAR_ij = β₀ + β₁·HasTailings + β₂·SameCommodity + β₃·PostGISTM + β₄·HasTailings×PostGISTM + β₅·Severity + ε_ij, clustered by event

## Method Notes: Event Study

The event study methodology follows the standard approach in financial economics:

1. **Identification assumption**: Failures are exogenous to peer firms' stock returns in the short run. Violated if: (a) events are anticipated, (b) events coincide with sector-wide shocks. Pre-event placebo window [-5, -2] tests for anticipation.
2. **Key validity checks**: Pre-event abnormal returns should be zero; placebo firms (non-mining) should show no response; results should be robust to alternative benchmarks.
3. **Common pitfalls**: Cross-sectional dependence (firms respond to the same market conditions), event clustering (multiple failures close in time), thin trading for some firms. Address with event-clustered SEs, exclusion of overlapping events, and minimum observation requirements.
4. **R packages**: `quantmod` for data, `fixest` for cross-sectional regressions, base `lm()` for market model estimation.
5. **Key papers**: MacKinlay (1997) JEL survey, Campbell, Lo & MacKinlay (1997) textbook.

## Planned Robustness Checks

1. Alternative event windows: [-1,+1], [-1,+3], [-1,+10]
2. Exclude overlapping events (within 10 trading days)
3. Exclude mega-events (top 3 deadliest)
4. Placebo: random pseudo-event dates (200 permutations)
5. Placebo: non-mining firm (utilities ETF XLU)
6. Leave-one-event-out stability
7. Mining-sector benchmark (XME) instead of S&P 500
8. Winsorized CARs (1/99 percentile)
9. Subsample: post-2000 only (better stock data coverage)
10. Exclude 2020 events (COVID volatility)

## Data Sources

- **Events**: WISE Chronology of Major Tailings Dam Failures (wise-uranium.org/mdaf.html)
- **Stock returns**: Yahoo Finance (via quantmod R package)
- **Market benchmarks**: S&P 500, XME (metals/mining ETF), XLU (utilities, placebo)
- **Firm characteristics**: Curated universe of ~50 major global mining firms + streaming/royalty companies
