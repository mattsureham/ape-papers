# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant B)

**Model:** deepseek/deepseek-v3.2
**Variant:** B
**Date:** 2026-03-29T14:35:45.360714

---

**Referee Report: "The Treatment Dividend: Supply-Side Opioid Restrictions and Medicaid Addiction Treatment"**

**1. Idea Fidelity**

The paper deviates from the original idea manifest in several critical ways, compromising the core causal identification strategy. The manifest proposed a *shift-share IV* design leveraging a *panel* of county-year data, where the instrument (pre-rescheduling HCP share × post-2014 indicator) would isolate the supply shock's timing. The paper instead implements a *cross-sectional* reduced-form regression, correlating a pre-period HCP share (2006–2012) with a post-period outcome (2018–2024). This design cannot recover the causal effect of the rescheduling for three key reasons: (1) it lacks a control group (all counties are "post-treatment"), (2) it cannot test for parallel pre-trends due to the absence of pre-2014 outcome data, and (3) it does not address the first-stage relationship between the instrument and actual opioid supply changes post-2014, which was central to the original identification story. The paper thus misses the central element of the manifest—using the rescheduling's timing as an exogenous shift—and instead relies on a much weaker, potentially confounded, cross-sectional comparison.

**2. Summary**

This paper examines whether counties more reliant on hydrocodone prior to its 2014 federal rescheduling saw higher subsequent utilization of Medicaid-funded medication-assisted treatment (MAT). Using a cross-sectional design linking pre-rescheduling prescription data (ARCOS, 2006–2012) to post-rescheduling Medicaid claims (T-MSIS, 2018–2024), it finds a positive but statistically insignificant relationship. The paper concludes that any "treatment dividend" from this major supply shock is too modest or heterogeneous to detect with this approach, highlighting the challenges of linking supply restrictions to treatment demand.

**3. Essential Points**

The following issues are fundamental and must be addressed for the paper to constitute a credible causal analysis.

