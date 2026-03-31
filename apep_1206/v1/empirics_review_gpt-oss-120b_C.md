# V1 Empirics Check — openai/gpt-oss-120b (Variant C)

**Model:** openai/gpt-oss-120b
**Variant:** C
**Date:** 2026-03-31T15:01:08.923462

---

**1. Idea Fidelity**  

The manuscript follows the original manifest closely. It uses the STATENT establishment‑by‑employment decomposition, exploits within‑municipality variation in the corporate Steuer‑Fuss, and asks the central question: do tax cuts draw “real” productive firms or merely “letterbox” entities? All components of the proposed identification strategy (municipality‑year panel, Di‑D, event study, sectoral triple‑difference, placebo with natural‑person tax cuts) appear in the final paper. The only notable deviation is the restriction to two cantons (Zurich and Basel‑Landschaft) rather than the broader national sample suggested in the manifest; the authors acknowledge this as a limitation. Otherwise, the research question, data, and econometric design are faithful to the original plan.

---

**2. Summary**  

The paper estimates the effect of a ≥5‑percentage‑point cut in Swiss municipal corporate tax multipliers on the intensity of employment per establishment, using a municipality‑year fixed‑effects Di‑D framework (2011‑2023). A tax cut raises the number of establishments by about 2 % but leaves total employment unchanged, driving a 2.1 % drop in employment per establishment overall and a 6.6 % drop in the tertiary sector. Placebo tests with personal‑income tax cuts and sector‑specific checks support the interpretation that the additional firms are “letterbox” companies rather than productive employers.

---

**3. Essential Points**  

| # | Issue | Why it matters | What to fix |
|---|-------|----------------|-------------|
| 1 | **Parallel‑trend validation and treatment timing** | The event‑study graphs are described but not shown; without visual evidence we cannot assess pre‑trend credibility, especially given the staggered and relatively few treated municipalities (25). Moreover, the binary “post‑cut” indicator collapses all post‑years into one treatment period, obscuring dynamic effects and possibly violating the recent “Granger‑Caused Treatment” literature (e.g., Goodman‑Bacon 2021, Sun & Abraham 2021). | Provide event‑study plots for the main outcome (log emp/est) and for the sector‑specific outcomes, with confidence bands. Adopt the Sun‑Abraham (or Callaway‑Sant’Anna) estimator to correctly aggregate staggered Di‑D estimates and report the resulting ATT. |
| 2 | **Standard‑error clustering** | The baseline clusters at the canton level (only two clusters) which severely under‑covers serial correlation and leads to over‑precise p‑values. The authors also report municipality‑clustered SEs in a robustness column, but the main results still rely on the under‑clustered baseline. | Re‑estimate all regressions with clustering at the municipality level (the natural clustering unit) and, if feasible, use a two‑way cluster (municipality × year) or a wild‑cluster bootstrap (Cameron, Gelbach, Miller 2008) to obtain reliable inference. |
| 3 | **External validity and selection bias** | The treated municipalities have substantially higher pre‑treatment tax rates (≈119 % vs. 53 %). This suggests that cuts are endogenous to fiscal pressure (e.g., a municipality may cut taxes because its revenue base is already inflated by many registrations). If the cut is a response to a pre‑existing influx of letterbox firms, the causal direction is reversed. | Conduct a pre‑trend balance test on the “tax‑rate gap” variable (high vs. low tax municipalities) and explore an instrumental‑variables strategy (e.g., political composition of municipal council, or lagged cantonal tax reforms) that predicts tax cuts but is plausibly orthogonal to contemporaneous firm‑location decisions. At a minimum, include municipality‑specific time trends or interact the treatment with pre‑cut tax level to show robustness to differential trends. |

If any of the three points cannot be satisfactorily addressed, the paper should be rejected; otherwise, addressing them will substantially improve credibility.

---

**4. Suggestions**  

Below are non‑essential (but highly valuable) recommendations for strengthening the paper, improving readability, and positioning the contribution within the broader literature.

