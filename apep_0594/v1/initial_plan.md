# Initial Research Plan: apep_0594

## Research Question

Did Spain's 2022 labor reform (RDL 32/2021) genuinely reduce labor market precarity, or did it merely relabel temporary contracts as "fijo discontinuo" (permanent-discontinuous) contracts? We exploit cross-regional variation in pre-reform temporary employment intensity to estimate the reform's causal effect on contract composition, employment levels, and job quality.

## Identification Strategy

**Bartik (shift-share) continuous-treatment DiD.** All 19 Spanish Autonomous Communities face the same national reform (March 30, 2022), but with differential exposure based on pre-reform temporary employment shares.

- **Treatment intensity:** Pre-reform (2021Q4) share of wage earners on temporary contracts in each region, which ranges from ~15% (Basque Country) to ~49% (Extremadura).
- **Timing:** Single national reform. TWFE is appropriate since timing is common across all units.
- **Key equation:**
  Y_{rt} = α_r + γ_t + β(Temp_Share_r × Post_t) + ε_{rt}
  where Temp_Share_r is the pre-reform temporary employment share in region r, and Post_t = 1{t ≥ 2022Q2}.

## Expected Effects and Mechanisms

**Primary hypothesis:** High-exposure regions experienced larger declines in temporary contract shares. The question is whether this reflects:
1. **Genuine improvement:** Permanent employment rises, total employment stable or growing, workers gain stability.
2. **Relabeling:** "Fijo discontinuo" contracts absorb former temporary workers without changing actual job duration or stability.
3. **Negative employment effect:** Rigid regulation destroys jobs, particularly in high-temporary sectors.

**Mechanism test (relabeling):** If the reform merely relabels, we should see:
- Fijo discontinuo contracts rise almost 1-for-1 with temporary declines
- No change in total employment or unemployment
- Seasonal employment patterns unchanged

**Theory predicts effects concentrate in:**
- Agriculture and construction (highest pre-reform temporary rates)
- Young workers (age < 30)
- Low-education workers

## Primary Specification

OLS regression with region and quarter fixed effects:

1. **Main outcome:** Temporary employment share
2. **Secondary outcomes:** Permanent employment share, total employment, fijo discontinuo share (where data permits)
3. **Treatment:** Pre-reform temporary share × Post indicator
4. **Fixed effects:** Region, Quarter
5. **Clustering:** Region level (19 clusters — will supplement with wild cluster bootstrap)

## Exposure Alignment

- **Who is treated:** All Spanish wage earners, but differentially by region and sector based on pre-reform temporary employment intensity
- **Primary estimand population:** Wage earners in high-temporary-share regions
- **Placebo/control population:** Regions with low pre-reform temporary shares (Basque Country, Navarra, Madrid)
- **Design:** Continuous-treatment DiD (not binary)

## Power Assessment

- **Pre-treatment periods:** 24 quarters (2016Q1 - 2021Q4)
- **Post-treatment periods:** 12+ quarters (2022Q1 - 2025Q1+)
- **Treated clusters:** 19 (all treated with varying intensity)
- **Variation in treatment:** SD of pre-reform temporary share across regions ≈ 8-10pp
- **Concern:** Only 19 clusters — wild cluster bootstrap and randomization inference essential

## Planned Robustness Checks

1. **Pre-trends:** Event study with region × quarter interactions (24 pre-periods)
2. **Wild cluster bootstrap:** Address small number of clusters (19)
3. **Randomization inference:** Permute treatment intensity across regions
4. **Leave-one-out:** Drop each region to check for outlier sensitivity
5. **Alternative treatment measures:** Use sector-level pre-reform temporary shares instead of region-level
6. **Placebo outcome:** Self-employment (should not be directly affected by the reform)
7. **Rambachan-Roth sensitivity:** Bound parallel trend violations

## Data Sources

1. **INE EPA Table 65328:** Wage earners by contract type, sex, and Autonomous Community (quarterly, 2016-2025)
2. **INE EPA Table 65133:** Employed by contract type, sex, and economic sector (quarterly, 2016-2025)
3. **INE DIRCE Table 306:** Firms by province and employee stratum (annual)
4. **Access:** Free API at servicios.ine.es — no authentication required

## Code Structure

- `00_packages.R` — Libraries and themes
- `01_fetch_data.R` — INE API data acquisition
- `02_clean_data.R` — Variable construction, treatment intensity
- `03_main_analysis.R` — Primary regressions and event study
- `04_robustness.R` — Wild bootstrap, RI, leave-one-out, placebos
- `05_figures.R` — All figures
- `06_tables.R` — All tables
