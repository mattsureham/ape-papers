# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant B)

**Model:** deepseek/deepseek-v3.2
**Variant:** B
**Date:** 2026-03-17T17:28:27.565028

---

**Referee Report**

**Paper:** “The Startup Tax: Municipal Broadband Preemption Laws and Firm Formation in the United States”

**Overall Assessment:** This paper tackles a timely and policy-relevant question: do state laws that restrict municipalities from providing broadband internet service stifle entrepreneurship? The core idea—using staggered adoption and repeal of these laws to identify causal effects on firm births—is strong and novel, as noted in the original manifest. The analysis is competently executed using modern staggered difference-in-differences (CS-DiD) methods. However, the execution diverges in several critical ways from the proposed research design, most notably in its handling of the broadband deployment mechanism. While the paper presents a plausible and interesting result, significant issues with data alignment, sample construction, and mechanism validation must be resolved before the conclusions can be considered robustly supported.

---

### 1. Idea Fidelity

The paper partially pursues the original idea but misses or under-develops several key components of the proposed identification strategy and data plan.

*   **Research Question & Core Outcome:** The paper correctly focuses on firm formation (from BDS) as the primary outcome, aligning with the manifest's novelty claim.
*   **Identification Strategy:** The use of a staggered DiD (Callaway-Sant'Anna) is faithful to the proposal. However, the paper effectively abandons the proposed **“Design B (Repeal)”**, which was touted as a source of “cleaner identification.” The repeal analysis is relegated to a single, underpowered robustness check (Table 4). The more promising “forward-looking” design (Design A) is implemented but with a critical sample limitation (see Essential Point #2).
*   **Data Sources:** The paper uses Census BDS and ACS data as proposed. However, it **omits the FCC Form 477 census-block provider data** entirely. This is a major deviation. The manifest explicitly listed this as a key dataset for measuring *broadband deployment* (as opposed to household *subscription*). This omission cripples the paper’s ability to test the primary hypothesized mechanism: that preemption laws reduce broadband availability and competition.
*   **Mechanism Tests:** The paper only weakly addresses the proposed channels.
    1.  **Broadband Penetration Channel:** Tested with ill-suited ACS subscription data (2015-2023) that misaligns with treatment timing, yielding a null result that is uninformative.
    2.  **Competition Channel:** Not tested. The proposed analysis of “incumbent ISP market power” is absent.
    3.  **Entrepreneurship Spillover:** The analysis is limited to aggregate firm births. The proposed test using NAICS 51 (Information) and 54 (Professional Services) for tech-specific spillovers is not conducted.
*   **Welfare Object:** The proposed consumer surplus analysis is not attempted.

In summary, the paper delivers on estimating an effect on firm formation but fails to build the empirical architecture—particularly regarding mechanisms—outlined in the original, compelling idea.

### 2. Summary

This paper provides the first staggered DiD estimates of the effect of state municipal broadband preemption laws on new business creation, finding that these laws reduce the firm birth rate by approximately 5%. The analysis is carefully conducted with respect to the firm birth outcome but is significantly hampered by data limitations that prevent a convincing test of the underlying mechanism (reduced broadband competition and deployment).

### 3. Essential Points (Critical Issues to Address)

The authors must convincingly address these three issues. Failure to do so should lead to rejection.

**1. The Misalignment of Broadband Data Invalidates the Mechanism Analysis.**
The paper uses ACS household broadband subscription data (available from 2015) to test for a treatment effect on broadband penetration. Since most laws were enacted between 1997 and 2011, the ACS data captures only the very tail end of the treatment period for a tiny subset of states. The admitted null result is not evidence against the mechanism; it is simply an artifact of poor measurement timing. The original manifest correctly identified **FCC Form 477** data as the solution. This dataset provides information on provider presence and technology types at the census block level from circa 2008 onward. The authors must use this data to construct a measure of broadband *availability* (e.g., number of providers, maximum advertised speed) that aligns temporally with the treatment period. This is not a minor suggestion; it is fundamental to establishing the logical chain from policy to outcome.

**2. Sample Construction Severely Limits External Validity and Power.**
The paper notes that because the BDS panel starts in 2004, “most early-adopting states (1997–2005)… are dropped from the CS-DiD estimation.” This is a critical flaw. It means the identifying variation comes from only 9 late-adopting states. This raises two major concerns:
*   **External Validity:** The estimated effect may not be representative of the impact of the broader set of preemption laws, which were predominantly passed earlier.
*   **Heterogeneity:** The effect of these laws may differ between early-adopting (potentially more restrictive) and late-adopting states. The authors must address this directly. At a minimum, they should: (a) justify why the late-adopter effect is policy-relevant for understanding the full set of laws, and (b) explore heterogeneity between early and late adopters using a method like the “stacked regression” estimator (which can incorporate units treated before the panel starts) or by using the repeal states as a separate, later-treated cohort for validation.

**3. The Evidence for the Proposed Causal Chain is Incomplete.**
The title calls preemption laws a “Startup Tax,” implying a direct cost channel: less broadband competition → higher prices/worse service → higher costs for potential entrepreneurs → fewer startups. The paper currently shows A (law) and C (fewer firms) but provides only a broken link to B (broadband market changes).
*   The authors must test the **competition channel**. Using FCC Form 477 data, they can examine if preemption laws are associated with reduced entry of new providers (especially municipal ones) or decreased competitive intensity in a market.
*   They should conduct a **heterogeneity analysis** to strengthen the mechanism. Does the negative effect on firm births concentrate in industries more reliant on broadband (NAICS 51, as suggested in the manifest)? Is it stronger in rural areas where incumbent ISP investment is weaker and municipal networks were more likely? Such tests would greatly bolster the argument that broadband, not some other concurrent state-level policy, is the operative channel.

### 4. Suggestions for Improvement

**A. Data & Measurement**
*   **Primary Mechanism Variable:** Prioritize obtaining and using FCC Form 477 data. Construct state- or county-level measures of broadband competition (e.g., HHI of providers, share of population with >1 provider, share with access to fiber).
*   **Sectoral Analysis:** Fulfill the manifest’s promise by analyzing firm births in NAICS sectors 51 (Information) and 54 (Professional, Scientific, Technical Services) separately. A stronger effect here would support the broadband mechanism.
*   **County-Level Analysis:** The manifest proposed ~31,000 county-year observations. While state-level analysis is fine for the main result, a county-level analysis could provide more granularity, better control for time-varying state policies, and enable more compelling heterogeneity tests (urban vs. rural).

**B. Empirical Strategy & Robustness**
*   **Incorporate Early-Treated Units:** Implement the “stacked” DiD estimator or an extended event-study framework that can use early-treated states as controls for later-treated ones before their treatment date. This would recover more of the intended variation and improve power.
*   **Deepen the Repeal Analysis:** The manifest highlighted repeals as a clean source of identification. The current single-line result is inadequate. Analyze the repeal states as a distinct “treatment reversal” cohort in a fully specified CS-DiD or event-study framework. Even with few post-periods, plotting the dynamic effects would be informative.
*   **Address Confounding Policies:** Broadband policy is not static. The paper should discuss and, if possible, control for other major state-level initiatives (e.g., state broadband grants, “dig once” policies) that coincided with the preemption era, especially for late-adopting states.
*   **Pre-Trends Scrutiny:** The significant positive coefficient at event time -12 is waved away but deserves more discussion. Is this driven by a single state? Does it persist in alternative specifications (e.g., using not-yet-treated controls, dropping the Arizona cohort)? The parallel trends assumption needs to be defended more rigorously.

**C. Presentation & Interpretation**
*   **Magnitude:** The 5% effect is presented clearly. To enhance policy relevance, consider translating the log-point reduction into a counterfactual number of “missing firms” over the treatment period for an average state.
*   **Standardized Effect Size:** The SDE table is a useful addition. Ensure the discussion clearly separates the *statistical* significance (modest/weak for CS-DiD) from the claimed *economic* magnitude (“large negative”).
*   **Limitations Section:** The current text buries critical limitations (ACS data timing, dropped early adopters) in the results section. A dedicated, frank limitations paragraph in the conclusion would improve scholarly integrity.
*   **Policy Context:** The conclusion mentions the federal Infrastructure Act. This is relevant but speculative. It would be better to tightly link the conclusion to the paper’s actual finding: if preemption laws have suppressed entrepreneurship, their repeal (where it has happened) may be a necessary precondition for federal funds to maximize their economic development impact.

**Conclusion on Contribution:**
The paper has the potential to make a genuine contribution. The core finding of a negative, plausibly causal link between preemption laws and firm formation is important and would be a novel addition to the literature on regulation and entrepreneurship. However, in its current form, the contribution is incomplete. The gap between the ambitious, well-scoped original idea and the executed paper is substantial, particularly regarding the mechanism. Addressing the three Essential Points is non-negotiable for establishing a credible causal narrative. The Suggestions, if implemented, would significantly strengthen the paper’s depth, robustness, and policy relevance.
