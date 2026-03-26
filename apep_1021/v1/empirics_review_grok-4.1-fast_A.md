# V1 Empirics Check — x-ai/grok-4.1-fast (Variant A)

**Model:** x-ai/grok-4.1-fast
**Variant:** A
**Date:** 2026-03-26T22:08:04.561943

---

### 1. Idea Fidelity

The paper deviates substantially from the original idea manifest. The manifest proposed a sector-month difference-in-differences (DiD) design using treatment intensity based on shell-company exposure in treated sectors (e.g., financial services K64-66, legal M69-70, real estate L68) versus controls (e.g., agriculture A, manufacturing C), at the sector-municipality-month level (119 municipalities × ~20 sectors × 84 months). The unit was sector × municipality × month, with an estimating equation incorporating sector-municipality fixed effects (\( \alpha_{ik} \)) and a HighExposure_i × Post_t interaction. Placebos included Estonia/Lithuania as synthetic controls and false reform dates (2016, 2019), leveraging sector-specific non-resident exposure from Bank of Latvia reports and Statistics Latvia NACE data.

Instead, the paper implements a coarser firm-type-by-geography DiD (shell-likely types like SIA in Riga vs. three controls: shell-likely non-Riga, non-shell Riga, non-shell non-Riga), aggregated to group-month cells (336 observations). It omits all sector variation (no NACE codes used), municipality granularity (Riga vs. rest only), event studies, and cross-country placebos. The research question shifts from AML shock propagation to *sector-level* firm demographics to overall *shell-company* dissolution in the capital, missing the manifest's emphasis on domestic costs via intermediary sectors (financial, legal, real estate). Data source matches (Enterprise Register CSV), but supplementary Statistics Latvia and Bank of Latvia sector data are unused. This is not a faithful pursuit of the original idea.

### 2. Summary

This paper examines the firm-level consequences of Latvia's 2018 AML shell-company bank account ban following the FinCEN designation of ABLV Bank, using the full Latvia Enterprise Register to construct a firm-type-by-geography DiD. It finds large increases in dissolution rates (+7.5 per 1,000 active firms, or 119% over baseline) and declines in registrations (-1.0 per 1,000) for shell-likely firms (e.g., SIA LLCs) in Riga, reducing the active stock by 28% (~24,000 firms lost), with spillovers to service providers like sole proprietors. Mechanism tests by firm type and registration cohort support a shell-company channel, framing results as a "laundering premium" quantifying opacity-sustained economic activity.

### 3. Essential Points

**1. Identification strategy lacks credibility due to coarse grouping and untested parallel trends.** The firm-type × geography DiD treats "shell-likely" (SIA/AS/foreign offices, ~80% of firms) in Riga as exposed, but SIA is Latvia's modal form for *all* businesses, not uniquely shells—diluting treatment specificity. Controls may not be valid: non-Riga SIA firms plausibly shared non-resident exposure (manifest notes Group 2 banks served nationwide), and Riga non-shell firms (e.g., farms) could capture capital-specific shocks. No event-study plots or pre-trend tests (e.g., leads in Eq. 1) are shown; summary stats hint at possible pre-divergence (treated dissolution mean 6.27 vs. controls ~3-4), undermining parallel trends. Authors must provide dynamic event-study estimates (e.g., \( \sum_{k=-24}^{48} \beta_k \) Treated_g × RelTime_{kt} ) with pre-2018 coefficients jointly testing =0 (p<0.10 threshold), or reject.

**2. Empirical approach mismatches the research question on *domestic economic costs*.** The paper quantifies shell dissolution but sidesteps propagation to *service sectors* (legal, real estate), central to the "ecosystem" claim and policy hook (FATF costs). Firm-type proxy misses this: no NACE/sector data used despite manifest's Statistics Latvia PX-Web API. Mechanism tables show spillovers (sole proprietors +2.5), but without sector links, effects could reflect direct shell closures, not broader costs. Authors must incorporate sector variation (e.g., interact Treated with NACE exposure from Bank of Latvia FSR) or reframe away from sector spillovers.

