# Initial Research Plan: Does Naming Work?

## Research Question

Does mandatory display of food hygiene ratings reshape food market structure through information-driven market discipline? Specifically, does requiring food businesses to publicly display their hygiene ratings increase exit rates of low-quality establishments, deter entry of low-quality operators, and improve average food safety standards?

## Policy Setting

The United Kingdom's Food Hygiene Rating Scheme (FHRS) rates food establishments 0–5 based on hygiene inspections. In November 2013, Wales became the first UK nation to mandate public display of these ratings (Food Hygiene Rating (Wales) Act 2013). Northern Ireland followed in October 2016. England has maintained voluntary display throughout, with compliance at ~69% vs. ~92% in Wales.

This cross-national policy variation creates a natural experiment: identical rating system, identical inspection criteria, but different display mandates.

## Identification Strategy

### Primary Design: Two-Cohort Staggered DiD

- **Cohort 1:** 22 Welsh unitary authorities (treated November 28, 2013)
- **Cohort 2:** 11 Northern Irish district councils (treated October 7, 2016)
- **Never-treated:** ~300 English local authorities
- **Unit of analysis:** Local authority × quarter (or month)
- **Estimator:** Callaway & Sant'Anna (2021) with never-treated as comparison group

### First Stage (Bite Check)

Display compliance: FSA audit data shows 92% mandatory display in Wales vs. 69% voluntary in England — a 23 percentage point "first stage."

### Placebo / Falsification Tests

1. **Non-food businesses** in treated LAs (shouldn't respond to FHRS mandate)
2. **Food manufacturers/wholesalers** (B2B, no consumer-facing display)
3. **Pre-trend tests** on all outcome variables
4. **Randomization inference** permuting treatment across LAs

### Triple-Diff

Country × post-treatment × food business (vs. non-food business in same LA). The non-food dimension absorbs country-specific trends that affect all businesses.

## Expected Effects and Mechanisms

### Information Channel
Mandatory display → consumers observe quality → demand shifts toward high-quality firms

### Predictions
1. **Exit rates:** Increase for low-rated firms (0–2); no change for high-rated (4–5)
2. **Entry rates:** Decrease overall (deterrence of low-quality entrants) or composition shift toward higher initial quality
3. **Average rating:** Improvement through selection (exit of bad) and upgrading (existing firms improve)
4. **Rating distribution:** Left-tail compression — fewer 0–2 ratings, more 4–5 ratings

### Competing Hypothesis
If display is merely performative (consumers don't actually respond), we should see no differential effects on exit/entry/quality.

## Primary Specification

$$Y_{lt} = \alpha + \beta \cdot \text{MandatoryDisplay}_{lt} + X_{lt}\gamma + \mu_l + \lambda_t + \varepsilon_{lt}$$

Where:
- $Y_{lt}$ = outcome in local authority $l$ at time $t$
- $\text{MandatoryDisplay}_{lt}$ = 1 if LA $l$ is in a mandatory-display jurisdiction at time $t$
- $\mu_l$ = LA fixed effects
- $\lambda_t$ = time (quarter-year) fixed effects
- $X_{lt}$ = time-varying controls (population, economic conditions)
- Clustering at LA level

## Planned Robustness Checks

1. **CS-DiD** (Callaway & Sant'Anna 2021) with cohort-specific ATTs
2. **HonestDiD** sensitivity to pre-trend violations (Rambachan & Roth 2023)
3. **Border design:** Restrict to Welsh LAs adjacent to English LAs
4. **Event study:** Dynamic effects with leads/lags for both cohorts
5. **Wild cluster bootstrap** for inference with 22 Welsh clusters
6. **Heterogeneity by urbanity:** Urban vs. rural LAs
7. **Heterogeneity by baseline quality:** LAs with many low-rated vs. high-rated firms pre-treatment
8. **Dose-response:** Using local display rate as continuous treatment (voluntary vs. mandatory)

## Data Sources

| Source | Variables | Coverage | Access |
|--------|-----------|----------|--------|
| Companies House bulk | Incorporation date, dissolution date, SIC code, postcode | All UK firms, 1844–present | Free CSV download |
| FSA FHRS API | Hygiene rating, inspection date, business type, location | 586K establishments, England/Wales/NI | Free API, no key |
| Land Registry PPD | Property prices, type, postcode | 24M+ transactions, 1995–present | Free CSV download |
| NOMIS | Employment, population by LA | LA-level annual | Free API |
| postcodes.io | Postcode → LSOA/LA geocoding | Full UK | Free API |

## Power Assessment

- **Treated clusters:** 22 (Wales) + 11 (NI) = 33
- **Control clusters:** ~300 (England)
- **Pre-treatment periods:** ~20 quarters (2008Q1–2013Q3 for Wales)
- **Post-treatment periods:** ~48 quarters (2013Q4–2025Q4 for Wales)
- **Within-cluster observations:** ~200–2,000 food businesses per LA
- **Total food establishments:** ~586,000

With 22 treated clusters, standard cluster-robust inference should be adequate, though we supplement with wild cluster bootstrap. The large number of establishments per LA gives substantial within-cluster variation for detecting economically meaningful effects.

**MDE estimate:** With 22 treated and 300 control LAs, quarterly observations over 12+ years, and baseline food business exit rate of ~8% annually, the MDE at 80% power is approximately 0.5–1.0 percentage points on exit rates — sufficient to detect economically meaningful market discipline effects.

## Exposure Alignment (DiD)

- **Who is actually treated?** Food businesses in Wales (from Nov 2013) and NI (from Oct 2016) required to publicly display hygiene ratings
- **Primary estimand population:** Food service establishments (restaurants, cafés, pubs, takeaways) — SIC 56.xx
- **Placebo/control population:** Non-food businesses in same LAs (manufacturing, retail non-food, professional services)
- **Design:** Standard two-cohort staggered DiD + triple-diff (food vs. non-food)
