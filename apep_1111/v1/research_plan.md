# Research Plan: The Repricing Retreat — FEMA Risk Rating 2.0 and Residential Construction

## Research Question

Does actuarially fair flood insurance pricing redirect residential construction away from flood-prone areas? FEMA's Risk Rating 2.0 (RR2.0), phased in October 2021–April 2023, replaced 53-year-old zone-based pricing with property-level actuarial risk assessment. Counties where premiums rose sharply face a new cost signal; this paper tests whether construction responds.

## Identification Strategy

**Continuous-treatment Difference-in-Differences.** The policy is national (no untreated counties), so I exploit cross-county variation in the intensity of the premium shock. FEMA publishes county-level distributions of monthly premium changes in $10 bins for 3,167 counties. Treatment intensity = share of policies in county *i* that experienced premium increases > $20/month.

**Specification:**

$$Y_{it} = \alpha_i + \gamma_{st} + \beta \cdot (\text{Post}_t \times \text{PremiumShock}_i) + X'_{it}\delta + \varepsilon_{it}$$

where $Y_{it}$ is log building permits in county $i$, quarter $t$; $\alpha_i$ are county fixed effects; $\gamma_{st}$ are state × quarter fixed effects (absorbing state-level macro shocks); $\text{PremiumShock}_i$ is the ex ante treatment intensity; and $X'_{it}$ includes time-varying controls (unemployment rate, house price index).

**Key identifying assumption:** Absent RR2.0, trends in building permits would have been parallel across counties with different premium shock intensities. The test: pre-trend coefficients in event-study specification should be zero.

**Falsification:**
1. Commercial/non-residential building permits (which are not tied to NFIP residential insurance) should show no response.
2. Counties with negligible NFIP participation should show no response regardless of premium change.

## Expected Effects and Mechanisms

**Primary hypothesis:** Counties experiencing larger premium increases will see a reduction in new residential building permits. Mechanism: higher insurance costs raise the effective cost of owning property in flood-prone areas, reducing demand for new construction.

**Direction:** Negative $\beta$ — more premium shock → fewer permits.

**Magnitude prior:** Modest effects expected. Insurance costs are a small fraction of total housing costs (typically 1-3% of house value annually). But marginal projects (those just barely profitable) may be deterred.

**Alternative channels:**
- Information channel: RR2.0 reveals that a property is riskier than previously understood
- Credit channel: Lenders may require flood insurance, making financing harder
- Adaptation channel: Construction may shift to lower-risk locations within the same metro area

## Primary Specification

Event study with continuous treatment:

$$Y_{it} = \alpha_i + \gamma_{st} + \sum_{k \neq -1} \beta_k \cdot \mathbb{1}[t = k] \times \text{PremiumShock}_i + \varepsilon_{it}$$

where $k$ indexes quarters relative to RR2.0 implementation (October 2021 for new policies).

## Data Sources

1. **FEMA County-Level Premium Change Data** — Excel file with distribution of monthly premium changes in $10 bins for 3,167 counties. Direct download from FEMA. This provides the treatment intensity measure.

2. **Census Building Permits Survey** — County-level monthly residential building permits (1-unit, 2-unit, 3-4 unit, 5+ unit). Available from Census Bureau website. Long time series (2004–2025+).

3. **FEMA OpenFEMA NFIP Policies** — 72.6M policy records. For this V1, I'll use aggregated county-level policy counts from the API rather than processing the full Parquet file.

4. **Controls:** BLS LAUS (county unemployment), FHFA HPI (house price index), FEMA flood zone maps.

## Robustness Checks

1. Alternative treatment intensity measures (mean premium change, share > $10/month)
2. Dropping COVID-affected quarters (2020Q2-2021Q2)
3. Restricting to counties with substantial NFIP participation (> 100 policies)
4. Placebo: commercial permits
5. HonestDiD sensitivity analysis for parallel trends violations
6. Clustering at state level (conservative) vs. county level
