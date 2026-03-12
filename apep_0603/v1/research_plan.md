# Research Plan: apep_0603

## Research Question

What is the local fiscal multiplier of unconditional cash transfers to families? Poland's Family 500+ program (2016) injected ~40 billion PLN annually (~2% of GDP) through monthly child payments. Because pre-program family composition varies dramatically across powiats (administrative districts), the per-capita fiscal injection differs by a factor of 2-3x across regions. We exploit this geographic variation in a continuous-treatment difference-in-differences to estimate the local economic multiplier.

## Identification Strategy

**Design: Bartik-style continuous-treatment DiD**

- **Treatment intensity:** Pre-program (2015) powiat-level share of households with 2+ children under 18 × national per-child transfer (500 PLN/month). Powiats with more multi-child families receive proportionally larger per-capita fiscal injections.
- **Timing:** Common treatment date (April 2016) with continuous geographic intensity — not staggered adoption.
- **Second shock:** July 2019 universalization (extending to first children regardless of income). Powiats with more single-child families above the income threshold become "newly treated."

**Specification:**

Y_it = α_i + γ_t + β × (Intensity_i × Post_t) + ε_it

where Intensity_i is the predicted per-capita transfer in 2015, and Post_t = 1(t ≥ 2016).

**Event study:**

Y_it = α_i + γ_t + Σ_k β_k × (Intensity_i × 1(t = k)) + ε_it

with k ∈ {2010, ..., 2015, 2017, ..., 2022} and 2015 as reference.

**Inference:** Cluster SEs at powiat level (382 clusters). Also report Conley spatial HAC SEs.

**Exposure Alignment:** The unit of analysis (powiat) is not the unit of treatment receipt (household). The 500+ transfers flow to individual families, but we measure outcomes at the district level. This is appropriate because the research question concerns the *local fiscal multiplier*—the aggregate economic effect of transfers landing in a geographic area—not the household-level spending response. The treatment intensity measure (pre-program birth rate) captures the per-capita density of transfer recipients in each powiat, which determines the aggregate fiscal injection per capita. The parallel trends assumption requires that high- and low-birth-rate powiats would have followed similar trajectories absent the program, not that individual households are comparable. Potential threats to this aggregate design include spatial spillovers (SUTVA violation across powiat borders) and within-powiat heterogeneity in how transfers translate to economic activity.

## Expected Effects and Mechanisms

- **Primary:** Higher transfer intensity → more business registrations, lower unemployment
- **MPC channel:** Effects should be larger in lower-income powiats (higher MPC)
- **Phase II comparison:** Universal expansion (2019) should show smaller per-PLN multiplier than targeted Phase I (adding higher-income families with lower MPC)
- **Sector channel:** Retail/services should respond more than manufacturing (transfers go to consumption)

## Primary Specification

- **Level:** 382 powiats × 13 years (2010-2022)
- **Treatment:** Continuous intensity based on 2015 family composition shares
- **Estimator:** TWFE with continuous treatment interaction (appropriate since timing is common, intensity is continuous)
- **Controls:** Powiat and year FE (baseline). Robustness: voivodeship × year FE
- **Clustering:** Powiat-level (382 clusters)

## Data Source and Fetch Strategy

**Primary source: GUS BDL API (Statistics Poland)**
- No API key required
- Confirmed working in smoke tests
- Variables:
  - Business registrations: var 60529 (gmina/powiat)
  - Unemployment: var 57436 (powiat)
  - Births: var 59 (gmina)
  - Marriages: var 58 (gmina)
  - Infant mortality: var 60569 (powiat)
  - Population: var 64428 (powiat)
  - Household composition: K3/G10 subject area (powiat)

**Fetch strategy:**
1. Query all 16 voivodeships' powiat-level data
2. Loop over years 2010-2022
3. Validate: no missing powiats, no implausible values
4. Save as CSV for R analysis

## Robustness Checks

1. Event study with pre-trend assessment (β_k for k < 2016 ≈ 0)
2. HonestDiD sensitivity analysis for parallel trends violations
3. Placebo test: "fake" treatment in 2013
4. Permutation inference: randomly reassign treatment intensity 1000×
5. Drop city-powiats (grodzkie) — urban areas may have different dynamics
6. Alternative treatment: share of rural population, share below poverty line
7. Voivodeship × year FE to absorb regional trends
8. Spatial first-difference to control for cross-border spillovers

## Outcome Measures

| Outcome | BDL Variable | Level | Interpretation |
|---------|-------------|-------|----------------|
| New business registrations per 10K | 60529 | powiat | Entrepreneurship / local demand |
| Registered unemployed | 57436 | powiat | Labor market slack |
| Live births | 59 | powiat | Fertility response (mechanism) |
| Marriages | 58 | powiat | Household formation |
| Infant mortality per 1000 | 60569 | powiat | Health / wellbeing |
