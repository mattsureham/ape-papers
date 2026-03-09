# Research Plan: Does Regulating Private Landlords Raise Property Values? Selective Licensing and Housing Markets in England

## Research Question
Does mandatory licensing of private landlords improve neighborhood quality enough to raise residential property values? We exploit the staggered adoption of selective licensing schemes across 100+ English local authorities since 2006 to estimate causal effects on property prices and anti-social behavior.

## Identification Strategy
**Method:** Staggered difference-in-differences using Callaway & Sant'Anna (2021).

**Treatment:** LA-level adoption of selective licensing under Housing Act 2004, Part 3. Treatment timing varies across LAs from 2006-2024.

**Identifying assumption:** Parallel trends in property prices between early-adopting and late/never-adopting LAs prior to scheme adoption. Testable with 8-18 years of pre-treatment Land Registry data.

**Why exogenous:** Licensing adoption reflects council political preferences and PRS concentration — not contemporaneous property price trends. The design compares LAs adopting at different times, not adopters vs. never-adopters. DWP/MHCLG administrative sequencing (Secretary of State approval process) adds friction that weakens selection on trends.

### Exposure Alignment
- **Who is actually treated?** Private landlords in designated areas must obtain a licence, comply with management standards, and pay fees.
- **Primary estimand population:** Properties in LAs with selective licensing — both privately rented and owner-occupied (spillovers through neighborhood effects).
- **Placebo population:** (1) Commercial properties (unaffected by residential licensing). (2) Owner-occupied properties in low-PRS neighborhoods within treated LAs.
- **Design:** DiD with continuous dose variation (PRS share).

### Power Assessment
- **Pre-treatment periods:** 8-18 years (Land Registry from 1995)
- **Treated clusters:** 40-100+ LAs (depending on confirmed adoption dates)
- **Post-treatment periods per cohort:** Varies; earliest cohorts have 15+ years post
- **Outcome observations:** 24M+ property transactions

## Expected Effects and Mechanisms
1. **Neighborhood quality channel:** Licensing → improved property conditions → reduced ASB → neighborhood upgrading → positive price capitalization
2. **Supply restriction channel:** Licensing costs → marginal landlord exit → reduced PRS supply → ambiguous price effect (fewer rental conversions may raise owner-occupied prices)
3. **Information channel:** Licensing status signals regulated area → buyer confidence → positive capitalization

**Primary hypothesis:** Net positive effect on property prices, concentrated in high-PRS neighborhoods. Magnitude: 2-5% price premium.

**Alternative:** If compliance costs dominate, prices could fall in high-PRS areas (landlord disinvestment).

## Primary Specification
```
Y_{i,l,t} = α_l + γ_t + β·Licensing_{l,t} + X'_{i,t}δ + ε_{i,l,t}
```
Where:
- Y = log(transaction price) for property i in LA l at time t
- α_l = LA fixed effects
- γ_t = year-quarter fixed effects
- Licensing_{l,t} = 1 if LA l has active selective licensing at time t
- X = property controls (type, new/old, freehold/leasehold)
- Clustering at LA level

Estimated via CS-DiD (Callaway & Sant'Anna 2021) with never-yet-treated as comparison group.

## Planned Robustness Checks
1. **Sun & Abraham (2021)** interaction-weighted estimator
2. **Event-study plots** — pre-treatment coefficient dynamics (formal joint test)
3. **HonestDiD** — sensitivity to violations of parallel trends (Rambachan-Roth)
4. **Placebo:** Commercial property prices (should show no effect)
5. **Dose-response:** Interact treatment with baseline PRS share
6. **Leave-one-out:** Drop each treated LA and re-estimate
7. **Randomization inference:** Permute treatment timing across LAs
8. **Goodman-Bacon decomposition** for diagnostic on TWFE bias
9. **Within-LA comparison:** Designated vs. non-designated areas (for partial schemes)
10. **Mechanism:** ASB reduction as intermediate outcome

## Data Sources
1. **HM Land Registry Price Paid Data** — 24M+ transactions, postcode-level, 1995-present
2. **UK Police API / data.police.uk** — ASB incidents by LSOA, monthly, 2010-present
3. **ONS NSPL** — Postcode to LSOA/LA lookup
4. **NOMIS Census 2021** — Tenure composition (PRS share) by LSOA
5. **ONS Private Rental Market Statistics** — LA-level median private rents, quarterly
6. **Selective licensing adoption dates** — Constructed from government records, council designations, Petersen et al. (2026)

## Timeline
1. Construct licensing adoption timeline (web research + government records)
2. Fetch Land Registry data (2005-2024, annual CSVs)
3. Fetch Police API ASB data
4. Fetch Census 2021 tenure data and ONS rental statistics
5. Link via NSPL postcode-to-LSOA crosswalk
6. Estimate CS-DiD and robustness battery
7. Write paper
