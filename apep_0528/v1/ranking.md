# Research Idea Ranking

**Generated:** 2026-03-05T16:53:33.215632
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| Do Administrative Borders Tax Electricit... | PURSUE (78) | PURSUE (88) | — |
| Building Energy Mandates and Fossil Fuel... | PURSUE (70) | PURSUE (72) | — |
| TRAF 2020 Tax Reform and Switzerland’s C... | CONSIDER (58) | — | — |
| Water Royalties and Hydroelectric Electr... | CONSIDER (52) | SKIP (48) | — |
| Cantonal Organic Farming Subsidies and A... | SKIP (45) | SKIP (38) | — |
| TRAF 2020 Tax Reform and Switzerland's C... | — | SKIP (28) | — |
| Idea 1: Do Administrative Borders Tax El... | — | — | PURSUE (84) |
| Idea 2: Building Energy Mandates and Fos... | — | — | PURSUE (74) |
| Idea 3: Water Royalties and Hydroelectri... | — | — | CONSIDER (64) |
| Idea 4: Cantonal Organic Farming Subsidi... | — | — | SKIP (57) |
| Idea 5: TRAF 2020 Tax Reform and Switzer... | — | — | SKIP (51) |

---

## GPT-5.2

**Tokens:** 6765

### Rankings

**#1: Do Administrative Borders Tax Electricity? A Multi-Border Spatial RDD of Swiss Cantonal Energy Policy**
- **Score: 78/100**
- **Strengths:** Exceptional measurement: universe municipal tariff data with *component decomposition* lets you test the mechanism (policy → “Abgaben” component) rather than just an ATE. Multi-border replication + staggered adoption (spatial RDD × event-study) + a strong placebo (uniform Netzzuschlag) is unusually referee-proof for a border design.
- **Concerns:** Cantonal borders may proxy deep differences in utility ownership, distribution network cost, procurement strategy, hydrology/topography, or political preferences that also move tariffs; even with event-time, policy adoption could coincide with other cantonal changes. You’ll need to show (i) stable pre-trends in the *same border pair*, (ii) no discontinuities in non-policy components, and (iii) robustness to excluding borders where DSOs/utility structures differ sharply.
- **Novelty Assessment:** **High.** There is border work in energy and Swiss institutional papers, but “cantonal energy-law reforms → tariff component pass-through” using ElCom decomposition + multi-cutoff spatial/event design feels genuinely under-mined.
- **Top-Journal Potential:** **Medium–High.** The “administrative borders as a tax wedge” framing is legible, the data scale is compelling, and the built-in placebo/mechanism decomposition fits the editorial pattern of a clean causal chain (policy → charges → retail price dispersion). To hit top-5, you likely need a welfare/counterfactual angle (e.g., implied incidence, dispersion attributable to policy vs fundamentals).
- **Identification Concerns:** Border endogeneity (borders coincide with geography and utility institutions) and bundled treatment (energy funds + mandates + promotion) are the main threats; the design is strongest if you can isolate the tariff components that mechanically correspond to the law and show no movement elsewhere.
- **Recommendation:** **PURSUE (conditional on: convincing border-pair pre-trend/event-study evidence; showing effects concentrate in the “Abgaben”/policy-linked components; documenting utility/DSO comparability or controlling for DSO fixed effects where possible)**

---

**#2: Building Energy Mandates and Fossil Fuel Commodity Substitution — MuKEn 2014 at Swiss Cantonal Borders**
- **Score: 70/100**
- **Strengths:** First-order policy question with a potentially surprising mechanism: regulation at *replacement* margins inducing oil/gas → electricity substitution (heat pumps), with climate/energy-security implications. The “rejected by three cantons” feature creates unusually clean conceptual counterfactuals for Europe-style building codes.
- **Concerns:** The biggest risk is *measurement/first-stage*: municipal GWR is often a stock measure, while MuKEn bites at the replacement event—effects may be slow and diluted without replacement-event data. Only a few key borders limits internal replication, and electricity tariffs are a weak proxy for electrification (you’d ideally want electricity consumption or heat-pump installations).
- **Novelty Assessment:** **Medium–High.** There’s a large literature on building codes/retrofits and energy demand, but much less that cleanly identifies *mandated* fuel switching at borders with administrative building registers; the Swiss “reject vs adopt” discontinuity is relatively distinctive.
- **Top-Journal Potential:** **Medium.** A top field journal (AEJ: Policy / JEEM / JPubE) is plausible if you can (i) show a sharp first-stage on heating system transitions, (ii) quantify substitution magnitudes, and (iii) connect to grid/peak-demand externalities. Top-5 is harder unless you can generalize to a broader regulation-vs-price mechanism with welfare.
- **Identification Concerns:** Border sorting and differential enforcement/inspection intensity; concurrent cantonal subsidies for heat pumps/renovations could be bundled with MuKEn adoption. The placebo split (new construction vs replacements) is good, but only if the data truly separates those margins.
- **Recommendation:** **PURSUE (conditional on: obtaining comparable heating-system data for *all* border cantons in the design; measuring replacement/installation flows or tight proxies; documenting concurrent subsidy regimes to separate “mandate” from “money”)**

