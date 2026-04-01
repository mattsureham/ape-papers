# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant C)

**Model:** moonshotai/kimi-k2.5
**Variant:** C
**Date:** 2026-04-01T13:02:49.962758

---

 **Review of "The Price of Silence: Short-Selling Bans, Overpricing, and the Retail Protection Paradox"**

---

### 1. Idea Fidelity

The paper pursues the core empirical strategy outlined in the manifest—exploiting the symmetric imposition and removal of South Korea’s 17-month short-selling ban—but deviates critically from the original research design in three ways. First, the sample collapses from the promised universe of ~2,500 KOSPI/KOSDAQ stocks to just 69 large-cap securities (2.8% of listed firms), discarding the cross-sectional variation essential for identification and external validity. Second, the treatment intensity variable shifts from pre-ban *short interest* (the manifest’s stated measure) to pre-ban *volatility*, a substitution that fundamentally alters the economic mechanism being tested. Third, the quantitative welfare calculation advertised in the manifest—computing retail investor losses using KRX investor-type flow data—disappears entirely, replaced by qualitative assertions about the "retail protection paradox" unsupported by micro-level trading data. While the symmetric event-study framework and placebo test remain faithful to the original concept, these omissions transform the paper from a comprehensive market-wide analysis into a small-sample demonstration with limited policy relevance.

---

### 2. Summary

This paper examines South Korea’s 2023–2025 complete short-selling ban using a cross-sectional event study of 69 stocks, finding that high pre-ban volatility predicts larger abnormal returns at ban imposition and more negative returns at removal. The author interprets this symmetric pattern as evidence that suppressing short selling inflated prices of speculative stocks, paradoxically harming retail investors who purchased during the ban-induced rally.

---

### 3. Essential Points

**1. Market-model abnormal returns are invalid when the treatment is market-wide.**  
The paper computes abnormal returns as $AR_{it} = r_{it} - r_{mt}$ using the KOSPI index. When the ban applies to the entire market, $r_{mt}$ is endogenous: it embeds the aggregate treatment effect (KOSPI rose 5.7% on ban day). Subtracting the market return induces a mechanical negative correlation between "abnormal" returns and the treatment, biasing estimated cross-sectional effects toward zero or flipping their sign depending on beta heterogeneity. The $R^2$ of 0.49 in the KOSPI subsample is a red flag—such explanatory power often signals a mechanical relationship or extreme outliers (e.g., Ecopro BM) rather than a causal parameter.

**2. The sample of 69 stocks is not representative and likely selected on outcomes.**  
The manifest promised analysis of ~2,500 stocks using KRX Data Marketplace. The actual sample comprises 50 KOSPI and 19 KOSDAQ stocks, presumably the largest and most liquid. This selection discards the very small-cap, high-volatility KOSDAQ stocks where short-selling constraints bind most tightly and retail participation is highest. The KOSDAQ subsample results (Table A.1) show the *wrong* sign for ban-imposition effects ($\hat{\beta} = -0.04$), suggesting selection bias or insufficient power. Without addressing how these 69 stocks were chosen (liquidity filters? data availability?), the external validity of the welfare conclusions is compromised.

**3. Volatility is a problematic proxy for short-selling demand.**  
The manifest emphasized pre-ban short interest as treatment intensity; the paper substitutes volatility, acknowledging short-interest data is unavailable. This is not a minor measurement error—volatility is endogenous to the same information arrival process that drives short-selling demand and is mechanically correlated with event-window returns. High-volatility stocks experience larger absolute price movements by construction, creating a "fake" treatment effect even without short-covering pressure. The paper requires validation (e.g., correlating pre-ban volatility with historical short interest in markets where both are observed) or an empirical argument that volatility captures constraints better than short interest.

---

### 4. Suggestions

**Address the endogenous benchmark.**  
Replace the KOSPI market model with an international benchmark (MSCI World ex-Korea, or a portfolio of Korean ADRs traded in New York) that is unaffected by the domestic ban. Alternatively, use a difference-in-differences design comparing Korean stocks to Taiwanese or Japanese competitors in the same sector, which would absorb global sectoral shocks while providing a clean counterfactual. If the cross-sectional pattern persists with an exogenous benchmark, the results will be credible; if it disappears, the current findings reflect benchmark contamination.

**Transparently justify the sample selection.**  
Report exactly why 2,431 stocks were excluded. If the constraint is Yahoo Finance data availability, acknowledge this limits generalizability to large-caps and discuss how this affects the welfare conclusions (retail investors disproportionately trade smaller KOSDAQ names). Consider a Heckman selection correction or at least demonstrate balance on observables between the 69 sample stocks and the full universe. Plot the distribution of CARs to show whether the results are driven by 1–2 extreme outliers (e.g., battery/EV names like Ecopro BM mentioned in the manifest).

**Validate the treatment intensity proxy or use an alternative design.**  
If short interest is truly unavailable, use pre-ban turnover or Amihud illiquidity (attempted in Table 5 but underspecified) as alternative proxies, and test for heterogeneous effects using actual sector-level short-interest data from the 2008–2009 Korean ban period as a predictor. Better yet, abandon the continuous treatment and use a sharp design: compare stocks above/below the median volatility (or the top quartile where short constraints bind) and present raw returns without the endogenous market adjustment.

**Formalize the symmetry test.**  
The correlation of $-0.28$ between imposition-day and removal-day CARs is suggestive but informal. Test the symmetry of coefficients directly: estimate $\text{CAR}_{i} = \alpha + \beta_1 \sigma_i \cdot \text{Imposition}_t + \beta_2 \sigma_i \cdot \text{Removal}_t + \varepsilon_{it}$ and test $H_0: \beta_1 = -\beta_2$. This pools the events, increases power, and formalizes the "built-in replication" claim.

**Temper welfare claims without micro data.**  
The "retail protection paradox" is compelling but speculative without observing retail flows. The manifest proposed using KRX investor-type data to calculate $(\text{retail net purchases}) \times (\text{correction})$. If KRX data remains inaccessible, reframe the conclusion as "potential welfare costs" rather than established harms, or calibrate using aggregate retail ownership data from the Korea Financial Investment Association.

**Small-sample inference.**  
With $N=69$, standard heteroskedasticity-robust SEs rely on asymptotic approximations. Report bootstrap standard errors (treating the cross-section as the sampling unit) and consider randomization inference (permuting treatment assignment across stocks) to verify the $p$-values.

**Variance ratio interpretation.**  
Table 4 shows post-ban inefficiency rising ($|VR(5)-1
