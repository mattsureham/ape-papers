# Research Plan: The Doula Dividend — Medicaid Coverage Mandates and Birth Outcomes

## Research Question
Does state-level Medicaid doula reimbursement reduce C-section rates and improve birth outcomes at the population level? All existing evidence exploits individual-level selection into doula use; the population-level ITT — the policy-relevant parameter — has never been estimated.

## Identification Strategy
**Staggered DiD (Callaway-Sant'Anna)** exploiting variation in state adoption of Medicaid doula reimbursement across 2018-2023.

**Treatment cohorts:**
- Always-treated (pre-sample): Oregon (2014), Minnesota (2014)
- 2022 cohort: Virginia (Apr), Maryland (Feb), Nevada (Apr), DC (Oct) — 4 units
- 2023 cohort: Michigan (Jan), California (Jan), Oklahoma, Massachusetts — 4 units
- Never-treated: ~40 remaining states

**Triple-difference:** Within treated states, Medicaid births (directly affected) vs. private-insurance births (unaffected placebo). This absorbs state-level confounds that affect all births equally.

**Key identifying assumption:** Conditional on state and year FE, C-section rate trends among Medicaid births in adopting vs. non-adopting states would have been parallel absent the policy. The within-state Medicaid vs. private comparison strengthens this by differencing out state-level shocks.

## Expected Effects and Mechanisms
- Individual-level doula RCTs show 40-47% C-section reduction (Gruber 2013, Kozhimannil 2024)
- Population ITT will be much smaller due to partial take-up (estimated 2-10% of Medicaid births)
- Expected ITT: 0.5-3 percentage point reduction in C-section rate among Medicaid births
- **Coverage-to-care gap:** the attenuation from individual efficacy to population effectiveness

## Primary Specification
Y_{s,t,p} = state-year-payer cell mean (C-section rate)
Callaway-Sant'Anna ATT(g,t) with never-treated states as controls
Triple-diff: (treated state × Medicaid payer × post) vs (treated state × private payer × post)
Clustering: state level (51 clusters)

## Outcomes
1. **Primary:** C-section rate (DMETH_REC)
2. **Secondary:** Preterm birth rate (GESTREC3), low birth weight rate (DBWT < 2500g)
3. **Heterogeneity:** Race (MRACE6) — Black vs. White C-section gap

## Data Source
**CDC NCHS Natality Microdata** (public-use files from CDC FTP)
- Years: 2018-2023 (6 years, ~3.6M births/year = ~22M total)
- Key fields: MAGER (maternal age), OE_GEST (gestational age), DMETH_REC (delivery method), PAY_REC (payment), MRACE6 (race), DSTATE (state), DOB_YY (year), DBWT (birth weight)
- Source: https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/DVS/natality/

## Threats to Identification
1. **Concurrent Medicaid expansions:** Postpartum Medicaid extension (12 months) overlaps timing — control with state-level expansion indicator
2. **Pandemic effects:** COVID disrupted birth care 2020-2021 — year FE absorb aggregate effects; triple-diff absorbs within-state effects
3. **Composition changes:** Medicaid eligibility changes shift who gives birth under Medicaid — check compositional stability in pre-period
4. **Take-up lag:** 9-month pregnancy means births in adoption year may have limited exposure — separate partial vs. full exposure years

## Robustness
1. Event study plots (pre-trends)
2. HonestDiD sensitivity bounds
3. Drop always-treated states (OR, MN)
4. Alternative estimators: Sun-Abraham, stacked DiD
5. Placebo: private-insurance births in treated states
6. Leave-one-state-out jackknife
