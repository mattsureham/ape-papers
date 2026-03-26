# Research Plan: apep_0988

## Research Question

Did Poland's phased Sunday trading ban (2018-2020) accelerate e-commerce displacement and small retailer exit, producing "creative destruction by decree"?

## Policy Background

Poland's Act on Restriction of Trade on Sundays (January 30, 2018) implemented a three-phase ban:
- **Pre-reform (2017):** All Sundays open for retail trade
- **Phase 1 (March 2018):** Two open Sundays per month (~50% reduction)
- **Phase 2 (January 2019):** One open Sunday per month (~75% reduction)
- **Phase 3 (January 2020):** Near-total ban (7 exempted Sundays/year, ~93% reduction)

E-commerce was unrestricted throughout — creating an asymmetric shock favoring online retail.

## Identification Strategy

**Continuous treatment DiD** at the powiat (county) level, N ≈ 380:
- **Cross-sectional variation:** Baseline (2017) retail employment share — powiats with higher retail dependence face larger effective treatment
- **Temporal variation:** Three discrete phase transitions
- **Specification:**
  Y_{it} = alpha_i + gamma_t + beta_1(RetailShare_i x Phase1_t) + beta_2(RetailShare_i x Phase2_t) + epsilon_{it}

This is a shift-share (Bartik-style) design:
- Shares = pre-reform retail employment share (cross-sectional)
- Shifts = policy intensity (temporal, nationally uniform)

**Main sample:** 2015Q1 - 2019Q4 (avoids COVID confound on Phase 3)

## Expected Effects and Mechanisms

1. **Employment reallocation:** Retail employment falls in high-retail-share powiats; possibly rises in logistics/warehousing
2. **Shop closures:** Small independent retailers exit disproportionately (cannot exploit exemptions)
3. **E-commerce substitution:** Online retail sales surge, especially in consumer goods
4. **Zabka loophole:** Chain convenience stores reclassified employees as franchisees to exploit the owner-operated exemption

Possible null: Workers simply shift to non-Sunday schedules, no net employment loss. This would be informative — regulation succeeded at its stated goal without displacement costs.

## Primary Specification

**Unit:** Powiat (county), N ≈ 380
**Time:** Quarterly, 2015Q1-2019Q4 (main) or 2015Q1-2021Q4 (extended with COVID controls)
**Treatment intensity:** RetailShare_i (continuous, 2017 baseline) x Phase_t (indicator)
**Outcome:** Trade-sector employment, unemployment rate, shop counts, retail sales
**Clustering:** Voivodeship level (16 clusters) — conservative, using wild cluster bootstrap for inference
**Placebos:** Non-retail sectors (manufacturing, construction) should show no effect

## Data Sources

1. **GUS BDL API** (Bank Danych Lokalnych — Poland's Local Data Bank):
   - Employment by NACE section at powiat level (monthly/quarterly)
   - Shop counts at powiat/gmina level (annual)
   - Retail sales (annual, voivodeship level)
   - Unemployment rates (powiat level, monthly)
   - Business registrations (powiat level)

2. **Eurostat** (robustness):
   - Cross-country retail employment trends (CZ, SK, DE as controls)

## Robustness Checks

1. Placebo sectors: manufacturing, construction employment (should not respond)
2. Cross-country comparison using Czech Republic, Slovakia (no Sunday ban) vs Poland
3. Wild cluster bootstrap for inference with 16 voivodeship clusters
4. Exclude border powiats (cross-border shopping spillovers)
5. Extended sample through 2021 with COVID controls (exploratory)
6. Alternative treatment intensity: shop density instead of retail employment share
