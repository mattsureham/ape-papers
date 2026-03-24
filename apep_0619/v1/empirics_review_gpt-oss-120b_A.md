# V1 Empirics Check — openai/gpt-oss-120b (Variant A)

**Model:** openai/gpt-oss-120b
**Variant:** A
**Date:** 2026-03-13T10:58:22.137769

---

**Referee Report**

---

### 1. Idea Fidelity  

The paper follows the original manifest closely. It uses the Bloomberg‑FOIA H‑1B lottery data (FY 2021‑2022) and matches firms to SEC EDGAR filings via EIN, exactly as proposed. The identification strategy – exploiting the firm‑level win‑rate (selected / registered) as a random shock conditional on the number of registrations – is retained. The research question (causal effect of high‑skill immigration access on R&D, capital investment and profitability of publicly‑traded firms) is also unchanged.  

**Minor departures:**  
- The original idea suggested also analyzing capital investment and profitability; the submitted paper presents results for operating income and PP&E but does not foreground a systematic profitability analysis (e.g., margins, ROA).  
- The manifest envisaged a “well‑powered null” and emphasized the possibility of heterogeneous effects for firms that rely heavily on H‑1B visas. The paper does explore heterogeneity but could expand on the definition of “high‑dependence” and on dynamic effects beyond two years.  

Overall, the manuscript stays true to the manifest’s core components.  

---

### 2. Summary  

The paper links petition‑level H‑1B lottery outcomes (obtained from a public Bloomberg FOIA release) to SEC‑filed financials for 848 publicly‑traded firms. Using the firm‑level win‑rate as an exogenous shock, it estimates reduced‑form regressions of R&D spending (and several ancillary outcomes) on the win‑rate. The main finding is a precisely estimated null: a 10‑percentage‑point increase in the win‑rate does not affect R&D expenditure, revenue, or other financial outcomes, suggesting that large firms can absorb short‑run H‑1B shocks through alternative hiring channels.  

---

### 3. Essential Points  

| # | Issue | Why it matters | What to do |
|---|-------|----------------|------------|
| **1** | **Potential violation of the “conditional randomization” assumption** – the win‑rate may be correlated with unobserved firm characteristics beyond the number of registrations (e.g., quality of the foreign talent pool, strategic use of the lottery). | If firms that submit many registrations differ systematically (e.g., they already have a larger R&D pipeline) the win‑rate could pick up a productivity channel unrelated to the random draw, biasing the estimate. | Conduct **balance tests** not only on pre‑lottery R&D but also on *pre‑lottery trends* in R&D (year‑by‑year) and on other firm‑level variables (e.g., R&D intensity, patent counts, headcount). Consider a **bivariate randomization check**: regress win‑rate on firm fixed effects and registration count, then verify that residualised win‑rate is orthogonal to pre‑trend variables. |
| **2** | **Limited treatment variation and mechanical correlation with firm size** – the win‑rate’s variance is highest for firms with few registrations, which are also smaller. The current specification controls only for log(registrations) and industry FE; this may not fully purge size‑related bias, especially for outcomes that are size‑dependent (e.g., revenue). | The positive coefficient on revenue is already flagged as spurious, but the same mechanism could attenuate or mask an effect on R&D for small firms. | Implement **inverse‑probability weighting** or **heteroskedasticity‑consistent standard errors** that account for the binomial variance of the win‑rate (i.e., weight observations by the number of registrations). Alternatively, use **instrumental‑variables** where the predicted win‑rate from a binomial model (given registration count) serves as the instrument for the observed win‑rate. |
| **3** | **Outcome measurement and timing** – the paper uses annual R&D expense from 10‑K filings, which may lag the actual hiring of H‑1B workers by several quarters, especially for large firms that plan R&D budgets years in advance. The two‑year horizon may be insufficient to capture delayed effects (e.g., after the employee’s first full fiscal year). | If the causal channel operates through “skill‑specific projects” that materialise only after the worker completes a full year, the null could be a timing artefact. | Test **longer horizons** (3‑4 years) where data are available, and include **lead‑lag specifications** that interact win‑rate with a “post‑treatment” dummy. If data are missing, discuss the limitation and consider using *quarterly* R&D estimates (if obtainable from the XBRL filing dates) to tighten timing. |

If the authors cannot satisfactorily address these three points, the identification would remain questionable and I would have to recommend rejection.  

---

### 4. Suggestions  

Below are constructive recommendations that, while not essential for basic acceptance, would greatly strengthen the paper, improve its credibility, and increase its contribution to the literature.

#### a. Strengthen the Identification Argument  

1. **Explicit Randomization Test** – Simulate the lottery process using the observed number of registrations for each firm and generate a distribution of win‑rates under pure random draws. Compare the empirical distribution of win‑rates (and its correlation with firm size) to the simulated distribution. Demonstrating that the observed win‑rates are statistically indistinguishable from the simulated ones would bolster the claim of randomness.  

2. **Placebo Outcomes Beyond R&D** – The current balance test includes revenue and assets, which are clearly size‑related. Adding *patent counts*, *citation‑weighted patents*, or *R&D intensity* (R&D / assets) as pre‑lottery outcomes would provide a richer falsification suite.  

