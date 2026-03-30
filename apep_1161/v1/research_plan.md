# Research Plan: apep_1161

## The Compliance Upgrade: Low Emission Zones and the Hidden Safety Dividend from Fleet Renewal

### Research Question

Do low emission zones (LEZs) improve vehicle safety and maintenance quality by forcing accelerated fleet turnover? London's Ultra Low Emission Zone (ULEZ) and UK Clean Air Zone (CAZ) rollouts charged or banned older, non-compliant vehicles. The intended effect is cleaner air. The unintended effect — never studied — may be safer roads: newer replacement vehicles have better brakes, tires, and structural integrity. We call this the **compliance upgrade**: regulatory pressure for emissions compliance produces safety co-benefits through mandatory fleet renewal.

### Identification Strategy

**Staggered Difference-in-Differences** exploiting the phased spatial rollout of ULEZ across London postcode areas plus CAZ adoption in Birmingham and Bristol.

Treatment waves:
1. **Central London (Apr 2019):** EC, WC postcodes
2. **Inner London (Oct 2021):** E, N, NW, W, SE, SW postcodes
3. **Birmingham CAZ (Jun 2021):** B postcode
4. **Bristol CAZ (Nov 2022):** BS postcode
5. **Outer London (Aug 2023):** BR, CR, DA, EN, HA, IG, KT, RM, SM, TW, UB, WD postcodes

Control group: ~50+ postcode areas in England/Wales never subject to an LEZ.

**Built-in placebo:** Euro 4 petrol vehicles are ULEZ-compliant; Euro 4 diesel vehicles are not. Same vehicle age cohort, different treatment status. If the effect operates through fleet renewal (owners scrapping non-compliant diesel vehicles and buying newer ones), we should see MOT improvement for diesel but not petrol vehicles of the same vintage.

**Estimator:** Callaway-Sant'Anna (2021) with postcode-area as unit, year as time period, and treatment defined by the first ULEZ/CAZ wave affecting that postcode. Event-study plots for pre-trend validation.

### Expected Effects and Mechanisms

1. **Fleet renewal channel:** Non-compliant vehicles are scrapped or sold out of the zone → replaced by newer vehicles with lower failure rates. Prediction: MOT failure rates fall in treated postcodes, concentrated in diesel vehicles.
2. **Maintenance investment channel:** Owners of marginally non-compliant vehicles invest in maintenance to pass emissions tests, incidentally improving safety-relevant components. Prediction: dangerous defect rates fall even among continuing vehicles.
3. **Compositional shift:** The fleet in treated areas becomes newer on average. Prediction: average test mileage per vehicle-year falls (newer cars); average vehicle age at test falls.

### Primary Specification

$$Y_{pt} = \alpha_p + \gamma_t + \beta \cdot \text{Treated}_{pt} + X_{pt}'\delta + \varepsilon_{pt}$$

Where:
- $Y_{pt}$: MOT failure rate in postcode area $p$, year $t$
- $\alpha_p$: postcode-area fixed effects
- $\gamma_t$: year fixed effects
- $\text{Treated}_{pt}$: indicator for postcode area $p$ being in an active ULEZ/CAZ zone in year $t$
- $X_{pt}$: controls (fleet composition, average vehicle age)

Standard errors clustered at postcode-area level. Wild cluster bootstrap for robustness given ~70 clusters.

### Data Source and Fetch Strategy

**Primary data:** DVSA Anonymised MOT Test Data
- Source: `edh-dvsa-data-gov-uk-files-prod.s3.eu-west-1.amazonaws.com`
- Files: `dft_test_result_YYYY.zip` for years 2017-2024
- Each file contains ~20M+ test records
- Fields: test_result, test_mileage, vehicle_id, postcode_area (first 1-2 characters), fuel_type, make, model, first_use_date, test_date
- Separate failure item files record specific defects with severity

**Fetch strategy:**
1. Download annual ZIP files for 2017-2024 (8 years)
2. Extract and process in chunks (files are large, ~2-4GB each)
3. Aggregate to postcode-area × year × fuel-type level for main analysis
4. Construct: failure rate, dangerous defect rate, average vehicle age, average mileage
5. Merge with treatment timing based on postcode-area mapping to ULEZ/CAZ zones

### Robustness Checks
- Diesel vs petrol placebo (same-vintage vehicles, different compliance status)
- Event-study pre-trends (2017-2018 for Phase 1)
- Leave-one-out (exclude London entirely)
- Donut specification (exclude vehicles registered in boundary postcodes)
- Wild cluster bootstrap p-values
- Callaway-Sant'Anna heterogeneity-robust estimates
- Placebo outcome: non-safety MOT advisory items
