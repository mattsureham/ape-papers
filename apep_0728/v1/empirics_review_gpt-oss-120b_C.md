# V1 Empirics Check — openai/gpt-oss-120b (Variant C)

**Model:** openai/gpt-oss-120b
**Variant:** C
**Date:** 2026-03-20T19:43:41.626008

---

**1. Idea Fidelity**  
The manuscript follows the manifest almost to the letter. It uses the Pierce‑Schott (2016) NTR‑gap as the industry‑level trade‑exposure variable, the pre‑2000 Black manufacturing share at the county level as the racial‑composition dimension, and the 2000‑onward PNTR timing as the temporal shock. The data source is exactly the QWI race‑by‑industry panel that the idea‑manifest highlighted, and the sample (≈2 500 counties, 21 three‑digit manufacturing NAICS, 1995‑2010) matches the feasibility check. The identification strategy is a triple‑difference (DDD) with county‑×‑industry, county‑×‑quarter and industry‑×‑quarter fixed effects, exactly as proposed. The only minor departure is that the paper reports a “continuous” NTR‑gap interaction rather than a simple “high‑vs‑low” binary, but that is a natural extension and does not break the core design.

**2. Summary**  
The paper shows that the 2000 grant of permanent normal trade relations (PNTR) to China widened the Black–White earnings gap in U.S. manufacturing. Using a triple‑difference design that exploits industry‑level NTR‑gap exposure, county‑level pre‑PNTR Black employment shares, and the post‑2000 period, the author finds a statistically and economically large increase in the earnings gap, driven mainly by job loss (the extensive margin) among Black workers in highly exposed industries.

**3. Essential Points**  

| # | Issue (must be fixed) | Why it matters |
|---|------------------------|-----------------|
| 1 | **Interpretation of the DDD coefficient** – the paper alternates between reporting a *positive* coefficient (0.96 *** in column 1) and a *negative* coefficient (‑1.254 *** in column 3). The sign conventions are unclear, and the magnitude is implausibly large for a log‑earnings effect (‑1.25 ≈ −78 % change). | A mistaken sign or scaling (e.g., using the raw NTR‑gap rather than a normalized version) inflates the effect and undermines the claim that the gap widens by “8.4 log points”. The manuscript must clarify the exact specification, the units of NTR‑gap, and provide a back‑of‑the‑envelope translation into dollars or percentages that are reasonable. |
| 2 | **Standard‑error clustering** – the baseline clusters at the state level (42 clusters) while the treatment varies at the industry level and the key interaction varies at the county‑industry‑quarter level. With only 42 clusters, the SEs are likely downward‑biased, especially given the huge number of observations. Moreover, the two‑way state‑by‑industry clustering in Table 5 shows a SE of 0.18 (much larger). The paper should adopt the more robust two‑way clustering (or wild‑cluster bootstrap) as the primary inference, and report the corresponding t‑statistics. | Under‑clustering can produce spuriously “highly significant” results. The discrepancy between the two SE calculations is already evident; the paper’s headline significance hinges on the smaller SE. |
| 3 | **Mechanism identification** – the extensive‑margin narrative is based on log‑employment, hires and separations regressions that again use the same DDD interaction. However, the employment coefficient (‑9.53) is absurdly large for a log‑employment regression (implies a >99 % reduction). This suggests a specification error (perhaps the dependent variable is not logged, or the coefficient is multiplied by 100). The paper needs to correct the functional form, present marginal effects in interpretable units, and ideally show heterogeneous effects (e.g., by county size, by Southern vs. non‑Southern) to substantiate the “last‑hired‑first‑fired” story. | If the mechanism numbers are mis‑scaled, the claim that “the extensive margin dominates” cannot be trusted. Accurate magnitude is essential for policy relevance. |

If any of these three points cannot be remedied, the paper should be **rejected** for insufficient credibility.

**4. Suggestions (non‑essential but highly recommended)**  