3. **Event‑Study Graphs** – Plot average R&D (in logs) for firms binned by win‑rate before and after the lottery, with 95 % confidence bands. A flat pre‑trend and a flat post‑trend would visualise the null and help the reader assess dynamics.  

#### b. Refine the Empirical Specification  

1. **Weighting by Registration Count** – As noted, the variance of the win‑rate falls with the number of registrations. Weighting each observation by the number of registrations (or by the inverse variance of the binomial) yields an efficiency gain and reduces heteroskedasticity induced by differing precision of the treatment variable.  

2. **Alternative Functional Forms** – The current model uses a linear specification in win‑rate. Because win‑rate is bounded between 0 and 1, a *logit* transformation (or a quadratic term) can capture diminishing marginal returns. Checking robustness to these specifications would rule out functional‑form misspecification.  

3. **Control for Pre‑Lottery R&D Trajectory** – Include the firm’s prior year’s R&D growth rate (or a lagged dependent variable) to absorb persistence. This also mitigates omitted‑variable bias from unobserved productivity shocks.  

#### c. Expand the Substantive Analysis  

1. **Decompose the “Substitution Channel”** – While the paper correctly argues that firms may substitute with OPT, L‑1, or domestic hires, the data allow a first‑order test: count the number of *new* H‑1B approvals (post‑lottery) versus *new* OPT extensions (if data are available from the Department of Labor’s H‑1B and DS‑160 datasets). Even a rough correlation would make the substitution story more concrete.  

2. **Heterogeneity by Dependence on Foreign Talent** – The current “high H‑1B dependence” indicator is defined as registrations per $100 M$ revenue. Consider alternative thresholds (e.g., top quartile) and interact the win‑rate with *pre‑lottery R&D intensity*; firms with high R&D intensity may be more sensitive to skilled labor shocks.  

3. **Profitability Measures** – The paper lists operating income and PP&E, but does not discuss margins (operating margin, ROA, ROE). Adding these outcomes would directly address the “profitability” part of the research question.  

#### d. Data and Replicability  

1. **Share Code and Matching Scripts** – The manuscript mentions a public GitHub repository for the H‑1B data; adding a separate repository (or a sub‑folder) with the exact Stata/R/Python scripts used for EIN matching, data cleaning, and regression would fulfill the “fully replicable” promise.  

2. **Document Missingness** – Provide a table showing the share of firms missing each outcome (R&D, revenue, etc.) and any systematic patterns (e.g., missingness higher for certain industries). This helps assess selection bias.  

3. **Update to FY 2023‑2024** – Although the manuscript focuses on FY 2021‑2022, the Bloomberg data also contain FY 2023‑2024 registrations. Even a brief extension (e.g., a pooled analysis) would increase sample size and allow a test of whether the null persists across later lotteries.  

#### e. Presentation  

1. **Clarify Units** – In Table 4, the coefficient on “R&D/Revenue” is displayed in raw dollar units, making interpretation difficult. Present the dependent variable in logs or as a ratio (percentage) to aid readability.  

2. **Standard Errors** – The main tables cluster at the firm level; given the limited number of firms (≈ 600), it may be advisable to also report **wild‑cluster bootstrap** standard errors (Cameron, Gelbach & Miller, 2008) to guard against small‑cluster bias.  

3. **Typographical Consistency** – Ensure that all “FY 2021” references are consistent (some places use “FY2021”, others “FY 2021”). Minor but improves polish.  

#### f. Theoretical Framing  

1. **Link to Existing Theory** – Briefly discuss why a null result is theoretically plausible in the context of *adjustable R&D pipelines* (e.g., dynamic managerial discretion) and *elasticity of skilled labor*. Citing works on firm‑level R&D elasticity (e.g., Hall & Orihuela, 2006) would situate the findings.  

2. **Policy Implications** – The discussion correctly points out that the welfare impact may fall on workers. Enhancing this section with a short welfare calculation (e.g., estimated lost expected earnings for rejected applicants) would make the policy relevance more concrete.  

#### g. Robustness Extensions  

1. **Alternative Matching Variables** – If some firms cannot be matched via EIN, a secondary match on *company name* (fuzzy string) could increase coverage. Report robustness to different matching strategies.  

2. **Check for Spillovers** – Large firms may affect the H‑1B lottery outcomes of other firms (e.g., by submitting many registrations). Test for *cross‑firm spillovers* by excluding the top 5 % of registration submitters and re‑estimating.  

3. **Placebo Treatment** – Randomly assign win‑rates to firms (preserving the distribution) and redo the main regressions. The distribution of placebo coefficients should be centred at zero; this adds confidence that the empirical pipeline is not introducing artefacts.  

---

**Conclusion**

The paper makes a valuable and novel contribution by assembling a fully public dataset that links H‑1B lottery outcomes to SEC financials, and by delivering a well‑estimated null on R&D investment. The identification strategy is promising, but the manuscript must more rigorously demonstrate that the win‑rate is truly exogenous after conditioning on registration count. Addressing the three essential points (randomization test, size‑related bias, timing of outcomes) is crucial for the paper’s credibility. The numerous suggestions above—particularly the weighting scheme, richer falsification tests, and clearer presentation—will help the authors convert a promising draft into a compelling, replicable AER‑Insights article.  

*Recommendation*: **Major revision** (address essential points; incorporate robustness and clarification).
