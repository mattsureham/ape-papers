# Research Plan: The Access Cost of Fraud Prevention — WIC EBT Mandates, Vendor Exits, and Infant Health

## Research Question
Did the staggered adoption of Electronic Benefit Transfer (EBT) for the WIC program — mandated by the Healthy, Hunger-Free Kids Act of 2010 — reduce infant health outcomes by driving independent WIC vendors out of business?

## Motivation
The WIC program serves 6.3 million participants annually, including 1.5 million pregnant and postpartum women. Meckel (AER 2020) documented that WIC EBT adoption increased independent vendor dropout by 5.4 percentage points, as small retailers lost profit margins from WIC fraud. Yet no study has traced this infrastructure loss to downstream health effects. If vendor exits reduced nutritional access for pregnant women, the EBT mandate — designed to reduce fraud — inadvertently harmed the population it aimed to serve.

## Identification Strategy
**Primary: Staggered DiD** using state-level WIC EBT adoption dates (2004-2020) with Callaway-Sant'Anna estimator. Treatment: binary indicator for state having adopted WIC EBT. Outcomes: state-year birth outcomes from CDC natality data.

**Intensity variation:** Interact EBT adoption with pre-EBT independent vendor share (from USDA FNS WIC vendor data). States with more independent vendors had greater exposure to the EBT-induced consolidation shock.

**Placebo outcomes:** Births to non-WIC-eligible mothers (proxied by high-income/high-education mothers), male birth weight (not nutrition-sensitive in the same way as low birth weight), and non-nutritional birth complications.

## Expected Effects and Mechanisms
- EBT adoption → independent WIC vendor exit (documented by Meckel 2020)
- Vendor exit → increased travel distance to WIC-authorized stores
- Increased travel costs → reduced WIC participation among pregnant women
- Reduced nutrition assistance → lower birth weight, higher preterm rate
- Effect should be concentrated in rural areas and among WIC-eligible populations

## Primary Specification
$$Y_{st} = \alpha_s + \gamma_t + \beta \cdot \text{EBT}_{st} + \epsilon_{st}$$

Where $Y_{st}$ is the birth outcome in state $s$, year $t$; $\text{EBT}_{st}$ is an indicator for state $s$ having adopted WIC EBT by year $t$. State and year fixed effects absorb level differences and common trends. Standard errors clustered at the state level.

Callaway-Sant'Anna group-time ATTs aggregate to an overall effect with proper weighting for staggered adoption.

## Data Sources
1. **WIC EBT adoption dates:** FNS/USDA WIC EBT status reports — state × year rollout timeline
2. **Birth outcomes:** CDC WONDER Natality data — state-level birth weight, preterm rate, low birth weight rate, breastfeeding initiation (2003-2023)
3. **WIC participation:** USDA FNS WIC Program data — state × year participant counts
4. **Controls:** State demographics from Census ACS (poverty rate, unemployment, female population 15-44)

## Key Risks
- **Attenuation from state-level aggregation:** Birth outcomes are noisy at state level; county-level would be better but CDC WONDER restricts county identifiers for small cells
- **Confounding policies:** Medicaid expansion, ACA rollout overlap with EBT adoption window — need to control for these or use triple-diff
- **Null result:** Ambrozek et al. (NBER 2025) found no aggregate WIC redemption effect — health effects may also be null. A well-powered null is still publishable if we can rule out economically meaningful effects.
