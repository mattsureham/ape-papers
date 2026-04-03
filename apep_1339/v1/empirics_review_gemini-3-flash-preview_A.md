# V1 Empirics Check — google/gemini-3-flash-preview (Variant A)

**Model:** google/gemini-3-flash-preview
**Variant:** A
**Date:** 2026-04-03T11:18:28.744003

---

**Referee Review**

**Title:** Obsolete by Design: Dam Vintage, Climate Gaps, and Downstream Flood Risk
**Journal:** AER: Insights (Format)

---

### 1. Idea Fidelity
The paper pursues the core thematic elements of the original idea—the engineering "fossilization" of dam spillways designed under TP-40 standards—but it makes a significant pivot in the empirical execution. The manifest proposed a **continuous IV strategy** leveraging the "Design Gap Ratio" (Atlas14/TP40) at the dam level to instrument for downstream exposure. Instead, the paper adopts a **state-year panel with cross-sectional identification** using "Pre-1970 Dam Share" as the primary treatment. 

While the paper constructs a "Design Gap Index" in Table 2, it does not use the instrumental variables approach suggested in the manifest. More importantly, the paper moves from a highly granular proposed analysis (census-tract NFIP claims, USGS streamflow, dam-specific gap) to an **aggregate state-level analysis**. This shift results in a "well-powered null" rather than the identification of a specific engineering-driven risk channel.

### 2. Summary
The paper investigates whether the "design gap" in U.S. dams—the difference between 1961-era precipitation standards (TP-40) used at construction and modern observed precipitation (Atlas 14)—predicts downstream flood disasters. Using a state-year panel (2000–2024), the author finds that a state’s share of pre-1970 dams is either uncorrelated or negatively correlated with FEMA flood declarations and NFIP claims. The author concludes that "compensating mitigation" (e.g., levees, zoning) has neutralized the physical obsolescence of the dam stock, except for a specific risk cohort of 1930s-era dams.

### 3. Essential Points

1.  **Ecological Fallacy and Aggregation Bias:** The shift from dam-level/tract-level analysis (proposed in the manifest) to state-level analysis (in the paper) is a major step backward in terms of identification. Flood risk and dam failures are hyper-local phenomena. By aggregating to the state level, the "treatment" (share of old dams) is likely swamped by state-level heterogeneity in topography, climate, and general flood-control spending. The negative coefficient in the Poisson model likely reflects a "Lurking Variable": older, more established states (e.g., in the Northeast/Midwest) have more old dams but also have more mature, non-dam flood infrastructure compared to rapidly developing, flood-prone Southern states. **The paper must return to a more granular unit of analysis (county or dam-catchment level) to provide a credible test.**

2.  **Identification of the "Design Gap":** The paper uses a "Precipitation Ratio" derived from annual mean precipitation (nClimDiv). However, dam spillways are designed for **extreme hourly or daily events** (e.g., 100-year, 24-hour storms), not annual means. Annual averages can stay constant while the frequency of tail events increases dramatically. Using state-level annual mean ratios to proxy for a local engineering design gap is conceptually flawed and likely attenuates any real effect to zero.

3.  **Invalid Placebo Reasoning:** The "Post-1990" placebo test (Table 3, Col 1) returns a weakly positive coefficient ($p=0.10$). The author interprets this as evidence that the null on old dams is robust. On the contrary, if new dams (built to modern standards) are associated with *more* flood declarations than old dams, it suggests the model is picking up **development and population growth**. New dams are built where people are moving (the Sunbelt), which is also where new flood declarations are most frequent due to increasing exposure. This strongly suggests that the "Pre-1970 Share" is simply proxying for "slow-growth/low-exposure geography," rendering the cross-sectional comparison uninformative for the engineering question.

---

### 4. Suggestions

**A. Restore the Granular Identification Strategy**
The original manifest’s idea of using the dam-specific Atlas14/TP40 ratio is far superior to the state-level share. 
*   **Action:** Re-run the analysis at the USGS HUC-8 or County level. For each county, calculate the drainage-area-weighted "design gap" of all upstream dams. 
*   **Action:** Use the USGS streamflow data mentioned in the manifest. A credible test would ask: "Conditional on a precipitation event of $X$ magnitude, is the peak discharge downstream higher for dams with a larger TP-40/Atlas14 gap?" This removes the political economy of FEMA declarations.

**B. Refine the Treatment Variable**
*   **Extreme Precipitation:** Replace the nClimDiv annual mean ratio with the actual "Design Gap" suggested in the manifest. Use the NOAA Atlas 14 raster minus the TP-40 raster at the dam’s specific coordinates for the 100-year/24-hour event. This is the actual parameter used by hydraulic engineers and provides the "engineering fossil" variation you seek.
*   **Spillway Type:** If possible, distinguish between dams with "ungated" (fixed) spillways and "gated" spillways. Gated spillways allow for operational adaptation; ungated spillways are purely a function of 1960s concrete dimensions and are the truest "fossils."

**C. Address the "Compensating Mitigation" Hypothesis**
The paper currently uses this as a "residual explanation" for the null. 
*   **Action:** Test this directly. Does the (negative) relationship between old dams and floods disappear in states with low flood-control spending or weak zoning? You can use the ASFPM (Association of State Floodplain Managers) state programs mapping to categorize "mitigation intensity."
*   **Action:** Control for the "hazard-days" or "precip-days" above a certain threshold at the local level to ensure the null isn't just because it hasn't rained hard enough near the old dams lately.

**D. The 1930s Result**
The 1930s specific risk is the most interesting finding in the current draft. 
*   **Action:** Expand on this. Were 1930s dams built under different federal programs (WPA/PWA) with lower spillway requirements than the 1960s PL-566 Small Watershed dams? This could be a fascinating sub-paper on "Emergency Infrastructure as a Long-Run Risk."

**E. Clarify the Outcome Variables**
FEMA declarations are highly political and subject to "declaration creep" over time. 
*   **Action:** Use "NFIP Paid Losses" (dollars per capita) rather than "Claims Count" to capture severity. 
*   **Action:** Include a control for the total insured value (TIV) in the floodplain. A state might have 0 claims simply because it has 0 NFIP policies, not because the dams are safe.

**F. Minor Presentation Issues**
*   The title mentions "Climate-Shifted Precipitation," but the empirical model uses a time-invariant state share. A difference-in-differences approach using the *timing* of Atlas 14 release (which informs local risk perception) as a shock might be more in line with AER: Insights' preference for sharp identification.
*   In Table 1, the SD of "Flood Declaration Count" is 11.81 vs. a mean of 3.09. This extreme overdispersion suggests the OLS (LPM) in Table 2 is inefficient; the Poisson or Negative Binomial results should be the primary focus.
