# Research Plan: The Saturday Soldier

## Research Question

Does compulsory weekend military service affect young men's labor market outcomes? Mexico's annual Sorteo Militar randomly assigns ~1 million 18-year-old men to either active Saturday training (white ball, ~40%) or reserve status (black ball, ~60%). Despite being one of the world's largest annual randomizations — affecting over 30 million men since 1942 — no economist has studied it.

## Identification Strategy

**Primary design: Male-female age-profile DiD.** Compare male vs. female employment/earnings trajectories across ages 15-30 using ENOE repeated cross-sections. The lottery creates a gender-specific disruption at age 18 for men only:

- Ages 15-17: Pre-lottery baseline. Male-female gaps reflect pre-existing gender differences.
- Age 18: Lottery year. ~40% of men assigned to Saturday service (6 hrs/week, 44 weeks).
- Ages 19-20: Post-service. Men have completed or are completing Saturday sessions.
- Ages 21-30: Long-run outcomes.

**Specification:**
Y_{igt} = Σ_a β_a (Male_i × I(Age_i = a)) + α_a + δ_t + γ_s + X'λ + ε_{igt}

With age 17 as reference, β_18 captures the ITT disruption effect and β_{20-25} captures the post-service trajectory.

**Key identification assumption:** The male-female gap in employment and earnings evolves smoothly through ages 15-17 (no differential disruption before the lottery), then shifts at 18 due to the Sorteo.

**Threats and responses:**
1. Other age-18 events (legal majority, voting age): Affect both genders equally → absorbed by age FEs
2. Differential school completion by gender: Control for education; check event study in school enrollment separately
3. Secular gender gap trends: Quarter and state FEs absorb these
4. Selection into ENOE: ENOE is population-representative; no attrition concern in repeated cross-sections

**Validation: 2025 dosage test.** In 2025, SEDENA raised the active assignment rate from ~40% to ~95%. If the age-18 disruption is driven by the lottery, the male-female gap at 18 should be ~2.4x larger for the 2025 cohort than pre-2025 cohorts (0.95/0.40 ≈ 2.4).

## Expected Effects

- Employment at age 18: Negative (Saturday obligations crowd out Saturday work)
- Formality at age 20+: Positive (cartilla militar required for many government/formal jobs)
- Earnings at age 20+: Ambiguous (lost experience vs. credentialing + soft skills)
- Education: Near-zero (Saturday service doesn't conflict with weekday school)

## Data

INEGI ENOE quarterly microdata, 2019Q1-2024Q4 (24 quarters, ~24 × 400K = 9.6M person-observations, filtered to ages 15-30 yields ~3M). Download from INEGI website (no API key needed). Merge SDEMT (demographics) + COE2 (income/hours) files.

Key variables:
- eda (age), sex (1=male, 2=female), nac_anio (birth year)
- clase1 (employment status), pos_ocu (occupational position)
- ingocup (monthly income), ing_x_hrs (hourly wage), hrsocup (hours)
- anios_esc (years education), seg_soc (social security access)
- ent (state), mun (municipality)

## Analysis Plan

1. Summary statistics by gender × age group
2. Male-female gap by single age (15-30) — the key descriptive table
3. Age-profile DiD regression: event study with age 17 as reference
4. Main specification: Male × Post18 with age/quarter/state FEs
5. Heterogeneity: formal vs. informal sector, education level, urban vs. rural
6. Mechanism test: social security access (formality) as the cartilla channel
7. 2025 dosage validation (if data available)
8. SDE appendix table
