# Early Literature Review — APEP-0546

## Top Idea: ERPO Laws and Suicide Means Substitution

### Related Human Papers

1. **Kivisto & Phalen (2018)** — "Firearm Legislation and Fatal Police Shootings in the United States" (*American Journal of Public Health*). Used interrupted time series to estimate CT and IN ERPO effects on firearm suicide. Found 13.7% and 7.5% reductions. **Overlap: HIGH** — same policy, same outcome. **Our delta:** We use heterogeneity-robust staggered DiD (Callaway-Sant'Anna) across all 22 states, demonstrating that TWFE produces spurious estimates. We also test means substitution directly.

2. **Humphreys, Gasparrini & Wiebe (2019)** — "Evaluating the Impact of Florida's Red Flag Law on Suicide Deaths" (*JAMA Network Open*). Used interrupted time series for Florida only. Found reduction in firearm suicides post-ERPO. **Overlap: MEDIUM** — single state vs. our multi-state panel. **Our delta:** We use causal DiD across 21 treated states with never-treated controls, not single-state ITS.

3. **Swanson et al. (2019)** — "Criminal Justice and Suicide Outcomes with Indiana's Risk-Based Gun Seizure Law" (*JAAPL*). Individual-level case study of 404 Indiana ERPO respondents. Found 95.8% survival rate. **Overlap: LOW** — individual-level analysis vs. our population-level approach.

4. **RAND Corporation (2023)** — "The Effects of Extreme Risk Protection Orders." Systematic review characterizing evidence as "limited." **Overlap: LOW** — review paper, not primary analysis.

5. **Miller, Azrael & Barber (2013)** — "Firearms and Suicide in the United States" (*AJE*). Epidemiological analysis of firearm access and suicide risk. **Overlap: LOW** — cross-sectional ecological study, not causal DiD.

### Overlap Risk Assessment

**Overall Overlap: MEDIUM**

The ERPO-suicide question has been studied, but exclusively through interrupted time series (single-state) or TWFE (multi-state). No prior study uses heterogeneity-robust staggered DiD, and no prior study directly tests means substitution by decomposing firearm/non-firearm suicide in a causal framework. The TWFE bias demonstration is novel.

### Required Delta Statement

**Our contribution beyond existing literature:**
1. First application of Callaway-Sant'Anna heterogeneity-robust DiD to ERPO-suicide question
2. Demonstration that TWFE produces a qualitative sign flip (negative significant → positive insignificant)
3. Direct test of means substitution hypothesis using mechanism decomposition
4. Longest available panel (1999-2024, 22 states) vs. prior single-state or short-panel studies
5. Drug overdose placebo test for confounding

**Status: PROCEED** — sufficient novelty for publication despite medium overlap with existing literature.
