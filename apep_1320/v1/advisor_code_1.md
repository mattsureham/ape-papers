# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-04-02T14:56:32.515343

---

**Idea Fidelity**

The paper tracks the manifested idea closely. It exploits WWII Army Air Forces training airfields as an instrument for contemporary airport access to study sectoral employment outcomes, employs the stated data sources (Wikipedia-derived airfields, OurAirports, CBP, ACS), reports the first-stage strength, and centers the question on air freight’s role in shaping manufacturing versus service orientation. All major components of the identification strategy and empirical focus described in the manifest appear in the submitted manuscript; there are no notable departures.

---

**Summary**

The paper uses the wartime siting of 729 WWII airfields as an instrument for today’s airport presence (medium or large airports) to investigate the causal effect of airport access on county-level employment composition in 2019. A strong first stage ($F=73$) links airfields to modern airports, and the IV estimates indicate that airports reduce the manufacturing employment share by about 6.7 percentage points while expanding professional services, with the manufacturing decline concentrated in urban counties. The findings are pitched as evidence that air infrastructure reallocates economic activity toward tradeable services rather than supporting local goods production.

---

**Essential Points**

1. **Exclusion Restriction Needs Sharper Defense.** The exclusion restriction—that WWII airfield siting affects current manufacturing only through the airport channel—remains under-justified. Counties that hosted training airfields likely benefitted from sustained federal investment, labor inflows, or complementary wartime infrastructure (rail, electricity, ordnance facilities) that could have persistent effects on post-war industrial structure independent of civilian airports. The current discussion is suggestive but thin. The authors should attempt to isolate the airport effect from broader WWII investment by controlling for (or instrumenting with) historical military presence (e.g., number of non-airfield bases, War Production Board plants, or personnel counts) or by showing that other provincial infrastructure indicators are unaffected by the instrument conditional on airport access. Without such exercises, the negative manufacturing effect may reflect broader wartime legacies rather than airport-induced reallocation.

2. **Interpretation of the IV Estimate versus OLS Requires Caution.** The manuscript interprets the IV estimate as the causal effect of airports, yet the OLS and reduced-form patterns suggest that counties historically more manufacturing-intensive are less likely to be compliers. In the absence of a detailed complier analysis, it is hard to understand which types of counties are driving the negative effect and whether this reflects airport-induced displacement or pre-existing differences. Providing a characterization of compliers—e.g., via treatment effect heterogeneity on observable pre-instrument outcomes—would help assess external validity. Without it, policy claims that “airports do not attract factories” risk being overgeneralized.

3. **Potential Correlation with Pre-Existing Economic Structure.** The dataset is cross-sectional for 2019, and there is no direct control for pre-war or mid-century manufacturing shares or growth rates. If WWII airfields were placed in counties already on different development paths (e.g., rural agricultural areas versus emerging service hubs), the IV estimate could capture those long-run trajectories. The balance table shows sizable differences in population and density even after controls, and no historical outcomes are included to demonstrate the instrument is orthogonal to past sectoral composition. Including lagged manufacturing shares (e.g., from 1960 Census) or other historical covariates would provide confidence that the IV is not simply picking up long-run pre-existing trends.

Given these issues, as currently presented, the paper’s claims rest on an exclusion restriction that is not yet fully credible, making it difficult to accept the causal interpretation without substantial additional evidence.

---

**Suggestions**

- **Strengthen the Argument for the Exclusion Restriction.** Consider adding historical controls that capture other wartime exposures—such as proximity to other military installations, presence of defense contractors, or temporary troop encampments—and show that the instrument is uncorrelated with these once geography and airport presence are accounted for. If such data are unavailable, the authors could exploit variation in which WWII airfields were converted to civilian airports. For example, comparing counties with airfields that remained military-only or were decommissioned to those that were successfully converted may help isolate the airport-specific channel.

- **Characterize Compliers and Mechanisms.** The IV estimate identifies a LATE for counties whose airports depend on WWII airfields. Providing observable traits of these compliers (population density, industrial composition, proximity to metropolitan areas) would help readers judge generalizability. Additionally, the “reallocation” narrative would benefit from more detailed mechanism checks—e.g., examining whether the services gains are concentrated in sectors heavily reliant on business travel (finance, professional services) or in establishments with high labor mobility. If possible, linking airports to air freight volumes (BTS T-100) at the county level or to measures of business travel intensity would directly connect the infrastructure channel to the economic outcomes.

- **Address Measurement and Data Concerns.** The airfield data rely on Wikipedia categories, but only 62% of airfields have geocoded coordinates. The paper should discuss how missing coordinates might bias county classification. For instance, are airfields without coordinates systematically in certain regions or county types, which could alter the instrument’s coverage? Sensitivity checks using subsets of airfields with high-confidence geocoding or using alternative historical sources (e.g., digitized military maps) would strengthen the credibility of the instrument. Similarly, the treatment variable—having a medium/large airport—could be enriched by using continuous measures (number of runways, passenger enplanements, freight tonnage) to see if results hold for airport size/intensity.

- **Consider Temporal Dynamics.** A cross-sectional specification cannot distinguish whether airports prevented manufacturing from developing or displaced it once established, as the Discussion notes. If panel data are not available for all counties, the authors might use older CBP data (e.g., 2000 or 2010) to see whether counties that acquired airports earlier experienced declines or slower growth in manufacturing around the time airports opened. Event-study-style graphics (even if imperfect) could at least show whether manufacturing shares in WWII-airfield counties were trending differently before and after significant airport upgrades, lending support to the causal channel.

- **Expand Placebo and Robustness Checks.** Beyond retail employment, other locally-traded sectors (e.g., construction, healthcare) should be shown to be unaffected to reinforce the argument that the effect operates through tradeable industries. The authors might also interact the instrument with secondary geographic features (e.g., distance to coast) to verify that the effect is not driven by coastal counties that benefitted from multiple wartime investments. Reporting results with different sets of controls (e.g., county fixed effects for region-year or including state-specific linear time trends) would reassure readers that the findings are not sensitive to specification choices.

- **Clarify the Role of Air Freight.** The title and motivating discussion emphasize air freight, but the empirical analysis focuses on airport access without directly measuring freight activity. If possible, incorporate BTS T-100 airport freight tonnage (even cross-sectionally) to show that instrumented airport access actually increases freight volumes, strengthening the narrative that air freight availability is reshaping sectoral employment. Alternatively, if freight data are unavailable or noisy at the county level, explicitly acknowledge this limitation and temper claims about air freight, focusing instead on airport connectivity more broadly.

- **Refine the Policy Discussion.** The conclusion currently states that airports “do not attract factories,” which may overstate what the LATE supports. Emphasize that the evidence pertains to counties whose airport access hinged on WWII airfield legacies, primarily in southern and western counties, and that results may differ for large metropolitan airports developed through other channels. Likewise, discuss whether the reallocation toward services is welfare improving or merely a compositional shift; referencing labor productivity or wage data, if available, could provide insight into whether the services expansion compensates for manufacturing losses.

By addressing these points, the paper would provide a more convincing causal story linking historical airfield legacies to contemporary sectoral composition and better inform infrastructure policy debates.