*   **Issue 1: The cross-sectional design does not identify the effect of the rescheduling.** The analysis compares counties with different historical HCP shares *after* the policy change, with no pre-policy outcome measures. The estimated relationship could be driven by pre-existing, persistent differences in treatment infrastructure, physician behavior, or patient demographics that are correlated with historical HCP prescribing. The balance test (Table 2) confirms that HCP share is correlated with observable county characteristics (poverty, race, population) even after state fixed effects, raising serious concerns about unobserved confounders. The paper must implement a panel data design (e.g., county-year observations spanning pre- and post-rescheduling) to leverage the timing of the policy shock for identification. At a minimum, the authors must locate and incorporate pre-2014 Medicaid treatment data (e.g., from SAMHSA's TEDS or earlier Medicaid files) to establish parallel pre-trends.

*   **Issue 2: The absence of a first stage invalidates the shift-share logic.** The entire identification strategy, as proposed in the manifest, hinges on the rescheduling causing a larger reduction in opioid supply in high-HCP-share counties. The paper presents no evidence that this occurred. It is essential to demonstrate the first stage: show that counties with higher pre-rescheduling HCP shares experienced a larger decline in total opioid volume (or HCP volume) *after* October 2014 compared to before. Without this, the "shift" component of the shift-share design is absent, and the interpretation of HCP share as a measure of "exposure to the supply shock" is unsupported. The authors should estimate this first stage using ARCOS data from, for example, 2010–2017.

*   **Issue 3: The outcome period (2018–2024) is too distant from the treatment (2014) for a clean test.** The rescheduling occurred in late 2014, but the outcome data begins in 2018. This four-year gap allows for many confounding events (e.g., the fentanyl crisis intensifying, state Medicaid expansions, the SUPPORT Act of 2018) that independently affect MAT utilization and may be correlated with historical HCP shares. The long lag also makes it difficult to attribute any observed effect to the rescheduling, as displaced users' pathways to treatment (or illicit markets) likely unfolded within 1-3 years. The analysis should focus on an outcome window closer to the policy change (e.g., 2015–2017), even if it requires using different data sources.

**4. Suggestions**

*   **Restructure as a Difference-in-Differences or Event Study:** Reconfigure the analysis to have county-year (or county-quarter) observations. The treatment variable should be the interaction between a county's pre-rescheduling HCP share and a post-2014 indicator (or a series of year indicators). This directly implements the shift-share instrument in a two-way fixed effects framework. Plot event-study coefficients to visually assess pre-trends and the dynamic effect.

*   **Locate and Integrate Pre-2014 Treatment Data:** The most pressing data limitation is the lack of pre-period outcome measures. Explore alternative data sources for the pre-period, such as:
    *   SAMHSA's Treatment Episode Data Set (TEDS), which includes admissions to substance use treatment facilities, available back to the 1990s.
    *   Medicaid MAX data (pre-2018) or early T-MSIS pilot states.
    *   Medicare Part D data for buprenorphine prescriptions, which is publicly available from 2011 onward.
    Even imperfect pre-period measures would significantly strengthen the design by enabling a test for parallel trends.

*   **Estimate and Report the First Stage:** Use ARCOS data from at least 2011–2017 to estimate: `ΔOpioid_Supply_ct = α + β (HCP_share_c × Post_t) + η_c + λ_t + ε_ct`. Demonstrate that high-HCP-share counties experienced a relative decline in opioid shipments after rescheduling. Discuss and test for substitution to other prescription opioids (e.g., oxycodone, tramadol).

*   **Refine the Outcome Variable:** The current outcome aggregates all MAT claims from 2018–2024. Consider:
    *   Creating quarterly or annual measures to model dynamics.
    *   Distinguishing between treatment *initiation* (e.g., first claim for an individual in a year) and ongoing treatment. The policy may affect these margins differently.
    *   Using county-level MAT *enrollment* counts if available, in addition to claims.

*   **Address Substitution and Illicit Market Channels Directly:** The "killer critique" in the manifest was substitution. The paper should engage with this more deeply. If data permits, examine whether counties with higher HCP exposure saw larger increases in heroin- or fentanyl-related overdose deaths (from CDC WONDER) post-2014. This would provide a more complete picture of the trade-off between treatment and illicit substitution.

*   **Improve the Balance Test and Robustness:** The current balance test shows concerning correlations. The authors should:
    *   Report normalized differences for key covariates.
    *   Conduct a joint test of significance for all covariates in a multivariate regression.
    *   Consider a sensitivity analysis using entropy balancing or matching to pre-process the data and create a more balanced sample of counties.

*   **Clarify the Contribution and Literature Review:** The introduction states that "the evidence on whether these interventions generate a 'treatment dividend' remains strikingly thin." The paper should more precisely situate itself relative to the closest related work (e.g., DiNardi (2025) on facility availability, Alpert and Evans on substitution to heroin) and clarify how the proposed design and data would advance beyond these studies.

*   **Temper Claims of Causality:** Given the current cross-sectional design, the language throughout the paper should be scaled back from causal to associational. The abstract's conclusion about the "limits of cross-sectional identification" is appropriate, but the main text often implies a causal interpretation that the design cannot support.

*   **Technical Suggestions:**
    *   In Table 3 (mechanisms), the note says the effect is "concentrated in methadone," but the coefficient for buprenorphine is larger in magnitude and the text later says buprenorphine shows the "strongest signal." Resolve this inconsistency.
    *   Report cluster-robust standard errors at the county level, not the state level, unless the treatment varies at the state level (it does not). The shift-share design may require alternative inference methods (e.g., Conley spatial HAC, state-level clustering if the shares are imbalanced across states).
    *   The sample size drops from ~3,000 counties in the manifest to 587 in the paper. Justify this sample restriction more transparently and test robustness to including all counties with ARCOS data.

**Overall Assessment:** The paper addresses a policy-relevant question with rich, novel data. However, in its current form, it does not deliver on the promise of the original idea to provide a causal estimate of the rescheduling's effect on treatment demand. The cross-sectional design is vulnerable to severe confounding. The essential points above must be convincingly addressed—principally by moving to a panel design with a pre-period and estimating the first stage—for the paper to make a credible causal contribution. The suggestions provide a path forward for a substantial revision.
