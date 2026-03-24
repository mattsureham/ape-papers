# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant A)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** A
**Date:** 2026-03-22T15:13:42.710385

---

# Referee Report

**Manuscript:** "Fear of Ten Billion: Bunching Evidence on the Regulatory Costs of Dodd-Frank"
**Journal:** AER: Insights (format)

---

## 1. Idea Fidelity

The paper faithfully executes the core elements of the original manifest. It applies Kleven-Waseem bunching estimation to FDIC Call Report data, exploits both the 2010 Dodd-Frank introduction and the 2018 EGRRCPA rollback, and includes the proposed placebo tests at non-regulatory thresholds. The data source shifted slightly from FFIEC CDR to FDIC BankFind Suite (functionally equivalent for total assets), and the pre-period starts in 2001 rather than 1992 as originally proposed, but this does not materially affect identification. The EGRRCPA de-bunching test—a key novelty claim—is properly exploited. One deviation: the manifest proposed dose-response across $10B and $50B thresholds, but the paper focuses exclusively on $10B. This is a reasonable scope decision given AER: Insights length constraints, though it leaves some comparative leverage on the table.

---

## 2. Summary

This paper provides the first formal bunching estimation of regulatory avoidance behavior at the $10 billion Dodd-Frank threshold, finding 55 percent excess mass below the cliff post-2010. The EGRRCPA natural experiment reveals that interchange fee caps (Durbin), rather than stress testing requirements, drive approximately half of the bunching response. The contribution is methodologically clean and policy-relevant, extending the bunching paradigm from tax and labor contexts into financial regulation.

---

## 3. Essential Points

**1. Statistical power and precision of bunching estimates.** The core bunching statistic ($\hat{b} = 0.549$) has a standard error of 0.308, yielding $p = 0.075$. While the share-based test is more precise ($t = 8.0$), the primary bunching estimate—the paper's methodological contribution—is borderline. The year-by-year table reveals the underlying problem: within-year cross-sections are extremely thin (e.g., 2013 SE = 6.800, 2021 SE = 16.816). For AER: Insights, this may suffice, but the authors should explicitly acknowledge that bunching estimation in banking contexts faces power constraints due to the relatively small number of banks near the threshold compared to, say, taxpayers near an income kink. A power calculation or simulation showing the minimum detectable effect given the observed bank counts would strengthen confidence that null results (e.g., pre-period) are not simply underpowered.

**2. Missing density histogram figure.** This is a significant omission for a bunching paper. The entire methodology rests on visualizing the excess mass relative to a smooth counterfactual. Standard practice in the bunching literature (Kleven 2013, Saez 2010, Ewens et al. 2024) includes a histogram of the running variable with the fitted polynomial overlaid and the excluded region marked. Without this, readers cannot assess whether the excess mass is visually apparent or whether the polynomial fit is reasonable. This should be added as Figure 1, even if it requires dropping another table.

**3. Trailing average enforcement and measurement timing.** The paper notes (Section 2) that the threshold is enforced based on a trailing average of prior quarters, yet the empirical strategy treats each quarter as an independent observation. If banks are evaluated on a 4-quarter average, then quarterly asset reports may not reflect the actual constraint banks face. This could attenuate bunching estimates (banks might temporarily cross $10B in a single quarter without triggering the threshold) or create measurement error. At minimum, the authors should show robustness using 4-quarter rolling averages as the running variable. If bunching persists with averaged assets, the case for strategic constraint is stronger.

---

## 4. Suggestions

**1. Clarify the unit of observation and clustering.** The paper uses bank-quarter observations (64,846 total) but clusters standard errors at the bank level in the bunching bootstrap. However, the share-based regression (Equation 3) mentions quarter fixed effects and heteroskedasticity-robust SEs without specifying clustering. Given that banks appear repeatedly across quarters, within-bank correlation is likely. I recommend clustering at the bank level for all specifications and explicitly stating this. If the number of clusters is small (~200-250 banks), consider using wild cluster bootstrap or reporting both clustered and unclustered SEs.

