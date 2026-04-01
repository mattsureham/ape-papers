# Research Plan: apep_1253

## Research Question

Does a permanent increase in SNAP benefits reduce labor supply, and if so, which industries lose workers? The October 2021 Thrifty Food Plan (TFP) revision permanently raised maximum SNAP benefits by 21% ($36/person/month). This paper exploits cross-county variation in pre-existing SNAP participation rates to identify industry-specific labor reallocation effects using the Quarterly Workforce Indicators (QWI).

## Identification Strategy

**Design:** Continuous-treatment DiD with county × quarter × industry panel.

**Specification:**
```
Y_{c,i,t} = α_c + γ_{i,t} + β × (SNAP_rate_c × Post_t) + X'_{c,t}δ + ε_{c,i,t}
```
where:
- Y = log employment (or hires, separations, earnings) in county c, industry i, quarter t
- SNAP_rate_c = pre-treatment (2019) SNAP household participation rate (continuous, predetermined)
- Post_t = 1[t ≥ 2021Q4]
- α_c = county FE, γ_{i,t} = industry × quarter FE
- Clustering: state level

**Key identification assumption:** Counties with higher vs. lower SNAP participation rates would have followed parallel employment trends absent the TFP revision. Testable with 12 pre-quarters (2019Q1–2021Q3).

**Treatment intensity:** SNAP participation rates range from <5% to >30% across US counties, creating strong cross-sectional variation in the per-capita benefit shock.

## Expected Effects and Mechanisms

**Income effect hypothesis:** Higher SNAP benefits raise non-labor income → reduce labor supply, especially in low-wage industries where SNAP recipients concentrate (food services NAICS 72, retail NAICS 44-45).

**Reallocation hypothesis:** Workers freed from subsistence-wage jobs may move to higher-paying sectors (healthcare NAICS 62, professional services NAICS 54) — a "benefit-induced upgrade."

**Null hypothesis:** Benefits are too small relative to wages to move labor supply at the county level.

**Expected signs:**
- Food services (72): β < 0 (employment decline in high-SNAP counties)
- Retail (44-45): β < 0
- Healthcare (62): β ≥ 0 (absorption or neutral)
- Manufacturing (31-33): β ≈ 0 (control sector — SNAP recipients underrepresented)

## Primary Specification

Industry-specific betas from interacted model:
```
Y_{c,i,t} = α_{c,i} + γ_{i,t} + Σ_j β_j × (SNAP_rate_c × Post_t × 1[i=j]) + ε_{c,i,t}
```

## Data Sources

1. **QWI sa/ns panel** (Azure): County × quarter × industry × age-group employment, hires, separations, earnings. ~150M rows, 2018–2023. Already on Azure Blob Storage.
   - Focus industries: 72 (food services), 44-45 (retail), 62 (healthcare), 56 (admin/waste), 31-33 (manufacturing), 54 (professional services), 52 (finance)
   - Focus age groups: A03 (25-34), A04 (35-44), A05 (45-54)

2. **SNAP participation rates** (USDA): County-level SNAP participation from USDA Food & Nutrition Service, using 2019 as the pre-determined treatment intensity.
   - Source: USDA SNAP Data Tables (https://www.fns.usda.gov/pd/supplemental-nutrition-assistance-program-snap)
   - Alternative: SAIPE poverty estimates as instrument/proxy

3. **County controls:** BLS QCEW for total employment trends, Census population, urbanicity classification.

## Fetch Strategy

1. Query QWI sa/ns from Azure for 7 NAICS sectors × 3 age groups × all counties × 2018Q1–2023Q4
2. Download SNAP county participation data from USDA
3. Merge on FIPS county code
4. Construct treatment variable: 2019 SNAP household participation rate

## Robustness

- Placebo test: 2019Q4 as false treatment date
- Exclude counties losing Emergency Allotments (EA) simultaneously
- Wild cluster bootstrap at state level
- Alternative treatment: SNAP per-capita benefit increase (continuous $)
- Leave-one-state-out jackknife
- Manufacturing sector as placebo outcome

## Concurrent Policy Threats

- **Enhanced unemployment expiration** (Sep 2021): Staggered by state — control with state × quarter FE
- **EA expiration** (varies by state, 2021–2023): Explicit robustness check excluding EA-affected periods
- **General COVID recovery**: Industry × quarter FE absorbs national recovery trends; identification is cross-county within-industry
