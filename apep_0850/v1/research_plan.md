# Research Plan: Cross-Border Workers and Minimum Wages

## Research Question

Does Geneva's CHF 23/hr minimum wage — the world's highest statutory floor, introduced November 2020 — change the sectoral composition of cross-border workers from France? Specifically, do high-bite sectors (hospitality, personal care, retail) experience differential reductions in cross-border worker flows relative to low-bite sectors (finance, pharma), and does this differ from other Swiss border cantons without minimum wages?

## Identification Strategy

**Triple-difference (DDD):**
- Dimension 1: Geneva (treated) vs. other border cantons (Vaud, Basel-Stadt, Schaffhausen — no cantonal minimum wage in this period)
- Dimension 2: High-bite sectors (hospitality ~35% below CHF 23/hr, personal care ~28%, retail ~22%) vs. low-bite sectors (finance ~3%, pharma ~1%)
- Dimension 3: Pre (Q3 2002 – Q2 2020) vs. post (Q4 2020 – Q4 2025)

**Primary specification:** Canton × NOGA-sector × quarter panel with canton-sector FE, sector-quarter FE, and canton-quarter FE. Treatment: Geneva × high-bite × post interaction.

**Event study:** Dynamic effects ±8 quarters around Q4 2020, testing parallel pre-trends in high-bite vs. low-bite sectors within Geneva relative to control cantons.

## Expected Effects and Mechanisms

**Mechanism:** Geneva's minimum wage raises the floor for cross-border workers in low-wage sectors. If labor supply from France is elastic (workers can commute to Vaud or stay in France), employers in high-bite sectors either:
1. Reduce hiring of low-skill cross-border workers (standard competitive model prediction)
2. Upgrade skill composition (hire fewer workers but higher-skill, or substitute French workers with Swiss residents)
3. Absorb the cost with minimal quantity adjustment (monopsony model prediction)

**Expected direction:** Under the competitive model, high-bite sectors in Geneva should see a relative decline in cross-border worker counts (or a slowdown in growth) post-November 2020, compared to the same sectors in control cantons. A null result would support monopsony interpretations in cross-border labor markets.

## Primary Specification

```
log(CBW_{cst}) = α_{cs} + δ_{sq} + γ_{cq} + β₁(Geneva_c × HighBite_s × Post_t) + ε_{cst}
```

Where:
- CBW = cross-border worker count
- c = canton, s = NOGA sector, q = quarter, t = time period
- α_{cs} = canton-sector fixed effects
- δ_{sq} = sector-quarter fixed effects (absorbs national sector trends)
- γ_{cq} = canton-quarter fixed effects (absorbs canton-specific shocks including COVID)
- β₁ = DDD coefficient of interest

Clustering: canton-sector level (conservative; also report wild cluster bootstrap at canton level given small number of cantons).

## Data Sources

### Primary: BFS Grenzgänger Statistics (GGS)
- Source: Swiss SDMX dissemination platform
- URL: `https://disseminate.stats.swiss/rest/v2/data/dataflow/CH1.GGS/DF_GGS_1?format=csvfile`
- Size: 523 MB, 11.5M rows
- Dimensions: 27 cantons × 86 NOGA sectors × 37 countries × 94 quarters (Q3 2002 – Q4 2025)
- Key variables: OBS_VALUE (cross-border worker count), CANTON_WORK, NOGA, CNTRY, TIME_PERIOD, SEX

### Secondary: BFS STATENT (Structural Business Statistics)
- Annual establishment and employment counts by canton and NOGA sector
- For normalizing CBW counts by total sector employment

### Sector bite classification
- From 2018 Swiss Wage Structure Survey (LSE) or inferred from pre-treatment CBW sector composition
- Sectors classified as high-bite if >15% of workers estimated below CHF 23/hr

## Robustness Checks

1. **Placebo canton:** Apply same design to Vaud as if treated in Q4 2020
2. **Placebo timing:** Test false treatment dates (Q4 2018, Q4 2019)
3. **Continuous bite:** Replace binary high/low-bite with continuous sector-level bite measure
4. **Country decomposition:** Test France-origin CBW separately from Italy/Germany-origin
5. **Ticino secondary test:** Ticino introduced CHF 19/hr minimum wage April 2021 — quasi-independent replication
6. **Leave-one-sector-out:** Ensure results not driven by a single large sector
7. **Wild cluster bootstrap:** Given small number of treated cantons (1 primary)

## COVID Confound Strategy

- Treatment onset (November 2020) coincides with COVID pandemic. Canton-quarter FE absorb all canton-level COVID shocks.
- The DDD within-canton comparison (high-bite vs. low-bite sectors within Geneva) differences out canton-wide COVID effects.
- Additional robustness: restrict pre-period to 2015-2019 (post-franc-shock, pre-COVID).

## Key Risk

The main threat is that COVID differentially affected high-bite sectors (hospitality, retail) in Geneva relative to control cantons. The canton-quarter FE absorb canton-level shocks but not canton × sector-specific COVID effects. The sector-quarter FE absorb national sector trends. The remaining concern is Geneva-specific × sector-specific COVID effects that coincide with the minimum wage timing. The Ticino replication (different timing, April 2021) partially addresses this.
