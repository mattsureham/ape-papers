# Research Plan: The Safety Valve Lottery

## Research Question

Did the First Step Act's expansion of the federal statutory safety valve reduce sentence length and racial disparities among drug trafficking offenders, and how did judge-level heterogeneity in safety valve utilization shape these effects?

## Background

The First Step Act (P.L. 115-391, December 21, 2018) expanded the safety valve (18 U.S.C. §3553(f)) by relaxing criminal history eligibility from 0-1 points to up to 4 points. USSC reports ~1,369 newly eligible offenders received relief in Year One. Pulsifer v. United States (March 15, 2024) narrowed eligibility, creating a reverse shock.

## Identification Strategy

**Triple-difference with judge-leniency IV:**

1. **Diff 1 (Time):** Pre-FSA (FY2002-FY2018) vs Post-FSA (FY2019-FY2024)
2. **Diff 2 (Eligibility):** Newly eligible defendants (criminal history 2-4 points) vs already eligible (0-1 points)
3. **Diff 3 (Judge leniency):** Leave-one-out mean safety valve utilization rate within district

Primary specification (reduced form):
`TOTPRISN_ij = α + β₁(Post × NewlyEligible) + β₂(Post × NewlyEligible × JudgeLeniency) + δ_d×t + γ_X + ε`

where i indexes defendant, j indexes judge, d indexes district, t indexes fiscal year.

## Expected Effects and Mechanisms

1. **Direct effect:** Newly eligible defendants should receive shorter sentences post-FSA (β₁ < 0)
2. **Judge heterogeneity:** Lenient judges should utilize the expanded safety valve more aggressively (β₂ < 0)
3. **Racial equity:** If safety valve expansion reduces sentences more for Black defendants (overrepresented in drug trafficking with criminal history 2-4), the racial sentencing gap narrows
4. **Pulsifer check:** The 2024 narrowing should partially reverse these effects

## Primary Specification

- **Outcome:** Total prison sentence in months (TOTPRISN)
- **Treatment:** Interaction of Post-FSA × newly eligible (criminal history 2-4 points)
- **IV:** Leave-one-out mean judge safety valve rate
- **Fixed effects:** District × fiscal year
- **Controls:** Offense characteristics, criminal history category, mandatory minimum indicator, gender, age, education, citizenship
- **Clustering:** District level (94 clusters)
- **Robustness:** Wild cluster bootstrap, leave-one-district-out

## Data Sources

1. **USSC Individual Datafiles** (FY2002-FY2024): ~60K cases/year, 1,400+ variables. Direct download from ussc.gov.
2. **JUSTFAIR** (OSF: osf.io/nseh5/): Links judge identifiers to 600K+ USSC cases through 2023.
3. Key variables: MAND1-MANDX (safety valve codes), TOTPRISN (sentence months), NEWRACE (race), DISTRICT, XCRHISSR (criminal history), STATMIN/STATMAX (mandatory min/max), DRUGTYP (drug type)

## Fetch Strategy

1. Download USSC individual datafiles from ussc.gov for FY2018-FY2024 (key window around FSA)
2. Download JUSTFAIR from OSF for judge identifier linkage
3. Merge on case identifiers
4. Construct judge leniency instrument using pre-FSA safety valve rates
