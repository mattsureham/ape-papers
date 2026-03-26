# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant A)

**Model:** moonshotai/kimi-k2.5
**Variant:** A
**Date:** 2026-03-26T15:34:33.259497

---

**Referee Report**

**Manuscript:** “The Wedge Illusion: Factor-Specific Tax Rates Move the Tax Base but Not the Factors”  
**Journal:** AER: Insights (target format)  
**Recommendation:** Major Revision

---

### 1. Idea Fidelity

The manuscript pursues the core empirical agenda outlined in the manifest with high fidelity. The authors exploit the rare within-municipality variation in corporate versus personal Steuerfuss (tax multiplier) rates in the Canton of Zurich to test whether factor-specific tax instruments generate factor-specific sorting. The data sources (STATENT, cantonal Steuerkraft statistics, population registers) match those proposed, and the research question—whether firms and residents respond to their respective tax prices or whether the standard one-dimensional Tiebout model suffices—remains central.  

Two deviations from the manifest are notable. First, the analysis is restricted to Zurich (172 municipalities) rather than pooling Zurich with Basel-Landschaft and Thurgau as originally envisaged; this reduces power but preserves data consistency. Second, the manifest described a “triple-difference” (DDD) strategy exploiting “within-municipality, within-year, across-factor-type variation,” whereas the implemented design is a two-way fixed effects panel with separate coefficients for corporate and personal rates (effectively a difference-in-differences across tax instruments). This is a reasonable simplification, but the authors should clarify why the interaction structure of a DDD was abandoned (likely due to the lack of a clean control group when all municipalities set both rates). Overall, the paper delivers on the proposal’s novelty: it is indeed the first to exploit the within-municipality wedge divergence to test for differential mobility.

---

### 2. Summary

Using a panel of 172 Zurich municipalities (2012–2023), the authors test whether changes in the corporate-personal tax wedge trigger Tiebout sorting. They find precise null effects on physical measures of economic activity (establishment counts, employment, population) but document large, significant declines in municipal tax capacity (Steuerkraft) when corporate rates rise. The paper concludes that factor-specific tax instruments alter financial reporting (profit shifting) rather than physical location, suggesting that tax competition operates through the ledger rather than the moving truck.

---

### 3. Essential Points

**1. Endogeneity of Tax Rate Setting.** The identification strategy assumes that changes in the corporate-personal wedge are orthogonal to unobserved shocks conditional on municipality and year fixed effects. This assumption is implausible in the Swiss municipal context. Steuerfuss rates are set annually by municipal assemblies in response to fiscal needs, budget deficits, and anticipated tax base changes. The striking result that higher personal Steuerfuss rates predict *higher* Steuerkraft (Table 2, column 6: $\hat{\beta}=+0.024$, $p<0.05$) is consistent with reverse causality—municipalities raise personal rates when they have fiscal slack or a growing tax base—rather than with inelastic personal tax bases. Similarly, corporate rate cuts may follow negative forecasts about the local tax base. Without an instrument (e.g., political fragmentation, close election results, or cantonal harmonization mandates) or a compelling narrative strategy isolating plausibly exogenous changes, the causal interpretation of the Steuerkraft elasticity (-3.1% per percentage point) remains speculative.

**2. Mechanism Ambiguity.** The paper interprets the Steuerkraft result as evidence of profit shifting or income reclassification. However, Steuerkraft is a three-year rolling average of the realized tax base, which conflates several mechanisms: (i) pure profit shifting (the same firms reporting lower profits); (ii) compositional changes (high-profit firms shrinking or exiting while low-profit firms enter, even if the *count* of establishments is unchanged); and (iii) mechanical mean-reversion in tax bases. Because the authors observe establishment counts but not profitability per establishment or corporate vs. personal tax revenue separately, they cannot distinguish between intensive-margin shifting and extensive-margin selection. The claim that “the firm stays, but its taxable income migrates” requires direct evidence on profit-per-firm or a decomposition of Steuerkraft into its corporate and personal components.

**3. Interpretation of Null Effects.** The paper characterizes the zero coefficients on establishments and population as a “precise null.” However, the confidence intervals (e.g., for establishments: $\hat{\beta}=0.002$, SE $=0.005$) do not rule out economically meaningful effects. A one-standard-deviation increase in the corporate rate (14.2 percentage points) could plausibly affect establishment counts by up to 10% given the upper bound of the 95% confidence interval ($0.002 + 1.96\times0.005 \approx 0.012$; $0.012 \times 14.2 \approx 17\%$). The authors should conduct equivalence tests or report standardized effect sizes (following Appendix Table 5) in the main text to demonstrate that the null is informative rather than merely imprecise.

---

### 4. Suggestions

**Addressing Endogeneity.** I recommend two approaches. First, exploit political economy instruments: municipal tax rates are often tied to local election cycles or the partisan composition of the executive. A regression discontinuity design around close municipal council elections (e.g., margin $<5\%$) could generate plausibly exogenous variation in fiscal conservatism and thus tax rates. Second, use cantonal-level reforms as instruments. Several cantons have mandated harmonization of municipal tax multipliers or imposed caps on rate dispersion; the threat of such reforms may induce anticipatory rate changes that are uncorrelated with local idiosyncratic shocks. If valid instruments are unavailable, the authors should pivot to a “narrative” identification strategy,
