# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant A)

**Model:** deepseek/deepseek-v3.2
**Variant:** A
**Date:** 2026-03-24T19:12:02.146633

---

**Referee Report**

**Paper:** “The Conscription Complement: Mandated Service Labor and Paid Employment in Swiss Healthcare”

---

### 1. Idea Fidelity

The paper successfully pursues the core idea outlined in the manifest: it exploits the sharp 2009 Tatbeweis reform as a natural experiment to estimate whether an exogenous influx of quasi-free mandated labor crowded out or complemented paid employment in Swiss healthcare and social sectors. The research question, primary data sources (BFS BESTA, ZIVI reports), and the basic DiD design comparing treated (NOGA 86-88) to control service sectors are faithfully implemented.

However, the paper departs from several key elements of the proposed identification strategy, weakening the potential credibility of its claims:
*   **Omitted Built-in Test:** The manifest explicitly mentioned the **2011 partial reversal** (a drop in admissions) as a "built-in test" for a dose-response relationship. The paper does not leverage this. Analyzing employment trends around this 2011 inflection point would significantly strengthen the case for a causal link.
*   **Missing Triple-Difference:** The manifest proposed a canton-level triple-difference design exploiting variation in deployment intensity. The paper remains at the **national sector level**, sacrificing a powerful source of cross-sectional variation and the ability to control for canton-time confounders (e.g., cantonal healthcare policies, demographic shifts). This is a major missed opportunity.
*   **Simplified Empirical Approach:** The analysis relies on a standard two-way fixed effects model. The manifest suggested a more nuanced approach, including a placebo test on unaffected sectors and a focus on "dose-response." While the paper includes a placebo test (fake 2006 reform) and a post-period split, the absence of the canton-level dimension means the "dose-response" is only temporal, not intensity-based.

In summary, the paper executes the basic idea but implements a less rigorous and less nuanced empirical strategy than originally envisioned, omitting features that would have greatly bolstered identification.

### 2. Summary

This paper provides novel evidence that a large, exogenous increase in mandated civilian service labor in Switzerland’s health and social care sectors—triggered by a 2009 policy reform—led to a significant increase in paid employment in those sectors, suggesting complementarity rather than crowd-out. The primary contribution is applying a classic labor supply shock framework to a unique setting (conscript labor) and shifting the focus from returns to conscripts to the equilibrium response of the receiving sectors.

### 3. Essential Points

The following critical issues must be addressed for the paper to be credible. Failure to adequately engage with points 1 and 2 would, in my view, warrant rejection.

1.  **The Threat of Differential Pre-Trends and the Sector-Specific Trends Result.** The paper acknowledges that adding sector-specific linear trends reduces the main coefficient to near-zero and insignificant. It offers two interpretations but leans toward dismissing it as over-control. This is not sufficient. The event study shows small, negative pre-trend coefficients that attenuate toward zero. This pattern, combined with the dramatic reduction when linear trends are added, strongly suggests the treated sectors were on a **steeper growth trajectory *prior* to the reform**. The event-study confidence intervals are wide, and the pre-trend coefficients, while insignificant, are not convincingly zero. The authors must:
    *   Formally test for parallel pre-trends (e.g., joint significance of pre-period interaction terms).
    *   Engage seriously with the possibility that the reform accelerated an existing divergence rather than caused a break. This could involve discussing underlying demand drivers (aging population) and testing whether the *acceleration* in growth post-2009 is unique relative to pre-2009 trends.
    *   Consider a more flexible specification, such as interacting `Treated` with a linear time trend *only in the pre-period*, to account for pre-existing differential growth before estimating the reform's effect.

2.  **Aggregation Bias and Heterogeneity.** The analysis aggregates three distinct sectors: Hospitals (86), Residential Care (87), and Social Work (88). These likely have different production functions, skill requirements, and capacity to absorb and utilize low-skilled conscript labor. A critical, policy-relevant question is obscured: does complementarity hold everywhere, or is it driven by one sub-sector (e.g., residential care aides complementing nurses) while others may show substitution? The authors must:
    *   Present results for each of the three treated sectors separately (vs. controls). This is crucial for interpreting the mechanism and generalizability.
    *   Acknowledge that the "health and social care" aggregate is overly broad and that the headline effect may mask important heterogeneity.

