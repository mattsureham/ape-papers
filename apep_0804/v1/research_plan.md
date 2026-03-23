# Research Plan: The Caregiving Tax

## Research Question
Do state autism insurance mandates increase maternal labor supply? Mandates that require private insurers to cover ASD therapies (ABA, speech, OT) reduce the caregiving burden on mothers of children with autism, potentially freeing them to enter or expand participation in the labor market.

## Identification Strategy
**Triple-difference DiD** exploiting three sources of variation:
1. **Cross-state**: Staggered mandate adoption by 46 states (2001–2015)
2. **Over time**: Before vs. after mandate effective date
3. **Within-state**: Mothers of children with cognitive difficulty (ACS DREM=1) vs. mothers of children without

The DDD estimand: β from Y_sgt = α_sg + δ_gt + γ_st + β(Post_st × DREM_g) + ε_sgt

This absorbs: state × group time-invariant differences, national group-specific trends, and state × year shocks common to both groups. The identifying assumption is that differential trends between DREM=1 and DREM=0 mothers would have been parallel absent the mandate.

**Secondary**: Callaway-Sant'Anna (2021) staggered DiD estimated separately for DREM=1 mothers, using never-treated states as comparison.

## Expected Effects
- **Positive** effect on maternal employment probability (primary)
- **Positive** effect on weekly hours worked
- **Positive** effect on annual wages/earnings
- Mechanism: mandate → insurance covers therapy → professional therapists provide care → mothers freed from full-time caregiving → labor supply increases

## Primary Specification
Individual-level regression using fixest:
- Outcome: employed (binary), hours, log wages
- FE: state × DREM group, year × DREM group, state × year
- Cluster: state level (50 clusters)
- Weight: ACS person weights (PWGTP)

## Data Source
**American Community Survey (ACS) 1-Year PUMS, 2008–2019**
- Person-level microdata with household linkage via SERIALNO
- Children 5–17 identified by AGEP; cognitive difficulty via DREM
- Mothers identified as adult women (SEX=2, AGEP 25–54) in reference person or spouse role
- Outcomes: ESR (employment), WKHP (hours/week), WAGP (wages)
- ~100K–150K mother-year observations for DREM=1 group; much larger comparison group

## Mandate Adoption Dates
Compiled from Chatterji et al. (2015 JPAM), Autism Speaks legislative database, NCSL. 46 states adopted between 2001 and 2015. Never-treated: AL, AK, ID, WY (as of 2015).

## Robustness
1. Event study (year-by-year DDD coefficients)
2. CS (2021) for DREM=1 group separately
3. Bacon decomposition
4. Placebo: physical disability (DPHY=1) — mandates target cognitive/behavioral therapy, not physical disability services
5. Alternative age cuts for mothers and children
6. Heterogeneity by mandate generosity (dollar cap) and mother's education
