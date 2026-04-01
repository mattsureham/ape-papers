# Research Plan: Counting Children Differently

## Research Question
Does the staggered adoption of Differential Response (DR) by U.S. states mechanically reduce reported child maltreatment rates by reclassifying referrals away from the investigation track, manufacturing an apparent decline in substantiated victim counts without changing underlying maltreatment prevalence?

## Policy Background
Traditional Child Protective Services (CPS) funnels every screened-in referral into a formal investigation that produces a substantiation finding, identifies perpetrators, and generates entries in NCANDS victim statistics. Starting with Florida (1993) and Missouri (1994), states adopted Differential Response systems creating a second "family assessment" track for low/moderate-risk referrals. Crucially, assessment-track cases do NOT produce substantiation findings, do NOT identify perpetrators, and are NOT counted in NCANDS victim statistics. By 2015, 32 states had adopted DR. The consequence: diverted referrals vanish from official statistics regardless of actual maltreatment.

## Identification Strategy
**Callaway-Sant'Anna (2021) staggered DiD** exploiting the staggered adoption of DR across 32 states (1993-2015) with 18 never-adopters as controls.

- **Treatment:** State-level DR adoption year (binary: adopted or not)
- **Key test — Denominator decomposition:** If referral counts remain stable but substantiated victim counts decline post-DR, the decline is an artifact of reclassification, not a real change in maltreatment
- **Falsification tests:**
  1. Child fatality rates (CDC WONDER) should NOT respond to DR — fatalities are always investigated regardless of DR status
  2. Physical abuse substantiations (too severe for DR diversion) should show no effect, while neglect substantiations (the category most likely diverted) should show the full artifact
  3. Placebo adoption dates in non-adoption years

## Expected Effects and Mechanisms
- **Main effect:** DR adoption reduces substantiated victim rates by diverting low-risk referrals to the assessment track (expected: moderate negative SDE, −0.05 to −0.15)
- **Mechanism 1 (Reclassification):** Referral counts remain stable while victims decline → the decline is artifactual
- **Mechanism 2 (Neglect vs. Abuse):** Effect concentrated in neglect (divertible) not physical/sexual abuse (always investigated)
- **Null falsification:** Child fatalities should not change — fatalities are never diverted

## Primary Specification
```
Y_{st} = α_s + γ_t + β · DR_{st} + X_{st}·δ + ε_{st}
```
Where Y_{st} is the victim rate per 1,000 children in state s, year t; DR_{st} is an indicator for DR adoption; α_s and γ_t are state and year fixed effects; X_{st} are time-varying state controls (child population, poverty rate). Standard errors clustered at state level. Callaway-Sant'Anna for heterogeneous treatment effects by adoption cohort.

## Data Sources
1. **Kids Count Data Center** (Annie E. Casey Foundation): State-year child maltreatment rates, victim counts, referral counts. Confirmed accessible via Excel download.
2. **ACF Child Maltreatment Reports**: Annual federal reports with state-level NCANDS aggregates. PDFs confirmed HTTP 200.
3. **CDC WONDER**: Child injury/fatality mortality data for falsification. Publicly available.
4. **DR adoption dates**: Compiled from Child Welfare Information Gateway, Merkel-Holguin et al. (2006), and subsequent state legislation tracking.

## Data Fetch Strategy
1. Download Kids Count Excel files for maltreatment rates by state and year
2. Construct DR adoption dates from published literature and policy databases
3. Fetch CDC WONDER child fatality data for falsification
4. Merge at state-year level

## Exposure Alignment
Treatment (DR adoption) and outcome (victim rate) are measured at the same level: state-year. DR adoption directly affects the state's CPS data-generating process, so the treated entity (the state's CPS system) is precisely aligned with the unit of observation. Children in DR-adopting states are exposed through their state's CPS reporting system. There is no cross-state contamination because NCANDS tracks each child through their state of residence.

## Key Risks
- Kids Count may not have all years or all variables needed (referrals vs. victims breakdown)
- DR adoption dates may be contested or gradual (pilot → statewide rollout)
- Some states may have reversed DR adoption, creating confounding variation
- State-level panel may have limited statistical power for some decompositions
