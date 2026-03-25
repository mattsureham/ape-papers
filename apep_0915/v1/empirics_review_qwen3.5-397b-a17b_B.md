# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant B)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** B
**Date:** 2026-03-25T13:02:00.108104

---

1. **Idea Fidelity**

The paper largely adheres to the original idea manifest regarding the core policy shock (2018 OIAI withdrawal), data source (EPA NEI Facility Summaries), and empirical strategy (difference-in-bunching). The sample period (2012–2021) and facility coverage align with the feasibility check. However, there are two notable deviations. First, the manifest proposed a mechanism test linking facility emissions to EPA Air Quality System (AQS) monitor data to verify ambient concentration changes; the paper explicitly relegates this to future work in the Conclusion, leaving the mechanism (real abatement vs. reporting) unresolved. Second, the manifest suggested using Criteria Air Pollutant thresholds as a placebo test; the paper instead uses placebo HAP thresholds (5, 15, 20 tons). While methodologically sound, this shifts the placebo strategy away from the original design. Overall, the core contribution remains intact, but the mechanism evidence is weaker than proposed.

2. **Summary**

This paper exploits the 2018 withdrawal of the EPA's "Once In Always In" (OIAI) guidance to test for strategic emission bunching at Clean Air Act hazardous air pollutant (HAP) thresholds. Using a difference-in-bunching design on NEI facility-level data, the author finds no response at the 10-ton single-pollutant threshold but significant bunching at the 25-ton combined-pollutant threshold. The results suggest that regulatory escape hatches are selectively exploited when abatement can be distributed across multiple pollutants rather than concentrated on a single species.

3. **Essential Points**

1.  **NEI Data Construction and Temporal Consistency:** The paper states that "EPA has produced annual emissions estimates since 2016," utilizing data for 2012, 2014, 2016, 2017, 2018, 2019, 2020, and 2021. Historically, the NEI is a triennial inventory (2011, 2014, 2017, 2020), with non-triennial years often relying on modeling or interpolation rather than direct facility reporting. If the 2018–2021 data are derived using different estimation algorithms than the 2014–2017 data, the observed "bunching" could be an artifact of methodological changes in the inventory compilation rather than behavioral responses. The authors must explicitly document the source of the "annual" data (e.g., is it the Air Markets Program Data, GHG Reporting Program, or interpolated NEI?) and demonstrate that the measurement error structure is consistent across the pre- and post-periods. Without this, the identification assumption of a smooth counterfactual density is threatened.

2.  **Distinguishing Real Abatement from Reporting Manipulation:** The welfare implications of the paper hinge on whether the 25-ton bunching represents genuine emission reductions or strategic reporting. The manifest proposed linking to AQS monitors to test this, but the paper omits this analysis. Given that the 10-ton threshold shows no response (where measurement is often more precise due to stricter monitoring for single major pollutants), the 25-ton result could reflect facilities exploiting the flexibility in aggregating multiple minor pollutants. The authors must strengthen the discussion on measurement discretion. At minimum, they should analyze whether facilities bunching at 25 tons are subject to Continuous Emission Monitoring Systems (CEMS) versus those using engineering estimates. If bunchers are predominantly estimation-based, the "escape hatch" may be purely administrative.

3.  **Interpretation of the 10-Ton Null:** The paper treats the null result at the 10-ton threshold as a well-powered finding indicative of technological constraints. However, Table 1 shows