---

**#3: TRAF 2020 Tax Reform and Switzerland’s Commodity Trading Sector**
- **Score: 58/100**
- **Strengths:** Very high policy stakes and international interest: Switzerland’s commodity trading cluster is globally important, and TRAF is a major regime break with heterogeneous cantonal rate responses. If you can credibly measure reallocation, the paper is inherently “newsworthy.”
- **Concerns:** High risk of the classic “cool policy, impossible measurement” outcome: the treated sector is small, concentrated, and hard to identify cleanly in STATENT without fine industry codes (and even then, traders may sit in services categories). Border RDD power will be thin, and firm location choices are highly endogenous around borders (anticipation, within-canton moves, office vs HQ reshuffling).
- **Novelty Assessment:** **Medium.** Corporate tax competition and firm mobility are heavily studied; what’s newer is “TRAF × commodity trading specifically,” but that novelty may not compensate for thin identification/measurement.
- **Top-Journal Potential:** **Medium (conceptually), Low (as currently measurable).** Editors like first-order tax reforms, but they also punish underpowered designs and ambiguous sector measurement. This becomes top-journal only if you can assemble near-universe, high-precision firm identifiers for commodity traders and show sharp spatial responses.
- **Identification Concerns:** Treatment is not just “rate cut” (it’s abolition of preferential status nationwide + cantonal package responses). Border comparisons may conflate pre-existing agglomeration forces (Geneva vs neighbors) with the reform.
- **Recommendation:** **CONSIDER (only if you can: reliably identify commodity trading firms—e.g., registry-based firm list matched to admin microdata; pre-specify MDE/power; and show the margin is cross-canton relocation rather than reclassification/accounting changes)**

---

**#4: Water Royalties and Hydroelectric Electricity Pricing in Swiss Mountain Cantons**
- **Score: 52/100**
- **Strengths:** Clear incidence question (do resource rents get passed through to consumers?) and a large, salient revenue source in mountain regions; pairing tariffs with municipal tax rates could speak to fiscal federalism.
- **Concerns:** The proposed identifying variation looks weak: many cantons sit at the federal maximum, and the 2015 cap increase is largely common across space—so “spatial DiD” may have little differential shock. Conceptually, Wasserzins is paid by generators but retail tariffs often reflect procurement on broader markets plus grid costs, so local pass-through may be limited mechanically, not just empirically.
- **Novelty Assessment:** **Medium–Low.** Wasserzins itself is niche but studied in Swiss energy policy circles; pass-through/market incidence is a standard question, and prior work exists (even if with different data).
- **Top-Journal Potential:** **Low–Medium.** Could land as a solid policy note if you can create real variation (e.g., plant-specific exposure interacted with the 2015 change), but in its current border form it risks reading as “null/ambiguous because no treatment contrast.”
- **Identification Concerns:** Lack of cross-border treatment contrast; border differences in generation mix and grid topology; and weak mapping from generator royalties to municipal retail prices.
- **Recommendation:** **CONSIDER (conditional on: constructing plant-level exposure—installed hydro capacity by municipality/utility—and using an exposure design rather than relying on canton borders)**

---

