# Research Ideas

## Idea 1: Does Coverage Create Capacity? Section 1115 SUD Waivers and the Supply of Behavioral Health Providers

**Policy:** Section 1115 SUD demonstration waivers, which allow Medicaid to pay for substance use disorder treatment in Institutions for Mental Diseases (IMDs)—reversing a 50-year federal exclusion. CMS issued guidance in November 2017; ~37 states received approval between 2017–2024, with staggered adoption creating clean cross-state variation.

**Outcome:** T-MSIS behavioral health provider supply (H-codes for community psychiatric support, SUD counseling, residential treatment; J-codes for MAT drugs like buprenorphine/naltrexone). Measured as: active provider count, claims volume, beneficiaries served, geographic spread—all at the state × month level.

**Identification:** Staggered DiD using Callaway-Sant'Anna (2021) estimator. Treatment: month of CMS waiver approval. States approved in 2019+ have ≥12 months pre-treatment in T-MSIS (data starts Jan 2018). ~30+ treated states with staggered timing.

**Why it's novel:** Existing 1115 SUD waiver research (Maclean et al. 2020, Wen et al. 2022, Saloner et al.) uses enrollment/utilization data to study demand-side effects. Nobody has examined the SUPPLY side: does lifting the payment ban actually create new treatment capacity? T-MSIS is the first dataset that makes provider-level supply analysis possible for Medicaid behavioral health. This paper fills a critical gap—we know waivers increased coverage, but we don't know if they increased capacity.

**Feasibility check:**
- Variation: ✅ 30+ states with staggered adoption (2017–2024), remaining states as controls
- Data access: ✅ T-MSIS Parquet (local, 2.74 GB), NPPES (free bulk download), waiver dates from CMS/KFF
- Novelty: ✅ No APEP paper on SUD waivers; no published paper using T-MSIS for supply-side waiver evaluation
- Sample size: ✅ 227M T-MSIS rows; H-codes alone account for ~15% of spending
- Built-in placebos: ✅ Personal care T-codes (unrelated to SUD), dental providers, HCBS providers
- Multi-margin analysis: ✅ Extensive (new provider entry), intensive (more claims per provider), geographic (spread to underserved areas), cross-payer (Medicare PUF substitution)

## Idea 2: Nurse Practitioner Full Practice Authority and the Structure of Medicaid Billing

**Policy:** State adoption of full practice authority (FPA) for nurse practitioners, allowing independent practice without physician oversight. ~8 states adopted FPA during 2018–2024 (Kansas 2022, New York 2022, Utah 2023, Massachusetts 2021, Delaware 2021, others).

**Outcome:** NP billing patterns in T-MSIS. In restricted states, NPs appear as servicing NPIs under physician groups. After FPA, NPs can bill independently. Measured via NP credential identification in NPPES + billing vs. servicing NPI status.

**Identification:** Staggered DiD on FPA adoption dates.

**Why it's novel:** NP-FPA research exists for Medicare; no one has used provider-level Medicaid claims data. T-MSIS + NPPES credential data uniquely identifies NP billing transitions.

**Feasibility check:**
- Variation: ⚠️ Only ~5–8 states adopted FPA during data window. Below 20-state threshold.
- Data: ✅ T-MSIS + NPPES credential matching
- Novelty: ✅ New Medicaid angle
- Sample: ✅ NPs are ~15% of Medicaid billing NPIs
- CONCERN: Too few treated states for credible staggered DiD. Would need to expand to include partial scope changes or COVID temporary expansions, adding noise.

## Idea 3: State Cannabis Legalization and Medicaid Behavioral Health Spending

**Policy:** State recreational cannabis legalization. ~15 states legalized during 2018–2024 (Illinois 2020, Montana 2021, New York 2021, Connecticut 2022, Missouri 2022, etc.).

**Outcome:** Behavioral health H-code spending and provider supply in T-MSIS. Does legalization increase demand for behavioral health services (cannabis use disorder) or decrease it (substitution away from opioids)?

**Identification:** Staggered DiD on legalization effective dates.

**Why it's novel:** Cannabis-health research is extensive but not at the Medicaid provider supply level. T-MSIS H-codes directly measure behavioral health treatment infrastructure.

**Feasibility check:**
- Variation: ⚠️ ~15 states, marginal. Some concern about concurrent policy changes.
- Data: ✅ T-MSIS + legalization dates (NCSL)
- Novelty: ✅ Supply-side angle is new
- CONCERN: Causal channel from legalization → behavioral health provider supply is indirect and diffuse. Multiple confounders (opioid epidemic, COVID, other state policies).

## Idea 4: Opioid Settlement Fund Disbursements and Behavioral Health Treatment Capacity

**Policy:** National opioid settlements ($50B+) disbursed to states starting 2022, with staggered timing based on settlement agreements and allocation formulas. Funds explicitly targeted at SUD treatment expansion.

**Outcome:** Behavioral health H-code provider supply, MAT drug (J-code) prescribing volume in T-MSIS.

**Identification:** Staggered DiD on first disbursement dates by state.

**Why it's novel:** First provider-level evidence on whether settlement money translates into treatment infrastructure.

**Feasibility check:**
- Variation: ✅ All 50 states received funds on different timelines
- Data: ⚠️ Precise state-level disbursement dates are hard to compile; KFF/NASHP track spending but not all dates public. Transparency varies.
- Novelty: ✅ No one has linked settlements to provider-level supply data
- CONCERN: Difficult to separate settlement-funded expansion from other concurrent investments (ARPA HCBS funds, state general funds). Short post-period (2022–2024).

## Idea 5: Medicaid Managed Care Mandates and Provider Market Consolidation

**Policy:** States mandating managed care enrollment for previously FFS Medicaid populations. Several states expanded MCO mandates during 2018–2024. MCO credentialing requirements create barriers for small/solo providers.

**Outcome:** T-MSIS organizational structure: share of billing through organizational NPIs (entity type 2) vs. individual providers (entity type 1). HHI concentration measures.

**Identification:** Staggered DiD on MCO mandate expansion dates.

**Why it's novel:** Market structure analysis of Medicaid provider networks using billing structure data.

**Feasibility check:**
- Variation: ⚠️ Few clean MCO mandate changes during data window (most predated 2018)
- Data: ✅ T-MSIS billing/servicing NPI structure
- Novelty: ✅ New angle
- CONCERN: MCO mandate changes during 2018–2024 are limited. Most states already had extensive managed care.
