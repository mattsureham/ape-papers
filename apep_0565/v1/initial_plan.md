# Initial Research Plan: The Credential Cliff

## Research Question

Does crossing a matric pass-level threshold in South Africa causally increase tertiary enrollment, tertiary completion, employment, and earnings? If so, how large are the returns at each credential tier, and do they vary by gender, province, and school socioeconomic status?

## Identification Strategy

**Multi-cutoff sharp RDD.** South Africa's National Senior Certificate (matric) exam assigns learners to three hierarchical pass levels — Higher Certificate (30%), Diploma (40%), and Bachelor's (50%) — based on mechanically-applied subject-score thresholds. There is no discretion: a learner with a 4th-best 20-credit subject score of 49% cannot receive a Bachelor's pass; one with 50% can. This creates a textbook sharp RDD at three distinct cutoffs.

**Running variable:** At each cutoff, the running variable is the binding-constraint subject score — the subject that, if it crossed the threshold, would flip the pass determination.

**Built-in placebos:** The three cutoffs create natural cross-cutoff placebos. The Diploma/Higher Certificate boundary (which opens diploma-level access but not university) serves as a placebo for the Bachelor's/Diploma boundary (which opens full university access). Effects should be larger at the Bachelor's cutoff if the mechanism is university access.

## Expected Effects and Mechanisms

1. **Tertiary enrollment:** Strong positive effect at Bachelor's cutoff (university access), moderate at Diploma cutoff (diploma program access), small at Higher Certificate cutoff (TVET access only)
2. **Employment:** Positive effects through human capital channel (credential → tertiary education → better jobs)
3. **Earnings:** Positive effects, larger at Bachelor's cutoff, with possible credential signaling independent of skill
4. **Mechanism:** The paper distinguishes between human capital (the education obtained) and signaling (the credential label itself) by comparing effects across the three tiers

## Data Strategy

### Primary: DataFirst NSC Examination Microdata (2010-2016)
- Individual-level exam scores for ~600K+ learners/year
- Variables: school type, examination centre, subjects, grades, gender, district
- Provides the running variable for the RDD
- DOI: 10.25828/pcn8-pc32
- Access: Licensed (registration + Data Access Agreement)
- Format: Stata (.dta)

### Outcome Data
1. **NIDS** (National Income Dynamics Study) — Panel data, 5 waves (2008-2017), ~28K individuals. Self-reported matric pass type + employment + earnings. Public use from DataFirst.
2. **QLFS** (Quarterly Labour Force Survey) — Cross-sectional, ~200K respondents/quarter. Reports highest qualification by credential type. From Stats SA.
3. **DHS 2016** — Individual-level education and employment data accessible via API.
4. **World Bank / ILO** — Aggregate context data.

### Data Contingency Plan
If NSC individual microdata cannot be accessed programmatically:
- Use QLFS microdata with credential-type variation
- Employ doubly-robust (DR) estimation with rich controls
- Oster (2019) bounding for selection bias
- The institutional setting (mechanical assignment) still identifies the parameter of interest

## Primary Specification

At each cutoff c ∈ {30, 40, 50}:

Y_i = α + τ · D_i + β₁(X_i - c) + β₂ · D_i · (X_i - c) + ε_i

where:
- Y_i is the outcome (enrollment, employment, earnings)
- D_i = 1[X_i ≥ c] is the treatment indicator
- X_i is the running variable (binding subject score)
- τ is the causal effect of crossing the cutoff

Bandwidth: Calonico, Cattaneo & Titiunik (2014) MSE-optimal, with triangular kernel.
Inference: Bias-corrected robust confidence intervals.
Multi-cutoff pooling: Cattaneo, Titiunik & Vazquez-Bare (2020).

## Planned Robustness Checks

1. **McCrary density tests** at each cutoff (rddensity package)
2. **Covariate balance** — gender, school type, province, district smooth through cutoff
3. **Donut-hole RDD** — exclude observations within 1 point of cutoff
4. **Bandwidth sensitivity** — 2, 5, 8, 10 percentage point bandwidths
5. **Polynomial specifications** — local linear, local quadratic
6. **Placebo cutoffs** — test at non-threshold values (35%, 45%, 55%)
7. **Cross-cutoff placebos** — effects at one cutoff as placebo for another
8. **Heterogeneity** — by gender, province, school quintile (SES)
9. **Local randomization inference** — rdlocrand as alternative to continuity-based

## Power Assessment

- ~400,000 matric passers per year × 7 years = ~2.8 million observations
- Even within narrow bandwidths (±5 pp), expect >100,000 observations per cutoff
- With this sample size, MDE should be <1 percentage point for enrollment outcomes
- Power is not a concern for this design

## Key Risks

1. **Data access:** NSC microdata requires DataFirst licensing — may not be API-accessible
2. **Manipulation:** Low risk — centralized marking, Umalusi moderation. McCrary test will confirm.
3. **Compound treatment:** Crossing 50% changes both the credential AND the subject score marginally. The effect is credential access + marginal skill difference.
4. **Linking:** NSC → HEMIS link exists for 2008 cohort but may not be available for 2010-2016 cohorts without DataFirst facilitation.
