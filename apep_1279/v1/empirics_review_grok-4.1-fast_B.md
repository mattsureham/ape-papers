# V1 Empirics Check — x-ai/grok-4.1-fast (Variant B)

**Model:** x-ai/grok-4.1-fast
**Variant:** B
**Date:** 2026-04-01T22:55:24.972026

---

### 1. Idea Fidelity

The paper largely pursues the original idea manifest but deviates in key ways that weaken fidelity. The core research question—using the WWI draft to causally identify acceleration of the farm-to-manufacturing transition via linked 1910-1920 MLP census data—remains intact, as do the outcomes (farm exit, occupational income score change, geographic mobility) and supporting heterogeneity analyses (county agricultural dependence as a DDD-like test, plus race). The unprecedented sample scale (4.9M men from the 43.9M panel) and novelty claim hold. However, it demotes the manifest's primary identification (sharp RD at the age-13/14 cutoff in 1910) to a flawed supplementary check, elevating the nativity-based DID to the main strategy without executing the promised full county x age-cohort DDD. The nativity DID was listed as "supporting," not lead, and the title, policy framing (less emphasis on lottery quasi-randomness), and exclusion of too-old controls (manifest focused on ages 14-23 draft-core vs. too-old/too-young) represent material shifts. These changes improve internal validity but sideline the manifest's cleanest quasi-experimental variation, risking a less exogenous estimand.

### 2. Summary

This paper exploits a nativity-based exemption in the 1917 Selective Service Act—native-born men faced the WWI draft while foreign-born non-citizens did not—to estimate via difference-in-differences the causal effect of draft exposure on occupational transitions from farming to manufacturing. Using a 4.9 million men panel linked across 1910-1920 full-count censuses, it finds draft-eligible natives were 1.6 pp more likely to exit farms (13-28% increase) and gained 0.43 SD more in occupational income scores than exempt foreigners, with effects concentrated in high-agriculture counties and among Black men, but no impact on migration. This provides causal evidence that forced military disruption broke agricultural "inertia," accelerating U.S. structural transformation.

### 3. Essential Points

The paper makes a coherent contribution with high-quality data but requires fixes to three critical identification and interpretation issues before acceptance; more than these would warrant rejection.

1. **Parallel trends and control group validity in the nativity DID**: The identifying assumption—that absent the draft, nativity gaps in occupational transitions would evolve similarly across eligible (ages 14-20 in 1910) vs. ineligible (10-13) cohorts—is untested beyond linear age controls and heterogeneity patterns. Foreign-born men differ sharply in pre-treatment observables (e.g., 23% vs. 45% farm residence, higher occ scores; Table 1), suggesting selection, urban sorting, or differential life-cycle trends (e.g., immigrants' networks aiding transitions). Authors must add event-study/event-time plots by nativity x eligibility, balancing tests (e.g., pre-1910 outcomes via 1900 linkages if available), or synthetic controls to validate trends. Without this, effects could reflect nativity-age interactions unrelated to the draft.

2. **Incomplete draft take-up and LATE interpretation**: Only ~11% of registrants (2.8M/24M) were inducted, with lottery-based selection within locals boards and exemptions (e.g., farm deferrals, which hit agriculture hardest). The estimand is an intent-to-treat (ITT) on eligibility/exposure risk, but the paper interprets local average treatment effects (LATE) on occupational outcomes as if representing drafted men's impacts, overstating policy relevance. Provide draft take-up rates by nativity/cohort (using registration data if linkable), bound LATE via monotonicity, or instrument actual service (e.g., via lottery numbers if accessible). Clarify that effects capture risk of disruption, not service per se.

3. **Underdeveloped rationale for downgrading the RD**: The manifest's primary RD (age 13/14 cutoff) is dismissed due to life-cycle confounds and placebo discontinuities, but this is endogenous—the paper's age controls are too sparse (linear only), bandwidths arbitrary, and placebos expected given discrete ages and smooth trends. Fully implement the promised RD as co-primary (e.g., higher-order polynomials, optimal bandwidths via Calonico et al., county FEs) and reconcile discrepancies (RD shows null/opposite signs). If RD remains invalid, explicitly falsify it with pre-trends from 1900-1910 MLP links; otherwise, reliance on DID alone misses the manifest's sharpest variation.

### 4. Suggestions

The paper is well-written, AER:Insights-suitable in length and polish, with strong data leverage from MLP (kudos on full-count linking transparency) and compelling mechanism (inertia break via heterogeneity). Effects are precisely estimated (state-clustered SEs appropriate for 49 clusters), and the null on migration smartly narrows channels. Expand to solidify a genuine causal contribution.

**Data and descriptives**: Report full sample construction flowchart (e.g., % linked by age/nativity; attrition biases?) and baseline balances beyond Table 1 (e.g., county ag share, literacy x nativity). Add Figures: (i) binned scatterplots of outcomes by age separately for natives/foreigners (visualize DID parallel trends); (ii) maps of raw farm-exit gaps by county; (iii) occscore distributions pre/post by group. Link to 1900 census for 2+ pre-periods in DID/event studies, testing anticipation (unlikely but informative). Compute farm-to-manufacturing flows explicitly (mentioned but not tabled; use IND1950 sectors).

**Empirical strategy refinements**: For DID, upgrade to two-way FEs (eligibility cohort x nativity) with age polynomials (quadratic/cubic) or age bins; test flex trends via leads/lags (e.g., 1910-1920 as "post," fake 1900-1910 "pre"). Triple-interact with county ag share for formal DDD (manifest promise), weighting by cohort size. For RD, use rddensity/robustness toolkit (e.g., rdrobust package); report IK/CCT bandwidths and density plots (McCrary p=0.27 is good but visualize). Stack designs via doubly-robust matching or triple-difference fully.

**Heterogeneity and mechanisms**: Triple down on predictions—interact with South/non-South (racial inertia), farm operator vs. laborer (tenancy attachment), literacy (info frictions). Test post-1920 persistence via 1930 links (MLP feasible?) for permanence. Explore channels: append military records (e.g., via NARA linkages) for service confirmation; proxy exposure via county induction rates.

**Interpretation and broader impacts**: Quantify economic magnitude (e.g., aggregate farm labor reallocation: 1.6pp x 10M eligibles ~160k exits). Contrast with WWII draft or Korean War for generalizability. Address welfare: occscore gains imply +X% wages (cite IPUMS score-income mapping); discuss deadweight loss (e.g., combat deaths, though low for WWI draftees). Lit positioning excellent (vs. Angrist, Collins); cite recent drafts work (e.g., Moser on WWI inventors).

**Presentation/polish**: Move robustness to main text (Table 5 feels appendix-y); add standardized effects table earlier (Appendix A great). JELs spot-on; keywords add "conscription, labor reallocation." Online appendix for full specs/code (GitHub link appreciated). Abstract tightens claims (e.g., "permanently accelerated" needs 1930 evidence).

Overall, with essentials addressed, this credibly advances understanding of policy-driven structural change—wars as exogenous "pushes" rivaling pulls like tractors/railroads. Minor tweaks elevate to publishable.
