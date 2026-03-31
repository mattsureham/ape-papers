# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-31T10:07:31.187465

---

**Idea Fidelity**

The paper generally pursues the original manifest idea: it leverages Korea’s January 2024 Phase 1 mandatory English disclosure reform and focuses on liquidity outcomes, foreign investment frictions, and Korea’s “reading” discount. The identification strategy is anchored in a staggered DiD using Phase 1 firms (total assets ≥ KRW 10 trillion) versus controls, and the data sources (Yahoo Finance for stock data, FinanceDataReader/DART for firm characteristics) align with the manifest. However, the paper does not deploy the manifest’s proposed RDD or triple-difference frameworks in practice. While the appendix reports an underpowered RDD, it is not central to the main analysis, and no triple-difference exploiting differential foreign ownership exposure is presented. The main empirical strategy is therefore simpler than envisioned; the promised RDD and triple-diff elements could have reinforced causality but remain largely undeveloped.

**Summary**

The paper examines whether Korea’s January 2024 mandatory English disclosure requirement for large KOSPI firms affected market liquidity. A DiD with firm and week fixed effects yields a statistically insignificant pooled effect on Amihud illiquidity and turnover, but reveals large, statistically significant illiquidity reductions (≈33%) for financial-sector firms. The paper interprets this sectoral heterogeneity as evidence that language frictions bind where detailed regulatory filings are the primary information channel.

**Essential Points**

1. **Credibility of Parallel Trends for the Pooled Estimate.** The pooled DiD exhibits a weakly significant violation of pre-trends (F=3.08, p<0.001), driven by two months roughly one year prior to treatment. This undermines confidence in the baseline coefficient, especially because treatment is determined by firm size—a correlate of post-2023 dynamics. Without stronger evidence that those two months reflect noise rather than a structural differential trend (e.g., placebo checks at different pseudo-treatment dates or pre-period trends stratified by sector), the pooled effect is difficult to interpret. Provide more diagnostics (e.g., visually plot event study coefficients with confidence intervals, test for pre-trends within subsets such as financial firms, or run a permutation test) to demonstrate that the pre-trends violation is benign.

2. **Treatment Classification and Control Group Composition.** The classification uses a one-time total asset threshold based on the most recent annual report, but Phase 1 treatment required foreign ownership ≥5% as well. The paper neither exploits this additional criterion nor explains whether it affects which large firms were actually treated versus those simply large enough but without the foreign ownership cutoff. Without confirming that all firms above the asset threshold were mandated—and that the control group remained untreated—the DiD risks contamination. Please document how treatment status is operationalized (e.g., firm list published by FSC, foreign ownership check) and whether there is any fuzziness. If fuzziness exists, consider a fuzzy DiD or limit the analysis to firms unambiguously treated vs. untreated.

3. **Mechanism for the Financial-Sector Effect.** The sectoral heterogeneity is the headline result, but the mechanism is asserted rather than tested. The paper claims English filings matter more for financial firms because foreign investors rely on regulatory filings there. Yet it lacks evidence that foreign trading or holdings actually increased for treated financial firms, or that financial firms had lower English disclosure before the mandate. A simple falsification is to show that foreign ownership growth post-treatment is concentrated in treated financial firms (using quarterly holdings). Alternatively, show that analyst coverage in English was lower for financial firms pre-treatment. Without these additional data, the interpretation remains speculative. Strengthen the mechanism by directly linking foreign participation (or another proxy for information reliance) with the liquidity response.

If these essential issues cannot be resolved, especially the second (treatment definition) and third (mechanism), the paper’s conclusions are not sustainable.

**Suggestions**

1. **Clarify Treatment Assignment and Timing.**  
   - Provide the actual list of Phase 1 firms mandated to disclose in English (perhaps in an online appendix) and confirm that no control firms were inadvertently treated.  
   - If the foreign ownership criterion mattered, explain how this was implemented. Did firms above the asset threshold but below the foreign-ownership cutoff remain untreated? If so, leverage that variation to refine treatment status or run sensitivity checks (e.g., restrict to firms with ≥5% foreign ownership).  
   - Detail whether firms began filing in English only in January 2024 or earlier/later (e.g., voluntary English filings could confound pre-period). You might check the language of filings for treated and control firms to document the sharpness of the break.

