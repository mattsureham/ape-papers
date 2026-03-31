# V1 Empirics Check — mistralai/mistral-large-2512 (Variant B)

**Model:** mistralai/mistral-large-2512
**Variant:** B
**Date:** 2026-03-31T10:42:35.239775

---

### 1. Idea Fidelity

The paper adheres closely to the original idea manifest. It exploits the EU’s COVID-19 slot waiver and its staggered restoration (0% → 50% → 64% → 80%) to estimate the causal effect of relaxing the "use-it-or-lose-it" rule on airport-level passenger volumes. The identification strategy—continuous difference-in-differences (DiD) with Level 3 (coordinated) vs. Level 1/2 (uncoordinated) airports, augmented with country×year fixed effects—matches the manifest’s proposed approach. The use of Eurostat’s *avia_paoa* data and the decomposition into scheduled/non-scheduled passengers (as a placebo test) are also consistent with the original plan. The paper does not miss any key elements of the manifest.

---

### 2. Summary

This paper provides the first quasi-experimental evidence on the causal effects of the EU’s COVID-19 slot waiver on airport competition. Using a continuous DiD design with staggered threshold restoration, the authors find no detectable effect of the waiver on passenger volumes at coordinated (Level 3) airports relative to uncoordinated (Level 1/2) airports, once country-specific shocks are absorbed. The results challenge the "incumbency shield" hypothesis and suggest that the binding constraint on airport throughput during the recovery was demand, not slot regulation.

---

### 3. Essential Points

**Critical Issue 1: Parallel Trends and Pre-Trends Testing**
The paper’s credibility hinges on the parallel trends assumption, which is tested in Table 3 (event study). While the within-country specification (column 2) shows no significant pre-trends, the baseline specification (column 1) reveals a marginally significant negative coefficient for 2016 (-0.088, p=0.02). This suggests differential trends *prior* to the waiver, which could bias the results. The authors must:
- Explicitly acknowledge this pre-trend in the text and discuss its implications for the baseline specification.
- Justify why the within-country specification (which absorbs country×year shocks) is the preferred approach, given that it eliminates pre-trends.

**Critical Issue 2: Interpretation of the Null Result**
The paper concludes that the waiver had "no detectable effect" on competition, but the null result could reflect either:
1. A true absence of effect (the waiver did not distort competition), or
2. Low statistical power to detect meaningful effects, especially if the waiver’s impact was heterogeneous (e.g., concentrated at specific airports or routes).
The authors must:
- Report power calculations or minimum detectable effects (MDEs) for the key specifications, particularly the within-country model.
- Discuss whether the null result could mask heterogeneity (e.g., by airport size, route type, or carrier dominance). The appendix (Table S1) hints at this but does not explore it thoroughly.

**Critical Issue 3: Mechanism and External Validity**
The paper argues that the waiver’s null effect is consistent with demand being the binding constraint, not slot access. However, this interpretation assumes that:
- The waiver did not lead to slot hoarding that blocked entry at the *route level* (which would not necessarily appear in airport-level aggregates).
- The recovery period (2021–2023) was long enough for competitive effects to materialize.
The authors must:
- Clarify whether route-level data (e.g., OAG or Cirium) could be used to test for effects on specific routes or carriers, even if such data are not currently available.
- Discuss the external validity of the results: Would a similar waiver in a non-crisis period (e.g., during a demand boom) have the same null effect?

---

### 4. Suggestions

**Data and Measurement**
1. **Alternative Outcomes**: The paper focuses on passenger volumes, but the "incumbency shield" hypothesis could also manifest in:
   - Market concentration (e.g., Herfindahl-Hirschman Index at the airport level).
   - Entry/exit of airlines or routes (if route-level data are available).
   - Slot utilization rates (e.g., % of allocated slots actually used).
   The authors should discuss these alternatives, even if data limitations preclude their use.

2. **Dynamic Effects**: The event study (Table 3) suggests that the effect of the waiver may have evolved over time (e.g., larger coefficients in 2020–2021 than in 2022–2023). The authors could:
   - Test for differential effects by waiver intensity (e.g., 0% vs. 50% vs. 64% thresholds).
   - Include leads/lags of the treatment variable to assess whether effects were delayed.

3. **Placebo Tests**: The scheduled/non-scheduled decomposition is a strong placebo test. The authors could further strengthen this by:
   - Testing for effects on cargo flights (which are not subject to slot rules but may correlate with passenger demand).
   - Using a triple-difference design (Level 3 × Waiver × Scheduled) to directly compare the two passenger types.

