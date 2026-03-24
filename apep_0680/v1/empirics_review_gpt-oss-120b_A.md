# V1 Empirics Check — openai/gpt-oss-120b (Variant A)

**Model:** openai/gpt-oss-120b
**Variant:** A
**Date:** 2026-03-14T16:04:07.656431

---

**1. Idea Fidelity**  
The submitted manuscript follows the original manifest closely: it exploits the sharp geographic perimeter of Lyon’s Zone à Faibles Émissions (ZFE) as a spatial regression‑discontinuity (RDD) using parcel‑level DVF transaction data, and it also presents a difference‑in‑discontinuities (DiD‑RDD) design to net out any pre‑existing price gap along the ring‑road boundary. All key components of the manifest are present – the running variable, bandwidth choices, the use of the EEA NO₂ monitors for a secondary check, and the focus on the policy relevance of the upcoming French abolition of ZFEs. The paper does not discuss the air‑quality data in the main analysis, but this was only listed as a secondary outcome in the manifest, so the omission is acceptable. Overall, the empirical strategy is faithful to the proposed idea.  

**2. Summary**  
The paper estimates the capitalization effect of Lyon’s low‑emission zone on residential property values by applying a spatial RDD (and a difference‑in‑discontinuities) to the full DVF transaction record. It finds that, after controlling for a pre‑existing price discontinuity along the ring‑road, the ZFE reduced inside‑zone prices by roughly 10 % (≈ ‑0.10 in log price) – a “mobility tax’’ that outweighs any air‑quality premium. The effect is driven by apartments and appears immediately after the first phase of the ban.  

**3. Essential Points**  

| # | Issue | Why it matters | What to do |
|---|-------|----------------|------------|
| 1 | **Potential omitted‑variable bias from the ring‑road** | The Boulevard Laurent Bonnevay is a major transport artery that may itself affect house prices (e.g., noise, traffic, accessibility). The DiD‑RDD attempts to purge a *level* pre‑existing gap, but the ring‑road could also induce *different trends* on each side of the boundary, violating the continuity of untreated potential outcomes. | Include explicit controls for distance to the ring‑road (or to major streets) and test for differential pre‑trends in a reduced‑form time‑varying specification (e.g., event‑study with interaction of distance and time). Show that the slope of the price‑distance relationship is parallel on both sides before the ZFE. |
| 2 | **Timing and treatment definition** | The paper treats the whole post‑Sept 2022 period as “treated”, yet the ZFE was implemented in two steps (Sept 2022 and Jan 2024). The DiD‑RDD specification only interacts a binary post indicator with the inside‑zone dummy, which conflates the two phases and makes the claim that “no additional effect from tightening” rely on a split‑sample analysis that is under‑powered. | Adopt a triple‑difference framework (inside × post‑2022 × post‑2024) or, more cleanly, estimate separate DiD‑RDD coefficients for each phase within a unified model. Provide power calculations and confidence intervals for the Phase‑2 estimate to justify the null finding. |
| 3 | **Validity of the McCrary test and sorting** | The McCrary density test is reported only for the *post‑ZFE* period, while the *pre‑ZFE* period shows significant bunching (p = 0.003). This raises concerns that the underlying spatial distribution of transactions changes around the boundary when the policy is announced, possibly reflecting anticipatory sorting (e.g., sellers timing sales before the ban). | Perform the density test separately for each month around the policy announcement to detect any short‑run spikes. If sorting is present, a placebo test using a *pseudo* boundary shifted a few hundred metres inward/outward can help assess robustness. Alternatively, employ a local–randomization approach that restricts attention to a narrow bandwidth where density is flat. |
| 4 | **Interpretation of the large covariate‑adjusted effect** | Adding property controls changes the estimate from ‑9.8 % to ‑16.3 % (Column 2). This sizable swing suggests that covariates are correlated with treatment status and that the simple RDD without controls may be biased. Yet the paper does not discuss why the covariate‑adjusted estimate is preferred or why the smaller bandwidth RDD (Column 1) yields a different magnitude. | Provide a clear justification for the preferred specification (e.g., bias‑variance trade‑off) and, preferably, report the covariate‑adjusted DiD‑RDD estimate (the “difference‑in‑discontinuities” version with controls). Demonstrate that the result is stable across bandwidths when controls are included. |