**#5: Cantonal Organic Farming Subsidies and Agricultural Commodity Production**
- **Score: 45/100**
- **Strengths:** Excellent long-run municipal panel outcomes (1975–2024) and a policy-relevant topic (organic transition, land use, farm structure). Data feasibility on outcomes is strong.
- **Concerns:** Treatment is not sharply defined or easily measured (cantonal “promotion intensity” is multidimensional, time-varying, and hard to code); likely small relative to the dominant federal payments, implying weak first stage and low signal-to-noise. Border RDD is especially fragile here because organic suitability correlates strongly with geography (altitude, slope, soil) which also changes at cantonal borders in Switzerland.
- **Novelty Assessment:** **Low.** Organic adoption/subsidies and agricultural responses are heavily studied internationally; without a sharp, well-measured policy discontinuity, this risks being “another border design on a familiar topic.”
- **Top-Journal Potential:** **Low.** Even with clean execution, it’s hard to make this belief-changing unless you uncover a strong, well-identified substitution mechanism (e.g., organic subsidies causing measurable output mix changes and spillovers) with a clearly exogenous policy shock.
- **Identification Concerns:** Border endogeneity (terrain/climate) + diffuse, bundled policy environment + weak treatment measurement.
- **Recommendation:** **SKIP (unless you can identify a single, sharp cantonal policy change with a known start date/eligibility rule and sizable budget that creates a credible discontinuity)**

---

### Summary

This is a strong batch in terms of *data ambition* and use of Swiss administrative variation, but several ideas lean heavily on border designs where treatment definition and institutional comparability are make-or-break. The clear front-runner is **Idea 1** because it combines (i) huge universe data, (ii) a mechanism-resolving outcome decomposition, and (iii) internal replication + placebo structure that directly targets the main border-design critiques. **Idea 2** is the next best if (and only if) you can secure replacement-margin heating data and avoid relying on tariffs as the main proxy.

---

## Gemini 3.1 Pro

**Tokens:** 8904

Here is the evaluation and ranking of the research proposals, calibrated against the editorial patterns of top economics journals and the specific criteria provided.

### Rankings

**#1: Do Administrative Borders Tax Electricity? A Multi-Border Spatial RDD of Swiss Cantonal Energy Policy**
- **Score**: 88/100
- **Strengths**: Combines universe-scale administrative data with a highly credible multi-cutoff spatial DiD design. The ability to decompose the outcome into exact pricing components provides a mechanical, "opponent-killing" placebo test.
- **Concerns**: Spatial RDDs can be vulnerable to endogenous sorting, though municipal borders are relatively fixed. The magnitude of the cantonal charges might be small relative to wholesale energy cost fluctuations.
- **Novelty Assessment**: Highly novel. While spatial RDDs are common, applying them to staggered policy rollouts across ~50 border pairs to decompose electricity tariffs is unstudied and addresses a major local policy puzzle.
- **Top-Journal Potential**: High. It perfectly matches the editorial preference for "universe admin data paired with a design that yields tight bounds." The built-in placebo (the federal fee) pre-empts alternative stories, and the exact decomposition of the tariff provides a highly legible causal chain.
- **Identification Concerns**: The main threat is that cantons might have adopted energy laws in response to underlying regional energy price trends, though the spatial border design and component decomposition largely mitigate this.
- **Recommendation**: PURSUE

**#2: Building Energy Mandates and Fossil Fuel Commodity Substitution — MuKEn 2014 at Swiss Cantonal Borders**
- **Score**: 72/100
- **Strengths**: Addresses a first-order climate policy question (fossil fuel substitution) using a clean natural experiment created by cantonal rejections of a federal mandate. The placebo test using new construction is theoretically very sound.
- **Concerns**: The design relies on only three specific cantonal borders, making it vulnerable to localized, border-specific confounders. The data feasibility is highly uncertain for the rejecting cantons.
- **Novelty Assessment**: Strong. Estimating the causal effect of building codes on energy substitution via spatial RDD is a fresh approach to a heavily debated energy transition topic.
- **Top-Journal Potential**: Medium. Uncovering a substitution/offset mechanism (oil to electricity via heat pumps) is a high-upside narrative. However, the reliance on only three borders might trigger reviewer concerns about "small context" or endogenous borders if not handled carefully.
- **Identification Concerns**: Endogenous sorting at administrative boundaries is a risk if the three borders proxy for deeper cultural or economic differences that drive both policy rejection and heating choices.
- **Recommendation**: PURSUE (conditional on: verifying municipal-level GWR heating data availability for SO, AG, and BE; confirming sufficient density of heating replacements at the borders)

**#3: Water Royalties and Hydroelectric Electricity Pricing in Swiss Mountain Cantons**
- **Score**: 48/100
- **Strengths**: Targets a highly salient local policy issue (Wasserzins) with excellent, readily available outcome data.
- **Concerns**: The design suffers from a near-fatal lack of variation, as most cantons charge the federal maximum, and the 2015 shock was national.
- **Novelty Assessment**: Moderate. While pass-through is a standard topic, doing it for hydro royalties via spatial RDD is new, though local think tanks have explored the theoretical bounds.
- **Top-Journal Potential**: Low. The lack of cross-sectional variation and reliance on a uniform national time shock will likely result in an underpowered, noisy null. Top journals explicitly punish "null because underpowered" papers.
- **Identification Concerns**: The spatial RDD lacks a sharp treatment bite across borders, and the 2015 spatial DiD is confounded by the fact that the federal maximum increase affected all cantons simultaneously.
- **Recommendation**: SKIP

