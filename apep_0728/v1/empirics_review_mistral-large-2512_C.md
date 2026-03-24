# V1 Empirics Check — mistralai/mistral-large-2512 (Variant C)

**Model:** mistralai/mistral-large-2512
**Variant:** C
**Date:** 2026-03-20T19:44:39.418187

---

### 1. Idea Fidelity

The paper closely follows the original manifest’s identification strategy, data source, and research question. Key elements are preserved:
- **Identification**: The triple-difference (DDD) design using (1) Pierce-Schott NTR gaps, (2) county-level pre-PNTR Black manufacturing share, and (3) post-2000 timing is implemented as proposed. The exclusion restriction (predetermined NTR gaps and racial composition) is appropriately emphasized.
- **Data**: The QWI race×industry panel is used as specified, with the same geographic and temporal coverage (1995–2010, 2,457 counties). The smoke test’s confirmation of a 18.6% pre-PNTR Black-White earnings gap is replicated.
- **Novelty**: The paper delivers on the promise of being the first to apply the QWI racial panel to a trade shock, and the Asian worker placebo test is a clever addition to isolate racial sorting mechanisms.

**Minor deviations**:
- The manifest proposed 4 industry groups, but the paper uses 21 three-digit NAICS industries. This is an improvement (finer granularity) but should be justified in terms of statistical power and clustering.
- The manifest’s "feasibility grade: READY" is borne out, but the paper could better acknowledge potential limitations of the QWI data (e.g., lack of individual-level mobility, discussed in Section 5).

---

### 2. Summary

This paper exploits the 2000 U.S.-China PNTR shock to estimate its racially heterogeneous effects on manufacturing earnings. Using a triple-difference design with predetermined NTR gaps and county-level racial employment composition, the authors find that PNTR widened the Black-White earnings gap by 8.4 log points per unit of NTR gap exposure. The effect is driven by extensive-margin job losses (reduced hiring and increased separations) for Black workers in high-exposure industries, consistent with occupational segregation channels. Robustness checks (placebo tests, clustering, trimming) and an event study support the causal interpretation.

---

### 3. Essential Points

#### **1. Magnitude and Plausibility**
The headline result—a **8.4 log-point widening per unit NTR gap**—is economically large but plausible given the context:
- For the median high-exposure industry (NTR gap = 0.30), this implies a **2.5% widening** of the racial gap. For apparel (NTR gap = 0.52), it’s **4.4%** (≈$140/month). These magnitudes align with Autor et al. (2013)’s estimates of trade-induced wage declines (≈4–8% in exposed regions) and are consistent with Black workers bearing a disproportionate share of the adjustment costs.
- **Concern**: The coefficient in Column (3) of Table 2 is **-1.254**, but the manifest’s "smoke test" suggested a baseline gap of 18.6%. A 1.25 log-point effect per unit NTR gap (≈125% of the baseline gap for a 1-unit exposure) seems implausibly large. The authors should clarify whether the coefficient is scaled correctly (e.g., is the NTR gap in decimal or percentage points? The manifest describes it as "52 percentage points" for apparel, but the paper treats it as 0.52). If the gap is in decimals, the effect is reasonable; if in percentage points, it’s too large.

#### **2. Standard Errors and Clustering**
- **State-level clustering (42 clusters)** is likely too conservative. The Pierce-Schott NTR gap varies at the *industry* level, and the key variation is cross-industry. With only 21 industries, clustering at the state level may understate true uncertainty. The authors should:
  - Report **wild bootstrap p-values** (Cameron et al., 2008) or **conventional t-statistics** (with 21 industry clusters) to assess sensitivity.
  - Justify why state-level clustering is preferred over industry-level or two-way clustering (which they do in Table 5, but the baseline uses state clustering).
- The **two-way clustered SE (0.18)** in Table 5 is still significant at 1%, but this should be the baseline specification given the design.

#### **3. Parallel Trends and Event Study**
- The event study (Table 3) shows **flat pre-trends** (1995–2000), which is reassuring. However:
  - The coefficients are **all negative and significant** pre-PNTR, suggesting a persistent Black-White gap that is *already* correlated with NTR gaps. This could reflect omitted variables (e.g., industry-specific skill demands or regional wage premia) that are not fully absorbed by the fixed effects. The authors should:
    - Test for **differential pre-trends** by interacting NTR gap × Black with linear time trends.
    - Show **graphical event studies** (with confidence intervals) to better visualize the break in 2001.
  - The post-PNTR divergence is **monotonic but modest** (0.17 log points over 8 years). This is plausible but should be contextualized: is this a large effect relative to other drivers of racial earnings gaps (e.g., automation, minimum wages)?

---

### 4. Suggestions

#### **A. Clarify the Scaling of Key Variables**
- **NTR gap**: The manifest describes it as "52 percentage points" (apparel), but the paper treats it as 0.52. This is critical for interpreting magnitudes. If the gap is in decimals, the effect is reasonable; if in percentage points, the coefficient should be divided by 100. The authors should:
  - Explicitly state the units in the text and tables (e.g., "NTR gap (0–1 scale)").
  - Recalculate the implied effects for key industries (e.g., apparel) using the correct scaling.
- **Earnings gap**: The paper reports log earnings gaps, but the abstract and introduction emphasize dollar amounts ($140/month). These should be reconciled (e.g., "a 4.4 log-point widening ≈ $140/month at pre-PNTR earnings levels").

