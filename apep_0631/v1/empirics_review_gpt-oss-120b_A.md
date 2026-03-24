# V1 Empirics Check — openai/gpt-oss-120b (Variant A)

**Model:** openai/gpt-oss-120b
**Variant:** A
**Date:** 2026-03-13T16:13:12.141141

---

**1. Idea Fidelity**  
The manuscript follows the manifest closely. It uses the 2018 TCJA SAL T cap and the 2025 OBBB reversal as a *symmetric* tax shock, constructs a continuous “SALT‑bite’’ measure from the 2017 IRS SOI zip‑code file, and estimates a continuous‑treatment difference‑in‑differences (DiD) with zip‑code and metro‑by‑month fixed effects. All data sources listed in the idea (Zillow ZHVI, IRS SOI, migration flows, FHFA, Redfin) are mentioned or incorporated, and the paper explicitly tests the symmetry (full reversal) hypothesis. No major element of the proposed identification strategy is omitted.

---

**2. Summary**  
The paper exploits the 2018 cap on the state‑and‑local‑tax deduction and its 2025 reversal to ask whether housing‑price capitalization of a tax subsidy is reversible. Using zip‑code‑level SALT‑exposure from IRS data and monthly Zillow house‑price indices, the author estimates that each \$10 k of SALT “bite’’ reduces prices by roughly 3 % after the cap, but the 2025 reversal does not restore those losses, implying a one‑way, “sticky’’ capitalization.

---

**3. Essential Points**  

1. **Parallel‑trends and the role of metro‑by‑month fixed effects** – The paper relies on a parallel‑trends assumption that high‑exposure zip codes would have followed the same price path absent the cap. The event‑study (Table 3) shows a small but statistically significant pre‑trend at k = ‑3 (0.009, p ≈ 0.02). This undermines the claim of no differential trend and suggests that the metro‑by‑month FE may not fully absorb pre‑existing dynamics. The author must either (i) demonstrate that the pre‑trend disappears when using finer fixed effects (e.g., zip‑by‑year‑month or state‑by‑year interactions), (ii) re‑estimate the model with a flexible pre‑trend (e.g., polynomial or spline) and show robustness, or (iii) conduct a formal pre‑trend test using the methodology of Callaway & Sant’Anna (2021) for continuous treatments.

2. **Short post‑reversal window and interpretation of asymmetry** – The OBBB reversal is observed for only seven months (July 2025‑January 2026). Housing markets often adjust with a lag, especially when the policy change is anticipated but the implementation date is near. The paper’s conclusion that capitalization is “sticky’’ is therefore premature. The author should (a) present a more nuanced discussion of the timing literature (e.g., Jappelli & Pagano 2020 on lagged price responses), (b) conduct a placebo test using an artificial “reversal’’ date earlier than 2025 to assess whether the observed post‑OBBB coefficient is driven by other contemporaneous shocks (COVID‑19, macro shocks), and (c) explicitly caution that the results pertain to *immediate* price responses.

3. **Measurement of treatment intensity** – The SALT‑bite variable uses the 2017 average SALT deduction per itemizing return and treats it as time‑invariant. However, the composition of filers and the amount of SALT claimed likely evolve (e.g., migration out of high‑tax areas, changes in filing status). If the true exposure declines over time, the interaction term may under‑state the effect and could bias the reversal test. The author should (i) update the SALT exposure each year using the IRS SOI annual zip‑code files (available up to 2022), (ii) show that the 2017 measure is strongly correlated with later years, and (iii) perhaps instrument the exposure with the 2017 measure while allowing for time‑varying controls.

If these three issues are not addressed, the paper’s main claim about irreversible capitalization remains unconvincing, and a recommendation for **major revision** is appropriate.

---

**4. Suggestions**  

*Methodological refinements*  

- **Flexible pre‑trend specification** – Incorporate zip‑specific linear (or higher‑order) time trends, or use the stacked DiD approach of Sun & Abraham (2020) adapted for continuous treatment. Plot the event‑study with confidence bands that include the pre‑period to make any residual drift evident.  

- **Alternative control groups** – Use zip codes with *no* SALT‑bite but similar observable characteristics (median income, home‑value, education) matched via propensity scores. This can help verify that the estimated effect is not driven by omitted confounders that correlate with both SALT exposure and price dynamics.  

