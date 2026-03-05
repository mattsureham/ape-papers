# Research Ideas

## Idea 1: Does 340B Drug Pricing Crowd Out Medicaid Patients? Cross-Payer RDD Evidence from Provider-Level Claims

**Policy:** The 340B Drug Pricing Program (Section 340B of the PHS Act) allows eligible hospitals to purchase outpatient drugs at steep discounts (25-50% off). General acute care hospitals qualify when their DSH adjustment percentage ≥ 11.75%. The program creates differential profit incentives by payer: hospitals profit from 340B discounts on non-Medicaid patients, but the "duplicate discount prohibition" bars them from stacking 340B discounts with Medicaid drug rebates. This creates an incentive to administer drugs more intensively to non-Medicaid patients relative to Medicaid patients.

**Outcome:** (a) Medicaid drug administration billing (J-codes) from T-MSIS at the hospital NPI level, monthly 2018-2024; (b) Medicare drug administration billing from Medicare Physician/Supplier PUF at the same NPI; (c) Ratio of Medicaid-to-Medicare drug billing as the key estimand.

**Identification:** Sharp RDD at the DSH adjustment percentage = 11.75% threshold. The running variable (DSH %) comes from CMS Hospital Cost Reports (HCRIS), publicly available. General acute care hospitals just above the threshold gain 340B eligibility; those just below do not. Multi-comparison design: Critical Access Hospitals and Rural Referral Centers qualify categorically (no DSH threshold) — these serve as a falsification test. The carve-in vs. carve-out state-level variation adds a heterogeneity dimension.

**Why it's novel:**
- Nikpay et al. (2018, NEJM) used this RDD to study total drug administration and physician consolidation. **Nobody has examined the Medicaid-specific channel** using provider-level claims.
- The T-MSIS × Medicare PUF cross-payer linkage (via NPI) is the novel data contribution.
- Tests a specific mechanism (duplicate discount → payer substitution) that is central to the current 340B reform debate in Congress.
- Natural placebos: (a) non-drug Medicaid billing at same hospitals; (b) drug billing at categorically-eligible hospitals (no threshold).

**Feasibility check:**
- Running variable: CMS HCRIS data has DSH adjustment percentages for ~4,500 general acute care hospitals. Available at data.cms.gov.
- Outcome: T-MSIS J-codes (drug administration) by billing NPI × month, pre-downloaded Parquet. Medicare PUF also by NPI × HCPCS.
- 340B entity list: HRSA OPAIS database provides participating hospitals with NPI.
- Manipulation concern: Bai et al. (2021) documented some bunching near the 11.75% threshold in 2014-2016. This is addressed with: (a) McCrary density test, (b) donut hole design excluding ±0.5pp around cutoff, (c) bandwidth sensitivity analysis.
- Estimated ~800-1200 hospitals within ±5pp of the threshold.

---

## Idea 2: Does Federal "Underserved" Designation Actually Attract Medicaid Home Care Providers? RDD at the MUA Threshold

**Policy:** HRSA designates Medically Underserved Areas (MUAs) based on the Index of Medical Underservice (IMU), a composite of four indicators: provider-to-population ratio, infant mortality, percent below poverty, and percent age 65+. Areas scoring IMU ≤ 62.0 receive MUA designation, which unlocks FQHC eligibility (enhanced Medicaid reimbursement), NHSC loan repayment placements, Conrad 30 J-1 visa waivers, and various federal grants. Despite billions in annual expenditures tied to MUA status, there is no causal evidence on whether designation increases Medicaid provider supply.

**Outcome:** Medicaid HCBS provider counts and billing intensity (T-codes: personal care, habilitation, attendant care) from T-MSIS, aggregated to the MUA service area × month level via NPPES ZIP codes.

**Identification:** Sharp RDD at IMU = 62.0. The IMU score can be reconstructed for all areas (including non-designated ones) from its four publicly available components, providing continuous running variable observations on both sides of the cutoff. Areas just below 62 (designated) gain federal program access; areas just above (not designated) do not.

**Why it's novel:**
- First causal estimate of MUA designation effects on Medicaid-specific provider supply.
- T-MSIS HCBS codes (T1019, S5125, etc.) measure a workforce invisible to Medicare data.
- Natural placebo: medical/CPT-coded Medicaid billing (not directly affected by MUA programs).
- Policy-relevant: HRSA periodically revisits the MUA methodology; evidence on whether the threshold matters is directly useful.

**Feasibility check:**
- IMU components available from HRSA AHRF (county-level) and Census ACS. Can reconstruct scores.
- Concern: IMU includes provider-to-population ratio (partial circularity with outcome). Mitigated because: (a) IMU uses ALL primary care physicians while outcome is Medicaid HCBS providers (different populations); (b) can use the other three IMU components as instruments/controls.
- Geographic unit complexity: MUAs can be counties, minor civil divisions, or custom service areas. Most (>80%) are whole counties, simplifying the analysis.
- Estimated mass near cutoff: uncertain — need to compute IMU distribution.

---

## Idea 3: Nurse Practitioner Full Practice Authority and the Medicaid HCBS Workforce: A Border Discontinuity Design

**Policy:** 34 states plus DC now grant Nurse Practitioners (NPs) Full Practice Authority (FPA), allowing independent practice without physician supervision. Restricted states require collaborative agreements or supervisory relationships. At state borders, otherwise similar communities face different regulatory environments for NP practice. Recent expansion: Michigan, Alabama, Louisiana, South Carolina, Wisconsin adopted FPA in 2025; California implementing 2024-2026.

