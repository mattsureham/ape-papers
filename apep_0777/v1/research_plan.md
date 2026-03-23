# Research Plan: The SNAP Buffer — Cross-Program Data Coordination and Medicaid Enrollment Resilience During the 2023–2024 Unwinding

## Research Question

Did states that used SNAP enrollment data for ex parte Medicaid renewals (via Section 1902(e)(14)(A) waivers) retain more Medicaid enrollees during the 2023–2024 continuous enrollment unwinding?

## Identification Strategy

**Difference-in-differences** with common treatment timing.

- **Treatment:** States with SNAP-Medicaid data coordination for ex parte renewals (~19 e14-waiver states approved April 2023)
- **Control:** States without e14 waivers (~32 states)
- **Treatment timing:** April 1, 2023 (end of continuous enrollment PHE)
- **Pre-period:** January 2019–March 2023 (51 months)
- **Post-period:** April 2023–December 2024 (21 months)

Fixed effects: state + month. Clustering: state level. Pre-trends test: event study with monthly leads/lags.

## Expected Effects and Mechanisms

**Mechanism:** SNAP eligibility thresholds are at or below Medicaid thresholds. States with e14 waivers can match SNAP enrollment rolls against Medicaid beneficiary files and auto-renew anyone with current SNAP eligibility — bypassing the standard renewal form process. This reduces procedural disenrollment (people losing coverage due to paperwork, not ineligibility).

**Expected effect:** E14-waiver states should retain more enrollees in the months immediately following unwinding start. The buffer may be temporary if underlying eligibility changes are eventually detected.

## Primary Specification

$$\text{Enrollment}_{st} = \alpha_s + \gamma_t + \beta \cdot (E14_s \times \text{Post}_t) + X_{st}'\delta + \varepsilon_{st}$$

Where:
- $\text{Enrollment}_{st}$ = Medicaid enrollment (normalized to March 2023 baseline) in state $s$, month $t$
- $E14_s$ = indicator for e14-waiver state
- $\text{Post}_t$ = indicator for $t \geq$ April 2023
- $X_{st}$ = state-month controls (unemployment rate, population)

## Data Sources and Fetch Strategy

1. **CMS Medicaid Enrollment:** Monthly state-level enrollment from data.medicaid.gov Performance Indicators dataset. Confirmed accessible via API.

2. **E14 Waiver Status:** Hand-coded from CBPP (Center on Budget and Policy Priorities) documentation of which states received Section 1902(e)(14)(A) waivers. 19 states confirmed.

3. **State Controls:** BLS LAUS (unemployment), Census population estimates.

### Fetch Order
1. CMS Medicaid enrollment (API) — primary outcome
2. E14 waiver status (hand-coded) — treatment variable
3. BLS unemployment (FRED API) — control
4. Census population (FRED API) — normalization

### Fallback
- If CMS API is down → use KFF state enrollment tracker
- If FRED unavailable → use ACS annual estimates

## Exposure Alignment

The treatment (E14 waiver) operates at the state level: a state either has the waiver or does not. The treated population is Medicaid beneficiaries who are also enrolled in SNAP — roughly 70% of SNAP households include a Medicaid beneficiary. The outcome (total Medicaid enrollment) captures all beneficiaries, including those not enrolled in SNAP. This dilutes the treatment effect: the SNAP buffer only directly affects dual SNAP-Medicaid enrollees, but our outcome includes Medicaid-only beneficiaries who receive no benefit from the E14 waiver. States with higher SNAP-Medicaid overlap should show larger effects — this motivates a heterogeneity analysis by dual enrollment share.

## Key Risks
1. **Selection into e14 waivers:** States that adopted e14 waivers may differ systematically (more administratively capable, more politically supportive of Medicaid). Pre-trends test is critical.
2. **Confounding:** States also varied in unwinding pace, pause/resume decisions, and other PHE-related policies. Need to control for unwinding start date and pace.
3. **Composition effects:** Enrollment retention could reflect different population compositions rather than administrative efficiency.
