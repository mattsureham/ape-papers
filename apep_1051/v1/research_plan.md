# Research Plan: Seeing Conservation Undone — Satellite Evidence on Land-Use Transitions after CRP Contract Expirations

## Research Question

When agricultural conservation contracts expire, does the land return to crop production? The 2014 Farm Bill mandated a step-down of the Conservation Reserve Program (CRP) acreage cap from 32 million to 24 million acres, forcing approximately 8 million acres of contracts to expire without reenrollment opportunity between 2013 and 2018. This paper estimates the causal effect of CRP contract expirations on county-level cropland conversion using satellite-derived land-use data.

## Identification Strategy

**Continuous-treatment staggered DiD.** Treatment intensity is defined as the share of county cropland enrolled in CRP contracts expiring during 2014-2018, driven by the national cap reduction. Counties with more expiring contracts received a larger "dose" of conservation reversal.

- **Unit of observation:** County-year panel (~1,500 agricultural counties, 2006-2022)
- **Treatment variable:** CRP acres expiring / total county cropland (continuous, county-level)
- **Treatment timing:** Staggered 2014-2018 (contracts expired in waves as the cap stepped down)
- **Fixed effects:** County FE + state-by-year FE (absorbs state-level agricultural trends)
- **Clustering:** State level (conservative)

## Expected Effects and Mechanisms

**Primary hypothesis:** Counties with more CRP contract expirations experience increases in crop acreage (corn, soybeans, wheat) and decreases in grassland/idle acreage.

**Mechanisms:**
1. **Direct conversion:** Farmers return CRP land to crop production for commodity revenue
2. **Commodity price sensitivity:** Conversion rates should be higher when crop prices are elevated (interaction test)
3. **Soil quality sorting:** Higher-quality CRP land (lower EBI scores) converts first

**Expected sign:** Positive effect on crop acreage, negative on grassland. Effect magnitude depends on how many expired acres actually convert vs. remain idle voluntarily.

## Primary Specification

$$Y_{ct} = \alpha_c + \gamma_{st} + \beta \cdot \text{ExpiredShare}_c \times \text{Post}_t + \varepsilon_{ct}$$

where $Y_{ct}$ is crop acreage (or grassland acreage) in county $c$ in year $t$, $\alpha_c$ are county FEs, $\gamma_{st}$ are state-by-year FEs, and $\text{ExpiredShare}_c \times \text{Post}_t$ captures the dose-response to CRP expirations.

## Exposure Alignment

The treatment variable measures county-level CRP enrollment loss as a share of total cropland. This captures the policy's extensive margin: counties with more CRP contracts expiring face a larger supply of newly available agricultural land. The treated population consists of farmers in these counties who must decide how to use formerly contracted land. The outcome (crop acreage) is measured at the same county-year level as the treatment, ensuring alignment between the unit of policy exposure and the unit of observation. State-by-year FEs absorb state-level confounders (weather, commodity programs), while county FEs absorb time-invariant county characteristics.

## Robustness Checks

1. **Pre-trend test:** Event study 2006-2013 (all pre-treatment)
2. **Placebo treatment year:** Assign false reform in 2010
3. **Alternative outcomes:** Total crop acreage, specific crops (corn, soybeans, wheat)
4. **Callaway-Sant'Anna estimator:** To address staggered treatment heterogeneity
5. **Dose-response:** Quartiles of treatment intensity
6. **Sensitivity to state-year FEs:** Replace with year FE + state trends

## Data Sources and Fetch Strategy

### Treatment: CRP Enrollment Data
- **Source:** USDA Farm Service Agency (FSA) via NASS QuickStats API
- **Variables:** CRP enrolled acres by county and year
- **Key:** `USDA_NASS` API key (confirmed available)
- **Query:** Program = "CONSERVATION", Commodity = "CRP", Data Item = "CRP - ACRES ENROLLED", geographic level = county

### Outcome: Crop Acreage
- **Source:** USDA NASS QuickStats API
- **Variables:** Planted/harvested acres for corn, soybeans, wheat, hay; total cropland
- **Geographic level:** County-year panel
- **Years:** 2006-2022

### Validation: Satellite-Derived Land Use (CDL)
- **Source:** USDA NASS Cropland Data Layer via CropScape API
- **Variables:** County-level acreage by land-use category (row crops, grassland/pasture, idle)
- **Use:** Validation of NASS survey-based acreage with satellite-independent measurement
- **R package:** `CropScapeR`

### Supplementary: County Agricultural Characteristics
- **Source:** USDA Census of Agriculture (2007, 2012, 2017)
- **Variables:** Total cropland, farm count, average farm size, irrigated acres
- **Use:** Balance table, heterogeneity analysis
