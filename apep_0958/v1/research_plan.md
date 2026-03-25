# Research Plan: When Green Courts Create Brown Politics

## Research Question

Did the Dutch Council of State's May 2019 PAS nitrogen ruling — which invalidated construction and farming permits near Natura 2000 sites — causally trigger both economic disruption (building permit collapse) and political realignment (the BBB populist party's rise)?

## Identification Strategy

**Continuous-treatment DiD.** Treatment intensity varies across municipalities based on pre-ruling exposure to Natura 2000 regulation:

- **Treatment intensity** = (share of municipal area within/near Natura 2000 sites) × (pre-2019 agricultural + construction employment share)
- **Event date:** May 29, 2019 (Raad van State ruling)
- **Unit:** Municipality × quarter (building permits) and municipality (BBB vote share)

**Key identifying assumption:** Municipalities with higher Natura 2000 proximity did not have differential pre-trends in building permits or political preferences before the ruling. Testable with 28 quarters of pre-data (2012Q1–2018Q4).

**Threats and mitigations:**
1. Endogenous Natura 2000 designation → sites designated in 1990s–2000s based on ecological criteria, not economic/political factors
2. COVID-19 confound → ruling is May 2019, COVID is March 2020; separate event windows
3. Pre-existing rural-urban political gradient → control for urbanization, agricultural employment, and pre-2019 party vote shares

## Expected Effects and Mechanisms

1. **Building permits (primary economic outcome):** Sharp decline in high-exposure municipalities post-ruling. The ruling froze ~18,000 permits immediately.
2. **BBB vote share (political outcome):** Higher BBB support in municipalities more exposed to the nitrogen ruling's economic disruption.
3. **Mechanism:** Economic anxiety from frozen permits/farm restrictions → demand for anti-regulation political representation → BBB captures this demand.

## Primary Specification

```
Y_{it} = α_i + γ_t + β × (Exposure_i × Post_t) + X_{it}'δ + ε_{it}
```

Where:
- Y_{it} = building permits per 1,000 residents in municipality i, quarter t
- Exposure_i = continuous treatment intensity (Natura 2000 area share × ag+construction employment share)
- Post_t = 1 after May 2019
- α_i, γ_t = municipality and quarter fixed effects
- X_{it} = time-varying controls

For political outcome (cross-section):
```
BBB_i = α + β × Exposure_i + X_i'δ + Province_p + ε_i
```

## Data Sources and Fetch Strategy

1. **CBS StatLine building permits** (table 83671NED): Municipality × quarter, 2012–2025. OData API, no auth.
2. **Kiesraad 2023 Provincial Elections:** Municipality-level results, all parties. CSV download.
3. **PDOK Natura 2000 shapefiles:** Spatial polygons for computing municipal proximity/overlap.
4. **CBS employment by sector:** Municipality-level agricultural and construction employment for treatment intensity construction.
5. **CBS population data:** For per-capita normalization.

## Robustness Checks

1. Pre-trend event study (quarterly dummies × exposure)
2. Placebo treatment dates (2016, 2017, 2018)
3. Leave-one-province-out
4. Alternative treatment intensity measures (binary high/low exposure)
5. Controlling for pre-2019 PVV/FvD vote shares (pre-existing populist support)
6. Donut specification excluding border municipalities of Natura 2000 sites
