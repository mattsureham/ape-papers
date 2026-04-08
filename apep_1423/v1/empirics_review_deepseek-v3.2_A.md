# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant A)

**Model:** deepseek/deepseek-v3.2
**Variant:** A
**Date:** 2026-04-08T14:06:57.329901

---

**Referee Report**

**Paper:** "The Ridgeline Discontinuity: Watershed Boundaries and the Enforcement Effect of Clean Water Act Impairment Listing"

**1. Idea Fidelity**

The paper deviates from the original, ambitious idea in several critical ways, resulting in a weaker and less credible analysis. The original manifest proposed a **boundary-based staggered Difference-in-Differences (DiD)** design, exploiting both spatial (watershed divides) and **temporal variation** from biennial 303(d) listing cycles over 1998-2024. This paper implements a **purely cross-sectional, static comparison** using only the most recent compliance snapshot (13 quarters) and a single point-in-time treatment status. This misses the core temporal identification component. Consequently, the paper cannot disentangle the causal effect of *becoming* listed from persistent, pre-existing differences between facilities in listed vs. non-listed watersheds. The HUC-8 fixed effects absorb time-invariant confounders but do not address time-varying ones or reverse causality. Furthermore, the manifest specified using a **running variable (distance to divide)** and bandwidths, moving toward a regression discontinuity (RD) framework. The paper instead uses a coarser "boundary sample" without validating the discontinuity assumption or examining spatial balance. Finally, the data scope is substantially reduced from the proposed "100K+ facilities x 17+ years" to a cross-section of 2,276 major facilities. The paper captures the spatial discontinuity idea but abandons the panel and temporal elements essential for credible causal inference on a policy that unfolds over time.

**2. Summary**

This paper uses watershed boundaries (HUC-12 divides) as a geographic discontinuity to test whether a Clean Water Act Section 303(d) "impaired waters" listing affects the compliance behavior of nearby regulated facilities. Comparing facilities within the same broader HUC-8 watershed but on opposite sides of a HUC-12 divide—some in listed subwatersheds, some not—the authors find a precisely estimated null effect: listing is associated with no meaningful change in violation rates.

**3. Essential Points**

The following issues are fundamental and must be resolved for the paper to be credible.

1.  **Misaligned Design and Endogeneity:** The cross-sectional, post-treatment design cannot establish causality. The critical threat is reverse causality and selection: facilities with worse compliance histories or in more pollution-prone locations are more likely to be in watersheds that *become* listed. The use of a contemporaneous "listed" indicator and a recent compliance window does not address this. A facility's violation record from the past 13 quarters may well have *contributed* to its watershed's current listing status. The authors note this concern but dismiss it with an argument about lags and cumulative conditions, which is an assumption, not a test. The proposed staggered DiD design from the manifest is the necessary solution: track facilities over time and compare changes in outcomes for those whose watersheds become listed versus those that do not, while leveraging the spatial boundary for comparison groups.

2.  **Invalid Spatial Discontinuity Assumption Unverified:** The paper asserts that HUC-12 boundaries are "geologically determined" and thus as-good-as-random for facility assignment, but provides no supporting evidence. For a spatial discontinuity design, the paper must demonstrate that facilities and their observable characteristics are balanced across the boundary. A simple comparison of means (Table 1) is insufficient; it must test for balance *within the bandwidth around the boundary* (e.g., 1-5 km as suggested in the manifest) and show the continuity of the density of facilities (no sorting). Furthermore, the analysis uses a broad "boundary sample" (any facility in a HUC-8 with both listed and non-listed HUC-12s) rather than a local comparison near the boundary. Facilities far from the boundary are less likely to be comparable. The paper needs to implement the RD-inspired approach it initially proposed, plotting outcomes and covariates against distance to the boundary and formally testing for discontinuities at the threshold.

3.  **Outcome Measurement and Mechanism Are Disconnected:** The outcome is facility-level compliance violations. However, the primary regulatory mechanism of a 303(d) listing is not to directly change a facility's compliance in the short term but to trigger a process that leads to stricter **permit limits** via a TMDL. These new limits are then incorporated during the facility's next NPDES permit renewal, which can take years. Finding no effect on violations in a short window does not test the policy's mechanism; it may simply reflect implementation lags. The paper should analyze the more proximate outcome: changes in the stringency of permit limits (e.g., concentration or mass-based limits for the impairing pollutant). If permit limits do not change, then a null effect on violations is an indictment of the policy's implementation, not necessarily its potential effect. The discussion section acknowledges this but post-hoc; the empirical analysis should be built around it.

