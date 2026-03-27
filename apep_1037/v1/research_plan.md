# Research Plan: The Round-Trip Tax — Capital Gains Taxation and Stock Market Participation in Taiwan

## Research Question

Does taxing capital gains on securities affect stock market participation and the cost of equity, or only trading volume? Taiwan's CGT round-trip (introduction Jan 2013, repeal Nov 2015) provides the cleanest natural experiment: abrupt introduction into a market with no CGT for 24 years, then abrupt repeal 3 years later.

## Policy Background

- **Pre-2013:** No CGT on securities since 1989. Taiwan had been a CGT-free equity market for 24 years.
- **April 26, 2012:** Cabinet announces CGT proposal → immediate market reaction.
- **July 2012:** Legislature approves amended CGT bill. 15% rate on gains exceeding TWD 1 billion for individual investors. Institutional investors subject to different treatment.
- **January 1, 2013:** CGT takes effect.
- **November 17, 2015:** Full repeal enacted after sustained market backlash and 25% trading volume decline.
- **Post-2016:** Return to CGT-free regime.

## Identification Strategy

### Design 1: Panel Event Study (Round-Trip)
Event study around three key dates:
1. Cabinet announcement (April 26, 2012)
2. Implementation (January 1, 2013)
3. Repeal (November 17, 2015)

The round-trip provides a **symmetric falsification test**: effects that appear at introduction should reverse at repeal. Effects that don't reverse suggest confounds rather than tax causation.

### Design 2: Cross-Sectional DiD (Treatment Intensity)
- **High-treatment firms:** Higher pre-2012 retail (individual) investor ownership share → shareholders more exposed to CGT
- **Low-treatment firms:** Higher institutional investor ownership share → shareholders less directly affected
- Treatment intensity measured as of 2011 (pre-announcement) to avoid endogeneity
- Firm and quarter fixed effects absorb level differences and common shocks

### Design 3: Within-Firm Round-Trip Symmetry
For each firm, test whether the magnitude of the introduction effect equals the magnitude of the repeal effect (opposite sign). Asymmetry could indicate adjustment costs or hysteresis.

## Expected Effects and Mechanisms

1. **Trading volume:** Sharp decline at introduction, rebound at repeal (known in existing literature)
2. **Investor composition shift:** Retail investors exit, institutional share rises (the participation channel)
3. **Cost of equity proxies:** P/E ratios decline (higher required returns), dividend yields rise
4. **Valuation effects:** Market cap declines for high-retail-ownership firms
5. **Heterogeneity:** Small/mid-cap firms (more retail-dominated) should be more affected than blue chips

## Primary Specification

```
Y_{it} = α_i + γ_t + β₁(Post_2013 × RetailShare_i) + β₂(Post_Repeal × RetailShare_i) + ε_{it}
```

Where:
- Y_{it}: outcome for firm i in quarter t (turnover, P/E, institutional share, etc.)
- α_i: firm fixed effects
- γ_t: quarter fixed effects
- RetailShare_i: pre-2012 individual investor ownership share (continuous treatment)
- Post_2013: indicator for CGT period (2013Q1–2015Q3)
- Post_Repeal: indicator for post-repeal period (2015Q4+)

The key test: **β₁ < 0 and β₂ > 0** (effects reverse) for trading and participation outcomes.

## Data Sources and Fetch Strategy

### Primary: TWSE Open API
- **Daily stock trading data:** Volume, value, open/high/low/close for all listed stocks (2010–2018)
  - Endpoint: `https://www.twse.com.tw/exchangeReport/STOCK_DAY?response=json&date=YYYYMMDD&stockNo=XXXX`
- **Institutional investor flows:** Foreign, investment trust, dealer buy/sell per stock
  - Endpoint: `https://www.twse.com.tw/fund/T86?response=json&date=YYYYMMDD`
- **P/E ratios and dividend yields:** All stocks
  - Endpoint: `https://www.twse.com.tw/exchangeReport/BWIBBU_d?response=json&date=YYYYMMDD`
- **Margin trading:** Margin purchase/sale balances
  - Endpoint: `https://www.twse.com.tw/exchangeReport/MI_MARGN?response=json&date=YYYYMMDD`

### Sample Construction
- Universe: All TWSE-listed ordinary stocks (excluding ETFs, REITs, preferred shares)
- Period: 2010Q1–2018Q4 (8 pre-announcement quarters, 12 CGT quarters, 12+ post-repeal quarters)
- Aggregate daily data to quarterly firm-level panels
- ~900 firms × ~36 quarters ≈ 32,400 firm-quarter observations

### Treatment Variable
- Pre-2012 average institutional investor ownership share (from TWSE institutional flow data)
- Higher individual (retail) share = higher treatment intensity
- Measured at 2011 annual average to avoid endogeneity

## Key Methodological Concerns

1. **Common shocks:** Global financial conditions changed 2012–2016. Quarter FE absorb common trends. The round-trip design is the main defense — global shocks wouldn't reverse precisely at Taiwan's repeal date.
2. **Anticipation:** Market may have priced in CGT before January 2013. The April 2012 announcement date captures this.
3. **Composition changes:** Firms may delist or list during sample. Use balanced panel as robustness.
4. **TWSE vs OTC:** Only TWSE-listed firms. OTC (TPEx) firms as potential control group for triple-diff.

## Robustness Checks

1. Balanced panel (firms listed entire 2010–2018 period)
2. Placebo test: OTC/TPEx firms (not subject to same CGT rules initially)
3. Event-time dynamic specification (quarter-by-quarter coefficients)
4. Alternative treatment intensity measures (market cap quintiles, sector)
5. Excluding announcement period (Apr–Dec 2012)
6. Winsorizing outcomes at 1%/99%