1. **Clarify variable construction**  
   * Report a table that maps each 4‑digit SIC to the 3‑digit NAICS and the resulting NTR‑gap, with means and standard deviations.  
   * Explain whether the NTR‑gap is used in raw percentage points (0–1) or multiplied by 100. That will resolve the sign/scale confusion.  

2. **Provide a clean “effect size” translation**  
   * Convert the log‑earnings coefficient into a dollar change for a typical high‑exposure industry (e.g., apparel with NTR‑gap ≈ 0.52). Show both the absolute change and the percentage change relative to the pre‑PNTR Black average.  
   * A short robustness check that caps the NTR‑gap at the 90th percentile can demonstrate that the result is not driven by a few extreme industries.  

3. **Robust inference**  
   * Adopt the two‑way (state × industry) clustering or the wild‑cluster bootstrap as the default.  
   * Report the effective number of clusters (e.g., using the “Cameron–Miller” adjustment) to reassure reviewers.  

4. **Alternative specifications**  
   * **Binary exposure**: Replicate the main DDD using a high‑vs‑low NTR‑gap dummy (e.g., >0.25). This aids interpretation and aligns with the original Pierce‑Schott paper.  
   * **Leave‑one‑out industry**: Drop the top exposure industry (apparel) and re‑estimate to verify that the result does not hinge on a single sector.  
   * **Placebo timing**: Use a fake “PNTR” date (e.g., 1997) and show that the triple interaction is null, strengthening the causal claim.  

5. **Heterogeneity checks**  
   * **Geographic**: Split the sample into the South, Midwest, and West to see whether the effect is driven by regional labor‑market dynamics.  
   * **Skill/education**: If the QWI provides average education or occupational category, regress the triple interaction on sub‑samples (high‑school vs. some college) to test whether lower‑skill Black workers are more affected.  

6. **Discussion of compositional vs. wage effects**  
   * Since the QWI does not follow individuals, the paper could complement the analysis with a supplemental data source (e.g., CPS or ACS) that tracks workers’ transitions across industries. Even a brief exercise showing that Black workers in high‑exposure counties have higher out‑migration or sector‑switching rates would bolster the mechanism story.  

7. **Sensitivity to other trade shocks**  
   * As the “bigger picture” section suggests, a short appendix estimating the same DDD for the 1994 NAFTA or the 2018 Section 232 steel‑tariff shock would illustrate the generality of the approach and increase the paper’s appeal.  

8. **Presentation improvements**  
   * Fix the typo in Table 2 where column 1 shows a **positive** coefficient (0.961) while the text discusses a **negative** widening effect.  
   * Align all tables (e.g., Table 5) so that the “Asian placebo” coefficient is clearly labeled as a *null* test; the current magnitude (‑0.691) is still statistically significant, which could be mis‑read as a failure of the placebo.  
   * Include a simple graph of the event‑study coefficients with confidence bands; visual inspection of parallel pre‑trends is more convincing than a table of numbers.  

9. **Economic relevance**  
   * Expand the policy implications beyond “targeted adjustment assistance”. Quantify the aggregate earnings loss for Black workers (e.g., total dollars per year) based on the estimated effect and the number of affected workers.  
   * Discuss how the findings relate to recent debates on trade‑adjustment programs (TAAs) and whether race‑targeted TAAs would have mitigated the observed gap.  

10. **Reference updates**  
    * Cite the latest QWI documentation (2024) and any recent methodological papers on DDD inference (e.g., Sun & Abraham 2021) to position the work within current best practices.  

---

**Bottom line:** The paper addresses an original and important question and exploits a novel data set with a clever DDD design. However, the current manuscript suffers from sign/scale inconsistencies, possibly understated standard errors, and implausibly large magnitude of the extensive‑margin coefficients. Resolving these three essential issues will make the contribution credible and policy‑relevant. The extensive list of supplemental suggestions should help the authors polish the analysis and presentation for an AER‑Insights submission
