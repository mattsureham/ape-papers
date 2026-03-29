# Research Plan: The Despair Dividend — Does Crop Insurance Save Lives?

## Research Question
Does federal crop insurance function as "despair insurance" by stabilizing agricultural income and reducing deaths of despair in rural America? When weather-driven crop losses hit farming communities, do federal indemnity payments buffer the income shock enough to prevent drug overdose deaths?

## Identification Strategy

### Primary: IV/2SLS (County-Year Panel, 2003–2021)
- **First stage:** Growing-season Palmer Drought Severity Index (PDSI) → crop insurance indemnity payments per capita
- **Second stage:** Predicted indemnity per capita → drug overdose death rate
- **Exclusion restriction:** Drought affects overdose deaths only through agricultural income channels (crop losses → economic hardship → despair). Defended by: (1) placebo on non-agricultural counties (no first stage), (2) placebo on non-despair deaths (cancer, heart disease should not respond), (3) controlling for temperature-related mortality directly
- **Clustering:** State level (accounts for spatial correlation in weather and policy)

### Secondary: Insurance Buffer Triple-Difference
- **Dimension 1:** Drought shock (high vs low PDSI severity)
- **Dimension 2:** Time (pre vs post drought year)
- **Dimension 3:** Crop insurance penetration (high vs low county-level insurance coverage)
- **Hypothesis:** High-insurance counties should show smaller death rate increases after drought vs low-insurance counties

## Expected Effects and Mechanisms
- **Drought → crop loss → income shock → deaths of despair** (income stabilization channel)
- Expected: Negative coefficient on indemnity payments (more insurance → fewer deaths)
- Magnitude: Moderate effect expected — income is one channel among many for despair deaths
- The "despair insurance" mechanism: crop insurance designed for agricultural risk inadvertently stabilizes household economic security, reducing the income volatility that triggers substance abuse

## Primary Specification
```
OD_rate_{ct} = α + β * Indemnity_hat_{ct} + X'_{ct}γ + μ_c + δ_t + ε_{ct}

First stage: Indemnity_{ct} = π + θ * PDSI_{ct} + X'_{ct}φ + μ_c + δ_t + v_{ct}
```
Where:
- OD_rate_{ct}: Model-based drug overdose death rate per 100K in county c, year t
- Indemnity_{ct}: USDA RMA crop insurance indemnity per capita
- PDSI_{ct}: Growing-season (April–September) average PDSI from NOAA climate division mapped to county
- X_{ct}: Controls (population, urban/rural classification, unemployment rate)
- μ_c, δ_t: County and year fixed effects

## Data Sources and Fetch Strategy

### 1. NCHS Model-Based Drug Overdose Death Rates
- **Source:** CDC WONDER / data.cdc.gov (dataset rpvx-m2md)
- **Coverage:** 3,136 counties × 19 years (2003–2021), 59,584 rows
- **Key advantage:** Bayesian hierarchical model estimates solve CDC suppression for small rural counties
- **Variables:** FIPS, year, population, model-based death rate, SD, CI, urban/rural code

### 2. USDA RMA Crop Insurance Summary of Business
- **Source:** USDA Risk Management Agency (rma.usda.gov)
- **Coverage:** County-year indemnity payments, premiums, subsidies, policies
- **Variables:** State/county FIPS, year, indemnity ($), premium ($), subsidy ($), net acres, policies earning premium

### 3. NOAA Palmer Drought Severity Index
- **Source:** NOAA National Centers for Environmental Information
- **Coverage:** 344 climate divisions, monthly, 1895–present
- **Variables:** Division code, year-month, PDSI value
- **Mapping:** Climate division → county using NOAA crosswalk

### 4. BLS Local Area Unemployment Statistics (LAUS)
- **Source:** Bureau of Labor Statistics
- **Coverage:** County-year unemployment rates
- **Variables:** FIPS, year, unemployment rate, labor force

## Key Risks
1. **Exclusion restriction:** Drought may affect deaths through channels other than agricultural income (heat stress, mental health from environmental degradation). Mitigated by: non-agricultural county placebo, non-despair death placebo, controlling for temperature
2. **First-stage strength:** PDSI must strongly predict indemnity payments. Prior work and smoke test suggest this holds (2012 drought: $17.45B vs $4.25B baseline)
3. **NCHS model-based estimates:** These are modeled, not observed — may smooth variation. But this is a feature (solves suppression) not a bug for our purposes
