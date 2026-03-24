# V1 Empirics Check — x-ai/grok-4.1-fast (Variant C)

**Model:** x-ai/grok-4.1-fast
**Variant:** C
**Date:** 2026-03-14T11:24:37.407251

---

### 1. Idea Fidelity
The paper faithfully executes the original idea manifest. It uses monthly ZIP-level Zillow ZHVI data for the St. Louis MSA (235 ZIPs vs. manifest's 223; minor discrepancy likely due to data availability), implements the geographic difference-in-discontinuities design with signed distance to the MO-IL border as the running variable, applies a 30km bandwidth (and narrower), and pools with Kansas City (202 ZIPs) for replication. The research question—testing capitalization of reproductive rights loss into property values via Tiebout sorting—is unchanged, as are the policy timing (overnight Dobbs trigger), outcome, and novelty emphasis (spatial RDD vs. state-level DiD). No key elements are missed; execution exceeds the manifest by adding robust placebos, bandwidth sensitivity, and leak tests.

### 2. Summary
This paper exploits the overnight activation of Missouri's abortion ban post-Dobbs at the Mississippi River border with abortion-protective Illinois to test for capitalization into ZIP-level home values using a geographic difference-in-discontinuities design. It finds a precise null near the border (e.g., -3.1% at 10km, SE=4.5%), with no evidence of Tiebout sorting, confirmed by bandwidth sensitivity, event studies, placebos, and a sign-reversing Kansas City replication. The results imply reproductive rights do not function as a priced local housing amenity, distinguishing border effects from aggregate state-level responses.

### 3. Essential Points
1. **Preferred specification ambiguity**: The full-sample linear distance×post specification yields a weakly positive 2.9% (SE=1.7%, p=0.086), presented as the "preferred," yet the abstract and narrative emphasize the insignificant narrow-bandwidth nulls (-3.1% at 10km). Authors must designate and justify a single preferred estimate (e.g., 10-15km linear spec) with pre-registration criteria or MSE-optimal bandwidth from rdrobust, as the current ambiguity undermines the "null" claim. Report conventional RDD p-values alongside.

2. **Missing event study visualization**: The event study is described verbally (pre-trends negative, brief post-jump then flat) but lacks a figure, critical for AER: Insights to assess parallel trends and dynamics visually. Include it as Figure 1; without it, readers cannot verify the "no sustained break" claim.

3. **Kansas City replication timing misalignment**: The MO×Post DiD starts post-June 2022 (MO ban), but Kansas protections were reaffirmed only via August 2022 referendum. July-August 2022 includes ~2 months of uncertain KS policy, biasing the estimate. Restrict KC post-period to post-August or use a separate KS×Post interaction; otherwise, the sign reversal lacks credibility as a falsification.

### 4. Suggestions
**Strengths to build on**: The design is clean and transparent—overnight shock eliminates anticipation (bolstered by leak placebo), ZIP/month FEs absorb fixed differences and trends, distance×post flexibly controls spatial heterogeneity, and clustering at ZIP yields precise SEs (plausible given N≈200 ZIPs, T=59; power >80% to detect 5% effects at 15km). Magnitudes are credible: nulls rule out large Tiebout effects (e.g., 5-10% school capitalization benchmarks), consistent with episodic abortion demand vs. daily amenities. Placebos (temporal, spatial shifts) and bandwidth table effectively demonstrate smooth trends over discontinuities. Standardized effect size table is a nice touch for comparability.

**Empirical refinements**:
- **Explicitly implement canonical spatial RDD**: Complement panel with binned scatterplots (Figure 2: pre/post/post-minus-pre binavgs of log ZHVI by distance bins <5km) and rdrobust density/McCrary tests on ZIP centroids (Appendix Figure). Report IK/MSE bandwidths; current cross-sectional RDD mention lacks details/table.
- **Enhance diagnostics**: Add covariate balance tests (e.g., pre/post changes in ACS income, demographics, % female 15-44 by distance bins) to affirm smooth changes at border×Dobbs. Plot distance polynomials pre/post to visualize diff-in-disc.
- **Power calculations**: Appendix table of minimum detectable effects (MDEs) by bandwidth (e.g., 95% power at α=0.05) would quantify precision claims (e.g., rules out >8% at 10km).
- **Secondary outcomes**: Manifest mentions ZORI rents and ACS migration—add them (1-2 tables). Rents test capitalization without migration frictions; migration inflows (% MO-to-IL movers post-Dobbs) tests sorting channel directly. If nulls hold, strengthens "no amenity" story.
- **Heterogeneity**: Interact MO×Post with ZIP % reproductive-age women, poverty, or suburbs (Tiebout strongest for families). Table by MSA subregions (e.g., St. Louis City vs. suburbs).
- **Longer horizon**: Extend to latest Zillow (2025+ if available); discuss slow adjustment (e.g., cite 2-3yr lags in Black 1999 school RDD).

**Presentation and exposition**:
- **Figures essential**: Add 3-4: (1) Event study, (2) binned RD pre/post/Δ, (3) distance×post polynomials, (4) KC parallel event study. AER: Insights thrives on visuals; text-only limits impact.
- **Abstract/title tweak**: Title "No Crossing" is punchy but specify "into Home Values." Abstract's -3.1% (10km) as lead should match a main table row; harmonize with positive full-sample.
- **Summary stats**: Table 1 shows stark MO-IL ZHVI gap ($253k vs. $152k); decompose into city/county levels and plot pre-trends by side to preempt "compositional" concerns.
- **Discussion depth**: Expand mechanisms: Quantify cross-border travel costs (e.g., 20min drive = low amenity loss per Anagol et al. 2024 amenities); contrast with Dench et al. (2025) state effects (e.g., interior MO might capitalize negatively). Policy angle strong—extend to property tax revenue sims.
- **Appendices**: Move bandwidth/placebo tables there if space-constrained; add code repo link (manifest has GitHub).
- **JEL/keywords**: Add H75 (policy capitalization), R11 (regional econ).

Overall, this is publishable in AER: Insights with fixes—strong null with diagnostics, timely Dobbs hook, novel spatial angle. Tighten specs/figs for clarity; effects/SEs already rigorous and plausible. Estimated revisions: 1-2 weeks.
