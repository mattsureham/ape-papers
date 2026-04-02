# V1 Empirics Check — mistralai/mistral-large-2512 (Variant A)

**Model:** mistralai/mistral-large-2512
**Variant:** A
**Date:** 2026-04-02T16:52:33.784503

---

### 1. Idea Fidelity

The paper closely adheres to the original idea manifest. It evaluates the effect of state-level single-family zoning preemption on missing middle housing construction using the Census Building Permits Survey (BPS) data and a staggered difference-in-differences (DiD) design. Key elements from the manifest are preserved:

- **Data source**: The paper uses the BPS county-level monthly structure-type breakdowns (2004–2024), though it aggregates to annual data, which is a reasonable simplification.
- **Identification strategy**: The staggered DiD approach with Callaway-Sant’Anna and randomization inference is implemented as proposed. The paper also includes the placebo test (5+ unit permits) and explores heterogeneity by state and urban/rural status.
- **Research question**: The paper directly addresses whether state zoning reform shifts construction toward missing middle housing, with a focus on the "implementation gap" as a key mechanism.

The paper goes beyond the manifest by:
- Emphasizing state-level heterogeneity, particularly Oregon’s success versus other states’ null effects.
- Exploring supply-side constraints and policy design implications in greater depth.
- Including robustness checks (e.g., excluding Montana, urban/rural splits) not explicitly mentioned in the manifest.

The only minor deviation is the exclusion of Washington (HB 1110) from the treated group due to its later compliance date, which is justified but not explicitly foreshadowed in the manifest.

---

### 2. Summary

This paper evaluates the effect of state-level zoning preemption laws (2019–2023) on missing middle housing construction in five U.S. states. Using a staggered DiD design and Census BPS data, the authors find a precisely estimated null effect overall, but dramatic heterogeneity: Oregon’s HB 2001 increased missing middle permit share by 2.6 percentage points, while California, Maine, and Montana showed no detectable response. The paper attributes this divergence to an "implementation gap," where Oregon’s prescriptive approach (mandating code changes, providing templates, and enforcing deadlines) succeeded, while other states’ permissive reforms failed to overcome local discretion. The results challenge the assumption that supply-side deregulation alone can solve housing shortages and highlight the importance of implementation design.

---

### 3. Essential Points

The paper is methodologically sound and makes a valuable contribution, but three critical issues must be addressed before publication:

#### (1) **Pre-trends and Parallel Trends Assumption**
The Callaway-Sant’Anna pre-test rejects parallel trends at *p* = 0.007, driven by Montana’s elevated baseline. While the authors acknowledge this and exclude Montana in robustness checks, the issue is more fundamental:
- The event study (Appendix) shows marginally significant pre-trends at *t* = –2 and –3, suggesting differential trajectories even in non-Montana states.
- **Action required**: The authors must (a) present a formal event study plot (not just Appendix text) to visually assess pre-trends, and (b) discuss whether the Oregon effect is robust to alternative control groups (e.g., only states with similar pre-trends or housing market conditions). If pre-trends persist, the pooled null may reflect bias, and the paper should focus exclusively on state-level heterogeneity.

#### (2) **Mechanism: The Implementation Gap**
The paper’s core claim—that Oregon’s success stems from its prescriptive implementation—is compelling but underdeveloped:
- **Missing evidence**: The paper cites anecdotal reports (e.g., California cities imposing restrictive design standards) but lacks systematic data on implementation differences. For example:
  - Did Oregon counties adopt the state’s model code uniformly? Were there holdouts?
  - Did California cities with fewer design restrictions see larger effects?
  - Were there differences in permitting delays or fees post-reform?
- **Action required**: The authors must either (a) provide descriptive evidence on implementation (e.g., share of Oregon cities adopting model code, examples of California cities with restrictive standards), or (b) weaken the causal language around the "implementation gap" and frame it as a hypothesis for future work.

#### (3) **Interpretation of Montana’s Negative Effect**
Montana’s negative coefficient (–2.7 pp, *p* < 0.001) is dismissed as "mean reversion," but this is unsatisfactory:
- Montana’s pre-treatment missing middle share (6.1% in the manifest’s smoke test) is higher than other states, but the paper does not explain why this would lead to mean reversion *only* after 2023.
- **Alternative explanations**: Could Montana’s reform have been poorly timed (e.g., coinciding with a construction slowdown)? Was there a compositional shift in permit-issuing counties?
- **Action required**: The authors must (a) test whether Montana’s negative effect persists when excluding rural counties (where missing middle construction is rare), or (b) provide a more nuanced explanation (e.g., substitution toward single-family or 5+ unit construction).

---

### 4. Suggestions

#### **Conceptual and Interpretive Improvements**
1. **Clarify the "implementation gap"**:
   - Distinguish between *legalization* (removing zoning barriers) and *implementation* (ensuring construction occurs). The paper’s key insight is that legalization alone is insufficient, but this could be sharpened by:
     - Comparing Oregon’s approach to other states’ reforms in a table (e.g., code mandates, deadlines, enforcement).
     - Citing literature on regulatory federalism (e.g., how states enforce preemption in other domains like labor or environmental law).
   - Consider framing the "implementation gap" as a *theory* rather than a conclusion, and discuss alternative explanations (e.g., construction costs, demand conditions).

