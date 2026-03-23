# Research Plan: Collateral Damage

## Research Question

Did the 2023–2024 Medicaid unwinding cause SNAP enrollment declines through administrative spillover? In ~24 states, the same eligibility workers and IT systems process both Medicaid and SNAP. When 94 million Medicaid redeterminations hit these shared systems, did the administrative overload crowd out SNAP processing, causing eligible households to lose food benefits?

## Identification Strategy

**Difference-in-Differences** comparing SNAP enrollment trends in states with integrated Medicaid-SNAP eligibility systems vs states with separate systems, before and after the Medicaid unwinding began in April 2023.

**Specification:**
```
ln(SNAP_st) = α_s + γ_t + β · (Integrated_s × Post_t) + X_st'δ + ε_st
```

Where Integrated_s = 1 for states where Medicaid and SNAP share eligibility workers/IT systems. Post_t = 1 for April 2023 onward. Controls include state-specific EA termination dates and economic conditions.

**Key insight:** The SNAP EA termination (March 2023) affects all states equally conditional on EA timing, but the administrative spillover from Medicaid unwinding hits only integrated-system states. The DiD isolates the spillover channel.

## Expected Effects

1. Integrated-system states see larger SNAP enrollment declines post-April 2023
2. Effects should be larger in states with high Medicaid procedural termination rates (proxy for administrative burden)
3. Placebo: SNAP enrollment in states with separate systems should show EA effects but no additional unwinding spillover

## Data Sources

1. **USDA FNS SNAP Monthly** (publicly downloadable Excel files, FY89-FY26): state × month participation counts and benefit amounts.

2. **CMS Medicaid Unwinding CAA Metrics** (monthly state reports): procedural vs eligibility-based terminations, total determinations, pending applications.

3. **KFF/CLASP Integrated System Classification**: Which states share Medicaid-SNAP eligibility workers and IT systems.

4. **BLS LAUS** (optional): state monthly unemployment rate for controls.
