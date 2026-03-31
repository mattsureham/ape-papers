# V1 Empirics Check — openai/gpt-oss-120b (Variant C)

**Model:** openai/gpt-oss-120b
**Variant:** C
**Date:** 2026-03-31T10:07:51.969768

---

**1. Idea Fidelity**  
The paper follows the manifest’s core idea: it uses Korea’s 2024 mandatory English‑disclosure rule as a staggered natural experiment to assess whether reducing language barriers improves market liquidity and narrows the “Korea discount.” The author implements the three identification strategies suggested (DiD, event‑study, RDD) and draws on the same data sources (Yahoo Finance for daily prices, DART/Open API for firm‑level assets). The only deviation is that the RDD is presented only as a supplemental, under‑powered check rather than a primary identification strategy, which is acceptable given the small number of observations around the KRW 10 trillion cutoff. Overall, the paper stays faithful to the original proposal.

---

**2. Summary**  
This paper exploits the January 2024 mandate that all KOSPI‑listed firms with assets ≥ KRW 10 trillion must file financial statements in English. Using a two‑way fixed‑effects difference‑in‑differences design (with event‑study checks and a placebo test), the author finds that mandatory English disclosure lowers the Amihud illiquidity ratio by about **33 % for financial‑sector firms** (β ≈ ‑0.40, p < 0.001) while having no detectable impact on non‑financial firms. The pooled effect for all treated firms is small and statistically insignificant.

---

**3. Essential Points**  

| # | Issue | Why it matters |
|---|-------|----------------|
| 1 | **Potential confounding from simultaneous reforms** (Value‑Up programme, foreign‑investor registration abolition) | Week fixed effects absorb common shocks, but the large‑firm group (treated) may have responded differently to these reforms than controls. The paper does not provide a convincing falsification that the effect is not driven by differential exposure to the Value‑Up incentives (e.g., higher dividends, buy‑backs) which are more common among banks and insurers. |
| 2 | **Parallel‑trend evidence is weak** | The pre‑trend F‑test rejects the null (p < 0.001) in the pooled sample, driven by two outlier months a year before treatment. Although the author argues the event‑study coefficients are “close to zero” near the policy date, the statistical rejection undermines confidence in the DiD identification. A more thorough examination (e.g., adding firm‑specific linear time trends, or using a synthetic‑control approach for the treated group) is needed. |
| 3 | **Treatment definition and sample selection** | The treated sample is defined purely by a total‑asset cutoff, but the paper restricts the analysis to the **top 300 firms by market cap**. This truncation creates a non‑random control group that may be systematically different (e.g., higher foreign ownership, richer analyst coverage). The resulting imbalance could inflate the sectoral heterogeneity. A robustness check using the full set of KOSPI firms (or a propensity‑score matched sample) would address this. |

If the authors cannot adequately resolve these three points, the paper should be **rejected** in its current form.

---

**4. Suggestions**  

Below are concrete, non‑essential recommendations that would substantially strengthen the manuscript and improve its credibility for an AER‑Insights audience.

---

### A. Strengthen the Identification  

1. **Triple‑Difference (DDD) Implementation**  
   - The manifest proposed a DDD to isolate the language channel from the foreign‑investor registration reform. Although the author mentions week fixed effects, an explicit DDD specification (Treat × Post × High‑Foreign‑Ownership) would test whether firms with pre‑existing foreign ownership (> 5 %) drive the results. If the effect remains only for high‑foreign‑ownership financial firms, the language mechanism becomes far more plausible.  

2. **Firm‑Specific Time Trends**  
   - Adding linear (or flexible) trends interacted with the treatment indicator can absorb any differential trajectory that large firms may have followed owing to the Value‑Up program. Report the coefficient with and without these trends to show robustness.  

3. **Synthetic Control or Matching**  
   - Construct a synthetic control for the treated cohort using a weighted combination of untreated firms that matches on pre‑treatment liquidity, size, sector composition, and foreign ownership. This will give a visual “gap” plot and provide an additional credibility check beyond the DiD.  

4. **Alternative Lag Structures**  
   - The policy effect may be gradual as firms prepare English filings. Estimate distributed‑lag models (e.g., up to 12 months) to capture the timing more precisely and to test whether the effect is concentrated in the months when the first English annual reports become publicly available.  

5. **Placebo at the Firm‑Level**  
   - Randomly assign the treatment status to a subset of control firms (keeping the same share of financials) and re‑estimate the DiD many times. The resulting distribution of placebo β’s should centre around zero; this Monte‑Carlo test further validates the inference.  

---

### B. Refine the Outcome Measures  

1. **Bid‑Ask Spread Proxy**  
   - The paper mentions a spread proxy but never reports results. Even a simple approximation (e.g., (Ask‑Bid)/Mid) from the Korean market’s Level‑2 data (if available) would provide a second liquidity dimension that is less sensitive to volume spikes.  

2. **Foreign Ownership Trading**  
   - If weekly data on foreign net inflows are available from the Korea Exchange, include them as an outcome. Demonstrating that foreign purchases rise for treated financial firms would directly link the language change to the hypothesised channel.  