2. **Strengthen Parallel Trends Evidence.**  
   - Present the event-study coefficients graphically for the pooled sample and for the financial vs. non-financial subgroups, including 95% confidence intervals, so readers can visually assess pre-trends.  
   - Conduct additional placebo exercises: assign treatment to different asset thresholds (e.g., 8 trillion KRW) or to placebo dates (e.g., January 2022 and July 2023) for financial firms, not just the pooled sample.  
   - An explicit “pre-trend balancing test” (e.g., regress pre-treatment trends on a treatment indicator controlling for firm characteristics) might reduce concerns about the two errant months driving the F-test.

3. **Augment the Mechanism with Foreign Investor Evidence.**  
   - If feasible, procure quarterly foreign ownership data (e.g., from DART filings or KRX disclosures) to show whether foreign holdings or turnover increased differentially for treated financial firms post-treatment.  
   - Alternatively, use investor relations materials to show that English-language analyst coverage before 2024 was particularly scarce for financial firms, suggesting they had fewer alternative English information sources.  
   - Consider linking liquidity improvement to changes in analyst forecast dispersion or trading by ETFs (some of which track financial sectors) to buttress the channel argument.

4. **Revisit the “Korea Discount” Framing with Valuation Evidence.**  
   - Since a key motivation is the Korea discount, include at least descriptive evidence (even in an appendix) that P/B or valuation multiples respond for treated financial firms. This can serve as a bridge to the broader narrative without overclaiming causality.  
   - If you have monthly or quarterly price-to-book data, run a DiD on log P/B to see whether the liquidity gains translate into valuation improvements. Even if insignificant, reporting the point estimates would contextualize the economic implications.

5. **Bring Back the Triple-Difference / RDD Ideas If Possible.**  
   - The manifest highlighted an RDD and a triple-difference exploiting foreign ownership. If the data or statistical power are insufficient, state that explicitly and explain why these strategies were dropped. If they remain infeasible, consider dropping the appendix mention to avoid raising expectations.  
   - If you can identify a subset of control firms with <5% foreign ownership just below the asset threshold, use this to implement the envisaged triple-difference: treated vs. controls × post vs. pre × high vs. low foreign ownership. This would sharpen identification, especially for the channel.

6. **Expand on the Placebo and Robustness Discussion.**  
   - The placebo test currently estimates treatment at Jan 2023 but only for the pooled sample. Provide analogous placebo results for the financial-sector subsample; this would reassure that the headline heterogeneity is not driven by pre-trends.  
   - Provide the coefficient magnitudes and standard errors for additional robustness checks (e.g., sector-level clustered SEs, monthly frequency) in the main text rather than just the appendix, so readers can assess robustness more easily.

7. **Address Standard Error Concerns.**  
   - Week fixed effects capture common shocks, but clustering at the firm level may understate uncertainty when treatment timing is uniform. Consider two-way clustering (firm × week) or using the wild cluster bootstrap if concerns about few treated clusters remain, especially for the financial subgroup.  
   - Report the number of clusters (firms) and check whether the significant financial-sector result is sensitive to alternative clustering (e.g., by sector or by treatment status).

8. **Improve Discussion of Null Results.**  
   - The pooled effect is small and insignificant; the narrative could more explicitly treat this as evidence that the mandate only matters conditionally. Frame this as an informative null rather than a weakness—language matters only where filings are the key friction.  
   - Discuss potential heterogeneity within non-financial firms (e.g., those with global operations vs. purely domestic). This could suggest why no effect is observed there and guide future extensions.

By addressing these suggestions, the paper would strengthen its identification, clarify the treatment mechanism, and make a more compelling case that English disclosure selectively alleviates severe information frictions in Korea’s financial sector.
