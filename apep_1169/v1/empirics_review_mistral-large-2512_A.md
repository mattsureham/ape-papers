# V1 Empirics Check — mistralai/mistral-large-2512 (Variant A)

**Model:** mistralai/mistral-large-2512
**Variant:** A
**Date:** 2026-03-30T21:35:27.642690

---

### 1. Idea Fidelity

The paper closely adheres to the original idea manifest. It leverages the staggered adoption of one-stop business registration portals across 11 U.S. states (2008–2022) to estimate causal effects on new firm formation using the Callaway-Sant’Anna difference-in-differences (DiD) estimator, as proposed. The primary data source (Census Business Formation Statistics via FRED) and outcome variables (total, high-propensity, and wage-planned business applications) align with the manifest. The paper also explores mechanisms (e.g., selection, capital constraints) and heterogeneity (e.g., distance-to-capital interactions), though the latter is not prominently featured in the results.

**Minor deviations:**
- The manifest mentions 11+ states, but the paper lists 11 treated states (Virginia, Kentucky, Nevada, Kansas, Mississippi, Wisconsin, Pennsylvania, Delaware, Connecticut, Texas, Arizona). The manifest’s "11+" may have included states later excluded for data or definitional reasons.
- The manifest highlights "distance-to-capital interaction" as a mechanism, but this is not empirically tested in the paper. The authors instead focus on broader mechanisms (selection, capital constraints).
- The manifest’s "welfare" discussion (implicit time cost savings) is not quantified in the paper.

### 2. Summary

This paper provides the first causal evidence on the effects of U.S. state-level one-stop business registration portals on new firm formation. Using staggered adoption across 11 states (2008–2022) and monthly Census Business Formation Statistics, the authors employ the Callaway-Sant’Anna DiD estimator to find precise null effects: portal adoption does not increase business applications (total, high-propensity, or wage-planned). The results are robust to alternative estimators, pre-trend tests, and leave-one-out checks. The paper argues that administrative friction is not a binding constraint on U.S. entrepreneurship, contrasting with prior findings from developing economies.

### 3. Essential Points

**1. Clarify the treatment definition and scope.**
   - The paper defines one-stop portals as consolidating filings across Secretary of State, Revenue, Labor, and Licensing, but the manifest and institutional background suggest heterogeneity in portal scope (e.g., some may not include licensing). The authors should:
     - Provide a clear, operational definition of "integrated one-stop portal" (e.g., must include at least X of Y agency filings).
     - Justify why partial portals (e.g., only Secretary of State + Revenue) are excluded or included.
     - Address potential measurement error in adoption dates (e.g., phased rollouts, pilot programs).
   - The appendix lists adoption dates but lacks details on how these were verified (e.g., were press releases cross-checked with user data or agency records?).

**2. Strengthen the parallel trends assumption.**
   - While the joint pre-trend test ($p = 0.44$) is reassuring, the paper should:
     - Show event-study plots for all outcomes (not just log BA) to visually assess pre-trends. The current appendix only mentions log BA.
     - Test for differential pre-trends in covariates (e.g., state GDP, unemployment, population) to rule out confounding from unobserved factors correlated with portal adoption.
     - Discuss whether states adopting portals differed systematically from non-adopters in ways that might bias results (e.g., higher baseline entrepreneurship, stronger e-government initiatives).

**3. Address potential power limitations for subgroup analyses.**
   - The manifest proposes testing heterogeneity by "distance-to-capital" (remote counties benefit more), but this is not explored. The authors should either:
     - Include county-level analyses (as mentioned in the manifest) to test this mechanism, or
     - Explicitly acknowledge the omission and justify why the state-level analysis is sufficient.
   - The paper’s power to detect effects for subgroups (e.g., corporate vs. sole proprietorships) is unclear. The authors should report power calculations or confidence intervals for key subgroups to contextualize null findings.

### 4. Suggestions

**A. Data and Measurement**
1. **Portal scope and adoption timing:**
   - Add a table or figure summarizing the scope of each state’s portal (e.g., which agencies are included) to clarify heterogeneity in treatment intensity.
   - Discuss whether portal adoption was phased (e.g., pilot counties before statewide rollout) and how this might affect treatment timing.
   - Consider a falsification test: Did portal adoption affect outcomes unrelated to entrepreneurship (e.g., tax filings, unemployment claims) that might proxy for unobserved confounders?

2. **Outcome variables:**
   - The paper focuses on business applications (BA), but the manifest also mentions county-level annual BFS data. The authors should:
     - Use county-level data to test for spatial heterogeneity (e.g., urban vs. rural effects).
     - Explore whether portals affected the *composition* of applications (e.g., shift from sole proprietorships to LLCs) or *speed* of registration (e.g., time from application to EIN issuance).
   - Clarify whether the BFS captures informal businesses (e.g., gig workers) or only formal registrations. If the latter, the null result might reflect substitution from informal to formal registration rather than no effect.

