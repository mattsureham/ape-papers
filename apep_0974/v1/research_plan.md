# Research Plan: When the SNAP Cliff Hits the Emergency Room

## Research Question
Does the expiration of SNAP Emergency Allotments (EA) shift Medicaid utilization from primary care to emergency departments? If so, does this demand shock affect ED provider supply and workload?

## Identification Strategy
**Callaway-Sant'Anna (2021) staggered DiD.** 18 states ended SNAP EA between April 2021 and January 2023; 32 states + DC retained EA through February 2023 (serving as never-treated or late-treated controls). Treatment is defined at the state-month level based on the first month a state's EA expires.

**Key threats and mitigation:**
1. Non-random EA timing (Republican governors ended early) — state FE absorb time-invariant differences; event-study pre-trends test parallel trends
2. COVID recovery confound — restrict early-treated analysis to states ending EA in 2021 (pre-Omicron); include state-specific linear time trends as robustness
3. Medicaid unwinding (April 2023+) — creates confound for late-ending states; focus on clean treatment window (April 2021–January 2023)

## Expected Effects and Mechanisms
SNAP EA provided $95–$250/month in additional food benefits. Expiration → food insecurity → dietary degradation → acute episodes (hypoglycemia, hyperglycemia, malnutrition-related conditions) → ED presentations. Simultaneously, fewer resources → missed primary care appointments → less preventive management → more acute episodes.

**Expected direction:** ED claims increase, primary care claims decrease (or stagnate), acuity ratio (ED share) increases in treated states post-EA expiration.

## Primary Specification
Y_{st} = α_s + α_t + β * EA_Expired_{st} + ε_{st}

Where:
- Y_{st}: log ED claims, log PC claims, or ED/(ED+PC) ratio at state-month level
- α_s: state fixed effects
- α_t: calendar month fixed effects
- EA_Expired_{st}: indicator = 1 after state s ends EA
- Clustering: state level (51 clusters)

## Data Sources
1. **T-MSIS** (Azure: `raw/medicaid/tmsis.parquet`): 227M rows, Jan 2018–Dec 2024. HCPCS codes for ED (99281-99285) and primary care (99213-99215). Aggregate by state-month using NPI→state mapping.
2. **NPPES**: NPI→state geocoding for billing providers. Download bulk NPPES file or query API.
3. **SNAP EA dates**: USDA FNS published state-by-state EA expiration schedule. Well-documented.
4. **SNAP participation**: USDA FNS state-monthly SNAP participation data for dosage/heterogeneity.

## Fetch Strategy
1. Query T-MSIS via DuckDB from Azure (out-of-core, 8GB RAM constraint)
2. Download NPPES bulk data for NPI→state mapping
3. Construct SNAP EA treatment dates from USDA documentation
4. Merge and aggregate to state-month panel
