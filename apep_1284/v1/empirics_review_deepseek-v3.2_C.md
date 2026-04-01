# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant C)

**Model:** deepseek/deepseek-v3.2
**Variant:** C
**Date:** 2026-04-01T23:41:00.211913

---

Here is my review as a seasoned econometrician.

### 1. Idea Fidelity
The paper faithfully executes the core research agenda outlined in the original manifest. It uses the BLM lottery leases (case type 3112xx) as the source of exogenous variation, aggregates them to the county-level "lottery share" measure, and links this to long-run county economic outcomes from BEA REIS data across multiple Western states. The research question—whether the speculator-induced delay in extraction affects long-run local economies—is addressed directly.

However, the paper deviates from one key element of the proposed identification strategy. The manifest specifically mentioned a **"Shift-share with oil price cycles"** design. This suggested an intention to leverage time-varying oil price shocks interacted with the cross-sectional lottery share, which could have provided more dynamic and potentially powerful identification of timing effects. The implemented design—a static county fixed effect model with a simple post-1990 indicator—is simpler but may fail to capture the nuanced, cyclical "boom vs. bust" timing mechanism that was central to the original idea's novelty. This is a significant simplification of the proposed empirical strategy.

### 2. Summary
This paper leverages the random allocation of federal oil and gas leases via Bureau of Land Management lotteries to test whether exogenous variation in extraction timing—induced by speculators winning and delaying development—influences long-run county economic outcomes. The main result is a precisely estimated null effect: counties with a higher share of lottery-allocated leases show no statistically or economically significant differences in per capita income or population growth over a fifty-year horizon.

### 3. Essential Points
The authors must address these three critical issues before the paper can be considered for publication.

1.  **The County-Level First Stage is Assumed, Not Demonstrated.** The entire identification strategy rests on the premise that a higher county-level lottery share causes a delay in *aggregate* county-level extraction. The paper cites Brehm (2021) for the parcel-level first stage but provides **no direct evidence** that this relationship scales to the county level. It is plausible that within a county, delayed drilling on lottery leases is perfectly offset by accelerated drilling on non-lottery leases, or that the timing variation is too small relative to county economic size to matter. The authors must present a county-level first stage: regress a measure of county-level drilling activity or timing (e.g., year of first production, cumulative production by decade) on the lottery share. Without this, the instrument's relevance is in serious doubt, and the null result is uninformative.

2.  **Inference is Unreliable with 13 State Clusters.** The paper acknowledges that clustering standard errors at the state level (N=13) raises concerns but proceeds anyway. This is not a minor issue. With so few clusters, cluster-robust standard errors are biased downwards, confidence intervals are invalid, and statistical tests are severely under-powered. The fact that the coefficient becomes marginally significant (p=0.09) with county-level clustering (Column 1, Table 4) highlights this fragility. The authors must implement and report results from methods designed for a small number of clusters, such as:
    *   Wild cluster bootstrap-t procedures (Cameron, Gelbach, & Miller 2008).
    *   Conley-HAC standard errors with spatial correlation kernels.
    *   Randomization inference, permuting the lottery share across counties within states or geographic strata.
    The validity of the paper's primary inference—a precise null—depends entirely on correcting this.

3.  **Potential Confounding from Correlated Geographic Features.** The identifying assumption requires that, conditional on total leasable acreage, the lottery share is "as good as random" across counties. This may not hold. The lottery was triggered when multiple parties filed for the *same* parcel within a 5-day window. The attractiveness of a parcel—and thus the probability of a lottery—likely correlates with its underlying geology and economic potential (e.g., proximity to known fields, accessibility). If counties with more geologically promising or accessible lands had more lotteries, then `LotteryShare_c` is correlated with omitted county features that directly affect long-run growth. The event study's positive (if noisy) pre-trends for income (Table 3) are a red flag for this. The authors must conduct a rigorous balancing test: regress pre-period (e.g., 1960) county characteristics (soil quality, baseline income/population, mining employment, distance to railroads/roads, topographic ruggedness) on the lottery share. A convincing case for exogeneity cannot be based on institutional description alone.

### 4. Suggestions
These recommendations are aimed at strengthening the analysis and interpretation.