If any of these four points cannot be satisfactorily addressed, the paper’s identification will remain questionable, and I would have to recommend **rejection**. Assuming the authors can resolve them, the paper can proceed to a **revise‑and‑resubmit**.  

**4. Suggestions**  

Below are a range of non‑essential (but highly valuable) recommendations that can improve the paper’s clarity, credibility, and contribution.  

1. **Explicit Statement of the Identifying Assumption**  
   - Write a short paragraph (or a displayed equation) that formalizes the continuity of the *untreated* potential outcome at the boundary: \( \lim_{d \downarrow 0} E[Y_i(0)|d_i=d] = \lim_{d \uparrow 0} E[Y_i(0)|d_i=d] \).  
   - Discuss why the ring‑road’s pre‑existing discontinuity does not violate this assumption once the DiD‑RDD is applied.  

2. **Graphical Diagnostics**  
   - Include a scatter‑plot of average log price versus distance to the boundary (separate curves for pre‑ and post‑policy). A visual check of parallel trends strengthens the continuity claim.  
   - Plot the density of observations across the running variable (both periods) to complement the McCrary test.  

3. **Placebo Boundaries and Falsification Tests**  
   - Shift the ZFE polygon east and west by 500 m and 1 km, re‑estimate the DiD‑RDD, and confirm that estimates are near zero.  
   - Use a “fake” implementation date (e.g., September 2021) and show no significant discontinuity.  

4. **Air‑Quality Outcomes (Secondary)**  
   - Even if the main focus is on housing values, a brief analysis of NO₂ concentrations at the boundary would enrich the story. Show that the ZFE indeed lowered pollutants (or not) and discuss whether the magnitude of the air‑quality change is consistent with the modest (or negative) capitalization effect.  

5. **Heterogeneity Beyond Property Type**  
   - Investigate whether the effect varies with proximity to public transport, distance to the city centre, or socioeconomic characteristics of the census block (e.g., median income). This can clarify the equity channel.  
   - Consider interacting the treatment with a “parking availability” indicator (e.g., whether the parcel has a private garage), which could explain the divergent apartment vs. house results.  

6. **Robustness to Alternative Functional Forms**  
   - Present results from a global specification (e.g., a spatial lag model) to show that the localized RDD is not picking up spillovers from adjacent neighbourhoods.  
   - Report the bias‑corrected estimates from `rdrobust` (the paper already mentions them but does not show the numbers).  

7. **Sample Construction Transparency**  
   - Provide a flow chart summarising the filtering steps from the raw DVF file to the final analytical sample.  
   - Offer a supplemental table listing the number of observations per year, per quarter, and per bandwidth.  

8. **External Validity Discussion**  
   - Briefly compare the Lyon estimate with the German LEZ findings (e.g., Sager & Krekel 2025) and the London ULEZ anecdotal evidence. Discuss how differences in policy design (binary ban vs. sticker‑based fee), vehicle fleet composition, and urban form might explain the divergent signs.  

9. **Policy Simulation**  
   - Use the estimated elasticity to simulate the wealth loss (in euros) for owners in the inside‑zone area, and contrast it with the estimated air‑quality benefit (e.g., avoided premature deaths). Even a back‑of‑the‑envelope calculation would make the “mobility tax” narrative more tangible for policymakers.  

10. **Technical Appendices**  
    - Provide the code used for distance calculations and for `rdrobust` (e.g., a reproducible R script).  
    - Include the exact polygon coordinates (or a DOI link) so that future researchers can replicate the analysis for other French ZFEs.  

11. **Minor Presentation Issues**  
    - Tables 3–5 could be condensed; consider moving some robustness checks to an appendix and keeping the main text focused on the preferred specification.  
    - In Table 2, the label “Inside ZFE” under the coefficient column is confusing; rename it to “Treatment × Post” or similar.  
    - The abstract mentions “difference‑in‑discontinuities” but the term never appears in the main text until the methods section; a brief explanation earlier would help readers.  

By addressing the essential points above and incorporating many of these suggestions, the paper will present a solid, credible identification of the housing‑value impact of low‑emission zones in France and will make a valuable contribution to the environmental‑urban economics literature.
