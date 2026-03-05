# Reply to Reviewers - apep_0529 v1

## Reviewer 1 (GPT-5.2): MAJOR REVISION

### Issue 1: Causal vs. descriptive framing given violated pre-trends
**Response:** We agree that the parallel trends violation limits causal interpretation. The paper already frames the TWFE as a "biased benchmark" and the CS-DiD as absorbing pre-existing trends. For v2, we will add Rambachan-Roth (2023) honest DiD bounds to formally assess sensitivity to pre-trend violations.

### Issue 2: Treatment measurement (binary vs. binding/vigilance)
**Response:** Valid concern. For v2, we will code enforcement regime (effectif vs. vigilance) and re-estimate with binding-only treated units. This would restrict Wave 1 to Paris and Lyon (the only fully binding ZFEs by late 2024).

### Issue 3: Additional identification strategies
**Response:** We will explore the 150,000 population threshold for RDD analysis and consider synthetic control matching on pre-treatment ENP trajectories.

---

## Reviewer 2 (Grok-4.1-Fast): MAJOR REVISION

### Issue 1: Pre-trends and robust estimators
**Response:** We will add CS-DiD with trend interactions and report MDE calculations. The null ENP result will be explicitly contextualized: with SE=0.141, the MDE is approximately 0.28 (2x SE), meaning only effects above ~0.3 ENP points would be detectable.

### Issue 2: Short post-period
**Response:** We will report cohort-specific ATTs separately (2022 cohort has 2 post-periods, 2024 cohort has 1). We acknowledge the 2024 snap election introduces confounding.

### Issue 3: Binding vs. vigilance disaggregation
**Response:** Addressed jointly with GPT reviewer's Issue 2.

---

## Reviewer 3 (Gemini-3-Flash): MAJOR REVISION

### Issue 1: Selection into treatment and balance
**Response:** We will add a pre-treatment balance table using INSEE commune-level demographics (income, education, population density, car ownership rates).

### Issue 2: Residential sorting
**Response:** We will use census data (2017 vs. 2021 comparisons) to check whether ZFE constituency demographics changed differentially. If sorting is present, the RN decline estimate will be explicitly noted as an upper bound.

### Issue 3: Heterogeneity by stringency
**Response:** Addressed jointly with enforcement coding in Issue 2 of GPT review.
