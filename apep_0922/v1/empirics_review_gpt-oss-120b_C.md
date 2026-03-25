# V1 Empirics Check — openai/gpt-oss-120b (Variant C)

**Model:** openai/gpt-oss-120b
**Variant:** C
**Date:** 2026-03-25T13:05:24.759714

---

**1. Idea Fidelity**  
The manuscript follows the original manifest closely. It uses the staggered state‑level adoption of alkaline‑hydrolysis (AH) legalization (2003‑2023) as a treatment, draws on BLS QCEW county‑ and state‑level data for NAICS 812210 (funeral homes) and NAICS 812220 (crematories), and implements the Callaway‑Sant’Anna (2021) staggered‑DiD estimator. All key elements—identification strategy, data source, and the research question of whether a cheaper, legally‑permitted alternative expands or compresses the funeral‑services market—are present. The only minor deviation is the exclusion of the 13 “always‑treated’’ states (those that legalized before 2014) from the main DiD; the manifest suggested using the full 23‑state sample but noted that pre‑treatment variation is needed, so this choice is justified and does not constitute a substantive gap.

---

**2. Summary**  
The paper investigates the competitive impact of legalizing alkaline hydrolysis, a low‑cost “water cremation’’ technology, on the U.S. funeral‑services industry. Using a staggered difference‑in‑differences design (Callaway‑Sant’Anna) with county‑level establishment counts and state‑level employment and wage data, the author finds that legalization raises funeral‑home employment by about 4.6 % and adds roughly nine establishments per treated state, while average wages are unchanged. The adjacent crematory sector does not shrink, suggesting that AH creates a new market segment rather than cannibalizing incumbents.

---

**3. Essential Points**  

| Issue | Why it matters | Suggested fix |
|-------|----------------|--------------|
| **A. Parallel‑trend validation, especially for wages** | The event‑study shows significant negative pre‑trends for wages (‑0.08 and ‑0.05 at t‑5, t‑4). This raises doubts that the post‑treatment wage increase is causal; it may reflect regression‑to‑the‑mean. | Re‑estimate the wage equation using (i) a tighter pre‑treatment window (e.g., t‑3 to t‑1) or (ii) state‑specific linear time trends, and report a placebo DiD where treatment dates are shifted to random years. If the wage effect disappears, drop it from the main results. |
| **B. Outcome definition conflates incumbents and new AH firms** | NAICS 812210 aggregates all funeral‑home establishments, so the “establishment growth’’ could be driven by existing funeral homes adding an AH service line rather than genuine entry of new firms. The interpretation of “market expansion’’ therefore remains ambiguous. | Use supplemental data (e.g., commercial business‑registry files, County Business Patterns, or industry‑specific licensing records) to separate “pure‑funeral‑home’’ establishments from those that explicitly list alkaline‑hydrolysis services. Even a binary indicator of AH‑capable firms (based on keywords in the firm name or licensing) would clarify the mechanism. |
| **C. Magnitude and economic significance of the establishment effect** | The ATT of 0.189 establishments per county is tiny relative to the mean of 5.2 establishments; the statistically significant state‑level effect (≈9 establishments) is driven largely by California. The paper claims a “9 % increase’’ but provides only raw counts, making it hard to assess the real economic impact. | Translate the establishment effect into a percent change for a typical state (e.g., median treated state) and discuss the cost side (e.g., extra payroll, capital investment). Present a back‑of‑the‑envelope calculation of total industry‑wide employment and revenue gains implied by the estimates, and compare them to the consumer price differential (≈$4,500 per disposition). |
| **D. Potential endogeneity of legalization timing** (optional, but serious) | The paper argues that legalization is driven by environmental advocacy rather than industry performance, but it provides no formal test. If states with faster funeral‑home growth are more politically receptive to AH, the estimates could be upward‑biased. | Conduct a falsification test using pre‑treatment trends in unrelated industries (e.g., retail) to see whether treated states were already on a different trajectory. Include state‑level covariates (death‑rate growth, median household income, political composition) interacted with time trends to test robustness. |
| **E. Standard‑error clustering** | Errors are clustered at the state level, which is appropriate given treatment varies at the state level, but the number of clusters (≈38) is modest. Standard errors may be downward‑biased. | Report wild‑cluster bootstrap‑t confidence intervals (or use the “CR2” adjustment) to confirm significance, especially for the establishment outcome where the p‑value is borderline. |