**4. Suggestions**

*   **Implement the Panel DiD Design:** Reconfigure the analysis to use the longitudinal data. Construct a facility-year panel (1998-2024). Define treatment as an indicator that switches on (and stays on) in the year a facility's HUC-12 is added to the 303(d) list. The estimating equation should include facility fixed effects (to control for time-invariant facility heterogeneity), year fixed effects, and HUC-8-by-year fixed effects (to control for all time-varying watershed-level confounders). The sample should be restricted to facilities within a specified bandwidth of a HUC-12 boundary. This design uses both the spatial and temporal variation as intended.
    *   **Specification Checks:** Test for parallel pre-trends by plotting event-study coefficients. Address potential spatial and serial correlation with two-way clustering (facility and watershed-by-time) or Conley standard errors.

*   **Validate the Spatial Discontinuity:**
    *   **Balance Tests:** For the cross-sectional RD component (or within the DiD sample), test for discontinuities in pre-determined facility characteristics (e.g., industrial classification, design flow, age) at the watershed boundary. Use local linear regression with an optimal bandwidth.
    *   **Manipulation Test:** Plot the density of facilities (or their locations) as a function of distance to the boundary. Perform a formal density test (McCrary 2008) to rule out strategic sorting.
    *   **Graphical Evidence:** Create a binned scatterplot of the primary outcome (e.g., pre-period violation rate) against distance to the boundary, separately for each side. This visually assesses the discontinuity assumption.

*   **Analyze the Correct Mechanism:**
    *   **Primary Outcome:** Shift the focus to **permit limit stringency**. Collect data on permitted effluent limits (from EPA's ICIS-NPDES or permit documents) for key pollutants. Test whether limits become more stringent (lower) for facilities in a watershed *after* it is listed for that specific pollutant.
    *   **Secondary/Alternative Outcomes:** If the data permits, examine intermediate steps: do listed watersheds see more frequent permit re-issuances, more enforcement inspections, or higher fines? This helps trace the causal chain from listing to compliance.

*   **Improve Data and Sample Description:**
    *   Clarify the sample construction. The paper states it starts with 18,800 facilities but only geocodes 4,589 major ones. Why? This could introduce selection bias. Discuss the representativeness of the major-facility sample.
    *   The summary statistics table (Table 1) shows that *all* facilities in the sample are "major" (Share major = 1.000). This should be stated clearly in the text, as the result is only generalizable to major dischargers. The title of Table 1 should be updated accordingly.
    *   Provide more detail on the ATTAINS data. How is the "listed" status defined for a HUC-12? Is it based on any impairment, or a specific pollutant? Linking the impairing pollutant to the facility's permitted pollutants would strengthen the analysis.

*   **Strengthen the Interpretation:**
    *   The null result is interesting, but the discussion should be more nuanced. Distinguish between (a) the listing mechanism being inherently ineffective, (b) implementation lags being too long, and (c) the effect being heterogeneous (e.g., only for facilities discharging the specific impairing pollutant). The current analysis cannot distinguish these.
    *   Compare the findings more directly to the cited literature (He et al., Keiser & Shapiro). The contrast with He et al. is particularly valuable; elaborate on the institutional differences (monitoring vs. permitting) that might explain the divergent results.

*   **Minor Presentation Issues:**
    *   The abstract's final sentence states the null result "indicates that the CWA's listing mechanism provides no incremental enforcement bite..." This is too strong a causal claim for the cross-sectional design. Tone it down to reflect the associational nature of the current evidence.
    *   In Table 2, column (1) and (3) have the same dependent variable label ("Violation Rate") but different specifications. Clarify.
    *   The "Standardized Effect Sizes" appendix table (A.2) is not referenced or discussed in the main text. Either integrate it or remove it.

**Overall:** The core idea is innovative and has high potential. However, in its current cross-sectional form, the paper does not deliver a credible causal estimate. By implementing the longitudinal DiD design originally envisioned, rigorously validating the spatial discontinuity, and focusing on permit limits as the key outcome, the authors can transform this into a compelling and publishable study. The required revisions are substantial but feasible given the data sources identified.
