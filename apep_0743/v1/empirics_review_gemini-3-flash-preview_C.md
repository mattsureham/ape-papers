# V1 Empirics Check — google/gemini-3-flash-preview (Variant C)

**Model:** google/gemini-3-flash-preview
**Variant:** C
**Date:** 2026-03-22T15:24:06.007048

---

This review evaluates the paper "Licensing the Last Rites: Mandatory Funeral Director Laws and Death Care Market Outcomes" through the lens of a seasoned econometrician.

### 1. Idea Fidelity
The paper follows the original idea manifest closely, identifying the 9 "mandatory" states and 41 "family-directed" states correctly. It successfully implements the proposed border-county pair analysis using Census CBP data. However, the paper narrows the temporal scope to 2017–2022 (averaging the data) rather than the 1998–2022 panel suggested in the manifest. While this collapses the time dimension to address noise, it leaves significant longitudinal variation on the table that could have been used to test for the "long-run equilibrium adjustment" mentioned in the discussion.

### 2. Summary
The paper uses a geographic border-discontinuity design to estimate the impact of state laws requiring funeral director involvement in death care. Contrary to the standard theory of occupational licensing as an entry barrier, the author finds no statistically significant or economically large differences in funeral home density, employment, or payroll per worker at the regulatory borders. The study provides a precisely estimated null, suggesting these mandates do not fundamentally alter the market structure of the death care industry.

### 3. Essential Points

*   **The Problem of "Payroll per Employee" as a Price Proxy:** The author uses "payroll per employee" as the closest available proxy for prices (Column 5, Table 2). This is a weak assumption. In the funeral industry, a high "price" for a cremation (e.g., $2,600 vs. $2,100) is likely driven by markup/rents or high fixed costs, not necessarily higher wages for staff. If there are licensing rents, they are likely captured by the *firm owner* (net profit) rather than the marginal employee's W-2 wages. The null result on payroll does not rule out the 24% price premium mentioned in the manifest. Without actual price data (which the manifest suggests is available from cross-sectional sources), the paper cannot dismiss the "regressive tax" hypothesis.
*   **The Missing Outcome: Non-Employer Statistics (NES):** The manifest notes that CBP excludes sole proprietorships. In many rural border counties, funeral homes are small, family-run operations with zero "official" employees. By only using CBP, the author may be missing the very margin where mandates matter most: the small, independent "alternative" providers. Merging with Census Non-Employer Statistics (NES) for NAICS 812210 is critical to ensure the results aren't just an artifact of the data source excluding the most sensitive market entrants.
*   **Power and Interpretation of the Null:** The author notes a Minimum Detectable Effect (MDE) of 0.31 establishments per 10k, which is 43% of the mean. In the context of "AER: Insights" style precision, an MDE of 43% is quite large. If the true effect of a mandate is a 10-15% reduction in firms (typical for licensing), this study is underpowered to find it. The claim that the results "rule out effects of the magnitude documented in the broader licensing literature" is therefore overstating the evidence.

### 4. Suggestions

**Econometric Refinement:**
*   **Move to a Panel Specification:** Instead of averaging 2017–2022, use the full 1998–2022 panel suggested in the manifest. Even without policy changes, a panel allows for state-specific trends and more robust standard errors. It would also allow the author to see if the "Cremation Transition" (Section 2) interacted with the mandates over time—did the gap between mandate and non-mandate states widen as cremation became the norm?
*   **Clustering and Degrees of Freedom:** The paper clusters at the state level. With only 9 treated states and 41 control states, the author effectively has a "small number of clusters" problem on the treatment side. Conduct a Wild Cluster Bootstrap or use randomization inference (permuting the 9 mandate states across the 50 possible states) to ensure the p-values are valid.
*   **Distance Decay:** Instead of a flat 75km bandwidth, include a "distance from border" term (interacted with treatment) or use local linear regression. Market integration is likely much higher for counties that are "touching" than those 74km apart.

**Data and Variables:**
*   **Death Rates as a Denominator:** The author uses "per 10,000 population." However, demand for funerals is driven by *deaths*, not *living* population. While "Percent 65+" is used as a control, a more direct approach would be to use the county-level death rate (from CDC Wonder) as either a control or the denominator for the dependent variable. A "funeral homes per 1,000 deaths" metric is a much cleaner measure of market saturation.
*   **Firm Size Distribution:** Instead of just "mean employees per establishment," look at the distribution. Do mandate states have fewer "small" firms (1-4 employees) and more "large" firms? CBP provides establishment counts by size class (e.g., 1-4, 5-9, 10-19 employees). Mandates likely kill the "mom-and-pop" tiny firms while leaving the mid-sized ones untouched.

**Mechanism and Discussion:**
*   **The "Captive Demand" Argument:** In Section 4.2, the author argues cross-border shopping is rare. This should be tested. If the author finds that funeral home density is *higher* on the non-mandate side of the border compared to the interior of non-mandate states, that would be evidence of "regulatory leakage."
*   **The "Home Funeral" Niche:** The Discussion (Section 6) mentions that home funerals are <5% of the market. This is the "smoking gun" for why the effect is a null. If the treatment only affects 5% of potential customers, we shouldn't expect a 20% change in the number of firms. The author should frame the paper more explicitly as a study of "The Limits of Licensing Impacts" rather than a search for a massive distortion that likely isn't there for the "average" consumer.

**Formatting and Minor Points:**
*   Table 4 (Segment Heterogeneity) shows Iowa-Missouri having a massive negative coefficient (-1.87) that is highly significant. This suggests that in some specific regions, the mandate *does* matter, while in others it doesn't. A map of the border pairs colored by the sign/magnitude of the effect would be very helpful for visualizing the spatial heterogeneity.
*   The payroll figures ($38k) seem plausible for the industry (which relies on mortuary technicians and part-time staff), but as noted, this is a poor proxy for the "monopoly tax" consumers pay. Any effort to find actual consumer price data for these specific border counties (perhaps via a web-scrape of "General Price Lists" or using the FCA 2023 data more granularly) would elevate the paper significantly.
