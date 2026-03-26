# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant A)

**Model:** moonshotai/kimi-k2.5
**Variant:** A
**Date:** 2026-03-26T22:08:26.539629

---

 **Referee Report: "The Laundering Premium"**

**Manuscript ID:** [Redacted]  
**Journal:** AER: Insights  
**Recommendation:** Revise and Resubmit (Major Revision)

---

### 1. Idea Fidelity

The executed paper deviates substantially from the original research design outlined in the manifest, with significant consequences for identification and credibility. The manifest proposed a **sector-month difference-in-differences** using NACE industry classifications (treating K64-66, M69-70, L68, N82.1 vs. agriculture/manufacturing controls) at the municipality level, leveraging continuous variation in sectoral exposure to non-resident banking. 

The submitted paper instead adopts a coarse **firm-type-by-geography aggregation** (SIA in Riga vs. three control groups), collapsing the data to just four group-month cells (336 observations). This represents a problematic simplification: it discards the sectoral heterogeneity (financial services vs. legal vs. real estate) that was central to the original identification strategy, eliminates the cross-sectional municipal variation (119 municipalities) that would enable proper clustering and precision, and abandons the cross-country placebo analysis (Estonia/Lithuania) proposed for validation. The paper also omits the "treatment intensity" dimension (sectoral dependence on Group 2 banks) in favor of a binary interaction.

---

### 2. Summary

This paper estimates the domestic economic cost of Latvia's 2018 anti-money-laundering (AML) enforcement, which prohibited bank accounts for shell companies following FinCEN's designation of ABLV Bank. Using Latvian Enterprise Register data (482,492 firms), the author employs a difference-in-differences design comparing limited-liability companies (SIA) in Riga to other firm types and locations. The paper finds that the ban increased monthly dissolution rates by 7.5 per 1,000 active firms (a 119% increase) and reduced the stock of treated firms by 28%, suggesting a substantial "laundering premium" in the formal business sector.

---

### 3. Essential Points

**E1. Aggregation and Identification Crisis.** The paper aggregates the underlying microdata to just four group-month cells (SIA/Riga, SIA/non-Riga, non-SIA/Riga, non-SIA/non-Riga) × 84 months = 336 observations. With only four groups, the DiD estimator has effectively zero degrees of freedom for clustering, and the "parallel trends" assumption becomes untestable. Heteroskedasticity-robust standard errors are inappropriate here; with four groups, you cannot even cluster at the group level. The manifest correctly identified ~952 sector-municipality cells as the appropriate level of aggregation—the paper must revert to this granularity to achieve credible inference.

**E2. Missing Sectoral Heterogeneity.** The original idea emphasized that spillovers to domestic intermediaries (lawyers, accountants, real estate agents) were the key margin of interest for policymakers. The current paper aggregates all SIA firms, treating shell companies and their domestic service providers identically. Without sectoral decomposition (NACE K, M, L vs. other sectors), the paper cannot distinguish between the direct effect on shells and the spillover effects to legitimate domestic businesses—a distinction the abstract and introduction highlight as the paper's primary contribution.

**E3. Absence of Validation Checks.** The manifest proposed event studies, false reform dates (2016, 2019), and Estonia/Lithuania as synthetic controls. The paper includes none of these. The single "Post" dummy (starting Feb 2018) conflates the FinCEN announcement with the May 2018 legal implementation, and without an event study, readers cannot assess pre-trends or dynamic treatment effects. Given the fuzzy timing (banks began closing accounts between February and May), the paper needs to test for announcement vs. implementation effects and demonstrate that the dissolution spike aligns with the regulatory prohibitions rather than coincidental trends.

---

### 4. Suggestions

**S1. Revert to Sector-Municipality-Level Analysis.** Return to the design specified in the manifest: sector (NACE 2-digit) × municipality (119 units) × month. This restores the 952+ cells mentioned in the feasibility check and allows for two-way or multi-way clustering at the sector and municipality level. The treatment should be defined as *sectoral dependence on non-resident banking* (e.g., share of sectoral output/value-added dependent on Group 2 banks, as documented in Bank of Latvia Financial Stability Reports) interacted with a Riga indicator, rather than a simple SIA dummy. This continuous intensity measure will provide more precise identification than the current binary classification.

**S2. Distinguish Shells from Service Providers.** The mechanism tests (Table 3) currently compare SIA firms to farm enterprises and sole proprietors. Instead, exploit the *sectoral* variation within Riga:
- **Directly treated**: Shell companies per se (likely in sector K/other financial)
- **Spillover sectors**: Legal/accounting (M69-70), real estate (L68), corporate secretarial (N82.1) per the manifest
- **Pure controls**: Agriculture (A), Manufacturing (C)

This will allow you to test whether the "laundering premium" operated through direct dissolution of shells (sector K) or through spillovers to domestic intermediaries (sectors M, L, N), which is the policy-relevant distinction.

**S3. Add Cross-Border Placebo and Event Studies.** Implement the Estonia and Lithuania comparison proposed in the manifest. These Baltic peers faced similar macroeconomic conditions but did not experience the ABLV-specific AML shock until later. A triple-difference (Latvia × Treated Sectors × Post) vs. Estonia/Lithuania would dramatically strengthen identification by absorbing common Baltic trends. Additionally, plot event-study coefficients for the 36 months pre-treatment and 24+ months post-treatment to show (a) parallel pre-trends and (b) the timing of the dissolution spike relative to Feb 2018 vs. May 2018.

**S4. Address Treatment Timing and Anticipation.** The paper uses February 2018 (FinCEN announcement) as the treatment date, but the shell-company account prohibition did not legally take effect until May 2018. Banks may have begun closing accounts immediately, or firms may have anticipated the ban. Run an event study to show when effects begin, and consider specifications using May 2018 as the official treatment date, potentially with an "anticipation period" dummy for Feb–Apr 2018.

**S5. Mechanism Evidence on Service Providers.** The sole proprietorship result is suggestive but noisy. If possible, link firms to their legal representatives or registered activities to identify "corporate service providers" directly. Alternatively, use sector codes to identify accounting/legal firms specifically, rather than relying on the blunt "sole proprietor" category which includes hairdressers and taxi drivers.

**S6. Improve Standard Error Reporting.** With 336 aggregated observations and only 4 groups, robust standard errors are anti-conservative. If the editor insists on the current aggregation, report wild cluster bootstrapped p-values (Cameron, Gelbach, and Miller 2008) with very few clusters. Better yet, use the disaggregated sector-municipality-month data and cluster at the municipality and/or sector level.

**S7. Clarify External Validity.** The conclusion claims this is the "cleanest available test" of shutting down a non-resident banking sector. However, the current design cannot distinguish between Riga-specific trends and treatment effects. With the proposed cross-country placebo (Estonia/Lithuania) and sectoral heterogeneity, you can credibly claim that the 28% reduction represents a causal effect of AML enforcement rather than, say, a Riga-specific housing boom-bust or tech sector contraction.

**S8. Data Visualization.** The paper currently has zero figures. Add: (a) an event-study plot showing dissolution rates by group relative to Feb 2018, (b) a map showing dissolution rates by municipality to demonstrate the Riga concentration, and (c) a figure comparing Latvia vs. Estonia/Lithuania trends.

The underlying data and research question are excellent and well-suited for *AER: Insights*. However, the current empirical approach squanders the rich variation available in the Enterprise Register by aggregating to just four groups. The paper should be revised to match the sectoral, geographic, and cross-country dimensions of the original design.