**#4: Cantonal Organic Farming Subsidies and Agricultural Commodity Production**
- **Score**: 38/100
- **Strengths**: Uses high-quality, long-horizon municipal agricultural data to study an important commodity transition.
- **Concerns**: Cantonal organic subsidies are likely too small relative to the massive federal baseline to induce a detectable behavioral response at the border.
- **Novelty Assessment**: Low to Moderate. Evaluating agricultural subsidies is a crowded field, and this specific cantonal variation is likely too marginal to yield a novel insight.
- **Top-Journal Potential**: Low. This reads exactly like the modal loss: a "technically competent but not exciting" standard RDD that will likely yield an unsurprising null due to a weak first stage.
- **Identification Concerns**: The treatment intensity (cantonal supplement) is dwarfed by the federal baseline, leading to severe underpowering at the cutoff and an inability to detect a clean causal effect.
- **Recommendation**: SKIP

**#5: TRAF 2020 Tax Reform and Switzerland's Commodity Trading Sector**
- **Score**: 28/100
- **Strengths**: Targets a massive, globally significant sector (commodity trading) and a major, highly disruptive tax reform.
- **Concerns**: Commodity trading firms are too few (~500) and too geographically clustered (Geneva, Zug) to provide sufficient statistical power at cantonal borders.
- **Novelty Assessment**: High conceptually, as the spatial reallocation of commodity traders post-TRAF 2020 is unstudied and highly relevant.
- **Top-Journal Potential**: Low. Despite the high stakes, this falls into the fatal flaw category of "thin-tail RDDs." Journals repeatedly reject spatial designs that rely on a handful of treated units at the actual border cutoffs.
- **Identification Concerns**: Severe underpowering at the core cutoff. Firms do not locate randomly at borders, and with N~500 nationally, the number of firms within a valid RDD bandwidth will be close to zero.
- **Recommendation**: SKIP

### Summary

This batch presents a stark contrast between highly credible, data-rich designs and conceptually interesting but empirically doomed ideas. Idea 1 is a standout, offering a rare combination of universe-scale data, a staggered spatial design, and a mechanical placebo that perfectly aligns with top-journal preferences for tight bounds and pre-empted confounders. I strongly recommend pursuing Idea 1 immediately, exploring Idea 2 conditionally based on data availability, and discarding Ideas 3, 4, and 5 due to fatal flaws in statistical power and treatment variation.

---

## Grok 4.1 Fast

**Tokens:** 5999

### Rankings

**#1: Idea 1: Do Administrative Borders Tax Electricity? A Multi-Border Spatial RDD of Swiss Cantonal Energy Policy**
- **Score**: 84/100
- **Strengths**: Exceptional novelty in exploiting cantonal policy borders with ElCom tariff decomposition for a clean mechanism test on energy price drivers; multi-border RDD with staggered timing, event studies, and built-in federal placebo provides robust replication and pre-trends testing across ~50 pairs.
- **Concerns**: Spatial sorting of high-income households near borders could bias if correlated with energy demand; long panel (2011–2026) risks time-varying confounders like national decarbonization trends.
- **Novelty Assessment**: Highly novel—Swiss energy RDDs exist (e.g., Farsi et al. 2025 on language borders), but none combine policy borders, staggered reforms, and tariff components; no direct priors on cantonal charges' pass-through.
- **Top-Journal Potential**: High—this fits "first-order stakes + legible causal channel" (policy → charges → tariffs) with mechanism surprise (borders as hidden taxes) and policy counterfactuals on price variation sources; top-5/AEJ:EP would excite for challenging geographic vs. policy price drivers, akin to crime pass-through winners.
- **Identification Concerns**: Strong overall, but spatial RDDs risk endogenous border sorting (e.g., firm location choices); placebo on federal fee and multi-cutoff replication mitigate, though covariate balance tests needed for demographics/energy costs.
- **Recommendation**: PURSUE (conditional on: confirming no pre-reform discontinuities in charges component; running covariate balance across all ~50 borders)