2. **Address the null result’s policy implications**:
   - The paper argues that the null challenges the YIMBY model, but this overstates the case. The null could reflect:
     - Short-run effects (the reforms are too recent to observe supply responses).
     - Incomplete implementation (e.g., California’s SB 9 may take years to show effects).
     - Binding non-zoning constraints (e.g., labor shortages, high interest rates).
   - **Suggestion**: Add a paragraph in the Discussion acknowledging these alternatives and discussing how future work could distinguish them (e.g., longer panels, case studies of permit applications).

3. **Revisit the urban/rural heterogeneity**:
   - The paper finds a null effect in urban counties, where housing demand is strongest. This is counterintuitive and warrants deeper exploration:
     - Could urban counties have higher baseline missing middle shares, leaving less room for growth?
     - Were urban counties more likely to impose restrictive design standards post-reform?
   - **Suggestion**: Split the urban sample by housing cost (e.g., high-cost vs. low-cost metros) to test whether demand conditions mediate the effect.

#### **Methodological Improvements**
4. **Improve pre-trend testing**:
   - Present a formal event study plot (e.g., Figure 1) with 95% confidence intervals for leads and lags. This is standard in DiD papers and would help readers assess parallel trends visually.
   - Test whether pre-trends are driven by specific states (e.g., Montana) or are more general. If the latter, consider:
     - Using a synthetic control approach for Oregon (the only state with a clear effect).
     - Restricting the control group to states with similar pre-trends (e.g., using a matching procedure).

5. **Address staggered adoption more rigorously**:
   - The paper uses both TWFE and Callaway-Sant’Anna, which is good, but the staggered adoption is limited (only two cohorts, one year apart). To strengthen the analysis:
     - Show that the TWFE and CS estimates are similar (as claimed) in a table or figure.
     - Discuss whether the small number of cohorts limits the generalizability of the results.

6. **Explore alternative outcome definitions**:
   - The paper focuses on missing middle *share*, but this could be mechanically affected by changes in single-family or 5+ unit construction. To rule out compositional effects:
     - Report results for the *level* of missing middle permits (not just share) in the main text.
     - Test whether the reforms affected the *total* number of permits (e.g., did missing middle construction displace single-family construction?).

#### **Data and Robustness**
7. **Extend the sample period**:
   - The paper uses 2004–2024 data but focuses on 2015–2024 for estimation. Given the reforms’ recency, the pre-period is short (2015–2021). To improve pre-trend testing:
     - Use the full 2004–2024 sample for the event study (even if estimation is restricted to 2015–2024).
     - Test whether the results are sensitive to the pre-period length (e.g., 2010–2021 vs. 2015–2021).

8. **Address zero-permit counties**:
   - The paper excludes counties with zero permits in all years, but many counties have zero missing middle permits in some years. This could bias the share-based outcome.
   - **Suggestion**: Report results using the inverse hyperbolic sine transformation (which handles zeros) or a two-part model (extensive margin: any missing middle permits; intensive margin: share conditional on >0 permits).

9. **Improve placebo tests**:
   - The placebo test (5+ unit permits) is a strength, but it could be expanded:
     - Test whether the reforms affected *single-family* permits (e.g., did missing middle construction displace single-family construction?).
     - Test whether the reforms affected *permit values* (e.g., did missing middle units become more expensive to build post-reform?).

#### **Presentation and Clarity**
10. **Clarify the treatment timing**:
    - The paper states that treatment timing is defined by the "compliance date," but the compliance deadlines vary within states (e.g., Oregon’s HB 2001 had a June 2022 deadline, but some cities may have complied earlier). This could introduce measurement error.
    - **Suggestion**: Discuss whether the results are sensitive to alternative treatment dates (e.g., law passage date, earliest compliance date).

11. **Improve the abstract and introduction**:
    - The abstract and introduction overstate the null result. The paper’s key finding is the *heterogeneity* across states, not the pooled null. Suggested revisions:
      - Abstract: "The pooled treatment effect is indistinguishable from zero, but state-level estimates reveal sharp heterogeneity: Oregon’s HB 2001 increased missing middle share by 2.6 percentage points (*p* < 0.001), while other states showed no detectable response."
      - Introduction: Emphasize that the paper’s contribution is the *comparative* evaluation of state reforms, not the null per se.

12. **Add a map or table of treated counties**:
    - The paper mentions 157 treated counties but does not show their geographic distribution. A map or table would help readers assess whether the results are driven by specific regions (e.g., Portland vs. rural Oregon).

#### **Future Research**
13. **Discuss limitations and next steps**:
    - The paper’s sample period ends in 2024, but the reforms are recent. Acknowledge that effects may grow over time (e.g., as builders adapt to new rules).
    - Suggest future work on:
      - Longer-term effects (e.g., 5–10 years post-reform).
      - Case studies of permit applications (e.g., how often are missing middle projects denied post-reform?).
      - Interaction with other policies (e.g., do ADU legalization laws complement missing middle reforms?).

---

### Final Assessment

This is a strong paper that makes a novel and policy-relevant contribution. The identification strategy is credible, the data are well-suited to the research question, and the heterogeneity analysis is compelling. With the revisions suggested above—particularly addressing pre-trends, strengthening the mechanism discussion, and clarifying the interpretation of the null result—the paper would be suitable for publication in *AER: Insights*. The authors should focus on:
1. **Pre-trends**: Provide visual evidence and robustness checks to ensure the Oregon effect is not driven by differential trends.
2. **Mechanism**: Add descriptive evidence on implementation differences or weaken the causal language around the "implementation gap."
3. **Montana’s effect**: Offer a more nuanced explanation for the negative coefficient.