#### **B. Strengthen the Mechanism Discussion**
- The **extensive margin** (employment/hires/separations) is compelling, but the paper could better distinguish between:
  - **Plant closures**: Are Black workers more likely to be in plants that shut down? The QWI lacks plant identifiers, but the authors could proxy for plant-level exposure (e.g., using county-industry employment concentration).
  - **Occupational sorting within industries**: Black workers may be overrepresented in production roles (e.g., sewing machine operators in apparel) that are more vulnerable to trade. The authors could:
    - Use **CPS data** to show Black-White occupational sorting within industries pre-PNTR.
    - Test whether the effect is larger in industries with greater Black-White occupational segregation.
- **Reallocation frictions**: The paper mentions spatial mismatch but doesn’t test it. The authors could:
  - Interact the DDD with **county-level measures of labor market tightness** (e.g., unemployment rates) to see if Black workers in slack markets fare worse.
  - Use **QWI flows** to test whether displaced Black workers are less likely to transition to other manufacturing industries.

#### **C. Address Potential Confounding**
- **Other shocks in the 2000s**: The post-PNTR period (2001–2010) includes the 2001 recession, China’s WTO accession (2001), and the Great Recession (2008). The authors should:
  - Show that the effect is **not driven by the 2001 recession** (e.g., exclude 2001–2002).
  - Test whether the effect **accelerates after 2001** (to rule out pre-existing trends).
- **Industry-specific trends**: The industry×quarter fixed effects absorb industry-specific shocks, but the authors should:
  - Test whether the effect is robust to **county×industry linear trends**.
  - Show that the results hold when **excluding industries with extreme NTR gaps** (e.g., apparel, textiles).

#### **D. Improve Robustness Checks**
- **Placebo tests**:
  - The **Asian worker placebo** is excellent but could be strengthened by:
    - Showing the **distribution of Asian workers across industries** (to confirm they’re in low-NTR-gap sectors).
    - Testing whether the effect for Asian workers is **statistically different** from the Black effect (e.g., using a stacked regression).
  - Add a **Hispanic worker placebo** (Hispanic workers were also concentrated in manufacturing but in different subsectors, e.g., food processing).
- **Alternative specifications**:
  - **Weighted regressions**: The QWI provides employment weights; the authors should show results weighted by county-industry-race employment to account for heteroskedasticity.
  - **Dynamic DDD**: Estimate the effect year-by-year (as in the event study) but with leads/lags to test for anticipation effects.

#### **E. Contextualize the Results**
- **Comparison to other shocks**: The paper could compare the PNTR effect to other drivers of racial earnings gaps, such as:
  - **Automation**: Autor et al. (2020) find that automation widened racial gaps in manufacturing. How does the PNTR effect compare?
  - **Minimum wages**: Derenoncourt and Montialoux (2021) show that minimum wage hikes compressed racial gaps. Did PNTR offset these gains?
- **Policy implications**:
  - The conclusion suggests "targeted adjustment assistance." The authors could:
    - Quantify the **number of Black workers affected** (e.g., "X% of Black manufacturing workers were in industries with NTR gaps > 0.2").
    - Discuss **existing programs** (e.g., Trade Adjustment Assistance) and whether they were racially equitable.

#### **F. Data and Reproducibility**
- **QWI limitations**: The paper acknowledges the lack of individual-level data but could:
  - Discuss whether the **compositional shifts** (e.g., Black workers exiting high-NTR industries) are driven by low-wage or high-wage workers (e.g., using quantile regressions if the QWI provides earnings distributions).
  - Note that the QWI **excludes self-employment and federal workers**, which may bias the sample if Black workers are overrepresented in these categories.
- **Replication materials**:
  - The paper should include a **replication package** with:
    - Cleaned QWI data (or scripts to access it).
    - Code for all tables/figures.
    - A **README** explaining how to replicate the results.

#### **G. Writing and Presentation**
- **Abstract**: The abstract is clear but could better highlight the **mechanism** (extensive margin) and **novelty** (first use of QWI racial panel).
- **Figures**: The paper would benefit from:
  - A **map** of NTR gaps by industry and Black employment shares by county.
  - A **graphical event study** (as mentioned above).
  - A **bar chart** comparing the DDD coefficients for Black, Asian, and Hispanic workers.
- **Tables**:
  - Table 2: The lower-order terms in Columns (1)–(2) are confusing. The authors should either:
    - Drop them (since the saturated specification in Column 3 is preferred), or
    - Explain why they’re included (e.g., to show the "main effects" of PNTR on earnings).
  - Table 5: The "Trim NTR" row should clarify what "trim" means (e.g., "exclude top/bottom quartile of NTR gaps").

---

### Final Assessment
This is a **strong paper** with a compelling identification strategy, novel data, and economically meaningful results. The core finding—that PNTR widened the Black-White earnings gap via occupational segregation—is plausible and well-supported by the event study and mechanism tests. However, the **magnitude of the effect** needs clarification (scaling of NTR gaps), and the **standard errors** should be more conservatively clustered. With these adjustments, the paper would be suitable for a top field journal (e.g., *AER: Insights*, *JPE*, or *REStud*).

**Recommendation**: Revise and resubmit, addressing the essential points above. The suggestions are constructive and would strengthen the paper’s credibility and impact.