If the authors cannot address points **A**–**C** convincingly, the paper should be **rejected** because the central claim (market expansion rather than competition) rests on ambiguous evidence.

---

**4. Suggestions**  

1. **Strengthen the Parallel‑Trend Evidence**  
   * Plot separate event‑study graphs for each outcome (establishments, employment, wages) with 95 % confidence bands.  
   * Include a “pre‑trend test” table reporting joint F‑statistics that all pre‑treatment coefficients equal zero.  
   * For wages, consider re‑specifying the outcome as **log total payroll** (wage × employment) to capture the overall labor market effect while mitigating noisy wage‑only dynamics.

2. **Disentangle Entry from Incumbent Expansion**  
   * Merge the QCEW data with the *National Establishment Time-Series* (NETS) or *ReferenceUSA* to obtain firm‑level identifiers and ages. This will allow you to compute the share of **new establishments** (age ≤ 3 years) after legalization.  
   * If such data are unavailable, use the “establishment count change” at the county‑year level together with the **number of establishments that disappear** to infer net entry.  
   * Report a decomposition: ΔEstabs = New – Closed + Re‑classification (e.g., existing funeral homes adding an AH line).

3. **Robustness to Alternative Control Groups**  
   * In addition to never‑treated states, construct a **synthetic‑control** for each treated state using a weighted combination of never‑treated states that match pre‑treatment trends in funeral‑home outcomes and demographic covariates. Compare the synthetic‑control ATT to the DiD estimate.  
   * Perform a “leave‑one‑state‑out” jackknife to guard against any single large state (e.g., CA) driving the results.

4. **Place Results in Economic Context**  
   * Convert the 4.6 % employment rise into **additional labor hours** and **estimated wage bill increase**, then compare to the aggregate consumer savings implied by lower AH prices (using the $2,500–$3,500 vs. $6–$8 k price gap). This will show whether the welfare gain accrues mainly to workers, firms, or consumers.  
   * Discuss potential **externalities** (environmental benefits, reduced landfill use) and how they might affect the net social benefit, even if the paper does not estimate them directly.

5. **Address COVID‑19 Shock More Directly**  
   * Although year fixed effects absorb common shocks, the pandemic may have altered death rates and funeral‑home capacity unevenly across states (e.g., hotspots). Include **state‑specific linear time trends** or interact a **COVID‑year dummy** (2020‑2021) with treatment status to test whether results are driven by pandemic‑related disruptions.  
   * Present a sensitivity check that excludes 2020–2021 observations altogether.

6. **Expand the Mechanism Exploration**  
   * Use Google Trends or social‑media keyword data (e.g., “water cremation”, “alkaline hydrolysis”) to construct a **public‑interest index** by state and year. Test whether the magnitude of the establishment effect correlates with the intensity of consumer awareness.  
   * If possible, obtain **state‑level AH facility licensing data** (many states require a separate “AH provider” license). Regress the number of licensed AH providers on the treatment indicator to show a direct link between legalization and the supply of the new technology.

7. **Presentation and Transparency**  
   * Add a **data availability statement** with URLs to the raw QCEW extracts, treatment‑date spreadsheet, and any supplemental files.  
   * Deposit the code (R or Stata) used for the Callaway‑Sant’Anna estimation in a public repository (e.g., GitHub) and provide a replication appendix.  
   * Clarify the **definition of “state‑level aggregation’’** in Table 4: does the ATT of 9.28 refer to the *total* number of new establishments per state or the *average* per treated state? Include the standard deviation across states.

8. **Minor Technical Corrections**  
   * In Table 2, label the columns uniformly (e.g., “Establishments (county)”, “log Employment (state)”, “log Wage (state)”).  
   * The footnote to Table 3 should explain why the “never‑treated only” control set yields virtually identical ATT—this reinforces robustness but deserves a brief comment.  
   * Correct the typo “Christoph‑Sant’Anna” in the text (should be “Callaway‑Sant’Anna”).  
   * Provide the exact **effective dates** (month, day) of legalization for each state in an appendix; this will allow readers to verify the treatment coding.

By incorporating these suggestions—particularly the decomposition of entry versus incumbent expansion and the stronger pre‑trend validation for wages—the paper will move from an interesting descriptive study to a rigorous causal analysis with clear economic implications. The core insight that legalizing a low‑cost alternative can enlarge a highly inelastic market is valuable; confirming it with tighter identification will make the contribution suitable for an *AER: Insights* article.
