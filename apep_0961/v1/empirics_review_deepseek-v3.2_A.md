# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant A)

**Model:** deepseek/deepseek-v3.2
**Variant:** A
**Date:** 2026-03-25T20:42:30.023947

---

**Referee Report:**
*The Fiscal Dividend of Tobacco Advertising Bans: Evidence from Swiss Cantons*

**1. Idea Fidelity**
The paper successfully and faithfully executes the original research idea outlined in the provided manifest. It directly addresses the core research question—estimating the causal effect of tobacco billboard advertising bans on healthcare costs—using the specified data source (FOPH OKP Dashboard) and identification strategy (staggered DiD with never-treated controls). The analysis includes the proposed event study, placebo tests on non-smoking-related cost categories, and utilizes the treatment dates from the cited Stoller (2026) work. No key elements from the original idea are missed; the paper is a coherent implementation of the proposed design.

**2. Summary**
This paper provides the first causal estimates of the fiscal impact of tobacco advertising regulation. Exploiting staggered billboard ban adoptions across Swiss cantons and comprehensive administrative health cost data, it finds that bans reduce total per-capita healthcare expenditures by approximately 5.4%, with effects concentrated in hospital costs and growing over time. The study makes a novel contribution by linking advertising policy directly to healthcare savings, filling a significant gap in the literature on the returns to public health regulation.

**3. Essential Points**
The following critical issues must be addressed for the paper to be suitable for publication. Failure to adequately resolve these would necessitate rejection.

**A. Inference with Few Clusters and the Ambiguous Placebo Test.** The analysis relies on 26 cantonal clusters. While the authors correctly note this limitation and employ the wild cluster bootstrap (p=0.16 for TWFE), this remains a first-order threat to causal inference. This concern is compounded by the ambiguous results of the core placebo test. The finding that physiotherapy costs decline with marginal significance (p=0.07, Table 2) and that several placebo category estimates have non-trivial magnitude (e.g., -5.0% to -9.4%) undermines the claim of a clean falsification. If unobserved canton-specific shocks correlate with ban adoption and affect these "non-smoking" categories, the parallel trends assumption for smoking-related categories is less credible. The authors must conduct a more rigorous assessment. This should include: (i) reporting wild bootstrap p-values for all main CS-DiD specifications, not just TWFE; (ii) conducting a permutation test where the treatment is randomly reassigned across cantons to generate a distribution of placebo estimates; and (iii) discussing the physiotherapy result explicitly—is there a plausible indirect link to smoking (e.g., via musculoskeletal health), or does this suggest confounding?

**B. Incomplete Validation of the Mechanism.** The paper posits that billboard bans reduce costs by lowering smoking prevalence, yet it does not present direct evidence for this mediating step. Stoller (2026) is cited for the effect on prevalence, but the authors must demonstrate this mechanism holds *within their sample and period* to rule out alternative pathways (e.g., bans coinciding with other cost containment policies or broader anti-smoking sentiment that directly affects healthcare utilization). The authors should: (i) Replicate the smoking prevalence analysis using cantonal data from the Swiss Health Survey or similar sources for the 1997-2024 period to confirm the first-stage effect. (ii) Perform a formal mediation analysis (e.g., a two-stage DiD or path analysis) to quantify how much of the cost reduction is statistically explained by changes in smoking prevalence. Without this, the claim that costs fall "through the health-stock mechanism" is not fully substantiated.

**C. Policy Bundling and Concurrent Interventions.** The identification strategy assumes billboard bans are the only relevant policy change differing across cantons over time. The threat of policy bundling is mentioned but not adequately tested. Swiss cantons may have implemented other tobacco control measures (smoke-free laws, sales taxes, cessation programs) or broader healthcare reforms (hospital financing changes, cost-control initiatives) concurrently. If these are correlated with billboard ban adoption, they represent a confounder. The authors must: (i) Collect systematic data on the timing of other major cantonal tobacco control and health system policies from sources like the WHO Tobacco Control Database or cantonal legal archives. (ii) Include these as controls in their DiD specification or, at minimum, show in a balance table that the adoption of other policies is not significantly correlated with billboard ban timing in the pre-period. (iii) Discuss the specific case of nursing home costs (which increase significantly). Is this truly a "longevity dividend," or could it reflect concurrent policy changes affecting elderly care?

