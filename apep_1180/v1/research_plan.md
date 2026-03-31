# Research Plan: Breaking the Language Barrier — Korea's Mandatory English Disclosure and Stock Market Liquidity

## Research Question

Does mandatory English-language financial disclosure reduce information frictions in capital markets? Korea's Financial Services Commission (FSC) mandated English disclosure for large KOSPI firms (total assets ≥ KRW 10 trillion, ~111 firms) starting January 2024, with phased expansion. This paper estimates the causal effect of English disclosure on stock market liquidity, using the mandate as a natural experiment.

## Why It Matters

The "Korea discount" — Korean firms trading at persistently lower valuations than global peers — is one of the most discussed puzzles in Asian finance. Language barriers in financial disclosure are a candidate explanation: if foreign investors cannot read Korean-only filings, they face higher information costs, reducing demand and liquidity. A mandatory disclosure mandate cleanly tests whether language is a binding friction, without the selection bias contaminating studies of voluntary English adoption.

## Identification Strategy

### Primary: Event Study DiD

Compare Phase 1 firms (mandated, assets ≥ KRW 10T) to similar KOSPI firms not yet mandated, around January 2024. Firm and week fixed effects absorb time-invariant firm characteristics and common shocks (including the November 2023 abolition of foreign investor registration, which affects all firms equally).

**Specification:**
Y_{it} = α_i + δ_t + β · Post_t × Treated_i + ε_{it}

where Y is the Amihud illiquidity ratio (primary) or log turnover (secondary), Post = 1 after January 2024, Treated = 1 for Phase 1 firms.

**Event study:** Dynamic DiD with leads and lags (weekly or monthly) to test pre-trends.

### Secondary: RDD at Asset Threshold

Sharp RD at the KRW 10 trillion total asset cutoff. Firms just above must disclose in English; firms just below do not yet. Use rdrobust with MSE-optimal bandwidth.

**Running variable:** Total assets (most recent fiscal year before mandate).

## Expected Effects

If language is a binding information friction:
- Amihud illiquidity should **decrease** for treated firms (more liquid)
- Trading turnover should **increase**
- Effects concentrated among firms with higher pre-treatment foreign ownership (stronger foreign investor demand for English filings)

If language is NOT the binding friction:
- Null effects on liquidity — suggesting the Korea discount is driven by governance, legal protections, or other factors

## Data Sources

1. **Yahoo Finance** — Daily OHLCV for all KOSPI stocks (suffix .KS). No API key required. ~800+ firms × 500+ trading days.
2. **DART Open API** (engopendart.fss.or.kr) — Firm financial statements (total assets for treatment assignment), filing dates, corporate fundamentals. Open API with key from dart.fss.or.kr.
3. **KRX (Korea Exchange)** — Official KOSPI firm list for universe definition.

## Primary Specification

Weekly Amihud illiquidity ratio:
Amihud_iw = (1/D_w) Σ_d |r_{id}| / Volume_{id}

DiD with firm and week FE, clustered at the firm level.

## Robustness Plans

1. Alternative outcome: log daily turnover
2. Placebo: pre-period "treatment" at earlier dates
3. Donut RD: exclude firms very close to the KRW 10T threshold
4. Matching: CEM or propensity score matching on pre-treatment characteristics (size, sector, foreign ownership)
5. Triple-difference: Treated × Post × HighForeignOwnership to isolate the foreign-investor channel

## Data Fetch Strategy

1. **Python (01_fetch_data):** Use `yfinance` to download daily price/volume for all KOSPI tickers. Use requests to query DART Open API for financial statements.
2. **R (analysis):** All econometric analysis in R using `fixest`, `rdrobust`.
