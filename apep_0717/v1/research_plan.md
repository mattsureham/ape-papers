# Research Plan: Capped and Crowded Out

## Research Question

Does reducing the benefit cap increase local authority temporary accommodation (TA) burdens? The November 2016 benefit cap reduction from £26,000 to £20,000/£23,000 dramatically expanded the capped population from ~20,000 to ~70,000+ households, with enormous cross-LA variation in treatment intensity. If newly capped households lose their tenancies, the cost shifts from DWP (benefit savings) to local authorities (TA expenditure) — a fiscal shell game rather than genuine savings.

## Identification Strategy

**Continuous-treatment DiD.** Treatment intensity = newly capped households per 1,000 population in each LA as of Q1 2017 (first full quarter after the November 2016 reduction). This is predetermined: the number of newly capped households depends on the pre-existing distribution of high-benefit claimants across LAs, which is driven by local housing costs and household composition.

**Specification:**
```
Y_{it} = α_i + γ_t + β(CappedShare_i × Post_t) + X_{it}'δ + ε_{it}
```

Where:
- Y_{it} = TA households per 1,000 population in LA i, quarter t
- CappedShare_i = newly capped households per 1,000 pop (time-invariant intensity)
- Post_t = 1 if t ≥ 2016Q4
- X_{it} = time-varying controls (UC rollout, population)
- α_i, γ_t = LA and quarter fixed effects

**Inference:** Cluster at LA level (296 clusters). Wild cluster bootstrap as robustness.

## Expected Effects and Mechanisms

1. **Direct displacement:** Capped households can't cover rent → eviction/homelessness → TA
2. **Crowding:** Capped households compete for limited social/private rental → displaced to TA
3. **Prevention costs:** LAs spend on prevention (Discretionary Housing Payments) but can't fully offset

**Expected sign:** Positive β — higher cap bite → more TA households. Literature on housing benefit cuts (Gibbons & Manning, 2006; Brewer et al., 2019) finds significant housing displacement effects.

## Primary Specification

TWFE with continuous treatment intensity. Event-study specification for dynamics:
```
Y_{it} = α_i + γ_t + Σ_k β_k(CappedShare_i × 1{t = k}) + ε_{it}
```

## Data Sources

1. **DWP Benefit Cap Statistics** — Quarterly ODS files with LA-level capped household counts. URL: stat-xplore.dwp.gov.uk or bulk ODS downloads.
2. **MHCLG/DLUHC Homelessness Statistics** — Table 784 (annual, pre-2018) and H-CLIC (quarterly, 2018+). Temporary accommodation households by LA.
3. **NOMIS** — Population estimates, claimant counts by LA (controls).
4. **UC Rollout Dates** — Published timetable of UC Full Service rollout by Jobcentre/LA.

## Exposure Alignment

The treatment intensity measure (capped households per 1,000 population at May 2017) captures the LA-level "bite" of the November 2016 cap reduction. The affected population consists of out-of-work households receiving Housing Benefit, Income Support, JSA, Child Benefit, and other qualifying benefits whose total exceeds the new cap threshold. The outcome (TA placements) directly measures the downstream housing consequence for a subset of these households — those who cannot find alternative accommodation after losing benefit income. The key alignment concern is that cap intensity is measured post-reform and may reflect behavioral responses; ideally one would use pre-reform benefit distributions, but DWP does not publish pre-reform LA-level caseloads in accessible form.

## Robustness

1. **Placebo outcome:** Pensioner homelessness (pensioners exempt from benefit cap)
2. **Placebo timing:** Fake treatment dates (2014, 2015)
3. **Dose-response:** Bin LAs into terciles/quartiles by treatment intensity
4. **Wild cluster bootstrap** for inference robustness
5. **Exclude London** (separate cap level of £23K)
6. **Control for Universal Credit rollout** (potential confounder)