- **Clustering and inference** – State‑level clustering may be too coarse given that many zip codes belong to the same metropolitan area. Try two‑way clustering (state × year) or wild bootstrap methods (Cameron, Gelbach & Miller 2008) to ensure robust standard errors.  

- **Placebo shocks** – Apply the same DiD design to a year before 2018 (e.g., 2014) with a fake “cap’’ defined analogously; the coefficient should be zero. This strengthens confidence that the observed post‑2018 effect is not driven by shared shocks (e.g., the 2015‑16 housing boom).  

- **Dynamic treatment effect** – Estimate a distributed lag model where the effect of SALT‑bite can evolve monthly after the shock. This can uncover whether the price response is immediate or gradual, which is especially relevant for the reversal period.

*Data extensions*  

- **Update SALT exposure** – The IRS SOI provides zip‑level SALT data for 2018‑2022. Even if the 2023‑2024 files are not yet released, using the most recent years would allow a test of whether exposure declines as households migrate.  

- **Incorporate migration flows** – The IRS migration matrices can be merged to construct an “outflow’’ variable for each zip. Including this as a control (or interacting it with the treatment) would directly test the sorting‑lock‑in mechanism posited for the asymmetric reversal.  

- **Alternative price measures** – Complement Zillow ZHVI with the FHFA repeat‑sales HPI and Redfin median sale price. While ZHVI is hedonic and arguably less sensitive to composition, the repeat‑sales index can confirm that the results are not an artifact of the Zillow methodology.  

- **Housing supply side** – Add construction permits or housing starts (e.g., from the Census Building Permits Survey) to explore whether supply adjustments mediate the price response.  

*Presentation and robustness*  

- **Clarify the “SALT bite’’ construction** – The paper defines bite as \((\text{avg SALT}-10{,}000)/10{,}000\). It would help readers to see a histogram of this variable and the distribution of exposure across metros.  

- **Effect size interpretation** – Translate the coefficient into dollar terms for a typical house (e.g., a \$500 k home in a high‑exposure zip loses ~\$16 k). This aids policymakers.  

- **Discuss alternative channels** – The paper mentions the simultaneous TCJA increase in the standard deduction as a possible confounder (Table 5, column 3). A more thorough accounting (e.g., adding a “standard‑deduction” interaction) would isolate the pure SALT effect.  

- **Re‑estimate using a continuous‑treatment estimator** – The recent literature on continuous DiD (e.g., de Chaisemartin & D’Haultfoeuille 2020) provides identification‑robust estimators that do not rely on linearity of the dose‑response. Applying such methods would strengthen the claim that the relationship is monotonic and roughly linear.  

- **Long‑run perspective** – Even if the reversal period is short, the paper could estimate a “partial reversal’’ coefficient using the most recent months as a leading indicator and discuss expectations for the next 2‑3 years, perhaps by projecting based on pre‑trend dynamics.  

*Theoretical framing*  

- **Link to Tiebout‑Rosen model** – Expand the discussion of why the model predicts symmetry (full adjustment of user cost) and how sorting lock‑in or anchoring violates the assumptions (perfect mobility, full information). A simple reduced‑form model could be added to illustrate the mechanisms.  

- **Policy relevance** – Highlight that the asymmetric effect implies a permanent redistribution of housing wealth, which may affect local tax bases and fiscal capacity. Discuss whether the OBBB’s phase‑out for high‑AGI filers further limits reversal.  

*Minor edits*  

- Correct the caption of Table 5: “Pseudo Treatment’’ should be clarified (it is the interaction with SALT bite for below‑cap zip codes).  
- In the abstract and conclusion, replace “sticky capitalization’’ with “asymmetric (or one‑way) capitalization’’ for consistency with the literature.  
- Ensure that the reference list includes all cited works (Rosen 1979, Gyourko & Tracy 1991, Hilber & Vermeulen 2016, Callaway & Sant’Anna 2021, Sun & Abraham 2020, de Chaisemartin & D’Haultfoeuille 2020).  

---

**Overall recommendation:** The paper tackles a novel and important question with a creative symmetric shock design. However, the evidence for irreversible capitalization is not yet compelling because of (i) a detectable pre‑trend, (ii) an extremely short post‑reversal observation window, and (iii) a static treatment measure that may mis‑measure exposure over time. I recommend **major revision** focused on strengthening the parallel‑trend validation, extending the treatment construction, and tempering the conclusions about asymmetry. Once these concerns are addressed, the study will make a valuable contribution to the tax‑capitalization and housing‑market literatures.