**A. Empirical Design & Specification**
*   **Implement the Proposed Shift-Share (Bartik) Design:** Revive the original idea. Interact the time-invariant county lottery share with a time-varying shock, such as national or global oil price changes. This would allow you to estimate a more dynamic effect: do high-lottery-share counties respond differently to oil price booms and busts? The estimating equation would look like:
    `Y_ct = β (LotteryShare_c * OilPriceShock_t) + γ_c + θ_t + ε_ct`
    This better captures the "timing" mechanism and uses more of the time-series variation in your data.
*   **Refine the Treatment Timing:** The use of a single `Post1990` indicator is crude. The "lottery era" ended gradually after FOOGLRA (1987). Consider a continuous treatment measure like the *potential years of delay*, estimated from a parcel-level model à la Brehm (2021), aggregated to the county level. Alternatively, use a more flexible event-study around the *county-specific* mean lease issuance year.
*   **Address Spatial Correlation:** Drilling and economic spillovers do not respect county borders. Use Conley standard errors to account for spatial autocorrelation across neighboring counties, in addition to the small-cluster corrections.
*   **Analyize Heterogeneity:** The null average effect may mask offsetting heterogeneity. Interact the treatment with baseline county features: resource endowment size (as in Appendix Table A1), pre-existing economic structure, or state fiscal rules for resource revenues. Perhaps timing only matters in counties where oil and gas became the dominant sector.

**B. Data & Measurement**
*   **Construct a County-Level Drilling Timeline:** Use data from DrillingInfo/Enverus or the IHS International Well Database to construct a county-year panel of drilling activity (wells spudded, production volume). This is crucial for the first-stage test and for more nuanced outcome analysis (e.g., effects on mining employment specifically).
*   **Improve Geographic Precision:** Acknowledge and, if possible, mitigate the error in assigning PLSS parcels to counties. A sensitivity analysis dropping counties where a significant portion of lease parcels fall near county boundaries would be prudent.
*   **Consider Alternative Outcomes:** The BEA's county-level earnings by industry (available in REIS) would let you test for sectoral reallocation (e.g., Dutch disease effects on manufacturing) even if total income is unchanged.

**C. Interpretation & Context**
*   **Clarify the Scope of the Null:** The title "The Speculator's Irrelevance" is too strong. The paper shows that one specific channel—county-level economic aggregation of speculator-induced drilling delays from 1960-1990 federal leases—does not yield a detectable signal in long-run *county-wide* per capita income. This does not mean speculation is irrelevant for lease-level efficiency, federal revenue, or short-run local dynamics. Frame the contribution more precisely.
*   **Engage with the "Resource Curse" Literature More Directly:** The discussion should more explicitly position the null finding within the theoretical mechanisms. For instance, the result suggests that, in the institutional context of the modern U.S., potential curses related to volatility (Timing Channel) may be mitigated by capital mobility, diversified local economies, or federal/state transfer systems. Contrast this with findings from Allcott & Keniston (2018), who found a curse. What institutional differences might explain the discrepancy?
*   **Strengthen the Policy Discussion:** The conclusion that the lottery "imposed no lasting economic cost on host counties" is a policy-relevant finding, but it should be qualified by the analysis's limitations (aggregation, U.S. context). Also discuss the *distributional* implications: while counties may not be hurt, did the lottery system merely transfer rents from the federal treasury to speculators? This is a different, but important, policy question.

**D. Presentation**
*   **Reorganize Tables:** Table 3 (Event Study) is difficult to parse. Convert it into a coefficient plot (figure) with 95% confidence intervals. This would make the pre-trends and post-period dynamics instantly visible.
*   **Report First-Stage F-Statistics:** If/when you estimate the county-level first stage, report the Kleibergen-Paap F-statistic prominently. In an IV context, a weak instrument would fundamentally change the interpretation of the null.
*   **Appendix on Institutional Details:** A map (figure) showing the spatial distribution of lottery share across Western counties would be invaluable for readers to assess the source of variation and potential spatial correlation.

By addressing the **Essential Points** and incorporating a selection of these **Suggestions**, the authors can transform this paper from an interesting null result into a compelling and credible contribution that clarifies the conditions under which resource extraction timing does—and does not—matter for local development.