3. **Covariates:**
   - Include state-level covariates (e.g., GDP, unemployment, population) in robustness checks to address potential confounding. Even if parallel trends hold, covariates can improve precision.

**B. Empirical Strategy**
1. **Estimator choice:**
   - The paper uses Callaway-Sant’Anna (CS) as the primary estimator, which is appropriate for staggered adoption. However:
     - Compare CS results to the *de Chaisemartin and D’Haultfœuille (2020)* estimator, which relaxes the parallel trends assumption for never-treated units.
     - Report the *Sun and Abraham (2021)* estimator’s event-study coefficients to assess dynamic effects (e.g., do effects grow over time?).

2. **Heterogeneity:**
   - Test for heterogeneous effects by:
     - State characteristics (e.g., baseline registration complexity, population density).
     - Portal scope (e.g., states with more integrated portals may see larger effects).
     - Time since adoption (e.g., learning curves for users).
   - The manifest’s "distance-to-capital" hypothesis is compelling. The authors should either test it or drop it from the paper to avoid misleading readers.

3. **Mechanisms:**
   - The paper discusses three mechanisms (selection, capital constraints, intent creation) but provides no empirical tests. Suggestions:
     - Use survey data (e.g., Kauffman Firm Survey) to test whether portal adopters report lower registration costs or higher satisfaction.
     - Compare effects on corporate applications (CBA) vs. sole proprietorships, as the latter may face lower registration barriers.
     - Test whether portals increased *compliance* (e.g., fewer abandoned applications, faster processing times) even if they didn’t increase applications.

**C. Interpretation and Generalizability**
1. **Null results:**
   - The paper frames the null as evidence that administrative friction is not binding in the U.S. This is plausible, but the authors should:
     - Discuss whether the null could reflect offsetting effects (e.g., portals increase applications but also increase failures due to lower-quality entrants).
     - Compare the U.S. context to developing economies more explicitly (e.g., baseline registration costs, enforcement of business laws).
   - Acknowledge that portals may have *dynamic* effects not captured in the short post-treatment windows (e.g., learning effects, network externalities).

2. **Policy implications:**
   - The paper concludes that portals are "worth doing for efficiency reasons" but not for increasing entrepreneurship. This is reasonable, but the authors should:
     - Quantify the efficiency gains (e.g., time saved per entrepreneur, as hinted in the manifest).
     - Discuss whether portals might have *long-term* effects (e.g., reducing churn in the business population, improving survival rates).
     - Compare the cost of portal implementation to alternative policies (e.g., SBA loans, tax credits) to contextualize cost-effectiveness.

3. **Limitations:**
   - The paper’s limitations section is thorough but could be expanded:
     - Discuss whether the BFS captures *all* new businesses (e.g., informal firms, gig workers).
     - Address potential spillovers (e.g., portals in one state may affect neighboring states via competition or migration).
     - Acknowledge that the analysis is at the state level, masking heterogeneity within states (e.g., urban vs. rural).

**D. Presentation and Clarity**
1. **Tables and figures:**
   - Add an event-study plot for all outcomes (not just log BA) to visually assess pre-trends.
   - Include a map of treated vs. untreated states to help readers contextualize the geographic distribution of adoption.
   - Simplify Table 1 (summary statistics) by focusing on key variables (e.g., drop redundant columns).

2. **Writing:**
   - The abstract and introduction are clear, but the discussion of mechanisms (Section 5) could be more concise. Consider moving some details to the appendix.
   - The "friction fallacy" framing is compelling but could be sharpened. For example, contrast the U.S. to developing economies more explicitly in the introduction.
   - The conclusion’s claim that "simplifying business registration does not generate new businesses" is strong. Soften it to reflect the paper’s focus on *applications* (not actual firm creation or survival).

3. **Appendix:**
   - Move the Goodman-Bacon decomposition (Table 3) to the main text, as it is central to the estimator choice.
   - Add a table listing portal adoption dates with sources (currently buried in the appendix).
   - Include a table of state-level covariates (e.g., GDP, population) to assess balance.

### Final Assessment

This is a well-executed paper that makes a valuable contribution to the literature on entrepreneurship and administrative barriers. The identification strategy is credible, the empirical approach is rigorous, and the null results are informative. With the suggested improvements—particularly around treatment definition, heterogeneity, and mechanisms—the paper could be even stronger. The authors should address the three essential points above to ensure the robustness and clarity of their findings. **Recommendation: Revise and resubmit.**
