# Research Plan: apep_1228

## Idea
idea_2180 — The Waterbed Illusion: Separating GIPP Pricing Effects from Claims Inflation Using Pre-Reform Price-Walking Intensity

## Research Question
Did the FCA's General Insurance Pricing Practices (GIPP) reform — which banned price-walking in UK home and motor insurance from January 2022 — create a waterbed effect where new customer premiums rose to compensate, or were post-reform premium increases entirely driven by exogenous claims cost inflation?

## Why It Matters
The FCA's own evaluation (EP25/2, July 2025) found a statistically significant -5.9% causal effect on motor premiums but failed to find significance for home insurance, and critically acknowledged that claims cost inflation (+12% motor, +49% home) overwhelmed the pricing remedy's savings. This is the fundamental identification challenge: separating regulatory pricing effects from background claims inflation. If the waterbed effect is real, "fairness regulation" in insurance may simply redistribute surplus from new to existing customers rather than creating consumer welfare gains — a prediction from IO theory (Armstrong & Vickers 2001) with major implications as EIOPA considers EU-wide differential pricing rules.

## Identification Strategy
**Continuous-treatment DiD.** Treatment intensity = pre-GIPP price-walking intensity at the firm level, measured as the ratio of renewal-to-new-business premium metrics from the 2021 H2 pilot FCA GI Value Measures data.

The key insight: claims cost inflation affects ALL firms regardless of their pre-GIPP price-walking behavior. The GIPP effect should be proportional to pre-reform price-walking intensity. Cross-firm variation in pre-reform intensity separates the two forces.

**Formally:**
Y_{it} = α_i + γ_t + β · (PriceWalkIntensity_i × Post_t) + X_{it}δ + ε_{it}

where β captures the differential effect of GIPP on firms with higher pre-reform price-walking intensity.

## Expected Effects and Mechanisms
1. **Waterbed effect:** Firms that were aggressive price-walkers should see larger increases in new-business pricing metrics post-reform, as they can no longer extract surplus from loyal customers
2. **Claims composition:** High-intensity price-walkers may attract different risk pools post-reform (selection channel)
3. **Complaint displacement:** Complaints may shift from renewal pricing to claims handling

## Primary Specification
- Unit: firm × year (annual GI Value Measures panel, 2021 H2 through 2024)
- Treatment: continuous, pre-reform price-walking intensity (measured 2021 H2)
- Outcomes: claims ratio, complaints rate, claims acceptance rate, average claims payout
- FE: firm + year
- Clustering: firm level

## Data Sources
1. **FCA GI Value Measures 2024** — firm-level panel, ~195 firms, 52 product categories. Claims frequency, acceptance rates, payout, complaints, premium share. URL confirmed, 117KB XLSX.
2. **Bank of England Insurance Aggregate Data** — quarterly 2017Q1-2025Q3, Net Written Premium and Loss Ratio by line of business. 9,901 rows, 789KB CSV.
3. **FCA Aggregate Complaints Data** — semi-annual, firm-level complaint volumes. 90KB XLSX.
4. **Confused.com/WTW Car Insurance Price Index** — quarterly average quoted premiums from 6M+ quotes (for aggregate context).

## Fetch Strategy
1. Download FCA GI Value Measures XLSX directly from FCA website
2. Download BoE Insurance CSV directly
3. Download FCA complaints XLSX directly
4. Construct treatment variable from 2021 H2 pilot data within GI Value Measures
5. Merge firm-level outcomes across waves

## Key Risks
- GI Value Measures may not directly contain renewal vs. new-business price metrics needed for treatment construction — if so, use claims ratio as proxy for price-walking exposure
- Only 3-4 annual observations per firm limits pre-trend testing
- 195 firms may include many small firms with noisy outcomes
