# Research Plan: The Formality Tax — Mexico's Vacation Mandate and the Informal-Sector Escape Valve

## Research Question

Does mandating more generous vacation benefits for formal-sector workers push employment toward informality? Mexico's January 2023 "Vacaciones Dignas" reform doubled minimum vacation days from 6 to 12 for workers with one year of tenure, providing a clean test of the informality margin response to non-wage benefit mandates.

## Identification Strategy

**Difference-in-Differences.** Treated: formal-sector workers (written contract, IMSS enrollment). Control: informal-sector workers (no contract, no social security). Treatment onset: January 1, 2023. Pre-period: Q1 2019–Q4 2022 (16 quarters). Post-period: Q1 2023–Q4 2024 (8 quarters).

**Triple-difference.** Among formal workers, those in high-informality sectors (retail, construction, agriculture — where switching to informality is easy) vs. formal workers in low-informality sectors (finance, utilities, public administration — where the formal premium is large and exit costs are high).

**Seniority gradient.** The reform's proportional bite varies by tenure: 100% increase for 1-year workers (6→12 days) but ~50% for long-tenure workers (16→24 days). This provides within-treatment dose variation orthogonal to concurrent minimum wage changes.

## Expected Effects and Mechanisms

**Lazear (1990) channel:** Mandated benefits raise the cost of formal employment → firms adjust by (a) reducing formal hiring, (b) shifting to informal arrangements, or (c) cutting wages to offset. If binding, we expect declining formality rates and increased formal-to-informal transitions.

**Gruber (1994) channel:** If workers value vacation above its cost, the mandate is welfare-improving and full incidence falls on wages. Formality rates remain stable or increase, but wages may decline.

**Predicted magnitudes:** Given Mexico's ~56% informality rate (the margin is active), even small compliance cost changes could shift workers. But vacation days are a relatively low-cost benefit compared to social security contributions (~35% of wage). Effect may be small — a well-powered null would be informative.

## Primary Specification

Y_{ist} = α + β(Formal_i × Post_t) + γ Formal_i + δ Post_t + X_{ist}θ + μ_s + ε_{ist}

Where:
- Y: hours worked / formal-to-informal transition / formality indicator
- Formal: ILO-criteria formal employment
- Post: Q1 2023 onward
- X: age, education, sex, sector
- μ_s: state fixed effects
- Clustering: state level (32 clusters)

## Data Source and Fetch Strategy

**ENOE (Encuesta Nacional de Ocupación y Empleo)** — INEGI's quarterly labor force survey.
- ~300,000 individuals aged 15+ per quarter
- Rotating panel (5 consecutive quarters per household)
- Freely downloadable CSVs from INEGI website
- Key variables: formal/informal status, hours, wages, sector, tenure, state

**Download:** 24 quarterly ZIPs (Q1 2019–Q4 2024), extract needed variables, combine.

## Key Risks

1. **Concurrent minimum wage increases:** Mexico raised minimum wages substantially in 2023-2024. Mitigation: informal workers also affected by MW; seniority gradient is orthogonal to MW.
2. **COVID recovery confound (2020-2021):** Mitigation: event study showing pre-trends, excluding COVID quarters in robustness.
3. **Compliance enforcement:** If enforcement is weak, the reform may not bite. This is testable — if no hours reduction among formal workers, the reform may not be binding.
