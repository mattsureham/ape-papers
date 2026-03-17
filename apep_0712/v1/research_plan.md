# Research Plan: apep_0712

## Title
Abolishing Ground Rent and the Capitalization of Tenure Reform: Evidence from England's Leasehold Reform Act

## Research Question
How much of the leasehold price discount reflects capitalized ground rent obligations? Does abolishing ground rent for new leases produce an immediate, discontinuous price increase for leasehold flats?

## Identification Strategy

### Strategy 1 — Temporal RDD
Running variable: transaction date (days from June 30, 2022 cutoff). New-build leasehold flats completed just before vs. after the Leasehold Reform (Ground Rent) Act 2022.

**Key assumption**: Potential outcomes (flat prices absent the reform) are smooth through the cutoff date. Transactions cannot be precisely manipulated to fall on a specific day — completion dates depend on construction timelines, mortgage approvals, and chain logistics.

**Threats**:
- Anticipation from Royal Assent (Feb 8, 2022). Address with donut RDD excluding Feb-Jun 2022.
- Seasonal patterns. Address with year-over-year comparison and DiD.
- COVID recovery affecting leasehold vs freehold differently. DiD handles this.

### Strategy 2 — Difference-in-Differences
Treated: New-build leasehold flats. Control: New-build freehold houses (unaffected by ground rent ban). Before/after June 30, 2022.

### Strategy 3 — Triple-Difference
Add existing (non-new-build) leasehold flats as second control group. They retain original ground rent terms and are unaffected by the Act.

### Strategy 4 — Independent Replication
Retirement property cutoff (April 1, 2023) provides a second natural experiment with different timing.

## Expected Effects
Ground rent of £300/yr at 5% discount rate = ~£6,000 NPV over 99 years. Expect positive discontinuity of £3,000-£8,000 for leasehold flats at the cutoff (or 1-3% of average flat price). Effect should be larger for flats previously subject to doubling clauses.

## Primary Specification
Local linear regression with CCT optimal bandwidth, triangular kernel. Outcome: log(transaction price). Running variable: days from June 30, 2022.

## Data Sources
1. **HM Land Registry Price Paid Data** — Bulk CSV download. Universe of all residential property transactions in England and Wales since 1995. Fields: price, date, postcode, property type (D/S/T/F), new build flag (Y/N), duration (F=freehold, L=leasehold).
2. **postcodes.io** — Map postcodes to local authority, region for geographic controls.

## Analysis Plan
1. Download Land Registry PPD bulk data (2020-2024)
2. Filter to new-build properties; construct running variable (days from cutoff)
3. Run McCrary/rddensity test for manipulation
4. Covariate balance tests (property type composition, geographic distribution)
5. Main RDD: log(price) on treatment indicator with local linear regression
6. DiD: new-build leasehold vs new-build freehold, before/after June 2022
7. Triple-diff: add existing leasehold flats
8. Robustness: bandwidth sensitivity, polynomial orders, donut RDD, placebo cutoffs
9. Retirement property replication (April 2023 cutoff)
