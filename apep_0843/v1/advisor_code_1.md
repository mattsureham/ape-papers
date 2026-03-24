# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-24T14:35:41.953216

---

**Idea Fidelity**  
The paper adheres closely to the manifest. It exploits the staggered adoption of Remote Online Notarization (RON) laws across 22 states between 2012 and 2019, uses monthly Census Business Formation Statistics obtained via the FRED API, and applies the Callaway–Sant’Anna staggered DiD estimator to estimate effects on business applications. The comparison between notarization-intensive (corporate BA) and less-intensive outcomes is present, as is the focus on pre-COVID, permanent adoption cohorts. The paper captures the original research question and identification strategy without notable omissions.

---

**Summary**  
The paper asks whether removing the in-person notarization requirement via Remote Online Notarization laws increased new business formation in the U.S. Using state-month data on business applications from the Census BFS and a Callaway–Sant’Anna staggered DiD estimator, it finds no detectable effect on overall business applications or on notarization-intensive categories such as corporate filings. Robustness checks, event studies, and minimum detectable effect calculations are used to argue that the null result is precisely estimated and policy-relevant.

---

**Essential Points**

1. **Control for Time-Varying Confounders**  
   The paper relies on parallel trends vis-à-vis never-treated states, but it does not incorporate any state-specific controls (e.g., economic activity, population growth, other regulatory changes) that might drive both RON adoption timing and business formation. Some of the adopters (Texas, Florida, etc.) may have been on different trends in construction, housing, or institutional reforms that also affected BFS. Including basic state-year economic controls or state-specific linear trends would strengthen the credibility of the parallel-trends assumption.

2. **Mechanism Placebo Tests and Comparison Groups**  
   The key mechanism is the elimination of a notarization-specific friction. While the paper compares corporate applications to aggregate applications, a stronger mechanism test would identify an outcome that should not respond if the friction is indeed notarization. For example, applications for sole proprietorships or filings in industries that do not require notarization could serve as falsification outcomes. Alternatively, using a within-state comparison between notarized and non-notarized filings (if data allow) would reinforce that the tested policy map is the relevant friction.

3. **Dynamic Treatment Adoption and Late Adopter Characteristics**  
   The 2019 cohort comprises 12 states, potentially dominating the aggregate ATT. The paper conducts leave-one-cohort-out checks but does not account for potential heterogeneity between early (1-2 states) and late adopters (12 states). Given the varying pre-treatment lengths and regional clusters, a more detailed breakdown of ATT by cohort or an estimation allowing for cohort-specific trends would help assess whether the null is driven by particular cohorts or by pooling states with divergent trajectories.

If additional concerns arise beyond these three points (e.g., treatment coding, resulting general equilibrium effects), the paper lacks sufficient novelty/identification and should be rejected, but based on current content major corrections should suffice.

---

**Suggestions**

1. **Enhance Parallel Trends and Control Strategy**  
   - Consider including state-level time-varying covariates (e.g., unemployment rate, GDP per capita, business-friendly policy indices) in the DID specification, either directly in the \texttt{did} call or via a pre-processing step, to absorb differential shocks that may correlate with RON adoption.  
   - Alternatively, implement state-specific linear trends or flexible event-time fixed effects to ensure that pre-treatment divergence is not hiding within the estimated zero.  
   - Report the results of placebo tests where treatment is randomly assigned to never-treated states to demonstrate that the estimator is not mechanically zero.

2. **Strengthen Mechanism Narrative with Additional Outcomes**  
   - Add a falsification outcome that should be unaffected by notarization (e.g., new applications for businesses that typically do not require notarization, or an outcome entirely unrelated to notarial acts such as building permits).  
   - If feasible, use data on the share of filings requiring notarization (or proxies such as industries from BFS) to demonstrate that the policy specifically operates through notarization-heavy activities.  
   - Provide supplementary plots or tables showing the raw (non-log) trajectories of corporate vs. non-corporate applications to allow readers to visually inspect the absence of a mechanical effect.

3. **Decompose ATT by Cohort and Address Heterogeneity**  
   - Report group-time ATT estimates (not only aggregate) for each cohort, or at least early vs. late cohorts, to illustrate whether any cohort shows a signal. This will help readers understand whether the null is a true absence of effect or the averaging of opposite-signed effects.  
   - Given the small number of early adopters (Virginia, Montana), consider whether their long pre-treatment windows dominate the event study. Showing cohort-specific event studies (e.g., aggregated for 2018 vs. 2019 cohorts) could be informative.  
   - Explore whether the effect differs by state characteristics (urbanization, notary density, existing digital infrastructure) to contextualize why RON may not have moved the needle in some places.

4. **Clarify Treatment Coding and Timing**  
   - Describe more precisely how treatment timing is assigned when a law is enacted in the middle of a month: is treatment coded from the first day of the effective month? Could there be anticipatory behavior in the months when the law is passed but not yet effective?  
   - Include the exact treatment dates in an appendix table and, if possible, plot the reform timing against a heat map of the outcomes to provide readers with intuition about the staggered design.

5. **Discuss Alternative Channels and Limitations**  
   - The discussion section could elaborate on why RON might fail to affect business formation despite being a tangible reform. Is it because notarization is rarely binding for new firms, because entrepreneurs can easily schedule in-person notarizations, or because RON uptake was limited due to complementary regulations (e.g., banks refusing RON-signed documents)?  
   - Discuss potential measurement error in BFS for this context—e.g., if corporate applications are still a small share of total formations, how does that affect the power of the tests?  
   - Acknowledge that the null result does not imply zero welfare benefits—RON may generate convenience or reduction in fraud even if it does not change firm creation, and provide suggestions for future research to explore these margins.

6. **Improve Presentation of Robustness and Power**  
   - When discussing minimum detectable effects, present the formula or computation in the appendices to allow replication (e.g., show the pooled standard error and the assumed variance).  
   - Provide a figure showing the estimated ATT over time (event study) with confidence intervals to improve interpretability beyond tabular form.  
   - Consider plotting the distribution of treatment dates and treatment intensity (number of states treated per month) to show whether the design is concentrated (e.g., many states in 2019) or well-distributed.

7. **Replication and Open Science**  
   - Although the paper links to a project repository, explicitly state whether the replication files (code, data pulls) will be made publicly available upon publication.  
   - Summarize in the appendix the specific FRED series codes used for each outcome to facilitate replication.

These suggestions aim to reinforce the credibility of the null finding, provide deeper insight into the mechanism, and make the paper more transparent and informative for both policymakers and researchers.
