# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant C)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** C
**Date:** 2026-04-02T14:57:01.262737

---

# Review: The Runway Reallocation

## 1. Idea Fidelity

The paper deviates significantly from the Original Idea Manifest. The manifest proposed estimating the effect of airfield legacies on **manufacturing export orientation** using **BTS T-100 freight data** combined with Census CBP. The submitted paper instead estimates the effect on **manufacturing employment share** using only Census CBP and OurAirports data. The BTS T-100 freight data specified in the manifest is absent. Consequently, the research question has shifted from "Does air freight access enable export-oriented manufacturing?" to "Does airport access reallocate labor from manufacturing to services?" While the latter is a valid question, it represents a fundamental pivot away from the proposed identification of freight-specific mechanisms. The instrument (WWII airfields) remains consistent, but the outcome and data infrastructure do not match the approved plan.

## 2. Summary

This paper exploits the quasi-random siting of WWII Army Air Forces training fields as an instrument for contemporary airport access to estimate the causal effect of air infrastructure on local employment composition. The author finds that counties with instrumented airport access exhibit a 6.7 percentage point lower manufacturing employment share and a corresponding rise in professional services. The results suggest that air infrastructure facilitates service-sector agglomeration rather than goods production, challenging the common policy assumption that airports drive industrial manufacturing growth.

## 3. Essential Points

1.  **Exclusion Restriction Threat (General Military Presence):** The identifying assumption relies on WWII airfield siting being unrelated to post-war economic potential conditional on geography. However, WWII airfields were not isolated infrastructure; they brought federal construction spending, permanent military personnel, and improved road/rail connections during the war. These factors could independently attract or repel manufacturing post-war (e.g., via labor market tightening or infrastructure spillovers) regardless of whether the facility became a civilian airport. The current controls (latitude, longitude, land area) may not fully absorb these non-airport military shocks.
2.  **Data Provenance and Instrument Construction:** The instrument is constructed using Wikipedia lists and the MediaWiki API. For a causal inference paper relying on historical variation, this source is insufficiently rigorous. Wikipedia entries are subject to editor selection bias (notable airfields are more likely to be documented than obscure strips) and potential geocoding errors. Reliance on this source undermines the credibility of the "exogenous" variation, as the digitization process itself may correlate with county characteristics (e.g., wealthier counties have better historical preservation societies contributing to Wikipedia).
3.  **Magnitude and Interpretation of Effects:** The estimated effect—a 6.7 percentage point reduction in manufacturing share (roughly 45% of the mean)—is economically massive. While the Anderson-Rubin interval rules out zero, the magnitude invites skepticism. It implies that for complier counties, the presence of an airport nearly halves the manufacturing sector's relative footprint. The paper attributes this to service-sector agglomeration, but does not rule out alternative channels such as land price inflation (airports raise nearby land values, pricing out factories) or labor competition (services bid up wages). Without distinguishing these mechanisms, the "runway reallocation" narrative remains speculative.

## 4. Suggestions

To strengthen the paper for publication, I recommend substantial revisions focusing on data verification, robustness checks, and mechanistic clarity. The following suggestions address the econometric vulnerabilities and the deviation from the original research design.

**Reconcile with Original Design or Justify Pivot**
The absence of BTS T-100 freight data is a major departure from the manifest. If freight data was inaccessible or proved unusable (e.g., too much missingness at the county level), this limitation must be explicitly acknowledged in the introduction. However, if feasible, you should attempt to incorporate air freight tonnage as a secondary outcome. Even if the primary result is about employment shares, showing that WWII airfields *do* increase freight volume would validate the first-stage channel (Airport → Freight Capacity). Currently, the paper argues airports help services via *passenger* travel, which contradicts the manifest's focus on *freight*. Clarifying whether the instrument affects freight, passenger, or general connectivity is crucial for interpreting the mechanism.

**Strengthen the Instrument Data**
Replace or validate the Wikipedia-based airfield list with authoritative archival sources. The manifest cited Maurer (1983) and USAF Historical Research Agency records; these should be the primary source. Wikipedia should only be used for supplementary geocoding if the official records lack coordinates.
*   **Action:** Cross-reference your 729 airfields with Maurer's *Air Force Combat Units of WWII* or the *Army Air Forces Stations* database.
*   **Action:** Report the match rate between your list and authoritative archives. If Wikipedia misses obscure training strips that were not converted to airports, your instrument may suffer from selection bias (capturing only "successful" or "notable" fields).
*   **Action:** Conduct a placebo test using airfields that were *not* converted to civilian airports. If these fields also correlate with economic outcomes, it suggests the effect is driven by general military presence rather than airport conversion.

