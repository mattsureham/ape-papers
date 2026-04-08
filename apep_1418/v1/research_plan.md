# Research Plan: Gas Windfalls and Local Development — Spatial Evidence from Bolivia's IDH Reform

## Research Question
Did Bolivia's 2005 IDH (Impuesto Directo a los Hidrocarburos) reform — which redistributed natural gas revenues to municipalities using a population-based formula with producing-department bonuses — improve local development outcomes? We exploit spatial proximity to gas fields as an instrument for per-capita transfer intensity.

## Identification Strategy
**Primary: Spatial IV (cross-sectional).** Distance from each municipality's centroid to the nearest operating gas field instruments for IDH per-capita receipts. The instrument is relevant because producing-department municipalities near gas fields receive both population-based IDH shares and additional royalty payments (2.7% at wellhead). The exclusion restriction holds because Bolivia's gas sector is capital-intensive with minimal local employment; we test for direct extraction channels.

**Secondary: Continuous DiD.** The 2005 IDH reform is a nationally simultaneous shock. We exploit cross-municipal variation in transfer intensity (determined by department and population rank) with municipality and year fixed effects.

## Expected Effects and Mechanisms
- **Positive:** Higher transfers → more infrastructure investment (water, electricity, roads), improved school enrollment, reduced poverty
- **Mechanism 1:** Direct spending on public goods (mandated post-2008 for health/education)
- **Mechanism 2:** Capacity absorption — municipalities with higher baseline capacity may convert transfers more effectively
- **Possible null:** Resource curse at subnational level — windfalls captured by local elites, spent on patronage

## Primary Specification
**Cross-sectional IV (2012 census, change from 2001):**
ΔY_m = α + β * IDH_percapita_m + X_m'γ + dept_FE + ε_m
instrumented by: distance_to_nearest_gasfield_m

**Panel DiD (annual, 2001-2019):**
Y_mt = α_m + δ_t + β * PostReform_t × TransferIntensity_m + X_mt'γ + ε_mt

## Data Sources
1. **World Bank API:** National poverty, GDP per capita, education indicators (context)
2. **UDAPE/INE Municipal Indicators:** UBN index, water/electricity access, enrollment (2001, 2012 censuses)
3. **MEFP/YPFB:** IDH transfer amounts by municipality (annual, post-2005)
4. **Global Energy Monitor:** Gas field coordinates (Sabalo, San Alberto, San Antonio, Margarita, Itau)
5. **INE Census:** Municipal population, demographic controls (2001, 2012)

**Fetch strategy:** World Bank API for national context. Construct municipal panel from publicly available census aggregates and published IDH transfer tables. Gas field coordinates from Global Energy Monitor.

## Key Risk
Municipal-level IDH transfer data and outcome data may not be available in structured API format — may need to construct from published government reports. If municipal data is inaccessible, the paper pivots to department-level analysis (9 departments) or resolves as failed.
