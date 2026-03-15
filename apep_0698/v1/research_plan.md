# Research Plan: The Paycheck Protection Program and Nonprofit Employment

## Research Question
Does emergency fiscal policy designed for firms (PPP Second Draw) preserve nonprofit employment, or does it merely delay contraction? Nonprofits have fundamentally different revenue structures (donations, grants, fees, government contracts) than for-profits — does this make PPP more or less effective?

## Identification Strategy
**Fuzzy RDD at the 25% revenue decline threshold.** The PPP Second Draw (January 2021) required borrowers to demonstrate a 25% decline in gross receipts in any 2020 quarter relative to the same 2019 quarter. I observe annual revenue from IRS Form 990 filings and use the annual revenue decline as a noisy but informative proxy for the quarterly threshold.

- **Running variable:** Percentage change in total revenue from fiscal year 2019 to 2020, computed from IRS SOI 990 extracts.
- **Threshold:** -25% (organizations declining more than 25% are more likely to qualify for Second Draw).
- **Treatment:** Receipt of a Second Draw PPP loan (SBA ProcessingMethod = "PPS").
- **First stage:** Plot P(Second Draw | annual decline) to verify a discontinuity exists near -25%.

If the first stage is weak (annual → quarterly mapping too noisy), I fall back to a reduced-form analysis comparing employment trajectories by revenue decline bins.

## Expected Effects
1. **Employment preservation** (primary): Second Draw recipients should maintain higher employment counts through 2021-2023 relative to similar organizations that didn't receive Second Draw.
2. **Revenue composition shift**: PPP may crowd out fundraising effort (moral hazard) or crowd in by signaling viability.
3. **Delayed contraction hypothesis**: If PPP only delays adjustment, employment effects should fade by 2023-2024.

## Primary Specification
Fuzzy RDD estimated via `rdrobust` with CCT bandwidth selection:
- Y = log(employment) in 2021, 2022, 2023
- Treatment = Second Draw PPP receipt (instrumented by threshold crossing)
- Running variable = annual revenue decline 2019→2020
- Covariates: organization size (pre-pandemic), NTEE code, state

## Data Sources
1. **IRS SOI 990 Extracts** (2018-2023): Annual nonprofit financial data (~300K organizations/year). Key fields: EIN, name, state, zip, noemplyeesw3cnt (W-3 employee count), totrevenue, totfuncexpns, totcntrbgfts, progrevnue.
   - URL: https://www.irs.gov/statistics/soi-tax-stats-annual-extract-of-tax-exempt-organization-financial-data

2. **SBA PPP Loan-Level Data**: Complete loan-level records including BorrowerName, BorrowerAddress, BorrowerZip, BusinessType, LoanAmount, ProcessingMethod (PPP=First Draw, PPS=Second Draw), ForgivenessAmount.
   - URL: https://data.sba.gov/dataset/ppp-foia

## Matching Strategy
Link SBA PPP records to IRS 990 filings using standardized (uppercase, stripped punctuation) organization name + 5-digit ZIP code. Accept exact matches; flag partial matches for sensitivity analysis.

## Placebo/Mechanism Tests
1. **First Draw only recipients** (no threshold, applied before Second Draw existed): no jump expected at 25%.
2. **For-profit sector**: if available, compare to for-profit PPP patterns.
3. **Revenue composition**: decompose into contributions vs. program revenue vs. government grants.
4. **Organization size heterogeneity**: small (<50 employees) vs. large nonprofits.

## Feasibility Assessment
- IRS SOI 990 data: confirmed accessible (HTTP 200, ~50-60MB/year)
- SBA PPP data: public download (11 CSVs by loan amount range)
- Sample: ~300K organizations/year in 990 data; ~150K nonprofit PPP recipients
- Matching: name + ZIP should yield 60-80% match rate
