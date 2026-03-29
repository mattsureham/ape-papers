# Research Plan: The Treatment Dividend of Supply-Side Opioid Restrictions

## Research Question

Does restricting prescription opioid supply push dependent users toward publicly funded addiction treatment, or toward illicit markets? We exploit the October 2014 federal rescheduling of hydrocodone combination products (HCPs) from Schedule III to Schedule II — the largest single opioid supply shock in US history, affecting 75% of ARCOS-reported volume — to identify the causal effect on Medicaid-funded medication-assisted treatment (MAT) utilization across US counties.

## Identification Strategy

**Method:** Shift-share (Bartik) reduced form

**Instrument construction:**
- **Shift:** Federal rescheduling (October 6, 2014) — a blanket federal rule motivated by aggregate national diversion statistics and congressional pressure, not by any county's treatment patterns
- **Share:** County-level pre-rescheduling HCP share of total opioid prescriptions, computed from ARCOS transaction data (2006–2012 average): HCP_share_c = Hydrocodone_pills_c / Total_opioid_pills_c

**Primary specification (cross-sectional):**
MAT_rate_c = α + β × HCP_share_c + X_c'γ + State_FE + ε_c

Where MAT_rate_c is county-level MAT claims per 1,000 population (from T-MSIS, 2018–2024 average), and X_c includes population, poverty rate, urbanicity, pre-rescheduling prescribing intensity, and demographic controls.

**Exclusion argument:** The federal rescheduling operates only through the physician-pharmacy supply chain (no refills, no phone-in, 30-day max). County HCP shares reflect historical prescribing habits and distributor relationships — predetermined relative to post-2014 treatment demand.

**Key testable predictions:**
1. High-HCP counties should show different MAT utilization than low-HCP counties
2. No differential effect on non-opioid SUD treatment (placebo)
3. Effect should be stronger for methadone/buprenorphine (OUD-specific) than general behavioral health

## Expected Effects and Mechanisms

Two competing hypotheses:
- **Treatment dividend:** Supply restrictions create a "treatment on-ramp" — users unable to refill prescriptions seek formal treatment. β > 0.
- **Illicit substitution:** Restricted users switch to heroin/fentanyl without seeking treatment. β ≤ 0.

The 24 existing studies document HCP prescribing declines of 3–66% with partial substitution to other opioids. No study has examined the downstream Medicaid treatment response.

## Data Sources

1. **ARCOS transactions** (Azure: `raw/arcos/arcos_transactions.parquet`) — 178M rows, 2006–2012, drug-level pill shipments. For constructing county HCP shares.
2. **T-MSIS** (Azure: `raw/medicaid/tmsis.parquet`) — 227M Medicaid claims, 2018–2024. MAT HCPCS codes: H0020 (methadone, 312M claims), J0571–J0575 (buprenorphine, 8.3M claims), J2315 (naltrexone, 160K claims). Provider NPIs geolocated to counties via NPPES.
3. **CDC WONDER** — County-level opioid overdose deaths (ICD-10 codes X40–X44, X60–X64, X85, Y10–Y14 with T40.x). For mortality mechanism test.
4. **NPPES** — Provider NPI-to-county geocoding.
5. **Census/ACS** — County-level demographic controls.

## Primary Specification Details

- **Unit:** County (cross-sectional, N ≈ 3,064 with substantial opioid volume)
- **Treatment intensity:** Continuous (HCP share ranges from 0.09 to 0.98, mean 0.70, SD 0.18)
- **Outcome:** MAT claims per 1,000 county population, averaged 2018–2024
- **Controls:** State FE, log population, poverty rate, % urban, % Black, % Hispanic, median age, pre-rescheduling opioid prescribing rate per capita
- **Inference:** Robust standard errors clustered at state level (51 clusters)
- **Robustness:** (a) Leave-one-state-out jackknife, (b) alternative HCP share definitions (2006–2009 only, 2010–2012 only), (c) donut analysis excluding top/bottom decile HCP share counties, (d) controlling for subsequent opioid policies (PDMP mandates, naloxone access laws)

## Exposure Alignment

The treatment variable (HCP share) varies continuously across counties within states. Counties with higher HCP shares had a larger fraction of their opioid supply subject to the new Schedule II restrictions (no refills, no phone-in, 30-day max). The affected population includes chronic pain patients on hydrocodone who now face greater friction maintaining prescriptions, and patients with opioid use disorder who had been sourcing prescription hydrocodone. The rescheduling does NOT directly affect heroin or fentanyl users, nor patients on oxycodone (already Schedule II). The timing is sharp: October 6, 2014, with no phase-in.

## Pre-registration of Diagnostics

- Balance test: HCP share uncorrelated with pre-existing county characteristics (after state FE)
- Placebo: Non-opioid SUD treatment (H0015, H0016 for alcohol/stimulant SUD) unrelated to HCP share
- Monotonicity: Effect increasing in treatment intensity (quintile dummies)
- Mechanism test: decompose into methadone vs. buprenorphine modalities
