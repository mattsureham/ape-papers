# V1 Empirics Check — openai/gpt-5.4 (Variant C)

**Model:** openai/gpt-5.4
**Variant:** C
**Date:** 2026-03-14T11:25:12.361844

---

## 1. **Idea Fidelity**

Yes, the paper broadly pursues the original idea in the manifest. It uses ZIP-level Zillow ZHVI, focuses on the Missouri–Illinois discontinuity in St. Louis after *Dobbs*, and adds Kansas City as a replication border. The core research question—whether the loss of reproductive rights is capitalized into nearby housing values—is preserved.

That said, two elements of the original design are only partially implemented. First, the manifest emphasized a *geographic diff-in-disc local to the border*; the paper instead leans heavily on panel DiD specifications over the full MSA with distance-by-post controls, which is not the same object and is visibly contaminated by broader metro-specific trends. Second, the manifest proposed secondary outcomes (rents, migration flows) to help interpret any null; those are absent, leaving the mechanism discussion speculative. In short, the paper follows the idea, but the execution drifts from a clean border design toward a less convincing statewide-side comparison within a metro.

## 2. **Summary**

This paper studies whether Missouri’s immediate abortion ban after *Dobbs* was capitalized into home prices relative to neighboring Illinois at the St. Louis border. Using monthly ZIP-level Zillow data and a difference-in-discontinuities framework, the paper finds no robust negative price effect near the border; the narrow-band estimates are near zero and imprecise, while wider-band estimates turn weakly positive and appear driven by differential trends. The headline contribution is therefore a border-level null: no clear evidence of local housing-market capitalization of reproductive rights in this setting.

## 3. **Essential Points**

1. **The design does not yet cleanly identify a border discontinuity.**  
   The central problem is that your “preferred” specification is not actually the local border design that motivates the paper. In Table 1, the full-sample estimate remains positive and changes with bandwidth in a way that strongly suggests residual spatial trend contamination. The fact that the sign flips from negative at 10 km to positive by 20–30 km is exactly what should make you distrust the full-sample linear-control specification, not prefer it. If the design is truly about capitalization at the border, the paper should be anchored on local specifications with transparent bandwidth choice, local polynomial control on each side, and figures showing the change in appreciation against distance to the border. Right now the paper’s strongest empirical fact is not “precisely estimated nulls,” but “results are highly specification- and bandwidth-sensitive.”

2. **The standard errors are likely too optimistic for the level of geographic aggregation and serial correlation in ZHVI.**  
   ZIP-clustered SEs are not obviously appropriate here. Treatment varies at the state-by-post level, outcomes are highly persistent and spatially correlated, and the effective number of independent border comparisons is much smaller than the number of ZIPs. With monthly smoothed Zillow data, serial correlation is substantial, and with a single treated border segment, spatial correlation is also first order. At minimum, you need to show robustness to Conley-style spatial SEs, two-way clustering (ZIP and month), and aggregation to the ZIP-level pre/post change or event-time change. My prior is that the reported significance at 5–10 percent in the broader-band estimates will weaken materially.

3. **The paper overstates the precision and economic meaning of the null.**  
   The abstract says the nulls are “precisely estimated” and “rule out meaningful Tiebout capitalization.” That is too strong. Your 10 km estimate of -3.1 percent with SE 4.5 percent rules out only very large effects; it does not rule out economically relevant effects in the 2–5 percent range. In housing markets, even a 2–3 percent capitalization effect can be meaningful. More importantly, the paper never pins down an ex ante economically meaningful minimum effect size based on plausible migration or willingness-to-pay magnitudes. Without that, the conclusion should be more modest: you do not detect a stable border effect in this setting over a 30-month horizon.

## 4. **Suggestions**

The paper is asking an interesting question, and the null could be publishable if the empirical design is sharpened and the claims are disciplined. My suggestions are mostly about tightening the identification and reframing the contribution.

First, **re-center the paper around a genuinely local border analysis**. I would strongly encourage you to move away from treating the full-MSA panel with a linear distance-by-post interaction as the main specification. That approach effectively extrapolates from suburban and exurban Missouri/Illinois differences far from the river, which is exactly where unrelated housing dynamics are likely strongest. For a paper framed as spatial capitalization at a border, the main table should report local estimates within prespecified windows—say 10, 15, and 20 km—with separate linear trends on each side and a clear explanation of how the bandwidth was chosen. The cross-sectional “change from pre to post” RDD may actually be closer to the right estimand than the current panel FE setup; if so, elevate it and show the raw binned scatter plots.

Second, **show the identifying variation visually**. This paper badly needs figures. At minimum:
- a map of ZIP centroids and the border;
- mean log ZHVI by side over time for ZIPs within 10–15 km;
- an event-study plot for narrow-border ZIPs only;
- a binned scatter of the pre/post change in log ZHVI against signed distance to the border with separate fits.  
Right now the reader has to infer from tables that wider bandwidths are contaminated. A figure would make that immediately clear and greatly improve credibility.

