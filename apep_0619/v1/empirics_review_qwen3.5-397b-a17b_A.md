# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant A)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** A
**Date:** 2026-03-13T10:59:06.753719

---

**1. Idea Fidelity**

The paper largely adheres to the original idea manifest, successfully executing the novel data linkage between Bloomberg's FOIA-obtained H-1B lottery data and SEC EDGAR financial filings. The core research question—estimating the causal effect of high-skilled immigration access on publicly traded firms' R&D investment—is preserved. However, there are two notable deviations. First, the manifest proposed using FY2021-2024 data, whereas the empirical analysis restricts the sample to FY2021-2022. Given the manifest's emphasis on maximizing variation and power, this reduction warrants explanation. Second, the manifest outlined an Instrumental Variables (IV) strategy ("Instrument: Firm-level H-1B lottery win rate... First stage: Higher win rate -> more H-1B petitions"), but the paper employs a reduced-form approach (Win Rate -> Financial Outcomes) without explicitly demonstrating the first-stage relationship between lottery wins and actual H-1B hiring. While reduced-form is methodologically sound for lotteries, the absence of the hiring first stage weakens the mechanism connecting the lottery shock to financial outcomes.

**2. Summary**

This paper exploits the random assignment of H-1B visa lotteries to estimate the impact of high-skilled immigration access on corporate innovation. By linking petition-level lottery outcomes to SEC financial filings for 848 publicly traded firms, the authors find a precisely estimated null effect: lottery win rates do not significantly affect R&D expenditure, capital investment, or profitability. The results suggest that established firms insulate innovation budgets from immigration shocks, likely through labor substitution channels such as OPT extensions or domestic hiring.

**3. Essential Points**

1.  **The Missing First Stage (Mechanism):** The identification strategy relies on the assumption that lottery win rates translate into actual labor supply shocks. However, the paper does not empirically demonstrate that higher win rates lead to higher net H-1B employment within these firms. If firms perfectly substitute lottery losers with OPT workers or offshore hires (as suggested in the discussion), the "dosage" of the treatment is zero, rendering the null result on R&D uninformative about the productivity of H-1B workers. You must either show a first-stage linking win rates to actual visa approvals/hiring (perhaps using LCAs as a proxy) or explicitly frame the result as a test of *firm substitution capacity* rather than *immigration impact*.
2.  **Power and Minimum Detectable Effect (MDE):** The standard errors are relatively large (e.g., SE = 0.245 on log R&D). While the point estimate is near zero, the 95% confidence interval allows for effects up to a 56% increase in R&D for a full unit change in win rate. For a policy-relevant interpretation, you need to calculate the MDE for a realistic shock (e.g., a 10 percentage point change in win rate). If the MDE is larger than the economic effect suggested by prior literature (e.g., Kerr & Lincoln), the null may reflect limited power rather than true inelasticity.
3.  **Ratio Variable Bias and Pre-Trends:** The treatment variable (Win Rate = Selected/Registered) has a denominator chosen by the firm. While you control for log registrations, the variance of the win rate is mechanically higher for firms with fewer registrations (binomial sampling). The fact that win rates predict pre-lottery *revenue* (Table 2, col 2) suggests that firm size correlates with win rate variance. Even though pre-lottery R&D is balanced, this size-variance correlation threatens the exclusion restriction if R&D scaling differs by firm size. You need to demonstrate that the null holds among large firms where win rate variance is low, or use an IV strategy where *number selected* instruments for *number hired* to avoid the ratio bias.

**4. Suggestions**

**Expand the Sample to FY2023-2024**
The manifest highlighted the availability of FY2021-2024 data as a key feasibility advantage, yet the paper restricts analysis to 2021-2022. Given the concern about statistical power (Essential Point 2), dropping half the available data is costly. If the FY2023-2024 data structure is consistent (i.e., includes selection status for non-winners), you should incorporate them. This would increase the sample size from ~587 observations to potentially ~1,200, tightening standard errors by roughly 30%. If there are structural breaks in the lottery mechanism (e.g., the FY2024 beneficiary-centric selection changes), explicitly test for stability across years or include year-specific fixed effects interacting with the win rate.

