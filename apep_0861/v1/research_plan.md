# Research Plan: Austerity Triage and the Collapse of Domestic Abuse Justice

## Research Question

Did police austerity causally reduce domestic abuse charge rates in England and Wales? We exploit heterogeneous exposure to central government grant cuts across 43 police forces after the 2010 Comprehensive Spending Review, using the pre-2010 council tax precept share as an instrument for the depth of officer reductions.

## Identification Strategy

**IV-DiD design:**
- **Endogenous variable:** Police officer FTE per capita (or per 1,000 population)
- **Instrument:** Pre-2010 council tax precept share (22%–64%) × post-2010 indicator
- **Outcome:** Domestic abuse charge rate (charges / recorded DA offenses)
- **Exclusion restriction:** The precept share reflects historical local government finance arrangements (property wealth, LA-level decisions about policing vs. services). Conditional on force-level demographics and crime rates, the precept share should not directly affect DA case attrition through channels other than police resources.
- **First stage:** Forces heavily dependent on central grants (low precept share) experienced deeper officer cuts when grants were slashed.

## Mechanism Tests
1. **Coercive control (Dec 2015):** This evidence-intensive crime category should be disproportionately affected by resource constraints. Triple-difference: post-coercive-control × low-precept forces.
2. **Victim withdrawal rates:** If austerity degrades investigation quality, victims may be more likely to withdraw support.
3. **PCSO cuts as mediator:** Community support officers handle early-stage DA reports.

## Expected Effects
- Forces with lower precept shares (more dependent on central grants) should see:
  - Larger officer FTE declines (first stage)
  - Steeper DA charge rate declines (reduced form)
  - Higher victim withdrawal rates
  - Disproportionate collapse in coercive control charges post-2015

## Data Sources

### Primary
1. **Home Office Crime Outcomes data** — Force-level outcomes by offense type, quarterly from 2012/13
   - URL: data.gov.uk → "Police recorded crime and outcomes open data tables"
   - Variables: DA-flagged offenses, charge/summons outcomes, victim withdrawal, evidential difficulties

2. **Home Office Police Workforce Statistics** — Officer FTE by force, annual
   - URL: gov.uk → "Police workforce, England and Wales" statistical bulletins

3. **Police funding data** — Central grants, council tax precept, total funding by force
   - URL: gov.uk → "Police funding for England and Wales" statistical releases
   - Key variable: Precept share = council tax precept / total funding (pre-2010 baseline)

### Secondary
4. **ONS mid-year population estimates** — Denominators for per-capita rates
5. **CSEW (Crime Survey for England and Wales)** — DA prevalence estimates (annual, not force-level)
6. **CPS VAWG reports** — Prosecution/conviction rates for violence against women

## Primary Specification

```
Y_{ft} = α + β * OfficerFTE_{ft} + X_{ft}γ + δ_f + θ_t + ε_{ft}

First stage: OfficerFTE_{ft} = π₀ + π₁(Precept_f × Post2010_t) + X_{ft}φ + μ_f + ν_t + η_{ft}
```

Where:
- f indexes police forces, t indexes years
- Y is DA charge rate (or related outcome)
- Precept_f is the pre-2010 council tax precept share (continuous instrument)
- Controls: population, crime rate, deprivation index
- Force and year fixed effects

## Robustness
1. Alternative outcome: conviction rate (CPS data)
2. Placebo: non-DA violent crime charge rates (should be less affected if DA is specifically deprioritized)
3. Event study: dynamic effects of austerity by precept quartile
4. Leave-one-out: exclude Metropolitan Police (London)
5. Wild cluster bootstrap (43 clusters is borderline)