**Methodology**
4. **Heterogeneity Analysis**: The appendix (Table S1) splits Level 3 airports into large hubs (≥10M passengers) and smaller airports, but the results are not discussed in the text. The authors should:
   - Explore heterogeneity by airport size, carrier dominance (e.g., % of slots held by the largest airline), or country (e.g., hubs in Germany vs. peripheral airports in Eastern Europe).
   - Test for effects on low-cost carriers (LCCs), which are more likely to be slot-constrained than legacy carriers.

5. **Functional Form**: The paper uses log passengers as the primary outcome, which is appropriate for proportional effects. However, the authors could:
   - Report results using the inverse hyperbolic sine (IHS) transformation (as in Table 4, column 4) as a robustness check, given its advantages for zero-valued outcomes.
   - Discuss whether the null result is sensitive to the choice of functional form (e.g., levels vs. logs).

6. **Standard Errors and Clustering**: The paper clusters standard errors at the airport level, which is appropriate. However, the authors could:
   - Report wild bootstrap p-values as a robustness check, given the relatively small number of Level 3 airports (N=68).
   - Discuss whether clustering at the country level (in addition to airport level) would be warranted, given that slot rules are set at the EU level.

**Policy Implications**
7. **Ghost Flights vs. Incumbency Shield**: The paper focuses on the "incumbency shield" but does not directly test for "ghost flights" (empty or lightly loaded flights operated solely to retain slots). The authors could:
   - Use flight-level data (if available) to test whether the waiver reduced the number of low-load-factor flights.
   - Discuss whether the null effect on passenger volumes implies that ghost flights were not a major issue during the waiver period.

8. **Regulatory Context**: The paper notes that the results inform the EU’s revision of Regulation 95/93. The authors could:
   - Compare the EU’s graduated restoration approach to other jurisdictions (e.g., the U.S., where slot rules were also waived but without a staggered restoration).
   - Discuss whether the null result implies that slot rules are less important for competition than previously thought, or whether the waiver’s design (e.g., temporary, staggered) mitigated potential distortions.

**Presentation and Clarity**
9. **Figures**: The paper would benefit from visualizations of:
   - The event study coefficients (Table 3) with confidence intervals, to better illustrate the parallel trends assumption.
   - The dose-response relationship (e.g., a plot of the effect of waiver intensity on passenger volumes).
   - A map of Level 3 vs. Level 1/2 airports to highlight the geographic distribution of treatment.

10. **Tables**: The tables are well-constructed, but the authors could:
    - Add a column to Table 1 (summary statistics) showing the number of airports by country, to highlight the geographic coverage.
    - Include a table showing the distribution of waiver intensity over time (e.g., % of airports subject to each threshold in each year).

11. **Discussion of Limitations**: The paper briefly mentions limitations (e.g., lack of route-level data) but could expand on:
    - Whether the results generalize to non-crisis periods (e.g., if demand were growing rather than recovering).
    - Whether the waiver’s temporary nature affected airlines’ incentives (e.g., if they expected the rule to be restored, they may not have hoarded slots aggressively).

**Minor Suggestions**
12. **Terminology**: The term "incumbency shield" is catchy but could be clarified. The authors should define it explicitly (e.g., "the ability of incumbent airlines to retain slots without operating flights, thereby blocking entry by competitors").
13. **Literature**: The paper cites key theoretical work on slot allocation (e.g., Brueckner, Czerny, Verhoef) but could engage more with the empirical literature on airline competition (e.g., Borenstein, Berry, Ciliberto) to contextualize the null result.
14. **Appendix**: The standardized effect sizes (Table S1) are useful but could be expanded to include:
    - Heterogeneity by country or region.
    - A comparison of effect sizes for the baseline vs. within-country specifications.

---

### Overall Assessment

This is a well-executed paper that makes a novel and policy-relevant contribution. The identification strategy is compelling, the data are comprehensive, and the results are robust to multiple specifications. The null finding is informative and challenges conventional wisdom about the importance of slot rules for competition. With minor revisions—particularly around the parallel trends assumption, heterogeneity analysis, and discussion of mechanisms—the paper would be a strong candidate for publication in *AER: Insights*. The authors should address the three critical issues above, but none of them are fatal flaws.
