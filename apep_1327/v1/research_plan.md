# Research Plan: The Pharmacy-Grocer Nexus

## Research Question

When chain pharmacies (CVS, Walgreens, Rite Aid) exit a neighborhood, they simultaneously remove SNAP-authorized food retail and Medicaid-billing pharmacy services. Does this dual service loss cause measurable declines in Medicaid pharmacy utilization and increases in emergency department use?

## Key Insight

CVS, Walgreens, and Rite Aid are simultaneously SNAP-authorized food retailers (~22,000 locations in SNAP data) and Medicaid-billing pharmacies. Rite Aid filed Chapter 11 in October 2023, closing 500+ stores. Walgreens closed 1,200+ stores in 2024-2025. These closures were driven by opioid litigation liabilities and corporate financial distress — not local neighborhood health conditions — providing plausibly exogenous variation.

## Identification Strategy

### Primary: Event-Study DiD at ZIP-Month Level

- **Treatment:** SNAP authorization end date for CVS/Walgreens/Rite Aid in ZIP z, verified against NPPES pharmacy deactivation within ±3 months
- **Unit:** ZIP × month
- **Period:** January 2018 – December 2024 (84 months)
- **Controls:** (1) ZIPs retaining dual SNAP-pharmacy; (2) ZIPs losing non-pharmacy SNAP retailer (grocery only); (3) ZIPs losing pharmacy without SNAP (pharmacy-only exit)

### Instrumental Variable: Rite Aid Bankruptcy

- **Instrument:** Rite Aid presence in ZIP as of 2022 × post-bankruptcy (Oct 2023+)
- **Exclusion:** Rite Aid closures determined by opioid settlement terms and lease optimization, not local health infrastructure
- **Cross-chain comparison:** ZIPs where Rite Aid closes but CVS/Walgreens remains (effect attenuates → "last pharmacy standing" mechanism)

### Falsification

- Chain grocery closures (Kroger, Safeway) without pharmacy operations should NOT affect Rx fill rates
- Pre-trends in pharmacy claims for eventual-closure ZIPs vs never-closure ZIPs

## Expected Effects

1. **Pharmacy claims decline:** ZIP loses pharmacy → Medicaid J-code and drug supply claims fall (some beneficiaries fail to transfer prescriptions)
2. **Beneficiary attrition:** Unique beneficiaries receiving pharmacy claims in ZIP decline
3. **ED spillover:** Medication non-adherence → increased ED utilization (99281-99285) and ambulance transport (A0425, A0427)
4. **Heterogeneity:** Effects concentrated in "last pharmacy standing" ZIPs (no substitute within reasonable distance)

## Data Sources

### 1. SNAP Retailer Historical Database (USDA)
- Source: USDA SNAP Retailer Locator / Historical Downloads
- Content: Store name, address, ZIP, authorization dates (start + end), store type
- Key filter: CVS, Walgreens, Rite Aid (~22,000 locations)
- Treatment variable: authorization end date = closure proxy

### 2. T-MSIS Medicaid Provider Spending (Azure)
- Path: `raw/medicaid/tmsis.parquet` (227M rows, 2.74 GB)
- Columns: billing_npi, servicing_npi, hcpcs_code, claim_from_month, beneficiaries, claims, paid
- Pharmacy outcomes: J-codes (injectable drugs, 350M claims, 32K providers)
- ED outcomes: 99281-99285 (ED E/M codes), A0425/A0427 (ambulance)
- Geographic linking: NPI → ZIP via NPPES

### 3. NPPES National Provider Registry
- Source: CMS NPPES bulk download or API
- Content: NPI, provider name, taxonomy code, practice address (ZIP), enumeration/deactivation dates
- Pharmacy taxonomy: 3336C0003X (community/retail pharmacy)
- Use: (a) geocode T-MSIS NPIs to ZIPs; (b) verify pharmacy closures via deactivation dates

## Primary Specification

```
Y_{zt} = α_z + γ_t + Σ_k β_k · D_{z,t-k} + X_{zt}δ + ε_{zt}
```

Where:
- Y_{zt} = pharmacy claims (or beneficiaries, or ED visits) in ZIP z, month t
- D_{z,t-k} = event-time indicators relative to chain pharmacy exit in ZIP z
- α_z = ZIP fixed effects
- γ_t = month fixed effects
- X_{zt} = time-varying controls (total SNAP retailers in ZIP, population)
- Standard errors clustered at ZIP level

IV (2SLS):
- First stage: Chain pharmacy exit_{zt} = RiteAid_present_2022_z × Post_Oct2023_t
- Second stage: Y_{zt} = β × Chain_pharmacy_exit_{zt} + FE + controls

## Analysis Pipeline

1. `01_fetch_data.R` — Download SNAP retailers, load T-MSIS from Azure, download NPPES extract
2. `02_clean_data.R` — Match SNAP stores to NPPES pharmacies by ZIP+name, construct ZIP-month panel
3. `03_main_analysis.R` — Event-study DiD, Rite Aid IV, cross-chain comparison
4. `04_robustness.R` — Grocery-only placebo, pre-trends, leave-one-chain-out, HonestDiD
5. `05_tables.R` — All tables including SDE appendix

## Exposure Alignment

The treatment (chain pharmacy closure) directly affects Medicaid beneficiaries who rely on the closed chain for pharmacy services. The treated population is Medicaid enrollees in the ZIP code who received injectable drug administration (J-codes) or other pharmacy services from chain pharmacy NPIs. Control ZIPs contain chain pharmacies that did not close during the sample period, providing a comparison group of similar Medicaid populations with continued pharmacy access. The ED outcome captures all Medicaid ED claims in the ZIP regardless of provider, aligning the outcome geography with the treatment geography. A potential mismatch arises because ED billing reflects provider location, not beneficiary residence; patients seeking care in adjacent ZIPs would be misclassified. The treatment is at the ZIP level, matching the outcome aggregation level.

## Key Risks

- SNAP end dates may not perfectly align with physical closure (store could lose SNAP before closing, or vice versa)
- T-MSIS pharmacy codes (J-codes) capture injectable drugs, not all prescriptions — may understate pharmacy utilization
- ZIP-level aggregation may mask within-ZIP substitution to nearby pharmacies
- Rite Aid bankruptcy timing (Oct 2023) gives limited post-period in T-MSIS (14 months)

## Literature

- Qato et al. (2019, JAMA Network Open): pharmacy closure → 5.9pp statin adherence decline
- Mathis et al. (2025): 28.9M Americans depend on single "keystone" pharmacy
- Guadamuz et al. (2021): racial disparities in pharmacy access
- Allcott et al. (2019, QJE): food deserts and nutrition inequality
- Sevak & Medalia (2022): SNAP retailer access and food security
- Hirth et al. (2021): pharmacy deserts and medication adherence
