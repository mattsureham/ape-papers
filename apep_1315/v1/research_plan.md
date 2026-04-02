# Research Plan: The Forever Chemical Discount

## Research Question

Does federal regulation of PFAS ("forever chemicals") in drinking water capitalize into local housing prices? The EPA's April 2024 Maximum Contaminant Level (MCL) of 4 ppt for PFOA/PFOS — the first-ever national PFAS drinking water standard — created ~1,693 water systems newly in violation. We estimate whether housing prices in ZIP codes served by above-MCL systems declined relative to below-MCL systems, and whether the effect is attenuated in states that already had binding PFAS standards.

## Identification Strategy

**Difference-in-differences** at the water-system-ZIP level:
- **Treatment**: ZIP codes served by public water systems with UCMR 5 detected PFOA/PFOS concentrations > 4 ppt (the federal MCL)
- **Control**: ZIP codes served by systems with levels below MCL or non-detect
- **Triple-difference**: (above/below MCL) × (post/pre federal rule) × (no prior state MCL / prior state MCL). States with pre-existing binding PFAS standards (NJ, MA, MI, NH, PA, VT, WI) serve as a within-treatment placebo — the federal MCL was redundant there, so housing markets should not respond.

**Key identifying assumption**: Conditional on ZIP-level fixed effects and year fixed effects, the housing price trends of above-MCL and below-MCL ZIP codes would have evolved in parallel absent the federal regulation.

**Threats and mitigation**:
1. *Pre-existing contamination awareness*: UCMR 5 monitoring (2023-2025) provided new information; many systems learned their PFAS levels for the first time. But some contamination was known pre-regulation (e.g., military bases, industrial sites). We control for proximity to known PFAS contamination sites.
2. *Selection into treatment*: Systems above 4 ppt may differ systematically. We verify parallel pre-trends and use coarsened exact matching on ZIP demographics.
3. *Concurrent policies*: State-level remediation programs and Superfund designations could confound. The DDD with prior-MCL states isolates the federal regulation's marginal information content.

## Expected Effects and Mechanisms

**Contamination disclosure effect**: The regulation + UCMR 5 monitoring publicly reveals which water systems have unsafe PFAS levels. Buyers discount contaminated areas → negative price effect.

**Cleanup commitment signal**: Federal MCL mandates remediation by 2029. This credible commitment to cleanup could support or even increase prices → positive or attenuating effect.

**Net prediction**: Negative short-run effect (disclosure dominates), potentially attenuating over time as remediation progresses. Prior-MCL states should show smaller or null effects (information already priced in).

## Primary Specification

$$\Delta HPI_{z,t} = \alpha_z + \gamma_t + \beta_1 \cdot AboveMCL_z \times Post_t + \beta_2 \cdot AboveMCL_z \times Post_t \times NoPriorMCL_s + X_{z,t}\delta + \varepsilon_{z,t}$$

Where:
- $\Delta HPI_{z,t}$: Annual change in FHFA House Price Index for ZIP $z$ in year $t$
- $AboveMCL_z$: Binary indicator for ZIP served by system with PFOA/PFOS > 4 ppt
- $Post_t$: Post-federal-MCL-announcement (2024+)
- $NoPriorMCL_s$: State $s$ had no pre-existing enforceable PFAS MCL
- Clustering: State level (conservative; also report ZIP and system-level)

## Data Sources and Fetch Strategy

1. **UCMR 5** (EPA): Bulk download from EPA SDWIS. 1.93M rows, 10,299 systems. Contains analyte concentrations by system. Free.
2. **UCMR5_ZIPCodes.txt**: Crosswalk from PWSID to ZIP codes (31,106 mappings). Free.
3. **FHFA ZIP5 HPI**: Annual House Price Index at ZIP code level, 1984-2024. 668K rows. Free download.
4. **State PFAS MCLs**: Hand-coded from EPA compilation (7 states with prior MCLs as of April 2024).
5. **ACS demographics**: Census API for ZIP-level controls (income, education, race, housing stock).

## Robustness Checks

1. Event study (leads and lags around April 2024 announcement)
2. Matching estimator (CEM on pre-treatment demographics)
3. Dose-response: Continuous PFAS concentration instead of binary above/below
4. Placebo outcomes: Commercial property values, unrelated economic indicators
5. Excluding military-base ZIPs (prior contamination awareness)
6. Alternative clustering (system, ZIP, county)
