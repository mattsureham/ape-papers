# Research Plan: Regulatory Leakage — State Civil Asset Forfeiture Reform and the Federal Equitable Sharing Escape Valve

## Research Question
When states restrict civil asset forfeiture, do law enforcement agencies circumvent reforms by routing seizures through the federal equitable sharing program? This tests whether state-level reform is sufficient or whether federal coordination is necessary to close the "escape valve."

## Identification Strategy
**Staggered Callaway-Sant'Anna DiD** exploiting the timing of 37 state forfeiture reforms (2014–2024) against 13 never-reformed states.

- **Treatment**: Year a state enacted forfeiture reform (conviction requirement, burden-of-proof elevation, or abolition)
- **Treatment intensity**: Heterogeneity by reform stringency (reporting only < burden-of-proof < conviction requirement < full abolition)
- **Unit of analysis**: Agency-fiscal year (N ≈ 76,200 agency-years, 7,620 unique agencies)
- **Control group**: ~2,600 agencies in 13 never-reformed states
- **Estimator**: Callaway and Sant'Anna (2021) with never-treated as comparison group

## Expected Effects and Mechanisms
- **Primary hypothesis**: Agencies in reformed states increase equitable sharing participation and revenue post-reform (circumvention)
- **Mechanism**: Federal equitable sharing allows agencies to bypass state restrictions — federal law applies regardless of state reform
- **Heterogeneity**: Anti-circumvention statutes (8 states) should attenuate the leakage effect
- **Extensive margin**: More agencies participate in equitable sharing post-reform
- **Intensive margin**: Participating agencies receive larger equitable sharing payments

## Primary Specification
```
ES_Revenue_{a,t} = α_a + γ_t + β × Post_Reform_{s(a),t} + ε_{a,t}
```
With Callaway-Sant'Anna group-time ATTs aggregated to event-time and overall ATT. Clustering at the state level (37 treated + 13 control = 50 clusters).

## Data Source and Fetch Strategy
1. **DOJ ESAC FOIA data**: `https://www.justice.gov/afp/dl/ESACfoia.zip` — 67,424 agency-year records, 7,620 agencies, FY2015–FY2025
2. **State reform coding**: Hand-coded from Institute for Justice "Policing for Profit" reports and NCSL legislative databases. Treatment dates from idea manifest.
3. **CATS asset-level data**: If available in the FOIA package, for intensive-margin analysis

## Exposure Alignment
Treatment is assigned at the state level — when a state enacts forfeiture reform, all law enforcement agencies in that state are treated simultaneously. The treatment maps directly to the outcome: agencies facing state restrictions have incentive to shift seizures to federal equitable sharing. The treatment is on-only (no repeals during sample). Federal policy changes (Holder 2015, Sessions 2017) affect all states and are absorbed by year FEs.

## Robustness
- Event-study plots (pre-trends test)
- HonestDiD sensitivity analysis (Rambachan-Roth)
- Leave-one-state-out
- Placebo: non-forfeiture revenue categories
- Binary reform vs. intensity-weighted treatment
- Wild cluster bootstrap (Cameron, Gelbach, Miller 2008) for inference with 50 clusters
