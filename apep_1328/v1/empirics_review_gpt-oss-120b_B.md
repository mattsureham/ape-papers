# V1 Empirics Check — openai/gpt-oss-120b (Variant B)

**Model:** openai/gpt-oss-120b
**Variant:** B
**Date:** 2026-04-02T18:45:17.312589

---

**1. Idea Fidelity**  
The paper follows the manifest idea closely. It investigates Estonia’s e‑Residency launch in December 2014, uses the Baltic neighbors (Latvia and Lithuania) as primary controls, and augments the comparison with a synthetic‑control donor pool of nine European small‑open economies. The data sources (World Bank entrepreneurship indicators, Estonia’s e‑Residency Dashboard, and auxiliary macro variables) match those listed in the manifest. The identification strategy—parallel‑trend DiD complemented by an augmented synthetic‑control method (ASCM) with conformal inference—is exactly what was proposed. The only minor deviation is the inclusion of a few extra covariates (trade openness, internet penetration) in one DiD specification, which does not alter the core design. Overall, the paper faithfully implements the original plan.

---

**2. Summary**  
This paper provides the first causal estimate of Estonia’s e‑Residency program on firm‑formation activity. Using a DiD and ASCM framework, it finds that eliminating the administrative border cost of incorporation raises new business registrations by roughly 8–11 firms per 1,000 working‑age residents—a 66–81 % increase—while having no detectable impact on GDP per‑capita. Decomposition shows that only 15–26 % of the surge stems from e‑Resident firms, with the remainder coming from domestic entrepreneurs, suggesting ecosystem spillovers but limited real‑economy effects.

---

**3. Essential Points**  

1. **Validity of the Parallel‑Trend Assumption** – The pre‑treatment event‑study coefficients are largely flat for 2011‑2013, but the earlier 2006‑2010 period shows a negative trend (Estonia catching up to peers). Because the treatment period is relatively short, any lingering differential trend could bias the DiD upward. The paper should provide a more formal test (e.g., coefficient‑on‑time trends, placebo DiD using a “pseudo‑treated” Baltic country) and discuss how the observed convergence affects the magnitude of the estimated effect.

2. **Measurement of the Outcome Variable** – World Bank’s IC.BUS.NDNS.ZS aggregates *all* limited‑liability company registrations, including branches and special‑purpose vehicles that may not reflect entrepreneurial activity. The authors rely on the e‑Residency Dashboard for the e‑Resident share but have no way to verify the “domestic” component. A robustness check using an alternative firm‑formation measure (e.g., national business register counts, sector‑level breakdowns, or startup‑specific registrations) would strengthen confidence that the estimated surge truly represents new entrepreneurial ventures rather than bookkeeping artefacts.

3. **Interpretation of the Null GDP Effect** – The paper argues that the lack of GDP response shows that the new firms are “virtual.” However, GDP per‑capita is a very coarse outcome and may not capture early‑stage productivity gains, export‑oriented services, or tax‑revenue effects that manifest with a lag. The authors should either (i) examine lagged GDP effects (e.g., 2‑year leads) or (ii) supplement with alternative welfare‑relevant outcomes such as tax receipts, employment in the ICT sector, or foreign‑direct investment inflows. Without this, the claim of a “hollow dividend” remains under‑substantiated.

If the authors cannot satisfactorily address these three points, the paper should be rejected.  

---

**4. Suggestions**  

1. **Enhance Pre‑Trend Diagnostics**  
   - Plot the raw series and fitted synthetic control for Estonia and the weighted donor pool, highlighting the 2006‑2010 convergence.  
   - Conduct an “event‑study with linear time trends” allowing each country its own pre‑trend and test whether the post‑treatment coefficient remains significant.  
   - Report placebo DiD estimates where Latvia or Lithuania are artificially treated; this complements the in‑space placebo already shown.

2. **Alternative Firm‑Formation Measures**  
   - Obtain Estonia’s national business register data (available via Statistics Estonia) to construct a count of *new* private limited companies, distinguishing between “e‑Resident” and “non‑e‑Resident” entities.  
   - If sectoral data are accessible, isolate high‑tech or services sectors where e‑Residence is most plausible, to see whether the effect concentrates there.  
   - Use the OECD’s Business Demography Statistics, which may provide a cross‑country comparable series, to verify robustness of the magnitude.

3. **Deeper Exploration of the Mechanism**  
   - The decomposition relies on aggregate dashboard totals. Consider matching e‑Resident firm IDs (if publicly available) to the World Bank series to directly estimate the share of total registrations.  
   - Interview or citation of qualitative evidence (e.g., growth of fintech service firms) could be incorporated to bolster the “ecosystem spillover” narrative.  
   - Test whether the surge in domestic registrations is temporally correlated with the rise in e‑Resident firms (e.g., Granger‑causality test on yearly aggregates).

4. **Broader Outcome Set**  
   - **Tax Revenue:** Use Estonia’s tax‑board data on corporate tax receipts or fee income from e‑Residency (the paper mentions €400 M cumulative revenue; a yearly breakdown would allow a DiD test).  
   - **Employment:** If quarterly employment data are available, examine whether the increase in firm registrations translates into higher employment, perhaps with a lag.  
   - **Export Activity:** Since many e‑Resident firms target EU markets, include export‑to‑EU shares as an outcome.  
   - **Innovation Indicators:** Patent applications or R&D expenditure could capture higher‑value activity that may be missed by GDP.

5. **Refine the Synthetic Control Implementation**  
   - Provide the exact hyper‑parameters (ridge penalty λ, donor‑weight constraints) used in the ASCM, and show a sensitivity analysis over a plausible range.  
   - Present the pre‑treatment RMSPE for the treated unit versus the average RMSPE of donor units; if the treated unit’s fit is substantially worse, discuss implications.  
   - Include a “donor‑weight plot” to transparently show which countries drive the synthetic Estonia, aiding interpretation of the counterfactual.

6. **Statistical Inference Presentation**  
   - The conformal p‑value of 0.21 for the ASCM ATT suggests weak statistical significance. It would help the reader to present the full confidence interval (e.g., 95 % CI) and discuss the practical relevance of the point estimate despite the wide interval.  
   - Consider using the “placebo‑in‑time” distribution of ASCM effects to complement the DiD p‑values, thereby giving a fuller picture of uncertainty.

7. **Clarify the Policy Discussion**  
   - The paper’s conclusion that the “digital border dividend is hollow” may be overstated. Emphasize that the program delivers fiscal and ecosystem benefits, and that the lack of GDP impact is consistent with the early‑stage nature of many e‑Resident firms.  
   - Discuss potential heterogeneity: perhaps larger e‑Resident firms (e.g., SaaS providers) do generate output later; suggest avenues for future research with firm‑level panel data.  
   - Situate findings relative to the broader literature on “borderless entrepreneurship” (e.g., work on digital nomads, offshore incorporations) to highlight the contribution.

8. **Minor Presentation Improvements**  
   - The table of summary statistics mixes post‑ and pre‑period means; consider separating them for clarity.  
   - Define the indicator IC.BUS.NDNS.ZS in a footnote the first time it appears, for readers unfamiliar with World Bank codes.  
   - Ensure consistency in notation (use either “Post” or “Post‑t” throughout).  
   - Add a brief description of the conformal inference method in the main text (Appendix is fine, but a one‑sentence reminder helps non‑methodologists).  

By addressing these suggestions, the paper will substantially strengthen its identification, broaden its evidence base, and provide a more nuanced assessment of the economic relevance of digital‑border reforms. The topic is timely and the data are promising; with the recommended refinements, the manuscript should merit publication in **AER: Insights**.