**#2: Idea 2: Building Energy Mandates and Fossil Fuel Commodity Substitution — MuKEn 2014 at Swiss Cantonal Borders**
- **Score**: 74/100
- **Strengths**: Novel test of commodity substitution (fossil → heat pumps/electricity) in energy transition via clean rejection borders; spatial RDD with built-in placebo (new builds vs. replacements) and dual outcomes (GWR heating + ElCom demand proxy) enable causal chain.
- **Concerns**: Data availability uneven across border cantons (e.g., SO/AG/BE GWR unconfirmed), risking underpowered design; electricity proxy may confound with non-heat uses.
- **Novelty Assessment**: Strong—no spatial RDDs on building codes' fuel substitution; builds on energy transition lit but first for Swiss cantonal rejections as counterfactual.
- **Top-Journal Potential**: Medium-high—mechanism surprise (substitution/offset in heating) with welfare implications for mandates; top field journal viable if framed as boundary test of transition barriers, but niche Swiss setting needs "cosmopolitan" tie-in (e.g., EU parallels).
- **Identification Concerns**: Only 3 borders limits power/replication vs. multi-border ideals; rejection vs. adoption may proxy canton fixed differences (e.g., green preferences), though placebo helps.
- **Recommendation**: PURSUE (conditional on: verifying GWR heating data for all 6 cantons; powering simulations for <10km bandwidths)

**#3: Idea 3: Water Royalties and Hydroelectric Electricity Pricing in Swiss Mountain Cantons**
- **Score**: 64/100
- **Strengths**: Addresses pass-through debate with spatial RDD + 2015 reform DiD; secondary tax substitution outcome adds welfare angle using reliable ElCom data.
- **Concerns**: Limited cross-border variation (most at federal max) and few mountain/plain borders yield low power; 2015 shock uniform across cantons weakens spatial contrast.
- **Novelty Assessment**: Moderately novel—builds on Betz et al. (2021) modeling but first causal retail price evidence; Wasserzins lit is thin, mostly theoretical/advocacy.
- **Top-Journal Potential**: Medium—pass-through null/precise bounds could win if powered (like crime prices), but underpowering and "another ATE" without strong mechanism risk "competent but not exciting" rejection.
- **Identification Concerns**: Temporal shock affects all equally, so spatial DiD relies on thin border samples; hydro production concentration may violate local randomization.
- **Recommendation**: CONSIDER (if power sims show MDE <20% pass-through; else pivot to firm-level)

**#4: Idea 4: Cantonal Organic Farming Subsidies and Agricultural Commodity Production**
- **Score**: 57/100
- **Strengths**: Leverages rich municipal ag data for RDD on organic transition; speaks to subsidy inframarginality debate.
- **Concerns**: Cantonal subsidies small/undocumented (federal dominates), requiring manual coding and yielding fuzzy treatment; no timing for DiD weakens ID.
- **Novelty Assessment**: Medium—organic subsidy effects studied (e.g., EU pilots), but Swiss cantonal spatial variation untapped; risks "another ag subsidy" paper.
- **Top-Journal Potential**: Low—standard RDD on farm shares lacks counterintuitive channel or stakes; reads as diffuse outcomes without causal chain, per appendix "modal loss."
- **Identification Concerns**: No sharp/timed policy variation (intensity continuous/ongoing); borders may sort land quality/farm types endogenously.
- **Recommendation**: SKIP

**#5: Idea 5: TRAF 2020 Tax Reform and Switzerland's Commodity Trading Sector**
- **Score**: 51/100
- **Strengths**: Timely on spatial reallocation in global commodity hub post-major reform.
- **Concerns**: ~500 firms too few/spatially concentrated for RDD power; unidentifiable in aggregate BFS data without NOGA codes or firm linking.
- **Novelty Assessment**: High—TRAF spatial effects unexplored, especially for traders; no priors.
- **Top-Journal Potential**: Low—cool policy but "impossible measurement" trap with thin tails; appendix flags underpowered RDDs/firm counts as fatal.
- **Identification Concerns**: Few treated units near borders; concentration (GE/ZG) violates RDD continuity, risking "endogenous sorting at boundaries."
- **Recommendation**: SKIP

### Summary
This is a strong batch overall, with Ideas 1–2 offering genuine top-journal potential via novel spatial designs, mechanism tests, and policy stakes in Swiss energy policy—a niche but quasi-experimental goldmine. I'd recommend pursuing Idea 1 first (cleanest execution), followed by Idea 2 after data checks; the rest suffer power or ID flaws that doom them to "competent but not exciting" status.

