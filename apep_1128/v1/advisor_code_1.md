# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-30T11:11:33.416230

---

**Idea Fidelity**

The paper closely follows the manifested idea. It exploits staggered state non-compete bans using knowledge-intensive sectors (NAICS 51 & 54) as treated industries versus NAICS 72 as placebo, race-specific QWI data, and a multi-difference strategy to isolate differential impacts on Black versus White workers. The manuscript reports the intended outcome variables (separation rates, hires, earnings), describes the same policy variation (OR/WA 2020, IL/CO 2022, MN 2023, CA/OK/ND benchmarks), and adopts the triple/quadruple-difference identification articulated in the idea. The main novelty claimed—racial heterogeneity in the non-compete literature—is preserved, and the identified evidence on wages versus turnover channels matches the original research question. No major elements from the manifest appear omitted.

**Summary**

Using QWI state-industry-race-quarter data and a quadruple-difference design, the paper estimates how staggered state non-compete bans affected racial gaps in knowledge-intensive industries. It finds that bans raise Black workers’ earnings relative to White workers (3.8 percent) without changing the racial separation rate gap, supporting a “bargaining dividend” interpretation where outside options improve wages even absent observable mobility increases. Placebo, pre-trend, and CS robustness exercises underpin the empirical narrative.

**Essential Points**

1. **Power and Inference with Few Treated States:** With five treated states and 2020 as the earliest ban, clustering at the state level makes inference fragile. Although the paper reports cluster-robust SEs and mentions Callaway-Sant’Anna results, the CS ATT itself is imprecise, and the current SEs may still overstate precision in the key interaction (β₂ for log earnings). I recommend reporting wild cluster bootstrap p-values (Cameron, Gelbach, and Miller) or randomization inference that better reflects the small number of treated clusters, especially for the earnings coefficient that drives the main conclusion.

2. **Validity of the Placebo Sector:** The identification hinges on NAICS 72 being unaffected by non-compete bans, yet Table 4 (Robustness) suggests only a simple DD on NAICS 72, not a full race × placebo comparison. If NAICS 72 is used to difference out time-varying shocks, the race-specific placebo is needed (i.e., race-specific gaps in NAICS 72 should be shown to exhibit no ban-related shifts). The paper should explicitly present and estimate the race-level treatment interaction for NAICS 72 to reassure that the quadruple differencing is isolating NCA effects rather than sector-specific racial dynamics.

3. **Interpretation of the Null Separation Result:** The null on separation rates is central to the bargaining interpretation, yet with wide confidence intervals the absence of an effect could stem from limited statistical power rather than a true zero. The paper should quantify what magnitude of change in separation rates it can rule out (e.g., minimum detectable effect relative to the pre-trend variance). If the detectable effect is still economically meaningful, the bargaining story gains credibility; otherwise, the claim that mobility “does not increase” may be overstated.

**Suggestions**

- **Clarify the Econometric Specification:** Equation (1) is a helpful shorthand, but the paper should better describe which interactions are absorbed by the fixed effects and which are estimated. For example, is the “Post × Knowledge × Black” coefficient identified relative to the four-way FE and the state-quarter-race FE? A small table of regressors or a decomposition of the FE structure would help readers reconstruct the DDDD logic and better assess whether the interaction relies on within-state variation or across-state comparisons.

- **Expand on the Callaway–Sant’Anna Implementation:** The CS results are reported briefly; consider laying out the cohort definitions, the aggregation weights, and whether the ATT is estimated separately for earnings and separation rates. If possible, include a figure showing dynamic treatment effects for each cohort to demonstrate parallel pre-treatment trends and to highlight that the earnings effects are not driven by, say, the OR/WA 2020 cohort alone.

- **Race Coding and Composition:** The QWI race variable A2 is broad (Black/African American) but may include multi-racial individuals. Given the paper’s framing about enforcement resources, the variation in workforce composition across states may matter. Descriptive statistics showing whether the share of Black workers in knowledge sectors increased or declined after bans would help rule out compositional changes (e.g., an influx of higher-paid Black workers) driving the earnings gap improvement.

- **Mechanism Evidence:** The “bargaining dividend” interpretation is plausible but would be strengthened with supporting evidence. One route is to examine earnings distributions or higher quantiles (if permissible) to see whether wage gains occur through top-ups or across the distribution. Alternatively, the author could check whether employer-reported wage growth is larger for established workers versus new hires (even if hires themselves do not rise). Even a simple correlation between pre-ban level of non-compete coverage (e.g., estimated from industry/state prevalence) and earnings gains would help argue that the effects operate through contract enforcement rather than other policies.

- **Address Spillovers to Always-Treated States:** CA/OK/ND are excluded, but they may still be relevant if bans in other states affect mobility into the benchmark zones. Discuss (perhaps in the appendix) whether their exclusion biases estimates and whether including them as “never treated” changes results qualitatively.

- **Supplementary Figures:** A figure plotting the four-way gap over time (e.g., difference-in-differences for log earnings by race within treated vs. control sectors) would make the dynamics more transparent than the tables. Panel plots of the racial gap in knowledge sectors versus the placebo across states could also be informative.

- **Clarify Policy Coverage Differences:** Since some bans were limited by income thresholds, Black workers (who earn less) may have benefited disproportionately. The paper should acknowledge that the treatment intensity varies across states and time; a heterogeneity tabulation by state or by whether the ban applied to the whole workforce would provide context for interpreting the estimated average effect.

- **Data Transparency:** Given that the analysis claims the data are available on Azure, consider providing the code or a more detailed description (e.g., exact file paths, processing steps) in an appendix. This would align with AER: Insights’ emphasis on reproducibility.

In sum, the paper addresses an important question with a thoughtful design, but reinforcing the inference strategy (especially around placebo sectors and power) and fleshing out the mechanism story will substantially strengthen the contribution.
