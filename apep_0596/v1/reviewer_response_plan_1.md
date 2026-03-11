# Reviewer Response Plan — Round 1

**Paper:** apep_0596 v1 — When the Canal Runs Dry
**Reviews:** GPT R1 (Major), GPT R2 (Major), Gemini (Minor)

## Key Themes Across Reviewers

### 1. Pre-trend violations (all three)
- All reviewers flag significant pre-treatment event-study coefficients
- **Action:** Add formal joint F-test of pre-treatment coefficients; add Rambachan-Roth (2023) and Roth (2022) citations; acknowledge limitation more honestly

### 2. Over-interpretation of null / missing MDE (both GPT)
- "No effect" is stronger than "cannot detect net effect"
- No power analysis or MDE reported
- **Action:** Compute MDE; report 95% CIs for realistic exposure contrasts; recalibrate all claims in abstract, intro, results, conclusion

### 3. Treatment measurement (both GPT)
- Origin ≠ route; Canal Share is a proxy
- **Action:** Add honest subsection in Limitations acknowledging this; note attenuation bias interpretation

### 4. Medium-port anomaly (Gemini, GPT R1)
- Coefficient of 27.01 is economically implausible
- **Action:** Add winsorized robustness check; strengthen discussion

### 5. External validity overstated (both GPT)
- Claims about "resilience" too broad for one temporary shock on aggregate values
- **Action:** Tighten claims throughout

### 6. Missing literature (both GPT)
- Rambachan and Roth (2023), Roth (2022) on pre-trend sensitivity
- **Action:** Add to references.bib and cite in text

### 7. Exhibit/Prose improvements
- Table 2 headers (code-style → descriptive)
- Mechanism section narrative
- Stronger conclusion sentence

## Execution Plan

### Code changes (04_robustness.R)
1. Add joint F-test of pre-treatment event study coefficients
2. Compute MDE for preferred specification
3. Add winsorized specification for medium-port robustness
4. Save results to CSV for paper integration

### Paper.tex changes
1. **Abstract:** Recalibrate from "no significant effect" to "no detectable net decline"
2. **Introduction:** Soften "economically zero" to "too small to detect"; add MDE framing
3. **Pre-trends discussion:** Add F-test result; cite Roth (2022), Rambachan-Roth (2023)
4. **Results:** Add MDE/CI interpretation paragraph
5. **Mechanisms:** Soften from "explains the null" to "consistent with the null"
6. **Limitations:** Add treatment measurement subsection; acknowledge attenuation
7. **Conclusion:** Narrow claims; add caveats about aggregate values vs. costs
8. **References:** Add Rambachan-Roth, Roth, Freyaldenhoven-Hansen-Shapiro

### Not addressed (infeasible without new data)
- Route-level shipping data (AIS/bill-of-lading)
- Container-specific transit measures
- Freight rate analysis
- Commodity-level decomposition
- TEU/vessel call outcomes