**4. Suggestions**
The following recommendations are aimed at strengthening the paper's contribution, presentation, and credibility.

**A. Empirical Strategy & Presentation**
*   **Event Study Refinement:** The event study is crucial for validating parallel trends. Extend the pre-treatment window beyond 10 years if data permits (1997 start may limit this). Plot the event-study coefficients with confidence intervals and a reference line at zero. Discuss the visual evidence for parallel trends more thoroughly in the text, noting any cohorts with volatile pre-trends.
*   **Dynamic Effects Specification:** Instead of only showing a static ATT, emphasize the dynamic effects table/figure. The growing effect over time is a key finding. Consider estimating a distributed lag model to quantify the cumulative effect over 5, 10, and 15+ years and discuss the implied long-term savings.
*   **Heterogeneity Analysis:** The early vs. late adopter analysis is insightful. Expand this by exploring other dimensions of heterogeneity: urban vs. rural cantons, initial smoking prevalence levels, or baseline healthcare cost levels. This can inform theories about which contexts make bans most effective.
*   **Standardized Effect Sizes:** Table A.1 on SDEs is useful. Integrate a discussion of these into the main results section to help readers gauge economic magnitude. Compare the SDE for healthcare costs to SDEs from other studies on smoking policies (e.g., tax increases) to contextualize the effect size.

**B. Data & Measurement**
*   **Cost Category Rationale:** Justify the classification of "smoking-related" vs. "placebo" categories more transparently. Provide citations from the medical literature linking hospital inpatient/outpatient costs directly to smoking-related diseases. Acknowledge that the classification is imperfect (e.g., some physician visits could be for smoking-related issues).
*   **Per-Capita Adjustment:** Confirm that the per-capita cost data from the FOPH dashboard is age-sex standardized or adjusted. If not, demographic changes (aging population) could confound trends. Consider controlling for canton-level demographic shares (e.g., % over 65) in a robustness check.
*   **Deflator:** Are the nominal CHF values deflated to a common year? If not, this should be done, as healthcare inflation varies over time and could differ across cantons.

**C. Interpretation & External Validity**
*   **Scope of Treatment:** Clarify that the estimated effect is for *outdoor billboard bans only*, not comprehensive advertising bans (which include print, point-of-sale, digital). Discuss whether the effect might be larger for more comprehensive bans, based on international literature.
*   **Cost-Benefit Framework:** Move towards a simple back-of-the-envelope cost-benefit calculation in the discussion. Combine the per-insured savings with the number of insured individuals and the administrative/political cost of implementing the ban. This directly addresses the "fiscal case" mentioned in the introduction.
*   **Generalizability:** Discuss the external validity of findings from Switzerland. Key factors include Switzerland's high-income setting, decentralized health system, and historically moderate tobacco regulation. Would effects be larger or smaller in countries with different health systems or initial smoking rates?

**D. Writing & Clarity**
*   **Abstract:** The abstract clearly states the main result. Ensure it also mentions the primary identification challenge (few clusters) and the key supporting evidence (dynamic effects, placebo tests).
*   **Results Narrative:** Structure the results section to tell a clearer story: 1. Validate parallel trends (event study). 2. Present main ATT. 3. Show effect heterogeneity over time (dynamics). 4. Decompose by cost category (mechanism). 5. Robustness checks (inference, leave-one-out).
*   **Limitations Section:** Expand the limitations section to dedicate a paragraph each to: (1) the few-clusters problem and its implications for interpretability, (2) the policy bundling issue, (3) the possibility of spillovers (if advertising bans in one canton affect behavior in neighboring cantons), and (4) measurement error in the treatment (enforcement intensity may vary).
*   **Tables & Figures:** Ensure all tables are fully self-contained. In Table 1, define "SDE" in the notes. In Table 2, consider adding a column for the wild bootstrap p-value alongside the clustered SE. Create a figure for the event-study dynamics; it is more impactful than describing it in text.

**Overall:** This is a timely, well-motivated paper with a clever design and a policy-relevant question. The core analysis is competently executed using modern DiD methods. Addressing the essential points regarding inference, mechanism, and confounding is **mandatory**. Implementing the suggestions will significantly enhance the paper's rigor, transparency, and contribution. I look forward to seeing a revised version.
