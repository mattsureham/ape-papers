# Research Ideas

## Idea 1: Do Red Flag Laws Save Lives or Shift Deaths? Means Substitution in Suicide Prevention
**Policy:** Extreme Risk Protection Order (ERPO) laws allow courts to temporarily remove firearms from individuals deemed a danger to themselves or others. Twenty-two states adopted ERPO statutes in staggered fashion: Connecticut (1999), Indiana (2005), California (2014), Washington (2016), Oregon (2017), Florida/Vermont/Maryland/Rhode Island/New Jersey/Delaware/Massachusetts/Illinois (2018), Colorado/Nevada/Hawaii/New York (2019), New Mexico/Virginia (2020), Maine/Michigan/Minnesota (2023-2024). Six states enacted anti-ERPO laws (Texas, Montana, Oklahoma, Tennessee, West Virginia, Wyoming). Two distinct adoption waves: pre-Parkland (5 states, 1999-2017) and post-Parkland (17 states, 2018-2024).

**Outcome:** CDC "Mapping Injury, Overdose, and Violence - State" dataset (Socrata API endpoint fpsi-y8tj): state-by-year death counts and age-adjusted rates for FA_Suicide, FA_Homicide, FA_Deaths, All_Suicide, All_Homicide, Drug_OD. 51 jurisdictions, 2019-2024 annual, no suppression. Extended panel: CDC WONDER Underlying Cause of Death (1999-2020) via wonderapi R package. ICD-10 codes X72-X74 (firearm suicide), X60-X84 (all suicide). Key constructed variable: Non-firearm suicide rate = All_Suicide - FA_Suicide (the means-substitution test).

**Identification:** Callaway and Sant'Anna (2021) staggered DiD with group-time ATTs, using never-treated and not-yet-treated states as controls. Key assumptions: (1) Parallel trends in suicide rates absent treatment; (2) No anticipation; (3) SUTVA. Heterogeneity by: (a) Pre-law gun ownership rate; (b) Pre-Parkland vs post-Parkland cohorts; (c) Enforcement intensity. Robustness: Sun & Abraham (2021); de Chaisemartin & D'Haultfoeuille (2020); Randomization inference; Synthetic DiD. Built-in placebo: drug overdose deaths (should not respond to firearm removal).

**Why it's novel:** (1) Means substitution is the elephant in the room — most studies report firearm suicide reductions but never test whether total suicides decline. (2) RAND's 2024 review found all existing multi-state studies have "serious or critical methodological concerns" from TWFE with heterogeneous effects. A proper CS-DiD across 22 states is absent. (3) Homicide effects are deeply uncertain. (4) No APEP paper on gun policy or suicide.

**Feasibility check:** Variation confirmed (22 treated states, 28 never-treated + 6 anti-ERPO controls). Data access confirmed (CDC Mapping Injury returns 51 jurisdictions x 6 years x 6 outcomes; CDC WONDER 1999-2020 via wonderapi). Novelty confirmed. Sample ~1,300 state-years.

## Idea 2: Can Shorter Workweeks Save Fertility? South Korea's 52-Hour Reform
**Policy:** South Korea's 2018 Amendment to Labor Standards Act reduced maximum weekly working hours from 68 to 52 (40 standard + 12 overtime), phased by firm size: 300+ (July 2018), 50-299 (January 2020), 5-49 (July 2021).

**Outcome:** Korean Labor and Income Panel Study (KLIPS) waves 18-26 (2015-2023), ~23,000 individuals. Contains marital status transitions, childbirth events, employer firm size, working hours, wages. Secondary: KOSIS Vital Statistics by Month for 17 provinces.

**Identification:** Multi-cutoff staggered DiD exploiting three treatment waves with built-in placebo tests (workers in 50-299 firms should show no effect during wave 1). Individual-level panel allows individual fixed effects.

**Why it's novel:** No existing causal study links the 52-hour reform to marriage or fertility outcomes. First-order policy stakes: Korea has world's lowest fertility rate (TFR=0.72 in 2023).

**Feasibility check:** Variation confirmed (three-wave staggered rollout). Data on Harvard Dataverse (106 files). Novelty confirmed. However, COVID overlap with wave 2 is a concern.

## Idea 3: The Local Fiscal Multiplier of Unconditional Cash Transfers: Poland's Family 500+
**Policy:** Poland's 2016 Family 500+ program (500 PLN/month per child, ~2% of GDP). Phase I (April 2016): universal for 2nd child+, means-tested for 1st child. Phase II (July 2019): fully universal. Annual cost ~40B PLN.

**Outcome:** GUS BDL API at powiat/gmina level: new business registrations, unemployment, live births, infant mortality, marriages. 382 powiats x 12 years = ~4,584 powiat-year observations.

**Identification:** Bartik-style continuous-treatment DiD with two policy shocks. Treatment intensity from pre-program (2015) powiat-level share of households with 2+ children (Phase I) and all households with children (Phase II).

**Why it's novel:** Existing 500+ literature focuses on individual/household-level effects. No paper studies the local economic multiplier using geographic variation. The two-phase design (means-tested then universal) provides a rare natural experiment for comparing universal vs targeted transfer multipliers.

**Feasibility check:** Variation confirmed (382 powiats with wide variation). Data access confirmed (GUS BDL API smoke-tested). Novelty confirmed.
