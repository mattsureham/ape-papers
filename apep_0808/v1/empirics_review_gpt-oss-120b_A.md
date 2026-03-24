# V1 Empirics Check — openai/gpt-oss-120b (Variant A)

**Model:** openai/gpt-oss-120b
**Variant:** A
**Date:** 2026-03-23T12:56:31.259157

---

**Referee Report – The Compliance Cliff: Mass Organizational Death and Selective Resurrection in the U.S. Non‑profit Sector**  

---

### 1. Idea Fidelity  

The paper follows the manifest’s core premise: it exploits the 2010 IRS “auto‑revocation” wave (377 k nonprofits, 10 % reinstatement) as a natural experiment to examine which organizational characteristics predict survival after a common regulatory shock.  

**What is retained:**  
- Use of the three‑dataset triad (Auto‑Revocation List, Business Master File, ProPublica API).  
- Focus on cross‑subsection, cross‑state, and “asset‑holding” variation as the identification lever.  
- Presentation of the shock as a discrete, exogenous event.  

**What is missing or altered:**  
- The manifest proposed a **dose‑response analysis using organization age as a running variable**; the paper never implements a regression‑discontinuity or analogous “running‑variable” approach.  
- The original idea highlighted **temporal variation in reinstatement incentives (pre‑ vs post‑shock)**; the paper provides only a simple “temporal placebo” table and a brief attenuation test, without a formal difference‑in‑differences design.  
- The manifest mentioned a **“information‑asymmetry mechanism”** and suggested exploiting the “surprise” nature of the 2010 wave versus later waves; the paper tests this only by comparing overall reinstatement rates, not by interacting the asset indicator with a “surprise” dummy in a unified specification.  

Overall, the paper captures the central research question but drops two of the more sophisticated identification components that would have strengthened the causal story.

---

### 2. Summary  

This paper documents the aftermath of the IRS’s 2010 mass automatic revocation of tax‑exempt status for 376 k nonprofit organizations. By matching the revocation list to the current Exempt‑Organizations Business Master File, the author shows that reinstatement probabilities vary dramatically across IRC subsections, with asset‑holding organizations (e.g., cemeteries, veterans posts) far more likely to survive. Linear probability regressions with state fixed effects reveal a 3.7‑percentage‑point “asset premium” in reinstatement, which attenuates in later years, suggesting an information‑asymmetry channel. The work argues that regulatory compliance shocks disproportionately eliminate “institutionally fragile” nonprofits, reshaping sector composition.

---

### 3. Essential Points  

1. **Identification Strategy Is Too Weakly justified**  
   - The paper treats subsection type (or the binary asset indicator) as the sole source of exogenous variation, yet subsection choice is plausibly correlated with unobserved size, professional staffing, and prior filing history—all of which affect reinstatement. State fixed effects do not fully absorb these confounders. A more credible strategy would combine subsection variation with **pre‑shock covariates** (e.g., 2007‑2009 filing history, asset size, employee count) or implement a **difference‑in‑differences (DiD)** design comparing reinstatement before and after a “surprise” dummy across subsections.  
   - The “temporal placebo” is presented only descriptively. Without a formal DiD or interaction term, the attenuation test cannot separate learning effects from composition changes in later waves.  

2. **Outcome Measurement May Misclassify Reinstatement**  
   - Matching revoked EINs to the *current* BMF identifies only organizations that are active **as of March 2026**. Organizations that reinstated but later dissolved (or were revoked again) are counted as “non‑reinstated,” biasing the reinstatement rate downward and potentially distorting subgroup comparisons if dissolution probabilities differ by subsection. A more accurate measure would use **annual BMF extracts** (or the IRS’s reinstatement‑date field) to capture the exact time of reinstatement.  
   - The paper does not verify that EINs are unique and stable over time; some organizations may have obtained a new EIN after dissolution, leading to false negatives.  

3. **Limited Economic Interpretation and Policy Relevance**  
   - The narrative focuses on an “information‑asymmetry” story but provides no direct evidence that asset‑holding organizations were *more* aware of the filing requirement (e.g., outreach receipt, email logs, or proxy measures such as prior electronic filing).  
   - The policy implication—that automatic revocation is “regressive”—is not quantified. A cost‑benefit illustration (e.g., aggregate revenue loss, lost charitable services) would substantially raise the paper’s impact.  

*Given these concerns, the paper cannot be accepted in its current form. The author should substantially revise the identification, improve outcome measurement, and deepen the economic interpretation.*  

---

### 4. Suggestions  

Below are concrete, non‑essential recommendations that, if incorporated, would greatly enhance the manuscript’s rigor, clarity, and relevance.

#### A. Strengthening the Identification  

1. **Incorporate Pre‑Shock Filings as Controls**  
   - Use the 990‑XML data (or the electronic “e‑Postcard” submission logs) to construct a binary indicator of whether the organization filed in any of the three pre‑shock years. This directly captures prior compliance behavior and can be interacted with subsection type.  