3.  **Fragile Inference and Limited Design.** With only **3 treated units** (sectors), the design is inherently underpowered and inference is fragile. The permutation p-value of 0.099 correctly highlights this. The paper cannot rely solely on cluster-robust SEs. The authors must:
    *   Make permutation-based inference the primary method for assessing statistical significance, not a supplementary check. The abstract's claim of a "marginally significant" effect under permutation should be front and center in the results, not buried.
    *   Acknowledge this fundamental limitation as a major caveat to any strong causal conclusions. The potential for a Type I error is non-trivial.

### 4. Suggestions

**A. Robustness and Specification Checks:**
*   **Conduct a Synthetic Control Analysis:** Given the small number of treated units, constructing a synthetic control for the aggregated health/social sector (or for each sub-sector) using the donor pool of control sectors would be more robust than a simple DiD with many heterogeneous controls. This would visually and quantitatively assess pre-trend alignment and the post-treatment effect.
*   **Test Alternative Pre-Periods:** The paper uses 2005-2008 as pre-treatment. Show that the results are not sensitive to using, for example, 2003-2008 or 2000-2008.
*   **Explore Non-Linear Trends:** Instead of (or in addition to) linear sector trends, consider including sector-specific quadratic trends or interacting sector FEs with broader time dummies (e.g., year-group interactions) to more flexibly account for underlying divergence.
*   **Incorporate the 2011 Reversal:** Follow the manifest's suggestion. Use the 2011 admission drop as a second shock. A model with time-varying "treatment intensity" (e.g., annual FTE of civilian servants in health/social) would be more informative than a binary post indicator. Does employment growth slow or flatten when the inflow slows?

**B. Mechanism and Interpretation:**
*   **Disentangle Mechanisms:** The discussion section lists capacity expansion, demand revelation, and pipeline effects. Provide some exploratory evidence. For example:
    *   *Capacity:* If possible, find data on sector outputs (e.g., hospital bed-days, care home residents). Does output grow faster in treated sectors post-reform?
    *   *Pipeline:* Use ZIVI or labor force data to test if cantons/regions with more civilian service placements later saw higher growth in *young male* employment in healthcare.
*   **Calibrate the Magnitude:** The 10:1 multiplier (50,000 paid FTE vs. 5,200 conscript FTE) strains credibility as a direct effect. The discussion should more forcefully frame this as the reform "accelerating" or "catalyzing" underlying growth in a constrained sector, with the DiD capturing the total differential growth, not a pure causal multiplier. Use back-of-the-envelope calculations to ask what share of the *overall* sector growth is attributed by the DiD.

**C. Presentation and Narrative:**
*   **Improve Visuals:** The event-study figure (currently a table) should be a graphical plot with confidence intervals. A figure plotting the evolution of log FTE for the treated aggregate and a synthetic control (or a carefully selected control group average) would be powerful.
*   **Refine the Literature Context:** Sharpen the contribution relative to the "conscription-earnings" literature. The paper correctly notes the shift in focus, but it could more explicitly tie the "crowd-out" theory to the broader literature on public job creation, workfare, and the economics of volunteering (where crowding out of paid labor is a central concern).
*   **Policy Implications:** The conclusion is well-stated. Consider adding a nuanced point about the *type* of conscript labor: is it the "near-free" aspect or the fact that it's a flexible, temporary workforce that drives complementarity? This helps generalize the finding beyond Switzerland.

**D. Data and Measurement:**
*   **Justify Control Group Selection:** The control group is very broad (retail to arts). The "narrow controls" specification is a good check. Provide a table showing pre-reform trends (e.g., growth rates in FTE from 2003-2008) for the treated sectors and each potential control sector to demonstrate the parallel trends assumption is most plausible for which comparators.
*   **Discuss Data Limitations:** Acknowledge that BESTA data may not perfectly capture all paid employment (e.g., very small practices). Also, discuss if there were any other major healthcare policy changes in Switzerland around 2009 (e.g., insurance reforms, hospital financing) that could confound the results.

**Overall:** The paper tackles a clever, policy-relevant question with a clear natural experiment. The current draft, however, relies on a potentially flawed parallel trends assumption and an overly aggregated analysis. Addressing the **Essential Points** is non-negotiable. Implementing the **Suggestions**, particularly those related to robustness checks and exploring heterogeneity, would transform this from a suggestive and interesting analysis into a much more compelling and credible piece of evidence.
