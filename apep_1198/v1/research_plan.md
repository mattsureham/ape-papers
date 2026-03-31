# Research Plan: apep_1198

## Research Question
Did the UK Feed-in Tariff's average-rate tariff bands create hidden notches at capacity thresholds that distorted residential solar PV system sizing?

## Identification Strategy
The UK FIT (2010-2019) assigned a single generation tariff rate to the entire installation based on total Declared Net Capacity (DNC). Crossing a capacity threshold (4 kW, 10 kW, 50 kW) changed the rate on ALL kWh generated — creating a revenue cliff (hidden notch) even though the tariff schedule appears graduated.

**Main design:** The January 2016 FIT reform merged the ≤4 kW and 4-10 kW tariff bands into a single 0-10 kW band at identical rates. This eliminated the 4 kW threshold while leaving the 10 kW and 50 kW thresholds unchanged.

**Prediction:** Bunching at 4 kW DNC should collapse after February 2016 (threshold eliminated), while bunching at 10 kW DNC should persist (threshold unchanged). The temporal difference-in-bunching at 4 kW versus 10 kW around the 2016 reform identifies the policy-induced component of bunching.

## Expected Effects
- Massive bunching below 4.0 kW during the FIT bands period (2010-2015)
- Sharp collapse of bunching after the February 2016 band merger
- Residual round-number/engineering bunching at 4.0 kW post-reform (not policy-driven)
- Persistent bunching at 10 kW throughout (threshold unchanged)

## Primary Specification
Kleven-Waseem bunching estimator applied to DNC (0.1 kW bins). Polynomial degree 7, with specification family across degrees 6-8 and multiple exclusion windows. Bootstrap inference (500 replications).

## Data Source
Ofgem FIT Installation Report (30 September 2025 release): 860,470 solar PV installations with DNC, commissioning date, tariff code, postcode, LSOA, installation type. Freely downloadable, no credentials required.

## Design Integrity Checklist
- Treatment timing: Feb 8, 2016 (band merger); scheme pause Jan 15-Feb 7, 2016
- In-sample treated units: ~765,000 installations in FIT bands period
- Unit of observation: individual installation
- Running variable: Declared Net Capacity (kW)
- Clustering: N/A (cross-sectional bunching, not panel)
- Pre-periods: April 2010 - Jan 2016 (~6 years of FIT band bunching data)

## Kill-Shot Concerns
1. The polynomial may struggle near 4 kW because the distribution is heavily peaked at domestic sizes (2-4 kW). Solution: use the difference-in-bunching framework and report raw ratios alongside formal estimates.
2. Residual bunching at 4.0 kW post-reform from engineering/round-number effects may blur the policy signal. Solution: use adjacent mass points (3.68, 3.92, 3.99) as within-threshold placebos — these should NOT collapse after the reform.
3. The 10 kW "control" threshold may also attenuate if tariff degression reduced the rate differential. Solution: build tariff-rate crosswalk to verify the 10 kW differential remained economically meaningful post-2016.