2. **Difference‑in‑Differences (DiD) Design**  
   - Define a “surprise” dummy = 1 for the 2010 wave, 0 for later waves. Estimate:  
     \[
     \text{Reinstated}_{ist} = \alpha + \beta_1 \text{Asset}_i + \beta_2 \text{Surprise}_t + \beta_3 (\text{Asset}_i \times \text{Surprise}_t) + \gamma_s + \delta_t + X_{i} \theta + \varepsilon_{ist}.
     \]  
   - The interaction coefficient isolates the extra asset premium when the shock was unexpected, providing a formal test of the information‑asymmetry mechanism.  

3. **Propensity‑Score Matching or Inverse‑Probability Weighting**  
   - Match asset‑holding and non‑asset organizations on observable characteristics (size, age, prior revenue, geographic density) before estimating reinstatement rates. This reduces bias from systematic differences across subsections.  

4. **Instrumental Variable (IV) Possibility**  
   - If there is variation in state‑level outreach intensity (e.g., number of IRS‑run workshops), use it as an instrument for “awareness” of the filing requirement. While data collection may be demanding, it would directly address the mechanism.  

#### B. Refining Outcome Measurement  

1. **Use Year‑by‑Year BMF Snapshots**  
   - Obtain the IRS Business Master File for each year 2010–2025. Identify the exact year an EIN reappears after revocation, constructing a **time‑to‑reinstatement** variable. This enables survival‑analysis (Cox proportional hazards) that accounts for censoring.  

2. **Validate EIN Stability**  
   - Conduct a spot‑check on a random subset of EINs to ensure they were not reassigned. If reassignment occurs, consider using a combination of EIN and organization name/address for matching.  

3. **Distinguish Permanent vs. Temporary Revocation**  
   - Some organizations may have voluntarily dissolved after revocation; flag those with a “termination” code in later BMF releases. Separate analyses for “permanent death” versus “temporary loss” would sharpen the narrative.  

#### C. Expanding the Empirical Framework  

1. **Survival Analysis**  
   - Estimate hazard ratios for reinstatement, allowing covariates (asset holding, subsection, state) to affect the speed of recovery, not just the binary outcome.  

2. **Heterogeneity by Size and Funding**  
   - Include continuous variables: total assets (from the most recent 990), annual revenue, number of employees (if available). Test whether the asset premium persists after controlling for these.  

3. **Robustness to Alternative Fixed Effects**  
   - Try **state‑year** fixed effects or **county‑level** controls to capture more granular nonprofit ecosystems.  

#### D. Deepening the Mechanism Argument  

1. **Direct Measures of Information Exposure**  
   - Leverage IRS outreach data (e.g., number of mailed notices per state) if publicly available, or construct proxies such as “Internet penetration” or “state nonprofit association membership density.”  

2. **Survey or Case‑Study Follow‑Up**  
   - Even a small supplemental survey of reinstated vs. non‑reinstated organizations could confirm whether lack of awareness, cost, or administrative capacity was the decisive factor.  

#### E. Policy Analysis  

1. **Quantify Welfare Loss**  
   - Estimate the aggregate charitable giving lost due to permanent deaths (using 990‑reported contributions). Compare this to the administrative cost savings from the revocation program.  

2. **Counterfactual Simulations**  
   - Simulate a “graduated” enforcement policy (e.g., warnings before revocation) using the observed reinstatement probabilities to assess potential reductions in permanent deaths.  

#### F. Presentation and Minor Issues  

1. **Clarify the Sample** – The abstract mentions “June 2011” while the main text uses “June 2010” for the revocation date; ensure consistent dating.  

2. **Table and Figure Labels** – Table 2’s subtitle “Reinstatement Rates by Organizational Subsection” could be expanded to note the reference category used in regressions.  

3. **Standard Errors** – Linear probability models with a binary outcome can produce predicted values outside \([0,1]\). Consider reporting a robustness check using a **fractional‑logit** model.  

4. **Citation Formatting** – Some in‑text citations (e.g., “\citet{blackwoodroeger2011}”) lack proper brackets; adjust to journal style.  

5. **Appendix Order** – Move the data‑appendix before the robustness appendix; readers will appreciate the detailed matching steps earlier.  

#### G. Roadmap for Revision  

- **Step 1 (Data):** Acquire annual BMF extracts, construct time‑to‑reinstatement, and validate EIN matches.  
- **Step 2 (Identification):** Implement DiD with the “surprise” interaction and/or propensity‑score matching; report pre‑trend checks.  
- **Step 3 (Mechanism):** Add at least one proxy for information exposure; discuss whether results change.  
- **Step 4 (Policy):** Provide a simple welfare calculation (e.g., lost charitable donations).  
- **Step 5 (Writing):** Clean up inconsistencies, enhance tables/figures, and ensure all specifications are fully reported.  

---

**Conclusion:**  
The paper addresses an important, under‑explored episode in nonprofit regulation and offers a rich administrative dataset. However, the current identification strategy relies on a crude comparison of subsections, leaving open the possibility that observed differences reflect pre‑existing heterogeneity rather than causal effects of the compliance shock. By tightening the causal design, improving outcome measurement, and deepening the economic interpretation, the manuscript could make a substantive contribution to the literature on regulatory compliance, organizational ecology, and nonprofit sector dynamics. I look forward to a revised version that tackles the points above.
