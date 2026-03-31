# Research Plan: Does Cheaper Transit Unlock Jobs?

## Research Question
Does Germany's Deutschlandticket (EUR 49/month flat-rate transit pass, May 2023) — which replaced wildly varying local transit prices (EUR 62–130/month) — improve local labor market outcomes? We test whether districts with larger effective price reductions experienced greater employment gains, exploiting the pre-existing cross-regional variation in Verkehrsverbund pricing as a source of treatment-intensity variation.

## Identification Strategy
**Treatment-intensity DiD.** The Deutschlandticket set a uniform EUR 49/month price across all German transit networks. Because pre-reform local monthly pass prices ranged from EUR 62 (Dresden) to EUR 130 (Cologne), the effective subsidy varied dramatically across regions. We construct treatment intensity as:

$$\text{Subsidy}_k = \max(0, \text{PrePrice}_k - 49)$$

mapped to Kreise via Verkehrsverbund boundaries.

**Key identification assumptions:**
1. Pre-reform price differences are predetermined (set by historical Verkehrsverbund pricing decisions, not by employment trends)
2. Absent the reform, high-price and low-price regions would have followed parallel employment trends
3. We verify (2) with 5+ years of pre-treatment data (Jan 2018 – April 2023)

**Dose validation:**
- EUR 9 ticket (June–August 2022): short, large subsidy → expect temporary spike
- Deutschlandticket (May 2023): permanent → expect sustained effect
- Price increase to EUR 58 (Jan 2025): partial reversal → expect partial attenuation

## Expected Effects and Mechanisms
**Primary hypothesis:** Cheaper transit widens job search radius → better matching → higher employment, especially in peripheral districts with high pre-reform prices.

**Heterogeneity predictions:**
- Stronger effects in districts with low car ownership / high transit dependency
- Stronger effects for commuter-heavy industries (services) vs. local industries (agriculture placebo)
- Stronger in districts farther from urban cores (where the price cut matters most for commuting)

**Effect direction:** We expect positive employment effects in high-subsidy districts. A well-powered null would suggest transit cost is not the binding constraint on labor market participation — housing, skills, or job availability matter more.

## Primary Specification
```
Y_{kt} = α_k + α_t + β × (Subsidy_k × Post_t) + X_{kt}γ + ε_{kt}
```
Where:
- Y_{kt}: unemployment rate or employment count in Kreis k, month t
- α_k: Kreis fixed effects
- α_t: month fixed effects
- Subsidy_k: continuous treatment intensity (pre-reform price – 49)
- Post_t: indicator for May 2023 onwards
- X_{kt}: time-varying controls (population, GDP)

Clustering: at the Verkehrsverbund level (the level of treatment assignment). ~25-30 clusters.

## Data Sources

### 1. Eurostat Regional Unemployment (lfst_r_lfu3rt)
- NUTS2 quarterly unemployment rates for German regions
- 2005–2024, ~38 NUTS2 regions × 80 quarters

### 2. Eurostat Employment by NUTS2 (lfst_r_lfe2emprt)
- Employment rates by NUTS2 region
- 2005–2024

### 3. Eurostat Rail Passenger Statistics (rail_pa_quartal)
- Quarterly rail passenger-km for Germany
- First-stage evidence: did ridership increase?

### 4. Treatment Intensity Construction
- Pre-reform Verkehrsverbund monthly pass prices from official sources
- Map Verkehrsverbünde to NUTS2 regions

### Data Fetch Strategy
1. Pull all three Eurostat datasets via the `eurostat` R package
2. Construct treatment intensity from published Verkehrsverbund price data
3. Merge on NUTS2 region codes

## Robustness
1. Event study with leads and lags
2. Agriculture employment as placebo
3. EUR 9 ticket as dose validation
4. Leave-one-region-out jackknife
5. Wild cluster bootstrap (few clusters)