Third, **treat the pre-trend problem as central, not secondary**. Your own event-study description suggests Missouri and Illinois were already on different appreciation paths. That is not a nuisance; it is the main threat. A fake-treatment test in January 2021 helps, but not enough. You should estimate and report border-specific pre-trends using only 2020–May 2022, especially in narrow windows. If the Missouri side was already converging/diverging near the border before *Dobbs*, then the post-period interpretation is inherently limited. One useful specification would be a trend-break model allowing side-specific linear trends pre-*Dobbs* and testing for a change in slope/intercept after June 2022.

Fourth, **be more careful about what ZHVI measures**. Zillow’s ZIP-level series are smoothed and model-based, not transaction prices. That does not invalidate the exercise, but it matters a lot for timing and power. Smoothed indices will attenuate short-run breaks and induce serial correlation. You should say this explicitly, and ideally supplement with transaction-based measures if feasible (e.g., FHFA HPI at finer geography, county assessor transactions, CoreLogic, Redfin median sale price if accessible). If not, then the interpretation should be “no detectable response in Zillow’s smoothed valuation measure,” which is weaker than “no capitalization.”

Fifth, **the magnitudes deserve more economic calibration**. Is a 3 percent border effect plausible? Maybe, but the paper gives no framework. A simple back-of-the-envelope would help: if abortion access changes expected household utility by X dollars annually for the subset of households who value it strongly, what capitalization would one expect under standard discounting? Alternatively, benchmark against known capitalization effects of school attendance boundaries, environmental disamenities, or crime changes. My own instinct is that a large immediate border effect in owner-occupied housing is unlikely, especially given cross-river clinic access, fixed moving costs, and mortgage-rate conditions in 2022–2024. That makes the null plausible—but you should articulate why.

Sixth, **the Kansas City replication is not yet an apples-to-apples replication**. Kansas’s protection was reinforced by the August 2022 referendum, not instantaneously on June 24, and the political/institutional timing differs. Moreover, Kansas City’s local housing dynamics differed sharply from St. Louis during this period. So the sign reversal is suggestive but not dispositive. I would present KC as an external comparison, not as a clean replication test whose opposite sign “confirms” the St. Louis estimate is spurious. If anything, the cross-city heterogeneity suggests caution in making broad claims.

Seventh, **the paper should incorporate at least one margin that could move before owner-occupied home values do**. The manifest proposed rents and migration, and that was wise. If abortion policy matters for residential sorting, rental markets should adjust faster than owner-occupied housing, particularly for younger and more mobile households. A null in both ZHVI and ZORI near the border would be much more convincing. Likewise, even coarse ACS or USPS migration evidence would help distinguish “no one moved” from “some people moved, but not enough to affect prices.”

Eighth, **address composition and comparability of ZIPs near the river more seriously**. The Missouri and Illinois sides of the St. Louis border are not symmetric. The Illinois side includes older industrial communities and different school/tax jurisdictions; the Missouri side includes very heterogeneous neighborhoods from the city to affluent county suburbs. ZIP centroids are also coarse geography for a river border. You should report balance and comparability for the narrow-band sample: baseline house values, demographics, density, commute patterns, and maybe pre-2020 growth rates by distance bins. If narrow-band ZIPs are still very different, that weakens the RDD intuition and makes a local trends approach more important.

Ninth, **rethink the rhetoric of “Tiebout”**. Tiebout sorting is a strong conceptual frame, but the setting here may be one where the relevant amenity is accessible across the border, so the prediction of sharp local capitalization is not obvious. The paper is strongest if it says: “In a dense cross-border metro with easy access to services on the other side, we find no evidence of short-run border capitalization.” That is a useful result. The stronger claim that reproductive rights are “neither a local nor border-adjacent amenity in housing markets” goes beyond the evidence.

Tenth, **clean up some internal inconsistencies and overstatements**. The abstract emphasizes a 10 km estimate; the main text calls the full-sample linear-control model the preferred specification. These cannot both be true. Likewise, “precisely estimated nulls” is inconsistent with a 4.5 percentage point SE in the narrowest window. The summary-statistics paragraph says average distance is “30–40 km,” while the table reports 22.4 and 30.7. These are small issues, but they matter in a paper resting on design credibility.

Finally, if you keep the paper in AER: Insights style, **the contribution should be sharpened to one clean take-away**: despite an unusually sharp legal discontinuity, there is no robust short-run evidence of housing-price capitalization at the St. Louis border. That is interesting. But for it to land, the paper must stop leaning on broad-band panel estimates, use more conservative inference, and state clearly what effect sizes are and are not ruled out. As written, the result is potentially valuable, but the econometric execution is not yet tight enough to support the paper’s strongest claims.
