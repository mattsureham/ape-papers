# Research Plan: The Detection Gap — HMDA Reporting Exemptions and Minority Lending

## Research Question

Does removing public disclosure requirements change lender behavior toward minority borrowers? Specifically, did the EGRRCPA Section 104 partial HMDA reporting exemption (May 2018) — which exempted ~3,300 small depository institutions from reporting key mortgage data fields — lead to wider racial disparities in mortgage denial rates at newly exempt lenders?

## Policy Background

The Economic Growth, Regulatory Relief, and Consumer Protection Act (EGRRCPA, S.2155) was signed into law on May 24, 2018. Section 104(a) granted partial reporting exemptions to depository institutions that:
1. Originated fewer than 500 closed-end mortgage loans in each of the two preceding calendar years
2. Maintained a satisfactory or better CRA rating

Approximately 3,300 institutions (~40-45% of HMDA reporters) qualified, though they accounted for only ~5% of total loan volume. Exempt institutions were no longer required to report several expanded HMDA fields (interest rate, DTI, loan costs, etc.) but continued reporting core fields including: borrower race/ethnicity, income, census tract, action taken (approval/denial), loan amount, and lender identity.

## Identification Strategy

### Primary: Lender-level Difference-in-Differences

- **Treatment group:** Institutions that gained exempt status under EGRRCPA Section 104 (Exempt Flag = 1 in HMDA data, beginning 2018)
- **Control group:** Non-exempt institutions operating in the same counties
- **Pre-period:** 2018 (partial implementation year — exemption applies to 2018 data collected starting January 2018 but reported in 2019)
- **Post-period:** 2019-2022 (fully under the exemption regime)
- **Baseline:** 2014-2017 (old HMDA regime, before expanded fields; all institutions reported the same core fields)

Key equation:
```
Y_{ict} = α + β(Exempt_i × Post_t) + γ_i + δ_ct + ε_{ict}
```
Where:
- Y = minority denial rate gap (Black-White denial rate difference) at lender i in county c at time t
- Exempt_i = indicator for EGRRCPA-exempt lender
- Post_t = indicator for post-2018
- γ_i = lender fixed effects
- δ_ct = county × year fixed effects (absorb local market conditions)

**Clustering:** Two-way at lender and county level.

### Secondary: Census-tract-level DiD

Compare mortgage outcomes in tracts with high vs. low pre-treatment exempt-lender market share. This tests whether market-level oversight gaps (not just lender behavior) affect equilibrium lending patterns.

### Robustness

1. **Bunching test:** Check for strategic bunching below the 500-origination threshold (McCrary density test)
2. **Placebo:** Use White-White comparisons (no expected treatment effect)
3. **Dose-response:** Interact treatment with share of tract lending from exempt institutions
4. **Event study:** Year-by-year treatment effects to verify parallel pre-trends

## Expected Effects and Mechanisms

**Primary hypothesis:** Exempt lenders increase racial denial rate disparities post-exemption. The mechanism is reduced oversight pressure — when detailed pricing data is no longer publicly disclosed, the expected cost of discriminatory lending (regulatory scrutiny, fair lending lawsuits, CRA reputation) decreases.

**Alternative hypotheses:**
- Null effect: small lenders already operate below the regulatory radar, so exemption changes nothing
- Negative effect (narrowing gap): reduced compliance burden allows small lenders to serve more minority borrowers
- Composition effect: minority borrowers sort away from exempt lenders toward non-exempt lenders with more transparent pricing

## Primary Specification

Main outcome: Black-White denial rate gap at the lender-county-year level

Secondary outcomes:
1. Hispanic-White denial rate gap
2. Log loan amount by race
3. Minority loan application volume (extensive margin)
4. Tract-level minority lending share

## Data Sources

### Primary: HMDA Loan Application Register (CFPB)
- **Source:** CFPB HMDA Data Browser API / bulk download
- **Years:** 2018-2022 (new format with exempt flag); 2014-2017 (old format for pre-trends)
- **Unit:** Individual loan application
- **Key variables:** action_taken, derived_race, lei, county_code, loan_amount, activity_year, exempt flag
- **Size:** ~6-8 million records per year

### Fetch Strategy

1. Download HMDA bulk files (CSV) from CFPB for 2018-2022 (new format includes exempt indicator)
2. Download HMDA bulk files for 2014-2017 (old format — all lenders reported same fields)
3. For old-format years, identify would-be-exempt lenders using origination counts < 500
4. Construct lender-county-year panel with denial rates by race

## Sample Restrictions

- First-lien, 1-4 family, site-built, owner-occupied home purchase loans (conventional)
- Exclude FHA/VA/USDA (government-insured programs with separate underwriting)
- Exclude applications withdrawn or incomplete
- Require county to have ≥ 1 exempt and ≥ 1 non-exempt lender
