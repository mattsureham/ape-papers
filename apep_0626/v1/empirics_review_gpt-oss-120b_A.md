# V1 Empirics Check — openai/gpt-oss-120b (Variant A)

**Model:** openai/gpt-oss-120b
**Variant:** A
**Date:** 2026-03-13T12:13:42.640682

---

**1. Idea Fidelity**  
The manuscript follows the original manifest closely. It uses the IPUMS Multigenerational Longitudinal Panel (1920‑1930 linked census) to trace native‑born men, defines the continuous “quota‑exposure” treatment as the county share of foreign‑born from the most‑restricted Southern‑ and Eastern‑European origins in 1920, and adopts a Bartik‑style difference‑in‑differences (DiD) design with a 1910‑1920 placebo. All of the outcomes listed in the manifest (ΔOCCSCORE, occupational upgrading, farm‑to‑non‑farm transition, mobility, home‑ownership) are examined, and the paper reports the required robustness checks (leave‑one‑origin‑out, alternative clustering, non‑mover subsample). Hence the paper stays true to the proposed idea and does not omit any key component of the identification strategy or data source.  

---

**2. Summary**  
The paper exploits county‑level variation in the pre‑1924 concentration of immigrants from countries most constrained by the Johnson‑Reed Act to estimate the causal impact of the immigration restriction on native occupational mobility. Using a linked census panel of over ten million native‑born men, the author finds essentially a zero effect of quota exposure on changes in occupational income scores, occupational upgrading, farm‑exit, and geographic moves, while noting a modest negative impact on home‑ownership transitions. The result challenges the “lump‑of‑labor” intuition that fewer immigrants mechanically raise native occupational outcomes.  

---

**3. Essential Points**  

| # | Issue (Why it matters) | Required Action |
|---|------------------------|-----------------|
| 1 | **Parallel‑trends assumption is not convincingly demonstrated** – The placebo regression (1910‑1920) uses the *same* 1920 exposure variable to predict pre‑treatment outcomes. Because quota exposure is measured in 1920, it may already reflect contemporaneous trends that also affect 1910‑1920 changes (e.g., counties that were already industrializing). A stronger test would compare *pre‑trend* dynamics *before* the exposure is measured (e.g., 1900‑1910 trends) or implement an event‑study‑style DiD using multiple pre‑periods. | Add an event‑study graph showing ΔOCCSCORE (or occupation shares) for several census waves (1900, 1910, 1920, 1930) and verify that trends are parallel up to 1920. Alternatively, construct a pre‑1920 exposure based on the 1890 foreign‑born share (the actual quota base year) and show it predicts no differential change in 1910‑1920. |
| 2 | **Treatment measurement may capture broader local characteristics** – County share of restricted‑origin foreign‑born correlates with urbanization, industrial composition, and human capital (see Table 1). While state and occupation fixed effects are included, residual confounding (e.g., industry mix, labor‑union density) could bias the estimate. The current specification does not fully exploit the Bartik logic of interacting a *national* shock with *local* exposure. | Augment the model with county‑level controls for industrial composition (e.g., share of manufacturing, mining, construction), unionization rates, or pre‑trend occupational structures. Consider a two‑stage Bartik approach: first predict the *expected* immigrant inflow by interacting national quota reductions with county‑level historic shares, then use that predicted inflow as the treatment. Show that results are robust to these richer controls. |
| 3 | **Outcome measurement and interpretation of the null** – OCCSCORE is a 1950‑based occupational income index; using it to measure *change* between 1920 and 1930 assumes that the relative ranking of occupations is stable and that the index captures real wage changes for the period. Moreover, the paper reports a statistically significant negative effect on home‑ownership but does not explore mechanisms or potential measurement error that could generate spurious significance. | Provide a robustness check using an alternative contemporary wage measure (e.g., imputed hourly earnings from the census, or the SEI) to confirm that the null is not driven by the OCCSCORE construction. For the home‑ownership finding, test whether the effect persists after controlling for local housing supply variables (construction permits, housing stock) and examine whether the result is driven by a few high‑exposure counties. Include a brief discussion of why a reduction in immigration would diminish home‑ownership despite the null occupational effect. |