3. **Liquidity‑Adjusted Returns**  
   - Compute a “liquidity‑adjusted” abnormal return (e.g., using the Pastor‑Stambaugh liquidity factor) to see whether the reduction in illiquidity translates into higher market valuation for the treated group.  

4. **Robustness to Alternative Illiquidity Measures**  
   - Report results using other standard illiquidity metrics (e.g., Roll’s implied spread, Kyle’s λ, or the zero‑return proportion). Consistency across measures would reinforce the finding.  

---

### C. Address Sample Construction  

1. **Full KOSPI Sample**  
   - Re‑run the baseline DiD on the entire universe of KOSPI‑listed firms (≈ 950) rather than the top‑300. This eliminates potential selection bias created by the market‑cap cutoff and allows the control group to contain smaller firms that may be more “foreign‑investor‑friendly.”  

2. **Propensity‑Score Matching**  
   - Match each treated firm to one or more control firms on pre‑treatment size, leverage, profitability, and foreign ownership. Present balance tables to demonstrate that the matched sample eliminates systematic differences.  

3. **Sector‑Specific Controls**  
   - Since the key finding is sectoral, include sector‑by‑time fixed effects (e.g., industry × week) to soak up common shocks that hit financials differently from other industries (e.g., macro‑financial policy changes).  

---

### D. Clarify Economic Significance  

1. **Translate Log‑Effects to Percent Changes**  
   - While the paper already notes that β = ‑0.397 ≈ 33 % reduction, do the same for the pooled estimate (β = ‑0.107) to show that the point estimate corresponds to roughly a **10 %** liquidity improvement—a magnitude that, albeit insignificant, is still economically relevant.  

2. **Link to Valuation**  
   - Using the liquidity‑valuation elasticity estimates from the literature (e.g., Fang & Peress, 2009), quantify the potential increase in firm value for financial firms (e.g., a 33 % illiquidity drop may imply a 2–3 % market‑cap uplift). This will make the “Korea discount” implication more concrete.  

3. **Policy Counterfactual**  
   - Provide a short calibration: if all KOSPI firms eventually adopt English filings (Phase 2 and 3), what aggregate reduction in the market‑wide illiquidity index is expected? This helps readers assess the broader welfare impact.  

---

### E. Presentation & Technical Details  

1. **Figure‑Based Event Study**  
   - Include a graph of the monthly event‑study coefficients with 95 % confidence bands for both the pooled sample and the financial sub‑sample. Visual inspection of pre‑trend dynamics is more persuasive than a table of coefficients.  

2. **Standard Errors**  
   - Consider two-way clustering (by firm and by week) or Driscoll‑Kraay standard errors to guard against serial correlation in the panel. Report whether the main results survive these alternative SE calculations.  

3. **Regression Discontinuity**  
   - Even though the RDD lacks power, the author could improve it by employing a local linear (or quadratic) estimator with optimal bandwidth selection (e.g., Imbens‑Kalyanaraman). Present the RD plot to show the raw relationship between assets and illiquidity around the KRW 10 trillion cut‑off.  

4. **Data Availability**  
   - Provide a reproducibility appendix with Python/R scripts that pull Yahoo Finance data via the `yfinance` package and query the DART Open API. Transparency is especially important for an AER‑Insights “short‑paper” format.  

5. **Minor Corrections**  
   - The baseline sample size in Table 1 (57,707 firm‑weeks) does not match the numbers reported in Table 2 (57,604 observations); reconcile this discrepancy.  
   - Clarify the scaling of the Amihud ratio (the current factor × 10⁻⁹ may confuse readers).  
   - In the abstract, replace “directionally consistent but imprecise” with a more precise statement about the statistical significance levels.  

---

### F. Extensions & Future Work  

1. **Phase 2 Follow‑Up**  
   - As Phase 2 (May 2026) rolls out, the design becomes a classic staggered‑adoption DiD with multiple treatment dates. The authors could plan a subsequent paper that exploits the additional variation to estimate dynamic treatment effects across firm size and sector.  

2. **Cross‑Country Comparison**  
   - A brief discussion or appendix comparing Korea’s mandate to voluntary English filing regimes in Japan or Taiwan would place the contribution in a broader context and suggest external validity.  

3. **Investor‑Level Data**  
   - If feasible, obtain data on foreign fund holdings (e.g., from the Korean Financial Supervisory Service) to directly test whether foreign participation rises for treated financial firms.  

---

**In sum**, the paper tackles a novel policy shock and uncovers an intriguing sector‑specific liquidity improvement. However, the current identification is weakened by (i) possible confounding from concurrent reforms, (ii) a rejected pre‑trend test, and (iii) a control group that is not fully comparable to the treated firms. Addressing these three essential points—preferably by adding a DDD specification, firm‑specific trends, and a more balanced sample—should be the priority before the manuscript is suitable for publication. The additional suggestions above will help the authors polish the analysis, clarify the economic magnitude, and meet the high standards expected of an AER‑Insights contribution.
