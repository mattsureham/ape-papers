# Research Plan: Mexico's Sorteo Militar and Youth Crime

## Research Question

Does compulsory part-time military service reduce youth crime? Mexico's Sorteo Militar randomly assigns ~40% of 18-year-old men to 44 Saturday morning training sessions (6 hours each). This paper estimates whether this structured weekend occupation reduces criminal activity during peak gang-recruitment years.

## Why This Matters

Youth violence is a first-order policy challenge in developing countries. The only causal evidence on military service and crime (Galiani et al. 2011, AEJ: Applied) found Argentina's *full-time* draft *increased* crime. Mexico tests the opposite margin: *part-time* weekend service in a high-violence context. The distinction between incapacitation (Saturday occupation) and socialization (discipline, networks) is policy-critical for the 30+ countries debating national service programs.

## Identification Strategy

**Primary Design: Male-Female Difference-in-Differences at ages 18-19**

- **Treatment group:** Males aged 18-19 (lottery-eligible)
- **Control group:** Females aged 18-19 (never eligible for Sorteo)
- **Pre-treatment ages:** 16-17 (before lottery eligibility)
- **Post-treatment ages:** 18-19 (during/after lottery service)
- **Additional controls:** Ages 20-25 (post-eligibility, for persistence tests)

The identifying assumption is that the male-female gap in crime outcomes evolves smoothly across the age-18 eligibility threshold absent the lottery. We test this with:
1. Event-study plots across ages 15-25 for both genders
2. Placebo tests using age groups far from 18 (e.g., 25-30)
3. Within-male cohort variation (pre/post 2025 reform as intensity shock)

**Key Estimating Equation:**
```
Y_igt = α + β₁(Male_i × Age18-19_t) + γ(Male_i) + δ(Age18-19_t) + X_i'θ + ε_igt
```
where β₁ captures the differential change in crime outcomes for lottery-eligible males at ages 18-19.

## Mechanism Tests

1. **Incapacitation:** Compare Saturday crime vs weekday crime (Sorteo sessions are Saturday mornings)
2. **Persistence:** Test whether effects continue after the ~10-month service period ends (ages 20+)
3. **Employment channel:** Use ENOE labor force survey data for labor market outcomes

## Data Sources

### Primary: SESNSP Municipal Crime Statistics
- Monthly crime counts by municipality, 2015-2025
- Categories: homicide, robbery, assault, extortion, kidnapping, drug offenses
- Open CSV from secretariadoejecutivo.gob.mx
- ~2,400 municipalities × 120+ months

### Secondary: ENVIPE Victimization Survey
- Annual microdata 2011-2024, ~90,000 households/year
- Individual-level: age, sex, state/municipality
- Captures both reported and unreported crime
- Key: can construct age×sex×state crime rates

### Tertiary: INEGI Mortality Statistics
- Death certificates with cause (homicide), age, sex, municipality
- Hard outcome (no reporting bias)

## Expected Effects

- **Incapacitation hypothesis:** Negative effect on Saturday crimes, null on weekday → small negative overall
- **Socialization hypothesis:** Negative effect persisting beyond service period
- **Criminogenic hypothesis (Galiani):** Positive effect if military exposure increases violence tolerance
- **Null:** No detectable effect if compliance/intensity too low (~40% treatment rate × ~6hrs/week)

## Primary Specification

Callaway-Sant'Anna or Sun-Abraham not needed here (no staggered adoption — the lottery operates annually within all states simultaneously). Standard two-way FE DiD with male×age-eligible interaction, clustering at state level (32 states).

## Feasibility Assessment

- ✅ Random assignment via lottery (gold standard)
- ✅ Data confirmed accessible (HTTP 200 in smoke tests)
- ✅ Large sample (~440,000 men per cohort; ~3,000 in ENVIPE per wave)
- ✅ Novel: zero papers use Sorteo for crime outcomes
- ⚠️ ITT design (not all drawn men actually attend)
- ⚠️ Male-female comparison requires parallel trends assumption across genders
- ⚠️ SESNSP data is aggregate (municipality level), can't link to individual lottery status
