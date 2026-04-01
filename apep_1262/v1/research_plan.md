# Research Plan: Sanctioned for Solidarity

## Research Question

Does state enforcement of social housing mandates trigger far-right electoral backlash? When French prefects declare communes "carencées" (deficient) under the SRU law — multiplying financial penalties, transferring preemption rights to the state, and allowing prefects to issue building permits directly — does this sovereignty shock shift voters toward the Rassemblement National?

## Policy Background

France's Loi SRU (Solidarité et Renouvellement Urbain, 2000) requires communes above population thresholds to maintain 20-25% social housing (logements sociaux). Every three years, prefects review compliance. Communes that fall short AND show insufficient effort are declared "carencées," triggering:
1. **Multiplied financial penalties** (up to 5× the base shortfall surcharge)
2. **State preemption rights** on property transactions
3. **Prefect-issued building permits** (overriding local mayor's authority)
4. **Mandatory 30% social housing** in new developments >12 units

The treatment has been applied in successive waves: ~220 communes (2011-13), 269 (2014-16), 280 (2017-19), 341 (2020-22).

## Identification Strategy

**Staggered DiD using Callaway-Sant'Anna (2021).**

- **Treatment:** First carence declaration for a commune in a given triennial period
- **Treated units:** 269-341 communes per period (cumulative ~550+ unique treated communes)
- **Control group 1:** SRU-subject communes that are in deficit but NOT declared carencées (~400-659 per period)
- **Control group 2:** SRU-compliant communes (meeting the quota)
- **Outcome:** Rassemblement National (RN) first-round vote share in presidential elections (commune level)
- **Election cycles:** 2002, 2007, 2012, 2017, 2022
- **Pre-treatment:** At least 2 election cycles before first carence declaration for each cohort
- **Estimator:** CS-DiD with never-treated and not-yet-treated controls, aggregated ATT

**Key identification assumption:** Conditional on being SRU-subject and in deficit, the timing of carence declaration is quasi-random — driven by prefectoral discretion and triennial review cycles, not by electoral trends.

## Expected Effects and Mechanisms

**Two competing channels:**
1. **Sovereignty channel (positive RN effect):** State override of local authority → resentment of central government → anti-establishment voting → RN gains
2. **Composition channel (ambiguous):** More social housing → demographic change → could trigger threat response (RN gains) OR contact effects (RN decline)

**Expected:** Net positive effect on RN vote share, driven primarily by the sovereignty channel. The composition channel operates with a lag (housing takes years to build), while the political signal is immediate.

## Primary Specification

Y_{ct} = ATT(g,t) via Callaway-Sant'Anna, where:
- Y = RN first-round presidential vote share (%)
- g = cohort (triennial period of first carence declaration)
- t = election year
- Controls: department fixed effects, commune population, median income

## Robustness

1. **Placebo outcomes:** Vote share for parties without anti-immigration platform (e.g., LR, PS center-left)
2. **Dose-response:** First-time vs. repeat carencées
3. **Triple-diff:** Within-department comparison to control for regional trends
4. **Event study:** Dynamic treatment effects showing pre-trends
5. **Alternative controls:** Using only never-treated SRU communes

## Data Sources

| Data | Source | Format | Access |
|------|--------|--------|--------|
| Carencée commune lists | data.gouv.fr (SRU inventory) | CSV | Open |
| Presidential election results | data.gouv.fr (élections présidentielles) | CSV/Parquet | Open |
| Commune characteristics | INSEE RP (population, income) | CSV/API | Open |
| Social housing stock (secondary) | RPLS via data.gouv.fr | CSV | Open |
| Property transactions (secondary) | DVF via data.gouv.fr | CSV | Open |

## Key Risks

1. **Selection into carence:** Prefects may target communes with specific political profiles. Mitigated by controlling for lagged political variables and using within-department variation.
2. **Power:** Election cycles are 5 years apart; with treatment waves every 3 years, there are limited pre/post observations per cohort. Mitigated by stacking multiple cohorts.
3. **Confounding reforms:** Other housing or immigration policies may coincide. Mitigated by placebo outcomes and national-level controls.
