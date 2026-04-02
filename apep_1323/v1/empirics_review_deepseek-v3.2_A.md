# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant A)

**Model:** deepseek/deepseek-v3.2
**Variant:** A
**Date:** 2026-04-02T16:36:53.880301

---

Here is a rigorous, constructive review of the paper "The Branch Exodus: Cash Penalties and the Decline of Physical Banking in Nigeria," structured as requested.

***

### **1. Idea Fidelity**
The paper does **not** pursue the original idea outlined in the provided manifest. The manifest proposed a high-potential, novel research design exploiting the **staggered, state-level rollout** of Nigeria's cashless policy across 37 states to identify its causal effects on **electronic payment adoption, state-level tax revenue, and economic activity** (using NBS IGR, CBN payment data, VIIRS nightlights). The submitted paper completely abandons this design in favor of a **cross-country DiD** comparing Nigeria to ten other African nations on a **different outcome (bank branch density)** using World Bank aggregate data.

This is a significant deviation. The original identification strategy (Callaway-Sant'Anna staggered DiD) was the core intellectual contribution, offering a plausible path to causal identification by comparing early- and late-adopting Nigerian states. The submitted paper's cross-country approach is fundamentally weaker and does not address the original research question regarding formalization and tax revenue. The paper misses the key elements of state-level variation, the intended outcomes, and the mechanism tests (e.g., e-payment channel decomposition, spatial displacement).

### **2. Summary**
This paper documents a correlation between Nigeria's 2012 cashless policy and a subsequent relative decline in the density of physical bank branches compared to a panel of peer African countries, terming this the "branch exodus." It finds no corresponding effect on ATM density. The author is transparent that concurrent macroeconomic shocks, particularly the 2014 oil price collapse, present a severe threat to the causal interpretation.

### **3. Essential Points**
The paper has a fatal flaw that must be addressed before it can be considered for publication. If the authors cannot credibly overcome this, the paper should be rejected outright.

1.  **Failure of the Parallel Trends Assumption and Invalid Control Group:** The core identification strategy is not credible. Nigeria is an extreme outlier within the proposed control group (Botswana, Ghana, Kenya, etc.). It is a large, oil-dependent, populous federation with a unique economic structure. The event study (mentioned in Section 4) shows Nigeria had a *positive pre-trend* in branch growth relative to peers **before** the policy. The post-2012 decline is as consistent with **mean reversion** or a **divergent response to common global shocks** (e.g., the 2014 oil crash) as it is with a policy effect. The placebo test on GDP growth (Table 3, col 6) confirms Nigeria's growth path diverged sharply from the control group post-2012. This violates the DiD assumption that Nigeria would have followed the control group trend absent treatment. The leave-one-out robustness does not solve this fundamental problem of an inappropriate counterfactual.

2.  **Misalignment of Research Question and Empirical Design:** The paper asks a microeconomic question about bank and customer responses to a specific transaction-level policy (cash penalties). However, it uses a macroeconomic, cross-country design that cannot isolate the policy mechanism from other nationwide shocks (recession, insurgency, other regulations). To credibly estimate the causal effect of the cashless policy on bank branch closures, the analysis must exploit **within-Nigeria, cross-sectional variation** in policy exposure (i.e., the staggered state-level rollout) and control for Nigeria-wide shocks using late-treated or never-treated states as controls. The current design cannot do this.

3.  **Lack of a Clear Causal Channel or Mechanism:** The paper posits that cash penalties made branches "unprofitable," but provides no direct evidence for this channel. A bank's decision to close a branch is a function of profitability, which depends on revenues (from all services) and costs. The policy targeted large cash transactions; did these constitute a major revenue stream for branches? Did operational costs change? Without evidence linking the policy to branch-level financials or documenting a change in the *type* of transactions at branches, the proposed mechanism remains speculative. The discussion conflates the policy with broader "digital transformation," which could be driven by other factors (e.g., rising mobile penetration).

### **4. Suggestions**
These suggestions are offered in the spirit of improving the research. The most productive path would be to return to the original, superior idea.

**A. Major Redirection (Pursue the Original Idea):**
*   **Salvage the Staggered DiD Design:** The state-level rollout is your strongest asset. Abandon the cross-country approach. The primary obstacle seems to be state-level *financial infrastructure* data. Be creative:
    *   **Outcome Shift:** If branch/ATM data at the state level is truly unavailable, pivot to the **original outcomes** in the manifest: **state-level Internally Generated Revenue (IGR)** from the NBS. This directly tests the "formalization" hypothesis. You could also use **VAT or CIT data** from the Federal Inland Revenue Service if disaggregated by state.
    *   **Alternative Data for Branches:** Explore alternative data sources: annual reports of major Nigerian banks often list branch networks; the Nigeria Inter-Bank Settlement System (NIBSS) *might* have agent/branch data; or use business registry/census data to count "banking and finance" establishments per state.
    *   **Leverage the Phased Rollout:** Use the three waves (2012-Lagos, 2013-6 states+FCT, 2014-nationwide) in a standard staggered DiD or an event study. Use the 30 states treated only in 2014 as the "control" group for the early-treated states in the 2012-2014 period. This controls for Nigeria-wide shocks like the oil crisis.

**B. Improvements to Current Cross-Country Analysis (If Insisting on This Path):**
*   **Strengthen the Control Group:** Use **Synthetic Control Method (SCM)** instead of simple DiD. Construct a weighted combination of donor countries that closely matches Nigeria's pre-2012 path of branch density, GDP per capita, oil dependence, mobile penetration, and perhaps a measure of conflict. This would be more credible than an equally-weighted panel of diverse countries.
*   **Conduct a "Falsification" Test on a Different Policy:** To bolster the causal claim, identify another country that implemented a **different, non-cash-related banking sector reform** (e.g., a Basel capital requirement change) around the same time but did *not* implement a cashless policy. Show that this country did *not* experience a similar "branch exodus." This would help rule out generic "banking reform" or "global financial trends" as the driver.
*   **Deepen the Mechanism Analysis:** The "unprofitable branches" story is weak. Can you find any supportive evidence?
    *   Use data from Nigerian bank annual reports to see if banks with a higher share of branches in early-treated states saw a larger decline in profitability or a sharper increase in digital banking investments.
    *   If you have city-level or geo-coded data, test whether branch closures were more pronounced in **commercial centers** (where large cash transactions targeted by the policy are more common) versus rural areas.
*   **Reframe the Contribution:** If the causal claim remains weak, reframe the paper as a **descriptive case study** highlighting an important paradox: a policy aimed at financial development coincided with a contraction in physical access points. The contribution then becomes documenting this tension and thoughtfully discussing the measurement gap (digital vs. physical infrastructure) and its implications for financial inclusion metrics.

**C. Presentation and Clarity:**
*   **Abstract & Introduction:** The abstract and introduction currently overstate the causal findings. They should more clearly reflect the severe confounding issue. The phrase "coincides with" is more accurate than "causal effect."
*   **Literature Review:** Expand the discussion to relate your findings to literature on **branch networks in the digital age** and **financial inclusion measurement**. Your point about "measurement gaps" in World Bank data is important and could be a standalone contribution.
*   **Policy Implications:** The conclusion is reasonable, but the policy implications should be tempered. Without clearer causal evidence, you cannot strongly recommend for or against cash penalty policies. Instead, emphasize the need for **integrated metrics** that track both physical and digital access and for **piloting policies with careful evaluation designs** (like Nigeria's original staggered rollout, which this paper unfortunately does not use).

**In summary,** the paper identifies a striking and policy-relevant correlation. However, in its current form, the empirical strategy does not support a causal interpretation, and it represents a missed opportunity to execute the more convincing, original research design. The author is strongly encouraged to pursue the state-level, staggered DiD approach outlined in the original manifest.
