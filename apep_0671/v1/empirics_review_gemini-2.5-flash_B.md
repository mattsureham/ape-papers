# V1 Empirics Check — google/gemini-2.5-flash (Variant B)

**Model:** google/gemini-2.5-flash
**Variant:** B
**Date:** 2026-03-14T12:22:05.343573

---

This paper leverages a rich, individual-level linked census panel to examine the occupational consequences of the 1924 Johnson-Reed Act for native-born workers. The analysis provides valuable micro-level evidence on a historically significant policy shock, contributing to the literature on immigration's labor market impacts. While the paper's ambition and data utilization are commendable, the interpretation of its findings, particularly in light of the placebo test, raises significant concerns regarding the strength of its causal claims.

---

### 1. Idea Fidelity

The paper adheres very closely to the original idea manifest.

*   \textbf{Research Question & Policy}: The paper precisely addresses the question of "Individual-Level Occupational Upgrading After the 1924 Immigration Quota Act," focusing on the Johnson-Reed Act as the key policy, consistent with the manifest.
*   \textbf{Data}: The paper uses the exact IPUMS MLP 1920-1930 linked panel (53.5M individuals) to track native-born workers and the 1920 full-count census for county-level exposure, as specified. The 1910-1920 linked panel is also used as a placebo. The actual sample size (11.7M vs. 10.7M specified) is slightly larger but within the same order of magnitude and intent.
*   \textbf{Outcomes}: OCCSCORE change, occupational upgrading/downgrading, farm-to-nonfarm transition, and industry switching are all included as outcomes, matching the manifest.
*   \textbf{Identification}: The paper employs the Bartik-style continuous-treatment DiD approach using the county-level share of 1920 population born in restricted-origin countries, exactly as planned. The placebo test using the 1910-1920 panel is central to the analysis, as intended.
*   \textbf{Novelty}: The paper delivers on the promised individual-level linked panel analysis, distributional insights beyond just average wages, the built-in placebo, and the statistical power.
*   \textbf{Feasibility Check}: The paper confirms the variation, data access, novelty, and sample size, consistent with the "READY" grade in the manifest. The "Smoke Test Log" data points are largely reflected in the summary statistics and descriptive text within the paper.

The paper is an excellent execution of the original idea, faithfully translating the manifest into a full draft.

---

### 2. Summary

This paper investigates how the 1924 Johnson-Reed Act's immigration restrictions affected native-born workers' occupational mobility. Using a massive 1920-1930 linked census panel, the authors exploit county-level variation in pre-existing restricted-origin immigrant shares to identify effects on OCCSCORE changes and occupational transitions. While initially finding that higher quota exposure leads to modest occupational upgrading for low-skill natives, a crucial placebo test from the 1910-1920 period reveals a strong pre-trend, ultimately suggesting that the quota may have *slowed* a pre-existing pattern of native advancement rather than causing new upgrading.

---

### 3. Essential Points

The paper’s core strength lies in its novel use of individual-level linked data and its ambitious scale. However, the interpretation of the results, particularly concerning causality, needs substantial clarification and a more robust approach to the identification strategy.

1.  **Reframing the Causal Claim and Main Finding**: The paper's primary and most problematic issue is its initial setup and subsequent reversal of its causal claim. The abstract begins by stating the policy "created county-level labor supply shocks" and that the analysis "provides the first individual-level evidence on whether immigration restriction caused native occupational upgrading or downgrading." However, the abstract then pivots, stating the placebo test "suggests that immigrant settlement endogenously tracked occupational opportunity" and "the difference... suggests that, if anything, the quota *reduced* the pace of native occupational upgrading." This complete flip of the causal interpretation, buried somewhat, critically undermines the paper's initial premise as a study of causal effects of *policy*. The main result ($\beta=4.3$) is presented as significant, but the placebo ($\beta=13.3$) effectively renders the *causal* interpretation of that $\beta=4.3$ coefficient highly suspect for the effect of the *quota*. The paper needs to directly address this. Is the main finding the $\beta=4.3$ (interpreted as a beneficial effect of restriction), or is the main finding the *difference between* $4.3$ and $13.3$ (interpreted as a cost of restriction)? If the latter, it needs to be explicitly estimated and presented as the core result. The current presentation is confusing and suggests a struggle to reconcile the main-period result with the placebo, rather than a clear and confident causal statement backed by a robust estimation of the *true* treatment effect.

