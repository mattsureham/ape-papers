# Research Plan: The Exit Option: Medical Aid in Dying Laws and End-of-Life Medicare Spending

## Research Question
Does the legalization of Medical Aid in Dying (MAID) reshape end-of-life Medicare spending composition — shifting resources from acute inpatient care toward hospice — even among patients who never use MAID?

## Identification Strategy
**Staggered Difference-in-Differences (Callaway-Sant'Anna 2021)**

Treatment: State-level MAID legalization in the 2016–2021 wave.
- California (June 2016), Colorado (December 2016), DC (February 2017), Hawaii (January 2019), New Jersey (August 2019), Maine (September 2019), New Mexico (June 2021)
- Always-treated (pre-sample adoption): Oregon (1997), Washington (2009), Montana (2009 court ruling), Vermont (2013)
- Never-treated: ~40 remaining states

Unit of analysis: County-year (CMS Geographic Variation PUF, county-level file)
Sample period: 2014–2022 (up to 7 pre-treatment years for earliest adopters)

Key threats:
1. Differential pre-trends in health spending → event study + HonestDiD sensitivity
2. Few treated clusters (7 states) → wild cluster bootstrap (Roodman et al. 2019)
3. Concurrent state health policies → triple-difference with non-terminal Medicare spending as within-state control

## Expected Effects and Mechanisms
**Primary mechanism:** "Exit option" cultural spillover. MAID legalization normalizes end-of-life planning conversations, increases advance directive completion, and shifts provider norms toward palliative care — even for patients who never request lethal medication.

Expected signs:
- Hospice spending per capita: **increase** (more enrollment, earlier enrollment)
- Inpatient acute spending per capita: **decrease** (fewer aggressive interventions)
- Total spending per capita: **decrease or null** (substitution, not addition)
- ER visits per 1000: **decrease** (fewer crisis-driven end-of-life interventions)

## Primary Specification
ATT(g,t) via Callaway-Sant'Anna, where g = cohort (state adoption year), t = calendar year.
- Outcome: standardized Medicare spending components per capita (county-year)
- Clustering: state level (treatment level)
- Inference: wild cluster bootstrap (7 treated states is sparse for asymptotic cluster-robust SEs)
- Robustness: (1) drop always-treated states, (2) exclude counties near state borders, (3) HonestDiD bounds, (4) placebo: non-terminal spending categories (e.g., diabetes management, orthopedic)

## Data Source and Fetch Strategy
**CMS Medicare Geographic Variation Public Use File (County-Level)**
- URL: https://data.cms.gov (free download, no API key needed)
- Years: 2014–2022
- Key variables: BENE_AVG_AGE, HOSPC_MDCR_STDZD_PYMT_PC, HOSPC_MDCR_PYMT_PCT, IP_MDCR_STDZD_PYMT_PC, ACUTE_MDCR_STDZD_PYMT_PC, ER_VISITS_PER_1000, TOT_MDCR_STDZD_PYMT_PC
- ~3,200 counties × 9 years ≈ 28,800 observations
