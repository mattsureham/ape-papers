# Research Plan: Fair Bills, Slow Care? State Surprise Billing Laws and Emergency Department Quality

## Research Question

Do state surprise billing protections degrade emergency department quality of care? If PE-owned staffing firms relied on out-of-network billing as a revenue strategy, mandated balance billing protections may have triggered cost-cutting that increased ED wait times and patient abandonment.

## Identification Strategy

**Callaway-Sant'Anna staggered DiD** exploiting the staggered adoption of comprehensive state surprise billing laws across 9+ states between 2015 and 2019.

**Treatment definition:** A state has a "comprehensive" surprise billing law if it:
1. Prohibits or caps out-of-network balance billing for emergency services
2. Establishes a payment standard or dispute resolution mechanism (arbitration, reference pricing)

**Treatment timing (based on effective dates):**
- 2015: New York (binding arbitration), Connecticut
- 2016: Florida
- 2017: California (AB 72)
- 2018: Illinois, Maryland, New Hampshire, New Jersey, Oregon

**Control group:** Never-treated states (no comprehensive law through 2019). States with partial protections (disclosure-only, narrow scope) are excluded or coded as untreated.

**Key identifying assumption:** Absent the surprise billing law, ED quality in treated states would have followed the same trajectory as in never-treated states. We test this with 3-6 pre-treatment periods.

## Expected Effects and Mechanisms

**Primary hypothesis:** Surprise billing laws reduced ED staffing firms' revenue → cost-cutting → longer wait times and higher LWBS rates.

**Mechanism:** PE-owned ED staffing firms (TeamHealth/Blackstone, Envision/KKR — covering 25-40% of US EDs) used out-of-network billing as a revenue strategy. Surprise billing laws eliminated this margin. Envision Healthcare filed for bankruptcy in 2023, citing state and federal surprise billing regulations.

**Expected direction:** Positive effect on wait times (longer), positive effect on LWBS rates (more patients leaving).

**Alternative:** Laws could improve quality if they reduce provider churn or financial distress for patients.

## Primary Specification

Y_{h,s,t} = α_h + γ_t + β × SurpriseBillingLaw_{s,t} + X'_{h,t}δ + ε_{h,s,t}

- h = hospital, s = state, t = year
- Y = OP-18b (ED median time to discharge) or OP-22 (LWBS rate)
- CS-DiD ATT with state-level clustering
- Never-treated states as controls

## Exposure Alignment

**Who is actually affected by treatment:** State surprise billing laws apply to state-regulated (fully insured) commercial insurance plans. They do NOT apply to self-insured (ERISA) employer plans, which cover roughly 60% of commercially insured individuals. The treatment thus directly protects approximately 40% of commercially insured ED patients in each treated state. Medicare and Medicaid patients are unaffected (already have out-of-network protections). The unit of analysis (hospital-year) captures average quality across all payers, meaning the treatment effect is diluted by the share of patients not subject to the law. This is an intent-to-treat design at the hospital level; the effect on the directly protected population may be larger. Ownership type (for-profit vs nonprofit) proxies for PE staffing firm penetration but is not a precise measure of hospital-level exposure to the billing regulation.

## Robustness

1. **Event study:** Pre-treatment coefficients should be flat
2. **HonestDiD bounds:** Rambachan-Roth sensitivity to pre-trend violations
3. **Bacon decomposition:** Verify clean comparisons drive the estimate
4. **Placebo outcomes:** Inpatient measures (not directly affected by ED staffing) as falsification
5. **Wild cluster bootstrap:** For inference with ~40 state clusters

## Falsification / Mechanism Tests

1. **ERISA falsification:** Hospitals with high self-insured (ERISA) patient share should show no effect — state laws don't bind for ERISA plans
2. **Inpatient placebo:** Inpatient mortality/readmission rates (not affected by ED staffing changes)

## Data Sources

1. **CMS Hospital Compare — Timely and Effective Care** (primary)
   - Hospital-level quality measures: OP-18b (ED median time), OP-22 (LWBS rate)
   - Annual archives at NBER: `data.nber.org/compare/hospital/YYYY/`
   - Current data via CMS API
   - ~4,500 hospitals/year with ED measures

2. **CMS Hospital Compare — General Information** (covariates)
   - Hospital type, ownership (for-profit, nonprofit, government)
   - Emergency services indicator
   - Bed count, teaching status

3. **Surprise billing law coding** (constructed)
   - Comprehensive vs partial classification from legal literature
   - Effective dates from state statute databases

## Sample

- Units: ~4,500 hospitals with ED measures per year
- Period: 2012-2019 (pre-pandemic, 8 years)
- Treated states: 9 states (2015-2018 staggered)
- Never-treated: ~30 states without comprehensive laws through 2019
- Total: ~36,000 hospital-year observations
