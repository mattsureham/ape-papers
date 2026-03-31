# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant B)

**Model:** deepseek/deepseek-v3.2
**Variant:** B
**Date:** 2026-03-31T11:47:34.577410

---

**REFEREE REPORT**

**Paper Title:** The Downwind Tax: Coal Pollution Transport and Rural Employment

---

### 1. Idea Fidelity

The paper **deviates significantly from the core identification strategy outlined in the original idea manifest**. The manifest proposed a clear **instrumental variables (IV) design**: using the HyADS atmospheric dispersion model's *predicted* coal PM2.5 exposure as an instrument for *actual, monitored* PM2.5 concentrations (from EPA AQS). The strength of this approach, as argued in the manifest, lies in using a physics-modeled variable (which is a function of emissions and meteorology/terrain) to isolate exogenous variation in pollution, purging measurement error and addressing potential correlation between actual pollution and local economic conditions.

The submitted paper **abandons this IV framework**. Instead, it uses the HyADS-modeled coal PM2.5 concentration directly as the regressor of interest in a reduced-form panel regression. This is a fundamentally different, and weaker, empirical strategy. The critical assumption now is that *within-county changes in modeled coal PM2.5 are uncorrelated with unobserved shocks to county employment*, conditional on county and year fixed effects. The authors provide some justification (distant plants, federal regulations), but this is a standard conditional exogeneity assumption, not the more compelling exclusion restriction offered by the physics-based IV. The paper therefore misses the key innovative element—the "physics-model IV"—that was central to the original idea's contribution and its claim to causal identification.

Furthermore, the paper uses a truncated sample (2014–2019 for outcomes) compared to the manifest's suggested ~20-year panel, reducing power and potentially missing the most significant variation from early regulatory phases.

### 2. Summary

This paper provides reduced-form estimates suggesting that declines in coal-attributable air pollution, as modeled by the HyADS atmospheric dispersion system, are associated with increases in county-level employment, particularly in rural areas. It finds no corresponding effect on average wages. The authors interpret these findings as evidence that cross-border pollution acts as a disamenity, reducing local labor supply on the extensive margin.

### 3. Essential Points

The authors must address these three critical issues before the paper can be considered for publication.

1.  **Implement the Proposed Instrumental Variables Strategy.** The paper's current identification strategy is not what was promised and is less credible. The authors must use the HyADS-predicted coal PM2.5 as an instrument for actual, measured PM2.5 (from EPA AQS monitors, interpolated to counties if necessary). This requires presenting a first-stage regression, reporting the instrument's strength (F-statistic), and discussing the exclusion restriction in detail: why does *modeled* pollution from upwind plants, based on physics and distant plant activity, affect local outcomes *only through* actual ambient pollution, conditional on controls? This is the core contribution promised in the manifest. The current reduced-form analysis should become the second stage of this IV model or be presented as a complementary result.

2.  **Extend the Outcome Data Panel and Reconcile Sample Periods.** The analysis uses a puzzlingly short and late window for outcomes (2014–2019). The HyADS data runs from 1999–2020, and the manifest listed BLS QCEW data from 1990. The most dramatic changes in coal PM2.5 occurred in the 2000s and early 2010s due to CAIR/CSAPR and MATS. The current 6-year window captures only the tail end of this trend, sacrificing immense statistical power and relevance. The authors must explain the choice of this short panel and extend the outcome data back to at least 1999 (or the earliest point of reliable QCEW county-level data) to harness the full identifying variation. The discrepancy between the available data and the data used must be justified or corrected.

3.  **Confront the State×Year Fixed Evidence and Confounding Directly.** The paper notes that the employment effect attenuates and loses significance when state×year fixed effects are included. This is a major red flag, suggesting that the identifying variation may be correlated with unobserved state-level economic shocks (e.g., regional business cycles, state-level policies) that also affect employment. The authors cannot merely note this as a "limitation" and proceed. They must:
    *   Systematically analyze whether the timing of coal PM2.5 declines is correlated with other state-level trends (e.g., coincident manufacturing declines, shale gas booms in certain states).
    *   Conduct a placebo test using the HyADS instrument *lagged* or *led* to see if "future" pollution predicts current employment changes.
    *   Consider an alternative research design that more explicitly isolates shocks from *specific distant plant closures or retrofits* and traces their effects on downwind counties, comparing them to upwind or non-downwind counties (a difference-in-differences style approach leveraging the unit-ZIP code linkages in HyADS).

