# Research Plan: The Recertification Ripple

## Research Question

Does SNAP recertification intensity cause Medicaid enrollment volatility in states with integrated eligibility systems? 26 states integrated SNAP and Medicaid eligibility determination onto a single platform to reduce administrative burden — but integration creates hidden coupling. When SNAP administrative intensity rises (shorter recertification intervals → more verification events), does bureaucratic resource competition spill over to destabilize Medicaid enrollment?

## Identification Strategy

**Design:** Difference-in-differences on a state-month panel (51 states × 36+ months).

**Treatment:** SNAP recertification intensity (continuous), measured as the share of SNAP households on short (≤6 month) recertification cycles. States with higher shares generate more administrative events per unit time.

**Key interaction:** Recertification intensity × Integrated Eligibility System (IES) indicator. The identifying assumption: conditional on state and month FE, SNAP recertification intensity affects Medicaid enrollment volatility differentially in IES states (where SNAP and Medicaid share caseworkers/IT infrastructure) versus non-IES states.

**Specification:**
```
ΔEnrollment_st = α_s + γ_t + β₁(RecertIntensity_st × IES_s) + β₂(RecertIntensity_st) + X_st'δ + ε_st
```

where β₁ is the parameter of interest: the differential effect of SNAP admin intensity on Medicaid enrollment changes in integrated states.

## Expected Effects and Mechanisms

**Primary mechanism:** Bureaucratic resource competition. In IES states, SNAP recertification events consume the same caseworker time, IT infrastructure, and processing queues that handle Medicaid renewals. Higher SNAP recertification intensity → processing backlogs → delayed Medicaid renewals → enrollment gaps/churn.

**Expected sign:** β₁ > 0 for enrollment volatility measures (more SNAP admin intensity → more Medicaid enrollment churn in IES states). β₂ ≈ 0 (no spillover channel in non-IES states).

**Alternative channel to test:** Information/reminder effect. Recertification events could REMIND eligible households to maintain Medicaid coverage, reducing churn (β₁ < 0). This is the competing hypothesis.

## Primary Specification

- **Outcome:** Month-over-month absolute change in Medicaid enrollment (state-month level). Rolling 3-month CV as secondary.
- **Treatment:** Share of SNAP households on ≤6 month recertification (continuous, from USDA ERS SNAP Policy Database)
- **Moderator:** IES indicator (binary, from KFF)
- **Fixed Effects:** State + Year-Month
- **Clustering:** State level
- **Sample:** Jan 2018 – Dec 2020 (pre-COVID core: Jan 2018 – Feb 2020; COVID natural experiment: Mar 2020+)

## Exposure Alignment

**Who is treated:** All Medicaid beneficiaries in states with integrated eligibility systems (IES). The treatment operates at the state-system level — when SNAP recertification intensity is high, the shared administrative infrastructure (caseworkers, IT queues, databases) that processes both SNAP and Medicaid is under greater load. Every Medicaid beneficiary in an IES state is exposed to the resulting processing delays, regardless of whether they personally receive SNAP. The unit of observation (state-month) matches the level at which the treatment operates (state-level administrative capacity).

**Treatment timing:** SNAP recertification intensity varies continuously at the state-month level based on the distribution of certification period lengths assigned to SNAP households. There is no discrete "treatment onset" — the design exploits continuous variation in administrative load interacted with the binary IES indicator. The identifying variation comes from within-state changes in recertification intensity over time (absorbed by state FE) and differential effects between IES and non-IES states (the interaction term).

## Robustness and Placebos

1. **Non-IES placebo:** Run main spec on non-IES states only; coefficient should be zero
2. **COVID natural experiment:** March 2020 blanket waivers extended all SNAP recertification by 6 months; administrative pressure suddenly evaporated → enrollment volatility should decrease differentially in high-intensity IES states
3. **Dose-response:** Use continuous recertification interval (mean months) instead of share
4. **Placebo outcome:** Medicare enrollment (not processed through IES) should be unaffected
5. **Leave-one-out:** Drop each IES state individually to check no single state drives results
6. **Wild cluster bootstrap:** Given 51 clusters, use WCB for inference robustness

## Data Sources

1. **CMS Monthly Medicaid Enrollment** — State-level total Medicaid/CHIP enrollment, monthly. From Medicaid.gov enrollment reports.
2. **USDA ERS SNAP Policy Database** — 18 recertification variables by state-month, through Dec 2020. Publicly available Excel.
3. **KFF Integrated Eligibility Systems** — 26 states identified as operating IES (Jan 2025 report). Binary classification.
4. **CMS Medicaid enrollment API** — For validation and extended time series.
5. **BLS LAUS** — State unemployment rates as time-varying controls.