| Area | Recommendation |
|------|----------------|
| **A. Clarify the Economic Magnitude** | - Translate the log‑point effects into more intuitive units (e.g., “a 5‑pp cut reduces the average firm size by 0.12 workers” as you do, but also compute the aggregate loss of employment‑intensity across the whole sample (total workers lost per 1 % increase in establishments). <br>- Discuss the fiscal trade‑off: estimate the net change in municipal tax revenue (additional registrations × reduced rate vs. lost revenue from existing firms) to highlight the welfare relevance. |
| **B. Expand the Sample** | - If data are available, incorporate additional cantons beyond Zurich and Basel‑Landschaft. Even a modest increase (e.g., adding Geneva, Vaud) would bolster external validity and increase the number of treated units, allowing more precise subgroup analysis (large vs. small municipalities, urban vs. rural). |
| **C. Robustness to Alternative Definitions of “Letterbox”** | - Instead of relying solely on sector (tertiary) as a proxy, construct a more refined “letterbox” indicator: e.g., establishments with ≤2 employees, or establishments classified under SIC codes typically used for holding companies (e.g., “financial intermediation”, “holding activities”). Show that results are robust to alternative thresholds. |
| **D. Address Possible Spillovers** | - Tax cuts in one municipality may induce firms to relocate from neighboring municipalities, affecting the control group. Test for spatial spillovers by including a distance‑weighted treatment variable for adjacent municipalities, or by dropping municipalities within a certain radius of treated ones. |
| **E. Multiple Hypothesis Testing** | - The paper presents several outcome regressions (total, tertiary, share, establishments, employment). Consider adjusting p‑values for multiple testing (e.g., Westfall‑Young step‑down) or focusing the narrative on a pre‑registered primary outcome (employment per establishment). |
| **F. Data Quality Checks** | - Verify that the STATENT establishment counts are consistent across years (e.g., no systematic under‑counting after a tax cut due to delayed registration). Include a brief discussion of any measurement error concerns and whether they bias the estimated β downward/upward. |
| **G. Presentation Improvements** | - Move the event‑study figures from the appendix to the main text; they are central to the identification argument. <br>- In Table 1, the “Corporate Steuerfuss (%)” column shows mean 52.9 % for controls and 118.6 % for treated—these are actually multipliers, not percentages. Clarify the unit (e.g., “Steuerfuss multiplier = 1.0 = 100 % of cantonal base”). <br>- Include a short “institutional motivation” paragraph that explains why municipalities can cut rates independently (political competition, revenue sharing) to help readers unfamiliar with Swiss fiscal federalism. |
| **H. Literature Positioning** | - Cite recent work on “tax competition within countries” that uses subnational data (e.g., Devereux & Griffith 2020 on U.S. counties, Kawai & Lin 2022 on Japanese prefectures) to underline the novelty of a Swiss case. <br>- Discuss how your findings inform the “minimum tax” debate beyond the Pillar Two reference; e.g., policy proposals for “inter‑municipal profit‑sharing” or “tax base neutralization.” |
| **I. Alternative Estimation Strategies** | - Consider a synthetic‑control approach for a few large treated municipalities (e.g., Zug) as a visual complement to the Di‑D estimates. <br>- If feasible, exploit the continuous nature of the tax cut (rather than the binary ≥5 pp threshold) using a continuous‐treatment Di‑D (e.g., a TWFE with the tax change as a regressor) and plot the marginal effect. |
| **J. Transparency & Replicability** | - Provide a URL to a public data repository (with anonymized raw STATENT extracts) and the exact Stata/R code used for the main regressions. This will aid reviewers and future researchers. |

---

**Overall Assessment**  

The paper tackles an important and under‑explored question: whether subnational corporate tax competition primarily reallocates “paper” firms rather than real productive activity. The data are uniquely suited to this task, and the baseline results are intuitively appealing. However, the credibility of the causal claim hinges on convincing evidence of parallel trends and appropriately clustered inference, as well as on addressing potential endogeneity of tax cuts. By implementing the essential fixes above and incorporating the suggested enhancements, the manuscript would meet the standards for an AER‑Insights contribution.