**2. Strengthen the EGRRCPA interpretation.** The claim that Durbin is the "binding constraint" because bunching fell by half after EGRRCPA is compelling but requires more careful qualification. EGRRCPA removed stress testing but also changed examination frequency and modified some prudential standards. The authors cite industry estimates of $50-80 million annual interchange losses, but stress testing also carries substantial compliance costs (staff, models, consulting). A more nuanced discussion would acknowledge that the 50 percent reduction could reflect either (a) Durbin being roughly half the total cost, or (b) stress testing being easier to avoid through balance sheet management than interchange revenue loss. Consider adding a brief back-of-the-envelope calculation comparing estimated compliance costs of each component.

**3. Address potential compositional changes more thoroughly.** The paper notes that the total number of banks in the $5-15B window increased across periods, which is "inconsistent with selective attrition from above the threshold." However, this does not rule out that banks just above $10B may have merged into larger institutions (exiting the sample entirely) while new banks entered below $10B. A table showing the fate of banks that crossed $10B (e.g., what fraction remained above vs. merged vs. failed) would help rule out attrition as an alternative explanation. The FDIC BankFind data should allow tracking of bank identifiers across quarters.

**4. Consider a regression discontinuity complement.** While bunching is the main contribution, a simple RD design on outcomes like lending growth, deposit rates, or profitability at the $10B threshold could provide complementary evidence of real effects (not just avoidance). This is not essential for AER: Insights but would strengthen the welfare implications in the Discussion section. Alternatively, cite existing RD work on Dodd-Frank thresholds if available.

**5. Improve table presentation.** Table 2 (bunching results) is difficult to parse. Panel B's three "Share below" rows are not clearly labeled by period in the table itself (the notes explain it, but the table should be self-contained). Consider restructuring as:

| Period | Share Below | Δ vs. Pre | SE |
|--------|-------------|-----------|-----|
| Pre-DF | 0.569 | — | (0.013) |
| Post-DF | 0.723 | 0.148*** | (0.018) |
| Post-EGRRCPA | 0.638 | 0.063*** | (0.019) |

Also, Table 4 (yearly bunching) has enormous standard errors that undermine the visual narrative. Consider collapsing to 3-year averages or showing a figure with confidence intervals instead.

**6. Discuss external validity and generalizability.** The paper extends the compliance-cost-notch paradigm from nonprofits and public firms to banking. A brief paragraph comparing the magnitude of bunching ($\hat{b} = 0.55$) to other contexts would help readers calibrate whether this is a large or small response. For example, Ewens et al. (2024) find X percent excess mass at the public company reporting threshold; how does banking compare? This would strengthen the "What's Bigger Here" claim from the manifest.

**7. Minor technical points:**
- The abstract says "55 percent more banks cluster" but $\hat{b} = 0.55$ means 55 percent excess mass relative to counterfactual, not 55 percent of all banks. Clarify language to avoid misinterpretation.
- Section 3 mentions excluding 2010 and 2018 as "transition years." Justify this choice—were banks uncertain about enforcement? A sensitivity including these years would be useful.
- The bibliography file is referenced but not provided. Ensure all citations (e.g., Kay 2023, Cortés 2020) are real and accessible.
- Consider adding a brief appendix showing the polynomial fit diagnostics (e.g., residual plots or alternative polynomial orders visually).

**8. Data availability statement.** AER: Insights requires data and code availability. Add a statement specifying where the cleaned dataset and replication code will be hosted (e.g., AER website, GitHub, or Harvard Dataverse). The current footnote mentions a GitHub repository for the APEP project but not specific replication materials for this paper.

---

**Overall Recommendation:** Accept with revisions. The paper makes a clean, policy-relevant contribution using a well-matched empirical approach. The identification strategy is credible, though statistical power is a limitation that should be acknowledged. The three essential points (power/precision, missing histogram, trailing average issue) should be addressed before publication. The suggestions above would further strengthen an already solid paper.