**Refine the Econometric Specification**
The current specification uses the win rate as a continuous treatment. This introduces noise because a firm with 1 registration has a win rate of either 0 or 1, while a firm with 100 registrations has a win rate near the mean. This heteroskedasticity can bias standard errors.
*   **Alternative Specification:** Consider using the *number of selections* as the instrument for the *number of H-1B hires*, with the *number of registrations* as a control. This avoids the ratio variable issue. The equation would be: $\text{Hires}_{it} = \pi_0 + \pi_1 \text{Selected}_{it} + \pi_2 \text{Registered}_{it} + \nu_{it}$, followed by the second stage on R&D.
*   **Weighted Regression:** If you retain the win rate, weight observations by the number of registrations to account for the precision of the win rate estimate. A win rate of 100% based on 1 registration is much noisier than 100% based on 50 registrations.
*   **Fixed Effects:** You mention firm fixed effects in Table 3 (Col 5), but the main results rely on cross-sectional variation (Col 1-2). Given the panel structure (2021-2022), firm fixed effects should be the primary specification to absorb time-invariant firm heterogeneity that might correlate with registration strategy. The within-firm estimate is currently buried in Column 5; bring this to the forefront if it remains precise.

**Clarify the Mechanism via Substitution Margins**
The discussion posits substitution (OPT, L-1, domestic hiring) as the reason for the null result, but this is currently speculative. To strengthen the paper:
*   **OPT Proxies:** While individual OPT data is restricted, aggregate OPT data by industry or firm size is sometimes available via ICE FOIA or DHS yearbooks. Correlate industry-level OPT growth with H-1B lottery losses to see if high-loss industries show higher OPT usage.
*   **Job Postings:** Use data from Burning Glass or similar (if accessible) to show that firms losing the lottery continue posting STEM jobs at similar rates. This would support the claim that labor demand didn't shrink, only the source changed.
*   **Offshoring:** If R&D budgets are unchanged but H-1B hires drop, did foreign subsidiary R&D increase? Some SEC filings disclose geographic segment R&D. A test showing that H-1B lottery losers increase foreign R&D would be a powerful complement to the domestic null.

**Address the Revenue Pre-Trend**
Table 2 shows that win rates predict pre-lottery revenue ($p < 0.05$). You dismiss this as mechanical size-variance, but it requires more robust handling.
*   **Interaction Test:** Interact the win rate with firm size (log assets). If the pre-trend is driven by small firms with noisy win rates, the interaction should be significant.
*   **Sample Restriction:** Re-run the main analysis restricting the sample to firms with >20 registrations. This reduces win rate variance noise. If the null persists in this "cleaner" subsample, it bolsters the credibility of the identification.
*   **Randomization Inference:** Given the discrete nature of the lottery, consider performing randomization inference (permutation tests) rather than relying solely on clustered standard errors. This accounts for the exact distribution of the lottery mechanism.

**Format for AER: Insights**
The current draft resembles a full-length empirical paper. *AER: Insights* typically requires a tighter focus (4-5 pages).
*   **Condense Background:** The Institutional Background section can be halved. Focus only on the lottery mechanics relevant to identification.
*   **Merge Tables:** Consider combining the Balance Test (Table 2) and Main Results (Table 3) into a single comprehensive table or moving robustness to an online appendix.
*   **Highlight the Data Contribution:** The replicable data pipeline is a major contribution. Consider adding a brief "Data Note" sidebar or footnote detailing the exact matching algorithm (EIN standardization) to maximize the utility for other researchers.

**Interpret the Null Carefully**
A null result is valuable, but avoid overclaiming. The conclusion states firms "insulate innovation budgets." Be precise: firms insulate *spending*, but do they insulate *output* (patents, citations)? If data allows, a brief mention of patent outcomes (using USPTO data linked by assignee) would distinguish between budget insulation and true innovation insulation. If patents are also unaffected, the substitution story is stronger. If patents drop while spending stays constant, firms are facing diminishing returns to substituted labor.

**Final Polish**
*   **Consistency:** Ensure the abstract matches the final sample size (848 vs 560 firms mentioned in table notes).
*   **Clarity:** Define "Win Rate" clearly in the text as "Selection Rate" to avoid confusion with individual beneficiary odds.
*   **Replication Package:** Since replicability is a key selling point, ensure the GitHub repository linked in the footnotes contains the exact cleaning scripts for the EIN matching, as this is the most fragile part of the pipeline.

By addressing the first-stage mechanism, refining the handling of the ratio variable, and maximizing the available data, this paper can make a definitive contribution to the literature on immigration and corporate innovation. The data linkage alone is a significant public good, and ensuring the empirical strategy is robust will maximize its impact.
