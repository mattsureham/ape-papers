# Research Plan: Frictionless Highways

## Research Question

Did India's February 2021 FASTag electronic toll mandate—which eliminated cash collection at 700+ national highway toll plazas overnight—increase traffic throughput and generate measurable economic spillovers in surrounding areas?

## Policy Background

On February 16, 2021, NHAI made FASTag (RFID-based electronic toll collection) mandatory at all national highway toll plazas. Pre-mandate, only ~34% of transactions used FASTag; post-mandate, adoption jumped to ~96%. Cash queues of 20-45 minutes were replaced by <10-second RFID reads. This is one of the largest simultaneous friction-reduction interventions in transport infrastructure.

## Identification Strategy

### Design 1: Plaza-Level Event Study (Direct Throughput Effect)
- **Unit**: 718 toll plazas
- **Outcome**: Daily traffic (PCU/day)
- **Treatment**: FASTag mandate (Feb 16, 2021)
- **Variation**: Treatment intensity = pre-mandate traffic volume (higher-traffic plazas had more congestion to relieve)
- **Data**: GitHub repo geohacker/toll-plazas-india (47 snapshots, Jun 2020 - Mar 2022)

### Design 2: District-Level DiD (Economic Spillovers)
- **Unit**: ~740 Indian districts
- **Outcome**: Annual mean nighttime lights (VIIRS Black Marble, 2015-2023) OR RBI district banking statistics
- **Treatment intensity**: Total daily plaza traffic (PCU) per district
- **Controls**: District + year FE, state × year FE, pre-mandate district characteristics
- **Data**: VIIRS via blackmarbler R package + GADM district boundaries

### Threats to Identification
1. **COVID recovery confound**: State × year FE absorb state-level recovery trends; within-state variation in plaza density provides identification
2. **Highway proximity**: Treatment intensity is traffic *through plazas*, not distance to highways. All highway-adjacent districts serve as controls if they lack plazas.
3. **Pre-trends**: 9 years of pre-treatment nightlights data (2012-2020); 8 months of pre-mandate traffic data (Jun 2020 - Jan 2021)
4. **Simultaneous mandate**: No staggering, but continuous treatment intensity (plaza traffic/district) provides a dose-response gradient

## Expected Effects
- **Traffic throughput**: 10-25% increase in effective daily vehicles (reduced queuing allows more throughput)
- **Nightlights/economic activity**: Small positive (SDE ~0.02-0.08) in high-treatment-intensity districts, concentrated near plazas
- **Distance decay**: Effects should be strongest within 5km of plazas, decay by 20km

## Primary Specification

```
Y_{dt} = α + β × (TreatmentIntensity_d × Post_t) + γ_d + δ_t + ε_{dt}
```

Where:
- Y_{dt} = mean nightlights (or log bank credit) in district d, year t
- TreatmentIntensity_d = total daily PCU through plazas in district d (standardized)
- Post_t = 1(year ≥ 2021)
- γ_d, δ_t = district and year fixed effects
- Cluster: state level

## Data Sources
1. **Toll plazas**: geohacker/toll-plazas-india (718 plazas, lat/lon, daily traffic, revenue)
2. **Nightlights**: NASA VIIRS Black Marble VNP46A4 via blackmarbler R package
3. **District boundaries**: GADM India level 2
4. **Fallback outcomes**: RBI DBIE district banking statistics (credit, deposits)
