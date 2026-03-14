# Research Plan: The Credit Boundary — Flood Insurance Mandates and Mortgage Market Segmentation

## Research Question

Does mandatory flood insurance in FEMA-designated Special Flood Hazard Areas (SFHAs) ration mortgage credit, and does this burden fall disproportionately on low-income and minority applicants?

## Policy Background

The National Flood Insurance Act (42 U.S.C. §4012a) requires any federally regulated lender to condition mortgage origination on flood insurance purchase for buildings within a Special Flood Hazard Area. This mandate is binary: inside SFHA = mandatory insurance; outside = no requirement. FEMA periodically revises flood maps, but the average map is 8+ years old. Flood insurance premiums can add $1,000–$5,000+ annually to housing costs, effectively raising the debt-to-income ratio for borrowers in designated zones.

## Identification Strategy

**Within-county cross-sectional design:** Exploit tract-level variation in FEMA flood risk exposure within the same county. County fixed effects absorb local housing market conditions, lending practices, and macroeconomic shocks. The treatment intensity is the FEMA National Risk Index (NRI) flood risk score at the census tract level.

**Key assumptions:**
1. Within a county, flood risk assignment is determined by topography and hydrology (not borrower selection)
2. Conditional on county and applicant characteristics, remaining variation in flood exposure is quasi-random
3. FEMA maps are updated infrequently (8+ year average), so current designation reflects historical risk assessment, not current borrower sorting

**Mechanism test:** The flood insurance mandate should increase debt-to-income burden but not affect creditworthiness. We test this by decomposing denial reasons:
- DTI-ratio denials should increase in flood zones (insurance raises monthly costs)
- Credit-history denials should not (flood zone doesn't affect credit scores)
- This internal contrast isolates the cost-burden channel from general risk pricing

## Expected Effects

1. **Extensive margin:** Higher flood risk → higher mortgage denial rates
2. **Intensive margin:** Higher flood risk → higher interest rates on originated loans
3. **Heterogeneity by income:** Effect concentrated among low-income applicants (cannot absorb insurance costs)
4. **Heterogeneity by race:** Minority-majority tracts face compounded impact (SFHAs overlap disproportionately with minority communities)
5. **Mechanism:** DTI-ratio denials increase; credit-history denials unaffected

## Primary Specification

Individual-level linear probability model (LPM):

```
Denied_i = β × FloodRisk_t(i) + γ × X_i + δ_c + ε_i
```

Where:
- `Denied_i`: binary (1 = denied, 0 = originated)
- `FloodRisk_t(i)`: FEMA NRI riverine+coastal flood risk score for tract t
- `X_i`: applicant income, loan amount, property value, loan-to-value ratio, loan purpose
- `δ_c`: county fixed effects
- Standard errors clustered at tract level

## Data Sources

| Source | Data | Access |
|--------|------|--------|
| CFPB HMDA | Individual mortgage applications, FL 2022 | Data Browser CSV download |
| FEMA NRI | Tract-level flood risk scores | CSV download from hazards.fema.gov |
| Census ACS 5-yr | Tract demographics (income, race, housing units) | tidycensus R package |

## Sample

- **State:** Florida (highest SFHA exposure nationally, ~67 counties)
- **Year:** 2022 (most recent full HMDA year with complete data)
- **Applications:** ~250K–400K purchase + refinance mortgage applications
- **Tracts:** ~5,000 Florida census tracts with NRI scores

## Tables Plan (max 5 + SDE appendix)

1. **Table 1:** Summary statistics by flood risk quartile
2. **Table 2:** Main results — denial rates and interest rates
3. **Table 3:** Mechanism — denial reason decomposition (DTI vs. credit history vs. collateral)
4. **Table 4:** Heterogeneity by applicant income
5. **Table 5:** Heterogeneity by tract racial composition
- **Table F1 (appendix):** Standardized effect sizes