If any of the three points cannot be satisfactorily addressed, the paper’s central claim—that the 1924 Act had no occupational impact on natives—remains insufficiently supported and should be rejected.  

---

**4. Suggestions (non‑essential but highly recommended)**  

1. **More granular event‑study design**  
   * Plot the evolution of the average OCCSCORE (and the binary upgrading indicator) for counties grouped by exposure quintiles across the 1900, 1910, 1920, and 1930 censuses. This visual will make the parallel‑trend argument more transparent and also demonstrate whether any delayed effects appear after 1930 (e.g., in the 1940 census, if data are available).  

2. **Use the 1890 foreign‑born share as the *exogenous* baseline**  
   * Since the quota formula is anchored to the 1890 census, constructing the exposure measure from the 1890 foreign‑born share (instead of 1920) would eliminate any concern that the 1920 share already reflects contemporaneous economic conditions. The author can still weight by the reduction factor (the 1924 quota cut) to obtain a “quota‑intensity” variable. Showing that results are unchanged would strengthen the exogeneity claim.  

3. **Address potential migration spillovers**  
   * Restricting immigration at the national level could induce internal migration of native workers (or of other immigrant groups) toward high‑exposure counties. Although the paper includes a mobility indicator, a more thorough analysis—perhaps a gravity model of intra‑U.S. migration—could rule out that the null is driven by offsetting inflows of natives.  

4. **Consider heterogeneity by skill level more systematically**  
   * The current heterogeneity split is by race and urban/rural status. Adding interaction terms between quota exposure and pre‑treatment OCCSCORE deciles (or the 1950 SEI) would directly test the “competition” channel that low‑skill natives should be most affected. Even if null, reporting the pattern (e.g., a slightly larger negative coefficient for the lowest decile) would be informative.  

5. **Clarify the treatment timing**  
   * The Act became effective July 1 1924, but the outcome window is a ten‑year span (1920‑1930). Some natives may have already left the labor force or retired before the shock could affect them. Adding a sub‑sample of workers aged 18‑35 in 1920 (more likely to be active in 1924‑1930) could increase power to detect any effect.  

6. **Robustness to clustering and inference**  
   * The paper clusters at the county–state level, but with over 3,000 counties the number of clusters is adequate. Nevertheless, a wild‑cluster bootstrap (Cameron, Gelbach, Miller 2008) would provide an extra safeguard against under‑coverage, especially for the binary outcomes with relatively few events.  

7. **Presentation of effect sizes**  
   * The current discussion of “0.006 standard deviations” may be hard for readers to interpret. Translating the coefficient into a concrete occupational shift (e.g., “the average native in a high‑exposure county would move down only 0.06 of a quartile in the occupational hierarchy”) would make the null more tangible.  

8. **Expanded discussion of external validity**  
   * The paper could briefly address to what extent the 1924 restriction, a massive and permanent quota, is comparable to modern, more limited immigration controls. Highlighting similarities and differences would help readers apply the findings to current policy debates.  

9. **Minor textual and technical edits**  
   * Correct the typo “quota exposure (Broad)” in Table 4 caption (should read “broader definition”).  
   * In Table 1, the column headings for quartiles are mis‑ordered (Q1, Q3, Q2, Q4); reorder them for clarity.  
   * Provide a line in the Appendix that documents the exact list of BPL codes used to construct the restricted‑origin share, facilitating replication.  

Overall, the paper tackles an important historical natural experiment with an impressive data set. By strengthening the parallel‑trend evidence, tightening the treatment definition, and providing additional robustness checks on the outcome measures, the author can turn a promising null result into a compelling contribution to the immigration‑labor market literature.
