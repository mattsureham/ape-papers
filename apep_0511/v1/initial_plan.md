# Initial Research Plan: Does 340B Drug Pricing Crowd Out Medicaid Patients?

## Research Question

Does 340B Drug Pricing Program eligibility change how hospitals allocate drug administration across payers — specifically, does it crowd out Medicaid drug administration relative to Medicare?

## Background

The 340B Drug Pricing Program allows eligible hospitals to purchase outpatient drugs at steep discounts (25-50% off). General acute care hospitals qualify when their DSH adjustment percentage exceeds 11.75%. The program generates approximately $44 billion in annual discounts (2022) and covers over 50% of US hospital outpatient drug purchases.

**The payer incentive asymmetry:** For non-Medicaid patients (Medicare, commercial), 340B hospitals profit from the spread between discounted acquisition cost and standard reimbursement. For Medicaid patients, the "duplicate discount prohibition" (Section 340B(a)(5)(A)) bars hospitals from using 340B prices if the state claims a Medicaid drug rebate on the same drug. Hospitals must choose: carve-in (use 340B for Medicaid, forgo rebates) or carve-out (don't use 340B for Medicaid). Either way, the Medicaid profit margin from drug administration is lower than for non-Medicaid patients.

**Prior work:** Nikpay, Buchmueller & Levy (2018, NEJM) used the DSH 11.75% threshold as an RDD to show 340B eligibility increases hospital-physician consolidation and total drug administration. Subsequent work (Desai & McWilliams 2018; Huang & Ketcham 2024) studied 340B effects on prescribing patterns and biosimilar uptake. **No study has examined the Medicaid-specific channel** — the payer for whom the duplicate discount prohibition explicitly limits 340B incentives.

## Identification Strategy

**Design:** Sharp Regression Discontinuity at DSH adjustment percentage = 11.75%

**Running variable:** Hospital DSH adjustment percentage, from CMS Hospital Cost Report (HCRIS) data. Continuous measure of hospital Medicaid/low-income patient share.

**Treatment:** 340B Drug Pricing Program eligibility (and participation — strong first stage documented by Nikpay et al.)

**Assumptions:**
1. No precise manipulation of DSH percentage around 11.75% (tested with McCrary density test + donut hole design)
2. No other policies create discontinuities at exactly 11.75% (tested with covariate balance)
3. Local continuity of potential outcomes at the threshold

**Key innovation:** Decompose the total drug administration effect by payer using T-MSIS (Medicaid) and Medicare PUF (Medicare) linked by NPI.

## Expected Effects and Mechanisms

**H1 (replication):** 340B eligibility increases Medicare/total drug administration (replicating Nikpay 2018 with newer data). Mechanism: 340B discount creates profit margin on drug administration for non-Medicaid patients.

**H2 (novel):** 340B eligibility has a smaller effect (or negative effect) on Medicaid drug administration. Mechanism: duplicate discount prohibition reduces the Medicaid profit margin, making Medicaid drug patients relatively less profitable.

**H3 (composition):** 340B eligibility decreases the Medicaid-to-Medicare drug billing ratio. This is the key cross-payer substitution test.

**H4 (heterogeneity):** Effects differ by carve-in vs. carve-out states. In carve-in states (hospital uses 340B for Medicaid), the profit margin on Medicaid drugs is higher → less crowding out.

## Primary Specification

```
Y_h = α + τ · 1(DSH_h ≥ 11.75) + f(DSH_h - 11.75) + X_h'β + ε_h
```

Where:
- Y_h = hospital h's Medicaid drug billing (J-codes from T-MSIS), or Medicare drug billing (from PUF), or the ratio
- DSH_h = hospital's DSH adjustment percentage
- f(·) = local polynomial (linear, with triangular kernel)
- X_h = hospital covariates (bed size, teaching status, ownership type, state)
- Bandwidth: CCT optimal, with robustness to half and double

**Unit of analysis:** Hospital (billing NPI) × year (average over months for annual analysis)

**Sample:** General acute care hospitals with DSH percentages within ±10pp of 11.75% threshold

## Planned Robustness Checks

1. **McCrary density test** at 11.75% (manipulation check)
2. **Donut hole:** Exclude hospitals within ±0.5pp of threshold
3. **Bandwidth sensitivity:** CCT optimal, half, double, and fixed 3pp/5pp/7pp
4. **Polynomial order:** Linear vs quadratic (Gelman & Imbens 2019: avoid higher order)
5. **Placebo cutoffs:** Test at 8%, 10%, 14%, 16% (no effect expected)
6. **Placebo outcomes:** Non-drug Medicaid billing (T/H/S codes), Medicare E&M codes
7. **Placebo hospitals:** Categorically eligible hospitals (CAH, rural referral) — no DSH threshold
8. **Covariate balance:** Hospital characteristics smooth through cutoff
9. **State fixed effects:** Control for state-level Medicaid policies
10. **Carve-in/carve-out heterogeneity:** Separate estimates by state 340B-Medicaid policy
11. **T-MSIS quality robustness:** Exclude states with poor DQ Atlas scores
12. **Time variation:** Estimate separately by year (2018-2024) to check stability

## Data Sources

| Source | Variables | Access |
|--------|-----------|--------|
| T-MSIS (local Parquet) | Medicaid drug billing by NPI × HCPCS × month | Pre-downloaded, 2.74 GB |
| CMS HCRIS | Hospital DSH adjustment %, bed size, teaching status, ownership | data.cms.gov, public |
| Medicare Physician/Supplier PUF | Medicare drug billing by NPI × HCPCS × year | data.cms.gov Socrata, public |
| HRSA OPAIS | 340B participating entities by NPI | 340bopais.hrsa.gov, public |
| NPPES | Provider geography, entity type, specialty | CMS bulk download, public |
| Census ACS | County demographics (poverty, uninsurance) | CENSUS_API_KEY |
| CMS DQ Atlas | State T-MSIS data quality scores | medicaid.gov, public |

## Exposure Alignment (for RDD)

- **Treated:** Hospitals with DSH % ≥ 11.75 (340B eligible)
- **Control:** Hospitals with DSH % < 11.75 (not 340B eligible)
- **Primary estimand:** Local average treatment effect at the threshold
- **Population:** General acute care hospitals near the 11.75% cutoff

## Power Assessment

- ~4,500 general acute care hospitals nationwide
- Estimated ~800-1,200 within ±5pp of threshold
- With CCT optimal bandwidth, effective sample likely 400-800
- MDE will be computed after observing outcome variance in the data
