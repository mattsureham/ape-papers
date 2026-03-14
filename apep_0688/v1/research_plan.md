# Research Plan: Violence Reduction Units and the Geography of Serious Crime

## Research Question

Do Violence Reduction Units (VRUs) reduce violent crime, or do they displace it to neighboring jurisdictions? The UK Home Office's 2019 allocation of Serious Violence Fund grants to 18 of 43 police force areas created a sharp treatment-control boundary. This paper estimates direct effects on crime in treated forces and displacement/deterrence spillovers to neighboring untreated forces using a Callaway-Sant'Anna staggered DiD.

## Identification Strategy

**Design:** Two-cohort staggered DiD with Callaway-Sant'Anna estimator.

- **Cohort 1 (April 2019):** 18 police forces received VRU funding
- **Cohort 2 (April 2022):** Cleveland and Humberside received additional funding
- **Never-treated:** ~23 forces that never received VRU funding

**Treatment assignment:** The 18 initial VRU forces were selected by the Home Office based on serious violence rates during March 2016 - March 2018. This creates selection on pre-treatment levels — parallel trends and event study pre-trends are crucial for identification.

**Spillover decomposition (key contribution):**
- Classify untreated forces as "boundary" (adjacent to ≥1 treated force) or "interior" (not adjacent to any treated force)
- If VRUs deter crime: both treated and boundary forces see reductions
- If VRUs displace crime: treated forces see reductions, boundary forces see increases
- Net effect (direct + spillover) answers whether total violence falls

## Expected Effects and Mechanisms

1. **Direct effect:** VRU funding enables multi-agency coordination (police, health, education, social services) → reduced serious violence in treated forces. Expected: negative (crime reduction), magnitude uncertain.

2. **Displacement channel:** If interventions push offenders across force boundaries, neighboring untreated forces absorb displaced crime. Expected if displacement: positive effect on boundary forces.

3. **Deterrence channel:** If VRU-funded enforcement raises expected cost of crime regionally, both treated and nearby forces benefit. Expected if deterrence: negative effect on boundary forces.

4. **COVID interaction:** Lockdowns from March 2020 dramatically altered crime patterns. Pre-COVID window (April 2019 - February 2020) provides 11 clean post-treatment months. Extended analysis includes COVID period with controls.

## Primary Specification

```
Y_{ft} = α_f + α_t + β₁(VRU_f × Post_t) + β₂(Boundary_f × Post_t) + ε_{ft}
```

Where Y_{ft} is the crime rate per 100,000 population in force f at month t. CS-DiD with group-time ATTs aggregated to event study.

**Robustness:**
- Placebo crime types (criminal damage, fraud — not targeted by VRUs)
- Permutation inference (Fisher exact test with re-randomized treatment)
- Pre-COVID only vs. full sample
- Alternative boundary definitions (1st-order vs. 2nd-order contiguity)

## Data Sources

1. **Home Office Police Recorded Crime Open Data Tables** — force × month × offence group (single download from data.gov.uk, 2002-present)
2. **ONS mid-year population estimates** by police force area (for per-capita rates)
3. **Force geographic boundaries** — for contiguity matrix construction
4. **VRU force list** — from Home Office Serious Violence Fund allocation (GOV.UK)

## Outcomes

| Outcome | Crime Category | Why |
|---------|---------------|-----|
| Violent crime | Violence against the person | Primary VRU target |
| Weapon possession | Possession of weapons | Key indicator of serious violence |
| Robbery | Robbery | Acquisitive violence, likely to displace |
| Placebo: Criminal damage | Criminal damage & arson | Not targeted by VRUs |
| Placebo: Fraud | Fraud | Not targeted by VRUs, no spatial dimension |

## Design Parameters

- Treated units: 18 forces (Cohort 1) + 2 (Cohort 2) = 20
- Control units: ~23 never-treated forces
- Pre-periods: 39 months (Jan 2016 - Mar 2019) for Cohort 1
- Post-periods: 11 months pre-COVID (Apr 2019 - Feb 2020); 51 months total (Apr 2019 - Jun 2023)
- Total observations: ~43 forces × 90 months ≈ 3,870

## Risks

1. **Selection on levels:** VRU forces are highest-crime forces. Mitigated by CS-DiD conditional parallel trends + event study pre-trends.
2. **COVID contamination:** Lockdowns distort crime patterns post-March 2020. Mitigated by pre-COVID-only analysis.
3. **Small N:** 43 forces is moderate. Mitigated by randomization inference.
4. **Imprecise boundary definition:** Force boundaries may not perfectly capture spillover geography. Mitigated by alternative contiguity definitions.
