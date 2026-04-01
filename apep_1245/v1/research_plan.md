# Research Plan: The Price of Silence

## Research Question

Does South Korea's 17-month complete short-selling ban (November 2023 – March 2025) protect retail investors or harm them through induced overpricing? The symmetric design — ban imposition followed by full reversal — provides an unusually clean test of short-selling restrictions' welfare consequences.

## Identification Strategy

**Cross-sectional event study with continuous treatment intensity.**

Treatment intensity = pre-ban firm characteristics that predict short-selling demand (small-cap premium, high-volatility, high retail ownership). The symmetric design provides two identifying events:

1. **Ban imposition** (November 6, 2023): Stocks with characteristics associated with high short interest should show larger positive abnormal returns (short squeeze) and subsequent overpricing.
2. **Ban removal** (March 31, 2025): Same stocks should show larger negative correction as shorts re-enter.

**Key assumptions:**
- Sunday-evening announcement = no anticipation for ban imposition
- Cross-sectional variation in firm characteristics is predetermined
- Common trends in returns across characteristic bins absent the ban

**Threats:**
- Concurrent market events absorbed by market-model residuals
- Selection into firm characteristics — use predetermined (pre-ban) measures
- Global market conditions — benchmark against non-Korean indices

## Expected Effects and Mechanisms

1. **Price efficiency decline**: Higher variance ratios, greater autocorrelation during ban
2. **Overpricing**: Stocks with high short-selling demand should drift up during ban, correct sharply after lift
3. **Retail harm**: If retail investors are net buyers of overpriced stocks during the ban, they bear losses when ban lifts

**Mechanism naming: "The Retail Protection Paradox"** — a ban justified as retail protection that systematically transfers wealth from retail to informed investors.

## Primary Specification

```
CAR_i = α + β × HighShortDemand_i + γ × X_i + ε_i
```

Where:
- CAR_i = cumulative abnormal return around ban imposition/removal
- HighShortDemand_i = pre-ban indicator/continuous measure of short-selling demand
- X_i = controls (sector, size, pre-ban volatility)

Event windows: [−1, +1], [−1, +5], [−1, +10] around each event.

## Data Source and Fetch Strategy

1. **Stock universe**: KOSPI and KOSDAQ constituents — use `yfinance` Python library to download daily OHLCV
2. **Stock list**: Scrape from KRX (Korea Exchange) or use a curated list of major index constituents
3. **Benchmark**: KOSPI index for market model
4. **Pre-ban characteristics**: Computed from pre-ban price data (market cap, volatility, turnover)
5. **Retail trading**: KRX investor-type data if accessible; otherwise use turnover as proxy

**Sample period**: January 2023 – present (pre-ban + ban + post-ban)
**Target sample**: 200+ stocks from KOSPI with sufficient liquidity

## Key Risk

Korean stock ticker enumeration and data quality from Yahoo Finance. Mitigation: start with KOSPI 200 index constituents which have the best coverage.