### 4. Suggestions

These recommendations would substantially improve the paper but are not absolute prerequisites for a revise-and-resubmit.

**Empirical Analysis & Identification:**
*   **Clarify the "Exposure" Variable:** The HyADS output is a *relative concentration* or *exposure contribution*, not a physical concentration in µg/m³. The paper should explain precisely what the variable measures (e.g., µg/m³-years of exposure per unit emission) and how it is calibrated or validated against monitored data. Discuss any potential scaling issues.
*   **Explore Dynamic Effects & Lag Structure:** Does the effect of pollution on employment manifest immediately or over several years? Estimate distributed lag models or include lags of the key regressor. This can inform mechanism (e.g., slow migration response vs. acute health-driven absenteeism).
*   **Formalize and Test the Spatial Equilibrium Mechanism:** The interpretation relies on a Rosen-Roback style model. Sketch a simple two-equation framework (labor supply and demand) to show how a pure disamenity shock could reduce employment with ambiguous effects on wages. Then, test auxiliary predictions: does the effect vary with housing prices or population density? Are effects stronger in sectors more sensitive to amenities (e.g., recreation, remote-work-compatible jobs)?
*   **Robustness with Alternative Error Clustering:** State-level clustering may be too coarse. Consider two-way clustering by county and year, or Conley standard errors that account for spatial correlation. Demonstrate that results are not sensitive to this choice.
*   **Business Dynamism Outcomes:** The manifest listed establishment births/deaths from Census CBP as an outcome. This is a fascinating margin that could directly speak to firm location decisions. Include these outcomes to strengthen the mechanism story.

**Presentation & Context:**
*   **Improve the Introduction and Literature Review:** The introduction could more sharply contrast this paper's approach (using a full-physics model for a specific pollution source) with prior work like Deryugina et al. (2019) that uses wind direction bins. Explicitly state the methodological contribution.
*   **Policy Quantification:** The back-of-the-envelope calculation in the conclusion is helpful. Make it more rigorous. Use the IV estimates (once implemented) to calculate the total employment gains from the coal PM2.5 decline between, say, 2005 and and 2020. Compare the magnitude to other documented benefits of coal retirement (e.g., mortality benefits from Henneman et al.).
*   **Discuss External Validity:** Coal PM2.5 is a specific component of total PM2.5. Can these elasticity estimates be generalized to other sources of particulate pollution? Why might coal PM2.5 have different effects (e.g., composition, perception)?
*   **Data Appendix Detail:** The final paper must include a comprehensive data appendix detailing the exact steps to construct the analysis panel from raw HyADS outputs, QCEW files, and crosswalks. This ensures replicability.
*   **Tables and Figures:**
    *   **Figure 1:** Provide a map showing the geographic distribution of the change in coal PM2.5 from 1999 to 2020 or from the start to the end of your sample.
    *   **Figure 2:** Plot the event study coefficients if adopting a plant-closure-based design.
    *   **Table 1:** Add a column for "Within-County SD" for key variables to highlight the relevant variation.
    *   **First-Stage Table:** When implementing IV, present the first-stage regression table prominently.
*   **Title and Abstract:** Consider refining the title to more accurately reflect the method (e.g., "Atmospheric Transport Modeling and the Employment Costs of Coal Pollution"). The abstract should clearly state the empirical strategy used (e.g., "We use the HyADS atmospheric model as an instrument for monitored PM2.5...").

**Conclusion:**
The paper tackles an important and policy-relevant question with a novel dataset. Its current execution, however, falls short of the innovative identification strategy that was proposed. By implementing the IV design, extending the data panel, and rigorously addressing the state-level confounding concern, the authors can transform this into a compelling contribution that truly bridges atmospheric science and labor economics.