**Address the Exclusion Restriction More Rigorously**
The concern that WWII military presence had direct economic effects beyond the airport channel is the primary threat to validity.
*   **Control for War Spending:** Include controls for total WWII military spending per capita in the county, if available (e.g., from Wallis 2014 or similar datasets on wartime contracts). This helps isolate the *airport* effect from the *federal spending* effect.
*   **Control for Other Bases:** Include indicators for non-airfield military bases (Army camps, Navy stations) in the county. If the effect persists after controlling for general military footprint, the exclusion restriction is more credible.
*   **Pre-Trend Proxies:** While you cannot observe 1940 manufacturing shares easily at the county level for all sectors, you can use 1950 Census data as a "post-war pre-trend" control. If the airport effect emerges only after the jet age (1960s+), it supports the airport mechanism. If the divergence exists immediately in 1950, it suggests the military base itself drove the change.

**Refine Inference and Standard Errors**
You cluster standard errors by state (50 clusters). With 3,000 observations, this is generally acceptable, but given the high leverage of the instrument (F=73) and the cross-sectional design, inference should be robust.
*   **Wild Bootstrap:** Consider reporting wild bootstrap p-values for the 2SLS estimates, which perform better with a small number of clusters (Cameron, Gelbach, and Miller 2008).
*   **Spatial Correlation:** Economic geography variables often exhibit spatial correlation beyond state borders. Consider Conley standard errors or clustering by economic areas (BEA) rather than political state boundaries to ensure significance isn't driven by regional spatial autocorrelation.

**Deepen the Mechanism Analysis**
The claim that airports "restructure local economies toward tradeable services" is compelling but needs more direct evidence.
*   **Land Prices:** Test if airport access increases county-level land values or commercial rents (using Zillow or commercial real estate data). If airports raise land costs, manufacturing (which is land-intensive) may be crowded out by services (which are land-light but value-dense). This would support a "cost channel" rather than just a "productivity channel."
*   **Labor Market:** Test for effects on average wages or college attainment. If services bid up skilled labor wages, manufacturing may become uncompetitive. Adding these intermediate outcomes would flesh out the "reallocation" story.
*   **Airport Size Heterogeneity:** You treat all medium/large airports equally. A regional jet hub may have different effects than a cargo hub (e.g., Memphis, Louisville). If possible, interact the instrument with airport size or cargo volume to see if the manufacturing effect is driven by specific types of air service.

**Clarify the LATE**
The compliers are counties that got an airport *because* of the WWII field. These are disproportionately in the South and West.
*   **External Validity:** Explicitly discuss whether these results generalize to the Northeast or Midwest, where airports were often built via different channels (e.g., pre-war municipal investment). The policy implication ("airports don't attract factories") might hold for Sun Belt expansion but not for Rust Belt revitalization.
*   **Sample Split:** You split by urban/rural density. Consider splitting by region (South/West vs. Northeast/Midwest) to see if the negative manufacturing effect is driven entirely by the Sun Belt compliers.

**Writing and Presentation**
*   **Title Alignment:** The current title ("Sectoral Composition of Local Employment") is accurate. Ensure the abstract clearly states that freight data was not used, to avoid misleading readers expecting trade analysis.
*   **Table 1 Balance:** The balance table shows significant differences in population. While you control for this, consider propensity score matching as a robustness check to ensure the IV isn't just picking up urbanization trends correlated with WWII siting.
*   **Magnitude Context:** In the interpretation section, compare the -6.7pp effect to other infrastructure shocks (e.g., the Interstate Highway System). This helps readers gauge whether the effect is unusually large for a transport infrastructure intervention.

By addressing the data provenance, tightening the exclusion restriction arguments, and clarifying the mechanism beyond simple sectoral shifts, this paper can make a robust contribution to the economic geography literature. The core intuition—that air transport favors services over goods—is sound, but the empirical execution needs to match the rigor of the historical instrument it employs.