**3. No placebo or falsification tests beyond subgroups weaken internal validity.** Manifest promised Estonia/Lithuania synthetic controls and fake dates; paper offers none. Subgroup placebos (farms null) are suggestive but non-random (authors pick "natural placebo"). Coinciding ECB wind-down/legislation (Feb-May 2018) risks anticipation/confounding. Authors must add (i) cross-Baltic DiD (Latvia Post × Riga-shell vs. Estonia/Lithuania analogs) and (ii) placebo on fake dates (e.g., 2016), reporting β=0; failure to do so implies rejection.

### 4. Suggestions

The paper is well-written, concise, and leverages a compelling institutional shock with accessible data—strong for AER: Insights. Results are large/precise, and the "laundering premium" framing is novel and policy-relevant. Below are targeted improvements to elevate it.

**Data and Measurement:**  
- Link firms to sectors via Statistics Latvia PX-Web (manifest-confirmed) or infer from firm names/addresses (e.g., keyword matches for "law"/"consulting"). Compute sector-month dissolution rates, then estimate sector-specific DiD (HighExposure_sector × Post), nesting within the current design. This directly tests propagation to financial/legal/real estate, aligning with the question.  
- Refine "shell-likely": add proxies like zero employees/assets (if inferable from register/address clustering) or registration address = postal box (common for shells). Report balance table: pre-treatment means of observables (e.g., registration year, region shares) across groups.  
- Extend outcomes: include log employment/tax filings if register links to tax data (common in Nordic registers); compute cumulative firm loss by 2021 with binned scatterplots (active firms vs. pre-2018 stock).

**Empirical Strategy:**  
- Replace Post dummy with flexible event study: 24 pre/48 post leads/lags, plotting coefficients ±90% CI (twosided). Test pre-trends (joint F-test) and dynamic effects (post-1 vs. post-12+). Use Callaway-Sant'Anna (2021) or Sun-Abraham (2021) for multi-period robustness if trends violate TWFE.  
- Stack controls hierarchically: estimate triple-difference (Treated_type × Riga × Post) to isolate interaction, reducing omitted variable bias. Cluster SEs at group level (only 4 groups, so wild bootstrap).  
- Robustness suite: (i) linear/group trends; (ii) alt Post (May 2018 law); (iii) exclude 2020 COVID (interaction term); (iv) synthetic controls weighting Estonia/Lithuania firm data (if accessible via EU registers). Report in \Cref{tab:robustness} with 8-10 columns.

**Mechanisms and Heterogeneity:**  
- Expand Table 3: include p-values for differences across rows (e.g., SIA vs. farms: β_SIA - β_farms =0 test). Plot dissolution paths by subgroup (4-panel event study).  
- Age het (Table 4): motivate 2000-09 boom with Figure (cohort shares over time). Add address-based het: % firms at high-density shell addresses (e.g., top 10 Riga postcodes).  
- Spillover depth: for sole proprietors, subclassify by likely occupation (name keywords: "accountant"/"lawyer") and re-run DiD—quantifies "real Latvians" hit.

**Broader Improvements:**  
- Introduction: Add stylized Figure 1: timeline (FinCEN Feb, ECB Feb, law May) overlaid with raw treated/control series. Cite Zwick-Roark (2023 AER:Insights) for firm dynamics DiD best practices.  
- Policy: Quantify costs (e.g., lost GDP via firm counts × sector productivity from Stats Latvia). Compare to FATF greylisting episodes (e.g., Panama papers).  
- Appendix: Full balance tests, raw series plots, power calculations (given N=336), and code/data links (GitHub praised). Standardized effects (Appendix A) good—extend to mechanisms.  
- Length: Trim background (merge subs), move robustness to Appendix—fits 15-page Insights limit.  

Addressing essentials could make this publishable; current design credibly shows shell dissolution costs but underplays sector propagation. Strong potential for policy impact.
