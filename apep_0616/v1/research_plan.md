# Research Plan: Police Austerity and Criminal Justice Quality in England and Wales

## Research Question
Did police budget cuts during UK austerity (2010-2018) reduce criminal justice quality — measured by charge rates, case attrition, and clearance — and did these effects fall disproportionately on investigation-intensive crime types (domestic violence, sexual offences)?

## Identification Strategy
**IV-DiD using pre-austerity council tax precept share as instrument.**

The 2010 Comprehensive Spending Review cut central police grants by ~20% in real terms. But forces with higher pre-existing council tax precept revenue were insulated: precept share ranged from 22% (Metropolitan Police) to 64% (Surrey) in 2009-10. This creates plausibly exogenous variation in the severity of officer cuts.

**Instrument:** Pre-2010 council tax precept share of total police funding × Post-2010 indicator.
- First stage: High-precept forces experienced smaller officer cuts.
- Reduced form: High-precept forces maintained higher charge rates.
- Exclusion restriction: Pre-austerity precept share affects crime outcomes only through officer numbers. Council tax base reflects property values and band distribution, not policing quality.

**Specification:**
- First stage: log(Officers_ft) = α_f + γ_t + δ(PrecShare_f × Post_t) + X'β + ε
- Second stage: ChargeRate_ft = α_f + γ_t + β × log(Officers_ft_hat) + X'δ + ε

Where f = force (43), t = year, PrecShare = 2009-10 precept share.

## Expected Effects
- Officer cuts reduce charge/summons rates (positive β in second stage)
- Effects strongest for investigation-intensive crimes: sexual offences, domestic violence, fraud
- Effects weakest for low-investigation crimes: drug possession (caught in act), motoring offences
- Mechanism: fewer officers → fewer investigators → cases dropped before charge

## Primary Specification
Panel IV-DiD, 43 police forces × ~15 years (2007-2022). Force and year fixed effects. Instrument: continuous precept share (2009-10) interacted with post-2010 indicator. Clustered SEs at force level. Robustness: wild cluster bootstrap (43 clusters).

## Data Sources
1. **Police workforce** — Home Office open data: officer headcount by force, 2003-2023
2. **Crime outcomes** — Home Office open data: charge/summons rates by force and offense type
3. **Police funding** — Home Office/CIPFA: central grant and precept revenue by force (for instrument)
4. **Recorded crime** — ONS/Home Office: total recorded crimes by force by offense group
5. **Population** — ONS mid-year estimates by PFA (for per-capita controls)

## Feasibility Assessment
- 43 police force areas × 15+ years = 645+ force-year observations
- Continuous instrument (precept share) with good spread (22-64%)
- All data from open government sources
- Built-in placebo: 2003-2009 pre-trends should be flat
- Offense-type heterogeneity provides mechanism test
