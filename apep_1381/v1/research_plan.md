# Research Plan: TRAIN Act Excise Shock and Philippine Leaf Tobacco Farming

## Research Question

How much did the Philippines' 2018 TRAIN Act — which raised cigarette excise taxes 67% over five years — reduce domestic leaf tobacco acreage through a supply-chain linkage?

## Context and Stakes

Existing TRAIN research focuses on health outcomes (reduced smoking) and revenue/distributional effects. **Zero published papers examine the upstream effect on tobacco farming**, which is a primary rural income source in the Ilocos tobacco belt. 

In low- and middle-income countries where tobacco is domestically grown, raising cigarette taxes may unintentionally shift harm from consumers to rural farmers. This finding matters for 20+ tobacco-growing LMICs (Zimbabwe, Malawi, Indonesia, Vietnam, India) considering excise reform.

## Identification Strategy

**Continuous-treatment difference-in-differences (DiD):**
- Comparator: Province tobacco dependence = (avg tobacco area 2013-2017) / (total cultivated area)
- Treatment: Post-TRAIN indicator (2018 onwards)
- Estimand: β = ATT for cross-province continuous treatment
- Event study: 8 pre-periods (2010-2017), 7 post-periods (2018-2024)

**Key assumption:** Conditional on province fixed effects and year fixed effects, the parallel trends assumption holds — provinces with pre-existing high tobacco dependence would have followed similar acreage trends as low-dependence provinces absent the tax shock.

## Mechanism

1. Excise tax ↑ (₱30→₱50 over 5 years)
2. Retail cigarette prices ↑ (~15-20% real)
3. Cigarette consumption ↓ (~3-7% elasticity in literature)
4. Manufacturer leaf procurement ↓ (PMFTC, JTI demand shifts)
5. Tobacco farmgate prices ↓
6. Farm reallocation away from tobacco

## Primary Specification

```
Acreage_{pt} = β₀ + β₁(TobaccoDep_p × Post2018_t) + γ_p + δ_t + ε_{pt}
```

Where:
- p = province (81 total)
- t = year (2010-2025)
- TobaccoDep_p = pre-TRAIN tobacco dependence (2013-2017 average)
- Post2018_t = indicator(t ≥ 2018)
- γ_p, δ_t = province and year fixed effects

**Expected effect:** β₁ < 0. A 10pp increase in baseline tobacco dependence → X% reduction in acreage post-2018.

## Data Sources

**Outcome data:** PSA PXWeb API (public, no registration required)
- Table 0092E4EAHM1.px: Non-Food and Industrial Crops area harvested by province (2010-2025)
- Table 0062E4EVCP1.px: Volume of production by province (2010-2025)
- Coverage: 106 geographic codes (all 81 provinces + regions)
- Crop codes: 15=Tobacco; 17=Virginia tobacco

**Preliminary data check (from idea manifest):**
- Ilocos Norte: -50% tobacco area (2015-2019)
- Ilocos Sur: -17%
- La Union: -24%
- Pangasinan, Isabela: near-flat (non-tobacco provinces)

**Policy timeline:**
- Signed: December 19, 2017
- Effective: January 1, 2018
- Escalation: ₱32.50 (2018) → ₱35 (2019) → ₱40 (2021) → ₱50 (2023), plus 4% annual escalation

## Robustness Checks

1. **Event study** — Leads/lags to verify pre-trends (8 leads, 7 lags)
2. **Placebo outcomes** — Non-tobacco crop acreage as within-province falsification test
3. **Heterogeneity by exposure** — Split high-exposure (Ilocos, La Union) vs. low-exposure provinces
4. **Mechanism test** — Check whether provinces with higher pre-TRAIN cigarette consumption saw larger declines
5. **Alternative DoD specification** — Compare 2010-2017 (pre) vs. 2018-2024 (post) using OLS

## Sample Size

- **Panel structure:** 81 provinces × 16 years = 1,296 province-year observations
- **Treated units (high-exposure):** 11 provinces with meaningful tobacco production (>200 hectares baseline)
- **Pre-treatment period:** 2010-2017 (8 years)
- **Post-treatment period:** 2018-2024 (7 years)

## Deliverables

1. Clean dataset: province × year × crop × acreage/production
2. Event-study plot (leads/lags)
3. Main DiD table (pooled + heterogeneous effects by exposure)
4. Placebo test table (non-tobacco crops)
5. Mechanism table (if cigarette consumption data available)
6. Lessons on supply-chain effects of excise policy in LMICs
