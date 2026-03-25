# V1 Empirics Check — google/gemini-3-flash-preview (Variant B)

**Model:** google/gemini-3-flash-preview
**Variant:** B
**Date:** 2026-03-25T10:54:37.952681

---

In my capacity as a referee for *AER: Insights*, I provide the following assessment of "The Phantom Race: Municipal Tax Competition Without Consequences in Switzerland."

### 1. Idea Fidelity
The paper follows the original idea manifest closely, specifically the core research question (testing Zodrow-Mieszkowski 1986) and the specific data source (Zurich *Jahresrechnungen*). It adopts the suggested identification strategy (Panel FE with year FEs) and explores the proposed mechanisms (STATENT data for firm growth). 

However, the paper significantly truncates the proposed sample period. While the manifest suggested data from 1995–2024 (approx. 4,000 observations), the paper analyzes 2012–2017 (680–819 observations). This reduction constitutes a major deviation that weakens the power of the study and limits the "event study" robustness check which was a key part of the original design. The paper also replaces the "instrument with neighbor rates" and "long-run panel" aspects with a more limited descriptive analysis of the 0.995 correlation between corporate and natural-person rates.

### 2. Summary
The paper uses within-municipality variation in tax multipliers (*Steuerfuss*) in Canton Zurich to test whether tax competition leads to the under-provision of local public goods. Exploiting a high-frequency panel of municipal financial accounts, the author finds a precise null effect: changes in corporate tax rates do not lead to changes in spending on education, social welfare, or infrastructure. The study concludes that "tax competition" in this context is a political signal rather than an economic driver of service erosion, as neither firms nor budgets respond to rate changes.

### 3. Essential Points
**1. Identification and Anticipation (Reverse Causality):**
The paper acknowledges but does not sufficiently solve the "reverse causality" problem. In the Swiss context, tax rates are often adjusted precisely because a municipality anticipates a change in its fiscal position (e.g., a planned large infrastructure project or an expected windfall from a new corporate resident). If a municipality cuts rates because it expects a huge influx of revenue, the null effect on spending isn't "no erosion"—it's an endogenous offset. The author must implement the instrument mentioned in the manifest (neighbor rates) or use a lead-lag structure to show that rate changes are not preceded by spending trends.

**2. The "Lockstep" Problem and Interpretation:**
The 0.995 correlation between corporate and natural-person rates is a critical finding that undermines the paper's ability to test the *corporate* tax competition of Zodrow-Mieszkowski. If the rates move together, the "treatment" is a general change in the size of local government, not a shift in the tax burden on mobile capital specifically. The paper frames this as a "phantom race," but it might simply be that the variation used does not isolate the mechanism the paper claims to test. The author needs to find cases of "decoupling" between the two rates or better justify why the general tax shift is an appropriate proxy for capital tax competition.

**3. Sample Period and Attrition:**
The drop from 1995–2024 to 2012–2017 is concerning and unexplained. The HRM accounting standards in Zurich changed in 2019 (HRM2), but data should be available back to at least 2000 under the previous standard. A 6-year panel is very short for detecting shifts in public goods like education or infrastructure, which have high "stickiness." The author must expand the time series to provide a credible test of long-run fiscal erosion.

### 4. Suggestions
*   **Expansion of Data:** The *Jahresrechnungen* data for Zurich is available via the *Statistisches Amt* API or CSV downloads back to the late 1990s. Even if categories change slightly, "Total Expenditure" and "Education" are usually bridgeable. Expanding the time frame is the single most important step for publication in a top-tier journal.
*   **Fiscal Equalization:** The Swiss *Finanzausgleich* (fiscal equalization) is a massive "mechanical" stabilizer. If a municipality loses revenue due to a tax cut, the canton often fills part of the gap in 2–3 years. The author should explicitly control for received equalization transfers to see if the "null" on spending is simply caused by the cantonal safety net.
*   **Lags:** Public spending is set in budgets (*Voranschlag*) before the *Steuerfuss* is finalized for the year. The author should regress $Y_{t+1}$ on $Tax_t$ to account for the budgetary cycle.
*   **The "Why" of Tax Changes:** Why do Zurich municipalities change their rates if it doesn't attract firms or change spending? The author mentions political signaling. A useful addition would be to check if tax changes correlate with local election cycles or changes in the party composition of the *Gemeinderat*.
*   **Dynamic Effects (Event Study):** With a longer panel, the author should provide an event study plot. Figure 1 should show the trajectory of spending 5 years before and 5 years after a $>5$pp tax cut. A flat line there would be much more convincing than the current Table 2.
*   **Zurich City vs. Others:** Zurich and Winterthur are the "vessels" for much of the spending. The author notes results are robust to excluding Zurich, but a more interesting test is whether the results hold for "tax haven" municipalities (e.g., Kilchberg, Rüschlikon) vs. high-tax rural ones.
*   **Mechanism (Reserves):** Swiss municipalities hold significant financial reserves (*Eigenkapital*). The paper should test if tax cuts lead to a depletion of reserves—this would explain why spending remains stable in the short run even if revenue falls.
*   **Institutional Detail:** Clarify whether the *Steuerfuss* change requires a mandatory referendum in Zurich (which it often does for large changes). This adds to the "stickiness" argument and helps justify the use of lagged variables.
