# Research Plan: The Education Cliff — Age-Based Benefit Discontinuities and Labor Market Outcomes in Denmark

## Research Question
Does the sharp age-30 benefit reduction in Denmark's 2014 Uddannelseshjælp reform — which cuts monthly welfare from ~DKK 10,600 to ~DKK 6,000 for under-30s — push young adults into employment or education?

## Identification Strategy
**Age-based RDD.** The 2014 reform created a sharp discontinuity at age 30: recipients under 30 receive ~43% less in monthly benefits than those 30+. Using single-year-of-age data from DST Statbank, I estimate a regression discontinuity around the age-30 cutoff, comparing welfare take-up, employment, and education enrollment for cohorts just below vs. just above 30.

The running variable is age (in years). The treatment is receiving the lower "youth" benefit rate. The key identifying assumption is that individuals born just before vs. after the age-30 threshold are comparable on unobservables.

## Expected Effects
- **Welfare take-up:** Lower benefits for under-30s should reduce welfare participation (substitution toward employment/education)
- **Employment:** Positive effect — lower replacement rate increases job search intensity
- **Education enrollment:** Ambiguous — reform explicitly incentivizes education, but lower income may also discourage it
- **Mechanism:** "Stick" effect (lower benefits push people out) vs. "carrot" effect (education subsidies pull people in)

## Primary Specification
Y_a = α + β·1(age < 30) + f(age - 30) + X_a'γ + ε_a

Where Y_a is the outcome for age group a, 1(age < 30) is the treatment indicator, f(·) is a polynomial in age centered at 30, and X_a are year fixed effects.

## Data Source
- **Statistics Denmark (DST) Statbank API** — public, no registration
- Tables: AUF03 (welfare recipients by age), AUK40/related (education enrollment by age), RAS200/LBESK01 (employment by age)
- Unit: age × year cells
- Years: 2010-2024 (pre/post reform in January 2014)
- Bandwidth: ages 20-40, with optimal bandwidth selection around the cutoff

## Exposure Alignment
The treatment (lower Uddannelseshjælp rate) applies to all welfare recipients under 30. The 25-29 age bin captures individuals who are directly exposed to the reduced benefit when they claim social assistance post-2014. The 30-34 control group is never exposed. Both groups are measured at the same calendar dates, so the treatment-timing alignment is exact: the reform applies universally from January 2014, and the age cutoff is administrative (date of birth), not behavioral.

Key concern: the 25-29 bin includes individuals who age into the 30-34 bin during the study period. In aggregate age-bin data, this creates flow between treatment and control, attenuating the DiD estimate toward zero. The estimate is therefore conservative.

## Robustness
1. Different polynomial orders (linear, quadratic)
2. Different bandwidths (±3, ±5, ±7 years)
3. Placebo cutoffs at ages 25, 35
4. Pre-reform (2010-2013) falsification — no discontinuity expected before reform
5. Donut RDD excluding age 30 exactly