**Outcome:** Medicaid HCBS and behavioral health billing (T-codes, H-codes) by NP-credentialed providers (identified via NPPES taxonomy code 363L) near state borders. Monthly panel from T-MSIS 2018-2024.

**Identification:** Border RDD comparing NP Medicaid billing in border counties of FPA states vs. adjacent border counties of restricted states. Running variable: distance to state border (positive = FPA side, negative = restricted side). Sharp treatment: FPA vs. restricted regulatory environment. Multiple border pairs across the US provide internal replication.

**Why it's novel:**
- Existing NP scope-of-practice literature focuses on patient outcomes (access, ER visits, costs). **No study examines how FPA affects NP participation in Medicaid HCBS** — the workforce most constrained by supervision requirements.
- T-MSIS HCBS codes are invisible to Medicare — this is exclusively Medicaid workforce data.
- Natural placebo: (a) physician Medicaid billing at same borders (physicians unaffected by NP scope rules); (b) non-HCBS NP billing (less affected by supervision constraints since office-based care has easier physician access).
- Multiple borders = internal replication across diverse settings.

**Feasibility check:**
- State FPA classifications: well-documented by AANP (annual State Practice Environment reports).
- NP identification: NPPES taxonomy code 363L* identifies NPs. Match rate to T-MSIS should be good.
- Border county identification: Census TIGER/Line adjacency files. Straightforward.
- Sample size concern: NPs billing T/H codes in border counties may be thin. Need to check NP density near borders.
- APEP overlap: apep_0089 studied NP scope of practice using DiD on physician employment. Different outcome (physician employment vs. NP Medicaid HCBS participation), different method (DiD vs. border RDD).

---

## Idea 4: Cross-Payer Spillovers at Medicare Payment Boundaries: Do Medicare Rate Cuts Starve the Medicaid Safety Net?

**Policy:** CMS divides the US into ~112 Medicare payment localities. The Geographic Practice Cost Index (GPCI) adjusts Medicare physician payments by locality, creating sharp payment discontinuities at county borders that separate different localities. For dual-billing providers (those serving both Medicare and Medicaid patients), Medicare payment generosity affects the opportunity cost of Medicaid participation.

**Outcome:** Medicaid billing volume and provider participation rates from T-MSIS, comparing providers in adjacent counties assigned to different GPCI localities. Also: Medicaid-to-Medicare billing ratio (using Medicare PUF) at border-adjacent providers.

**Identification:** Spatial RDD at GPCI locality boundaries. Running variable: distance to county boundary separating two localities with different GPCIs. Treatment: being in the higher-GPCI (higher Medicare payment) locality. The boundaries follow county lines, which are administrative rather than reflecting current healthcare market conditions.

**Why it's novel:**
- The cross-payer mechanism (Medicare → Medicaid) has been theorized but rarely tested at the provider level.
- T-MSIS + Medicare PUF linkage via NPI uniquely enables this.
- Multiple boundaries across the US provide internal replication.
- Policy-relevant: Medicare payment reform (e.g., MACRA adjustments) may have unintended consequences for Medicaid access.

**Feasibility check:**
- GPCI data published annually by CMS with locality-county crosswalks. Available for 2018-2024.
- Concern: GPCI differences at borders may be small (a few percent). Need to check whether economically meaningful.
- County border adjacency: Census TIGER/Line. Standard.
- Provider matching: NPI → NPPES ZIP → county → locality. Straightforward.
- Statistical concern: spatial correlation in errors requires cluster-robust inference.

---

## Idea 5: The Hidden Cost of Hospital Consolidation: 340B Eligibility and the Vertical Integration of Medicaid Drug Services

**Policy:** Same 340B program as Idea 1, but focused on a different mechanism: When hospitals gain 340B eligibility, they have incentives to acquire physician practices and shift drug administration from independent offices to hospital outpatient departments (HOPDs) where the 340B discount applies. Nikpay et al. (2018) documented this physician consolidation for Medicare. The Medicaid channel is unstudied.

**Outcome:** Share of Medicaid drug billing (J-codes) from organizational NPIs (entity type 2) vs. individual NPIs (entity type 1) in T-MSIS. Also: entry/exit of independent physician drug billing NPIs near 340B-eligible hospitals.

**Identification:** Same DSH % ≥ 11.75% RDD as Idea 1, but different estimand: the organizational structure of Medicaid drug provision rather than the payer mix. Uses T-MSIS's billing/servicing NPI structure (65% of rows have different billing and servicing NPIs, revealing organizational relationships).

**Why it's novel:**
- Extends Nikpay's consolidation finding to Medicaid — does 340B-driven consolidation affect Medicaid drug access or cost?
- T-MSIS uniquely reveals organizational billing relationships (billing NPI ≠ servicing NPI).
- Medicaid patients face different access constraints than Medicare — consolidation effects may differ.
- Natural comparison: categorically-eligible hospitals (no DSH threshold).

**Feasibility check:**
- Same data as Idea 1 (CMS HCRIS for DSH %, T-MSIS for Medicaid drug billing, NPPES for entity type).
- Entity type (individual vs organization) from NPPES. Well-defined.
- Billing vs servicing NPI distinction in T-MSIS is the key structural variable.
- Manipulation concern: same as Idea 1, addressed with donut hole design.
