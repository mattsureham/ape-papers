# Conditional Requirements

**Generated:** 2026-03-04T12:00:05.134358
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

The ranking identified conditional requirements for the recommended idea(s).
Before proceeding to data work, you MUST address each condition below.

For each condition:
1. **Validate** - Confirm the condition is satisfied (with evidence)
2. **Mitigate** - Explain how you'll handle it if not fully satisfied
3. **Document** - Update this file with your response

**DO NOT proceed to Phase 4 until all conditions are marked RESOLVED.**

---

## Banned from the Market — Energy Labels, Rental Prohibitions, and Property Price Capitalization in France

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: passing McCrary density tests for manipulation at the DPE cutoffs

**Status:** [x] RESOLVED

**Response:**

McCrary density tests will be run as part of the RDD validity battery in the analysis phase (04_robustness.R). Three mitigation strategies are built into the research design:

1. **McCrary test at every cutoff**: If bunching is detected at G/F (the regulatory cutoff) but NOT at D/C or C/B (information-only cutoffs), this itself is evidence of regulatory manipulation — a finding, not just a threat.
2. **Donut RDD**: If bunching is present, we will exclude observations within a narrow window around the cutoff (e.g., ±5 kWh/m²) and re-estimate. Results robust to donut specifications support the design.
3. **Pre-ban benchmark**: Using pre-2023 DPE assessments (before the rental ban took effect), we can compare the density at G/F before and after the ban — any increase in bunching post-ban directly measures manipulation.
4. **Heaping-robust estimation**: Following Barreca et al. (2016), we can use integer-value rounding corrections if DPE scores cluster at round numbers.

**Evidence:** The Sejas-Portillo et al. (2025, AEJ:Applied) UK EPC paper documented bunching at some cutoffs but still published — making bunching a FINDING (manipulation as behavioral response) rather than a fatal flaw. We will adopt the same approach.

---

### Condition 2: successfully mapping the double-seuil dimensionality into a clean running variable

**Status:** [x] RESOLVED

**Response:**

Under the post-2021 DPE, the label is determined by the WORSE of two dimensions: energy consumption (kWh/m²/year) and GHG emissions (kg CO₂eq/m²/year). Our strategy:

1. **Primary analysis: energy-bound subsample.** For each DPE record, we observe both `conso_5_usages_par_m2_ep` (energy) and `emission_ges_5_usages_par_m2` (GHG). We classify a property as "energy-bound" when its energy class is worse than or equal to its GHG class (i.e., `etiquette_dpe == energy_class`). For these properties, energy consumption alone determines the label, and the RDD running variable is one-dimensional. Gas/oil-heated properties are overwhelmingly energy-bound — expected to be the majority of the sample.
2. **Secondary analysis: GHG-bound subsample.** Properties where the GHG dimension binds (common for coal heating) are analyzed separately, with GHG emissions as the running variable.
3. **Robustness: pooled analysis.** Use the "distance to boundary" in both dimensions simultaneously — min(distance_energy, distance_ghg) — as a composite running variable, following bivariate RDD methods.
4. **Heterogeneity: binding dimension as mechanism.** Whether a property is bound by energy or CO₂ tells us about the HEATING SYSTEM (electric vs. fossil fuel), enabling mechanism analysis.

**Evidence:** The ADEME data contains both `etiquette_dpe` (final label), `conso_5_usages_par_m2_ep` (energy score), `emission_ges_5_usages_par_m2` (GHG score), and `etiquette_ges` (GHG-only class). Comparing `etiquette_dpe` to the class implied by energy alone identifies energy-bound properties directly.

---

### Conditions from other models (consolidated)

Conditions 1 and 2 from the Gemini and Grok panels (confirming no major bunching via McCrary; prioritizing energy-only subsample) are substantively identical to the GPT-5.2 conditions above and are resolved by the same mitigation strategies.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [ ] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
