# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant C)

**Model:** moonshotai/kimi-k2.5
**Variant:** C
**Date:** 2026-04-02T14:59:38.432984

---

 **Idea Fidelity**

The paper pursues the core empirical strategy outlined in the manifest—using WWII airfield placement as an instrument for modern airport infrastructure—but departs significantly from the original research question and data specification. The manifest proposed analyzing *air freight access* (using BTS T-100 freight tonnage data) and its effect on *manufacturing export orientation*. Instead, the executed paper shifts to a binary treatment ("medium or large airport" from OurAirports) and studies sectoral employment shares rather than trade orientation. 

This is not a minor reframing; it changes the economic mechanism entirely. The original idea emphasized freight logistics and export competitiveness; the current paper interprets results through a passenger-oriented agglomeration lens ("face-to-face meetings"). The BTS T-100 freight data, flagged as "confirmed" in the feasibility check, does not appear in the analysis despite being central to the identification story (air freight vs. passenger services). Consequently, the paper cannot distinguish whether the estimated effects operate through cargo capacity (as proposed) or passenger connectivity (which drives the service-sector agglomeration mechanism discussed in the interpretation). The manuscript should either utilize the freight data as originally specified or reframe the research question away from freight and the "Cleared for Takeoff" export-orientation premise.

**Summary**

This paper uses the historical placement of 729 WWII Army Air Forces training airfields as an instrument for contemporary airport presence (medium/large classification) to estimate causal effects on county-level employment composition. The central finding is that airport access reduces manufacturing employment shares by 6.7 percentage points while increasing professional services employment, an effect the authors term the "runway reallocation." The first stage is strong ($F = 73$), with WWII airfield presence increasing the probability of modern airport access by 27 percentage points.

**Essential Points**

1.  **Failed Conditional Balance Threatens Exclusion Restriction.** Table 2 reports balance tests showing that conditional on latitude, longitude, and land area, counties with WWII airfields remain vastly more populous and dense (coefficient on log population density: 1.115, SE 0.087). The text claims this represents "substantial improvement," but the magnitude is economically enormous—airfield counties have roughly three times the population density of non-airfield counties even after controls ($e^{1.115} \approx 3.05$). This suggests the geographic controls fail to absorb the military's preference for areas with growth potential (southern/western counties experiencing post-war boom). The instrument likely captures the Sun Belt structural transformation rather than airport-specific infrastructure effects. Without convincingly addressing this imbalance—perhaps through matching or county fixed effects in a panel—the exclusion restriction is untenable.

2.  **Mathematical Inconsistency in Heterogeneity Analysis.** The main 2SLS estimate for manufacturing share is $-0.067$ (Table 3, Panel A). However, when splitting the sample by urban/rural status (Table 4, columns 4–5), urban counties show $-0.040$ and rural counties show $+0.025$. With roughly equal sample sizes ($n_{urban} \approx 1,570$, $n_{rural} \approx 1,569$), these subsample estimates should approximately average to the pooled estimate. They do not: $(-0.040 + 0.025)/2 \approx -0.007$, which is an order of magnitude smaller than $-0.067$ and of opposite sign in rural areas. This discrepancy suggests a specification error, differential first-stage compliance rates not accounted for in the presentation, or an interaction between the instrument and urban status that invalidates the simple decomposition. The authors must reconcile these numbers or correct the analysis.

3.  **Ambiguous Economic Mechanism and Conflated Treatment.** The paper conflates air freight access (the original focus) with general airport presence. The mechanism invoked to explain the manufacturing decline—agglomeration of professional services requiring "face-to-face meetings"—is driven by passenger traffic, not cargo. Yet the introduction cites literature on freight (Feyrer 2009, Donaldson & Hornbeck 2016) and the abstract mentions "air freight capability." The estimated effect could reflect land use competition (airports consuming industrial land), noise regulation pushing manufacturing away, or passenger-driven service agglomeration—theories with opposite policy implications. The manuscript must clarify which mechanism is being tested and demonstrate that the results are specific to freight-capable airports (e.g., using the promised BTS T-100 data) rather than any commercial airport.

**Suggestions**

**Address the Selection Bias.** The current geographic controls (latitude, longitude, quadratics) are insufficient to capture the military's targeting of counties with growth potential. I recommend:

*   **Historical Parallel Trends:** Obtain 1940 Census data on manufacturing employment shares *before* airfield construction. If WWII airfield counties were already on different industrial trajectories, the instrument captures pre-trends rather than airport effects. A 1940 manufacturing share control should be included; if the coefficient on the instrument changes substantially, the exclusion restriction fails.
*   **Matching:** Propensity-score match WWII counties to non-WWII counties on 1940 population, manufacturing density, and wartime agricultural mix (since military sought flat, rural land), then estimate the model on the matched sample. This would bound the effect away from the Sun Belt growth story.

**Clarify the Complier Group and Mechanism.** The LATE interpretation requires knowing who the compliers are. With a 27 percentage point first stage, the compliers are counties that received a WWII airfield and developed a modern airport, but would not have had one otherwise. These are likely specific types of emerging metro areas (e.g., Phoenix, Dallas). 

*   **Intensive Margin:** Use the BTS T-100 freight data promised in the manifest. Test whether results are stronger for airports with high freight tonnage vs. passenger enplanements. If the "manufacturing decline" result is driven by passenger hubs (Atlanta, Denver) rather than freight hubs (Memphis, Louisville), the story is about service-sector agglomeration, not freight access.
*   **Land Use Channel:** Test whether the manufacturing decline is spatially concentrated immediately around the airport (within 5km) versus county-wide. If the effect is county-wide, it supports sectoral reallocation; if localized, it suggests land competition or noise constraints.

**Inference and Robustness.** With only 45 clusters (states), standard errors clustered at the state level may suffer from few-cluster bias. 
*   Report wild cluster bootstrap p-values (Cameron, Gelbach & Miller 2008) or use the FGLS adjustment. The Anderson-Rubin confidence interval is mentioned in the text but not shown in tables; it should be reported alongside the delta-method standard errors.
*   The heterogeneity analysis should explicitly model the interaction (airport × urban) rather than splitting samples, which allows testing whether the coefficient differences are statistically significant (currently unclear).
*   **Falsification Tests:** The instrument should be tested against pre-WWII (1920, 1930) manufacturing shares in a panel specification. If WWII airfield indicators predict *past* manufacturing declines, the instrument captures regional trends, not airport construction.

**Magnitude Check.** A 6.7 percentage point decline in manufacturing share from airport access is large (half a standard deviation). For context, compare this