2.  **Addressing the Placebo Test Failure Systematically and Quantifying the "True" Effect**: The paper correctly identifies the placebo test (`1910-1920 pre-quota panel yields an effect three times larger`) as a "complication" and a "threat to validity." However, it then continues to present the 1920-1930 $\beta=4.3$ as a "main result" and discusses its implications (e.g., skill heterogeneity) as if it were a clean causal estimate. If the parallel trends assumption fails so dramatically (a $\beta$ of 13.3 vs. 4.3), then the 1920-1930 $\beta=4.3$ estimate *cannot* be interpreted as the causal effect of the quota. The authors must either:
    *   **Propose a difference-in-differences-in-differences (DDD) strategy**: This is the natural econometric response to a failed parallel trends test in a DiD setup. Estimate $\beta_{1920-1930} - \beta_{1910-1920}$ and present *this* difference as the causal effect of the quota. This directly operationalizes the insight that "the decline from 13.3 to 4.3... is consistent with complementarity." This change in interpretation needs to be central to the results section, not a late-stage discussion point.
    *   **Argue explicitly why the $4.3$ is still informative**: If a DDD is not feasible or desired, the authors must provide a much stronger argument for why the $4.3$ coefficient, despite the very large pre-trend, still represents a meaningful policy effect. This would require acknowledging the baseline trend and explaining how the policy *deviated* from that trend, but the current discussion on complementarity from the decline *is* a DDD-style argument. Therefore, simply presenting the $4.3$ as a "main result" is misleading given the very strong pre-trend.

3.  **Endogeneity and Selection into Exposure**: The explanation for the placebo result -- "immigrant settlement endogenously tracked occupational opportunity" and "immigrants into economically dynamic counties" -- is plausible. However, this is precisely the fundamental endogeneity concern that makes a Bartik-style instrument problematic without a strong parallel trends assumption. If high-exposure counties were already on a differential path of native occupational upgrading, then the "treatment" (county-level restricted share) is not exogenous to the *potential outcome path* of natives. The current identification strategy, which relies on *conditional* parallel trends (given state and initial occupation FEs), appears to have failed. The authors need to explore additional controls, fixed effects, or alternative instruments (e.g., push factors of migration combined with historical settlement patterns) to address this fundamental selection issue if they wish to claim a causal effect of the policy itself. The current setup identifies the change in the *association* between immigrant concentration and native outcomes, not necessarily the *causal impact of the quota on native outcomes*, due to the pre-existing unobserved factors driving both.

---

### 4. Suggestions

The following suggestions aim to strengthen the paper's claims and make its nuanced findings clearer and more robust.

1.  **Refine the Causal Language Throughout**: Given the findings from the placebo test, the paper should be extremely careful with its causal language. Phrases like "caused native occupational upgrading" in the abstract, or "If immigrants and natives compete... restricting immigration should reduce labor supply... enabling natives to upgrade" in the introduction, set up an expectation of a direct, positive causal effect of the quota on native upgrading. If the ultimate finding is a *reduction* in the *pace* of upgrading compared to a counterfactual (i.e., the DDD interpretation), then the language needs to reflect this from the abstract onwards. The conclusion is more balanced, but the abstract and introduction should prime the reader for the full story, including the nuanced role of the placebo.

2.  **Explicitly Estimate and Present the DDD result**: As mentioned in the Essential Points, the most natural way to address the failed parallel trends and operationalize the insight that the quota "reduced the pace of native occupational advancement" is to run a DDD.
    \begin{equation*}
    \Delta Y_{ict} = \alpha + \beta \cdot \text{RestrictedShare}_c \times \text{PostQuota}_t + \gamma \cdot \text{RestrictedShare}_c + \lambda \cdot \text{PostQuota}_t + X_{i,1920}'\gamma + \delta_s + \mu_{o} + \varepsilon_{ict}
    \end{equation*}
    where $\text{PostQuota}_t$ is an indicator for the 1920-1930 period. The coefficient $\beta$ from this specification would be $(\beta_{1920-1930} - \beta_{1910-1920})$, which is the true causal effect the authors are hinting at. Present this as the main result for OCCSCORE change and other key outcomes. This would be a much stronger and more defensible causal claim than the current presentation.

