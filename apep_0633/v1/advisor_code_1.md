# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-13T16:11:59.726152

---

**Idea Fidelity**

The paper largely adheres to the manifest. It exploits the staggered legalization of recreational marijuana across 20 (24 as originally planned) states, uses the Census Annual Survey of School System Finances through 2022, implements Callaway & Sant’Anna (2021) as the main estimator, and assesses the heterogeneity driven by education earmarking. The falsification strategy—federal revenue placebo—is present, though the manifest-listed additional tests (local property tax, non-education state spending, non-earmark placebo) are only partially implemented. The “fungibility rate” comparison to Evans & Zhang is mentioned qualitatively but not quantified with confidence intervals. Overall, the core idea is pursued, but some of the planned identification checks and robustness analyses need fuller implementation to match the manifest.

---

**Summary**

The paper assesses whether marijuana tax earmarks increase education spending or are absorbed through fiscal fungibility. Using state-level school finance data from 2008–2022 and a Callaway-Sant’Anna difference-in-differences design, the author finds that legalization raises per-pupil education expenditure in earmarking states by about \$1,175, a figure that greatly exceeds observed marijuana revenue per pupil. The result is interpreted as evidence that earmarks provide political cover for broader education spending rather than purely redirecting earmarked dollars.

---

**Essential Points**

1. **Parallel Trends and Dynamic Evidence.** The credibility of the CS-DiD hinges on the parallel trends assumption, yet the paper does not present the required event-study/dynamic graphs or cohort-specific pre-period coefficients. Without these, it is difficult to assess whether legalization states (especially the early Western cohorts) were already on steeper spending paths relative to never-legalizers. Please plot the group-time ATT estimates (or the aggregated event-study with simultaneous confidence bands) and report statistical tests for pre-trend violations. If pre-trends differ, consider conditioning on observable covariates or using alternative control sets.

2. **Treatment Definition and Heterogeneity Interpretation.** States are classified as “earmark” vs “no-earmark,” but the narrative acknowledges that “no-earmark” states still channel revenue to related programs (youth development, etc.) and that earmark states’ commitments vary (some fund capital projects, others operating funds). The paper needs a more systematic coding of earmarking design (e.g., percent of revenue earmarked, level of binding commitment, whether earmarks are statutory or ballot) and to show that the heterogeneity analysis is not confounded by other attributes (e.g., geographic region, fiscal capacity). At present, the \>$1,000 ATT in earmark states could reflect broader policy preferences of those states rather than the earmark per se. Consider a difference-in-differences-in-differences (three-way) design that compares earmark vs non-earmark states while controlling for pre-policy trends or imposing a more flexible time-varying control.

3. **Magnitude versus Revenue and Mechanism.** The central finding—education spending increases by roughly five times the observed marijuana revenue per pupil—is striking but not sufficiently explained. This could result from measurement error in revenue (data are very sparse, covering only 10 states) or from omitted variables: perhaps the same states increased education spending for unrelated reasons (e.g., rising demographics). The paper should integrate the revenue data more directly into the estimation (e.g., instrumenting actual revenue flows with legalization timing, or using a continuous-treatment DiD that weights by per-pupil revenue). Additionally, presenting analyses of other budget categories (non-education spending, overall general fund) would clarify whether the spending surge is specific to education or reflects a broader fiscal expansion.

If these issues cannot be resolved convincingly, the identification conclusions remain tentative. Addressing them is essential before recommending publication.

---

**Suggestions**

1. **Event-Study Diagnostics and Pre-Trend Controls.** Provide the full dynamic ATT plots, either cohort-specific or aggregated over event time, with simultaneous confidence bands to assess pre-legalization trends. If balance fails, consider controlling for lagged spending growth, adding state-specific linear trends, or using synthetic control-like weights for poorly behaved cohorts.

2. **Refine Earmark Coding and Mechanism Testing.** Construct a clear, reproducible taxonomy of earmarking (e.g., share of tax revenue statutorily dedicated to education vs. other purposes). Document how each state’s legislation differs—does the earmark flow to operating spending, capital grants, or general education funds? Use this taxonomy to test whether stricter earmarks (higher shares, statutory vs. discretionary) correlate with larger spending increases. Additionally, test whether the increase is driven by capital outlay (consistent with construction funds) or current spending; Table 1 and Table 3 imply some heterogeneity, but disaggregated time-series would help.

3. **Link Revenue Flows to Spending Effects.** Integrate the marijuana revenue data more directly. For example, estimate whether the observed per-pupil spending increases are mechanically explained by the revenue available using a simple regression: $ \Delta \text{Spending}_{it} = \alpha + \beta \text{RevenuePerPupil}_{it} + \gamma_i + \delta_t + \varepsilon_{it}$. Compare the estimated $\beta$ to the implied passthrough ratio. Consider instrumenting revenue with legalization timing to capture exogenous variation. If revenue data are limited post-2022, emphasize the coverage limitations and discuss how this affects inference.

4. **Placebos and Alternative Outcomes.** The paper already uses federal revenue as a placebo, but additional falsification tests would strengthen the identification claim. Use outcomes that should not respond to legalization (e.g., state spending on transportation) and outcomes that should if fungibility holds (e.g., non-education general fund spending or social services). Also, test whether property tax rates or local effort change post-legalization. This will help distinguish whether the earmarked dollars genuinely augment education budgets or merely cover reallocated general-fund spending.

5. **Address Small Sample / Single Cohort Sensitivity.** Acknowledge the concerns raised by the influence of Alaska more formally. Consider using the wild cluster bootstrap or randomization inference tailored to small-sample inference with 20 treated units. Additionally, report estimates excluding other influential states or using leave-one-out diagnostics to demonstrate robustness.

6. **Clarify the Interpretation of “Passthrough >1.”** The current framing suggests earmarks “work too well,” but this result could simply reflect omitted variables (e.g., economic growth, other concurrent policies). Lay out alternative explanations explicitly and, where possible, test them. For instance, does the spending surge occur immediately after legalization, or is there a lag suggesting broader policy adjustments? Does the spending increase track marijuana revenue growth over time, or is it a one-time jump?

7. **Enhance Discussion of Political Mechanism.** The idea that earmarks provide political cover is intriguing; consider empirically testing this by examining legislative behavior or spending announcements. Can you show that education appropriations voted on post-legalization increased relative to general fund appropriations? If data are unavailable, clearly delineate this as a hypothesis requiring future work rather than a confirmed mechanism.

By addressing these points, the manuscript will better align its empirical strategy with the ambitious research question and provide stronger causal evidence on the fiscal effects of marijuana earmarks.
