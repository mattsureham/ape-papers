# Research Plan: The Frozen Threshold Trap — How the LISA Property Cap Reshapes First-Time Buyer Markets

## Research Question

Does the Lifetime ISA's frozen £450,000 property price cap reduce first-time buyer transaction volumes in Local Authorities where median house prices cross the threshold? As nominal house prices grow while the cap stays fixed, the LISA subsidy becomes increasingly inaccessible — do affected areas see fewer FTB purchases, compositional shifts toward cheaper property types, or price bunching below the cap?

## Policy Background

The Lifetime ISA (LISA), introduced April 2017, provides a 25% government bonus (up to £1,000/year on £4,000 savings) for first-time buyers purchasing property costing £450,000 or less. At £450,001, the buyer loses the entire accumulated bonus AND pays a 6.25% early withdrawal penalty. The cap was set in 2017 and has never been uprated despite 28% cumulative house price growth nationwide. By 2023, 57 of 331 English/Welsh LAs had median house prices above £450K, up from 26 at LISA's introduction.

## Identification Strategy

**Staggered DiD:** Treatment = LA's median house price first crosses £450K. 57 treated LAs with staggered crossing times (2010–2023), ~200 never-treated controls remaining below £450K throughout. Use Callaway and Sant'Anna (2021) heterogeneity-robust estimator for group-time ATTs.

**Triple-difference (robustness):** High-FTB-share areas × post-LISA (Apr 2017) × LA-median-above-£450K. The third difference exploits that LISA eligibility only matters for FTBs, not existing homeowners.

**Key threats:**
1. Price growth endogeneity — addressed by using pre-LISA (pre-2017) price trends in event study; parallel trends test
2. Compositional change in housing stock — addressed by property-type fixed effects and separate analysis by type
3. Other policies affecting FTBs (SDLT relief, Help to Buy equity loan ending) — addressed by UK-wide controls and timing controls

## Expected Effects and Mechanisms

1. **Volume effect:** FTB purchases decline in LAs crossing £450K as LISA subsidy becomes inaccessible
2. **Compositional shift:** Buyers substitute toward flats/terraces (cheaper) from semi-detached/detached
3. **Price bunching:** Transactions cluster just below £450K (testable with density discontinuity)
4. **Sorting:** FTBs displaced from expensive LAs into neighboring cheaper ones (spatial spillovers)

## Primary Specification

```
Y_{lt} = α_l + α_t + β · Above450K_{lt} + X_{lt}γ + ε_{lt}
```

Where l = LA, t = quarter, Y = FTB-proxy transaction count or property-type share, Above450K_{lt} = 1 when LA l's median price exceeds £450K at time t.

CS-DiD with group-time ATTs aggregated to dynamic event-study estimates.

## Data Sources and Fetch Strategy

1. **HM Land Registry Price Paid Data** — Download annual CSVs (2010–2024), link postcodes to LAs via ONS NSPL lookup. Count transactions, compute price distributions, identify bunching.
2. **ONS House Price Statistics for Small Areas (HPSSA)** — 331 LA quarterly median prices to define treatment timing (when median crosses £450K).
3. **HMRC LISA Statistics** — Monthly house purchase withdrawal counts and values (aggregate, for descriptive context).
4. **ONS NSPL** — Postcode-to-LA mapping for Land Registry PPD linkage.

All data are public, no API keys required for core sources.