3.  **Visualize the Pre-Trend and Main Effects**: A crucial addition would be a figure plotting the coefficients of `Restricted FB Share` for the 1910-1920 period and the 1920-1930 period, with 95% confidence intervals. This visual representation would dramatically illustrate the "three times larger" effect and make the core tension of the paper clear to the reader immediately. This is standard practice in DiD analyses with multiple pre-periods or placebo tests.

4.  **Explore Mechanism via Complementarity vs. Competition**: The paper alludes to the "tension between the skill-group heterogeneity (which supports competition) and the failed placebo (which supports complementarity)." This is a powerful point that needs to be developed further.
    *   **Heterogeneity of the Placebo**: Does the placebo effect for 1910-1920 also show a similar skill gradient? If high-exposure counties had high upgrading for low-skill natives *before* the quota, that would complicate the "competition" interpretation even within skill groups for the post-quota period. If the placebo effect is primarily driven by high-skill workers who also benefited from immigrant labor's complementary role, this would strengthen the complementarity argument for the overall effect.
    *   **Task-Based Framework**: Can the authors explicitly map occupations to task content historically? (e.g., using 1950s data as a proxy for 1920s). This would allow moving beyond "low-skill" vs "high-skill" and directly test if occupations with higher manual task intensity (where immigrants concentrated) experienced different effects than those with higher analytical/communication task intensity (where natives might upgrade).

5.  **Robustness Checks on Sample Definition and Controls**:
    *   **Age restrictions**: The paper uses 18-55 in 1920. Is the effect particularly sensitive to restricting the age range? For instance, focusing on prime-age workers (e.g., 25-45) could reduce noise from entry/exit into the labor force or early career mobility.
    *   **Occupational Link Rates**: The data appendix mentions differential link rates. Can the authors explore if linkability systematically varies with county exposure? While the MLP is robust, any differential selection into the panel by county exposure could bias results.
    *   **Additional County-Level Controls**: While state fixed effects absorb many regional trends, including pre-trends in manufacturing growth, agricultural specialization, or other relevant economic indicators at the county level (e.g., from agricultural census or manufacturing census data) could help control for potentially confounding factors beyond just aggregate state trends. Given the strong pre-trend, any additional controls that could help explain the differential upgrading paths of counties would be valuable.

6.  **Clarify "State x Occupation FE" Interpretation**: The result for "State x Occ. FE" is "virtually identical" to "State FE + Initial Occupation FE." This is an interesting finding and implies that the key variation is cross-county *within* state-occupation cells, rather than state-specific occupational trends. The paper should highlight this more, as it strengthens the claim that the individual occupation-level mobility is being captured.

7.  **Discussion of Null Results**: Some results are effectively null (e.g., upgrading, geographic mobility, standardized OCCSCORE change is "small positive"). In an AER: Insights format, it's important to be explicit about these null effects and give them equal weight in the narrative. For instance, the discussion could explicitly state "we find no evidence that the quota significantly increased the probability of occupational upgrading for the average native worker." This precise language adds clarity.

8.  **Contextualize in Broader Historical Literature**: The paper already cites relevant work by Tabellini, Goldin, and others. Expanding the discussion slightly to more explicitly link the findings to the broader debates in historical immigration literature (e.g., how the findings align or differ from earlier aggregate studies or qualitative historical accounts) could enrich the introduction and discussion. For instance, linking "mass immigration" periods to "economic dynamism" more directly with existing historical scholarship would be beneficial.

By addressing these points, particularly by operationalizing the insights from the placebo test into a central DDD estimate, the paper can make a stronger, clearer, and more defensible contribution to the literature on the causal effects of immigration policy.
