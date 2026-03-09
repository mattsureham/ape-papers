# Research Ideas

## Idea 1: Billions to the Village: Indonesia's Dana Desa and the Infrastructure-Health Nexus
**Policy:** Indonesia's Village Law No. 6/2014 mandated direct fiscal transfers (Dana Desa) from the central government to all ~75,753 rural Desa villages starting January 2015. Urban Kelurahan (~8,486 units) were explicitly excluded. Cumulative transfers exceeded $60B by 2024, with ~90% spent on infrastructure (roads, water, electricity, health posts). Allocation grew from IDR 20.7T ($1.5B) in FY2015 to IDR 60T ($4.3B) by FY2017.
**Outcome:** Infant mortality rate (DHS API: 237 records, 33 provinces, 8 waves 1987-2017), under-5 mortality, health facility delivery rates, childhood diarrhea prevalence, household electrification. Secondary: VIIRS nighttime lights for economic activity at village level.
**Identification:** Province-level continuous-treatment DiD using Desa share as treatment intensity (ranges from ~0% in DKI Jakarta to ~99% in Papua). 5 pre-treatment DHS waves (1987-2012) + 1 post-treatment (2017). Village-level binary DiD for VIIRS (75,753 Desa vs 8,486 Kelurahan). Callaway-Sant'Anna continuous treatment estimator.
**Why it's novel:** No top-journal study on Dana Desa. Existing work uses weak designs (2-wave cross-sections, no pre-trend testing). First to combine DHS multi-wave health panel with village-level nighttime lights. First cost-per-infant-life-saved calculation for Dana Desa.
**Feasibility check:** Confirmed: DHS API returns 237 IMR records for Indonesia at subnational level. VIIRS available on Google Earth Engine. Desa shares vary from 0-99% across provinces. 5+ pre-treatment waves for parallel trends.

## Idea 2: Can a Child Allowance Buy a Job? Poland's Family 500+ and the Local Fiscal Multiplier
**Policy:** Poland's Family 500+ program (April 2016) provided 500 PLN/month per child, costing ~2% of GDP annually. Extended in July 2019 to include first children. Geographic variation from baseline family composition creates a Bartik-style instrument.
**Outcome:** Business registrations, unemployment rate, marriages, births at gmina/powiat level from GUS BDL API. 4,198 gminas, 6+ pre-periods.
**Identification:** Bartik-style continuous treatment DiD using pre-program family composition × national transfer schedule. Two clean temporal shocks (2016, 2019). CS-DiD estimator.
**Why it's novel:** Existing literature focuses on individual labor supply; no study estimates local fiscal multiplier effects of the world's largest universal child allowance via geographic variation.
**Feasibility check:** GUS BDL API confirmed. 4,584 powiat-years or 50,376 gmina-years.

## Idea 3: Shorter Hours, More Babies? South Korea's 52-Hour Workweek and the Fertility Crisis
**Policy:** South Korea's staggered 52-hour workweek cap (2018: 300+ employees, 2020: 50-299, 2021: 5-49) created three clean treatment waves based on firm size thresholds.
**Outcome:** KLIPS panel (23,000 individuals, 11,670 households, 2015-2023), marriage rates, fertility. World Bank API for aggregate fertility.
**Identification:** Three-wave staggered DiD with multi-cutoff design enabling internal placebo tests across firm-size groups.
**Why it's novel:** No causal study linking 52-hour reform to marriage/fertility. Mechanism is theoretically ambiguous (more time for family vs. lower overtime income).
**Feasibility check:** KLIPS on Harvard Dataverse, tidyklips R package on CRAN. 3-8 years pre-treatment.
