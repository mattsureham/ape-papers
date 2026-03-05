# Research Idea Ranking

**Generated:** 2026-03-05T10:07:59.940781
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| Slower Streets, Safer Streets? The Causa... | PURSUE (73) | — | — |
| Planning Protection or Housing Blockade?... | PURSUE (67) | — | — |
| The Empty Homes Tax: Council Tax Premium... | CONSIDER (58) | CONSIDER (58) | — |
| Cumulative Impact Assessments and the Ni... | CONSIDER (52) | — | — |
| When It Rains, It Crimes? Extreme Rainfa... | SKIP (45) | SKIP (32) | — |
| Slower Streets, Safer Streets? The Causa... | — | PURSUE (88) | — |
| Planning Protection or Housing Blockade?... | — | SKIP (45) | — |
| Cumulative Impact Assessments and the Ni... | — | SKIP (40) | — |
| Idea 1: Slower Streets, Safer Streets? T... | — | — | PURSUE (82) |
| Idea 3: Planning Protection or Housing B... | — | — | CONSIDER (68) |
| Idea 2: The Empty Homes Tax: Council Tax... | — | — | CONSIDER (62) |
| Idea 5: Cumulative Impact Assessments an... | — | — | SKIP (55) |
| Idea 4: When It Rains, It Crimes? Extrem... | — | — | SKIP (48) |

---

## GPT-5.2

**Tokens:** 6983

### Rankings

**#1: Slower Streets, Safer Streets? The Causal Effect of Wales's 20mph Default Speed Limit on Road Casualties and Property Values**
- **Score: 73/100**
- **Strengths:** A rare, first-in-the-UK nation-scale transport reform with high political salience and a clean “treated nation vs not” contrast. STATS19 enables tight internal diagnostics (road-type placebo; severity/user-type/time-of-day mechanisms) that can read like an “opponent-killer” design.
- **Concerns:** Only **22 treated clusters** (Welsh LAs) and a **short post window** make inference fragile (needs wild bootstrap/randomization inference); 2019–2021 COVID-era dynamics can contaminate pre-trends if not handled carefully. Property-value capitalization is plausible but likely subtle and easily swamped by local housing shocks unless treatment intensity is measured at a much finer spatial level than LA.
- **Novelty Assessment:** **High.** Plenty on speed limits/road safety generally, but essentially no credible causal paper yet on *this* universal Welsh default reform (and almost none pairing it with hedonic capitalization).
- **Top-Journal Potential:** **Medium.** AEJ:EP/JPubE/JoUE are very plausible if the paper shows a clear first stage (actual speed/compliance or enforcement proxies) and a compelling mechanism chain; top-5 potential is harder given short horizon and likely “sign as expected.”
- **Identification Concerns:** Parallel trends are non-trivial with COVID and with contemporaneous UK road-safety changes; treatment is not “one policy one dose” because **exempt roads** and **2024 partial reversals** create heterogeneous intensity (good if measured; bad if ignored). Cluster count requires RI/wild bootstrap and conservative aggregation choices.
- **Recommendation:** **PURSUE (conditional on: (i) pre-specifying inference with 22 treated clusters—wild bootstrap/RI; (ii) extending pre-period back pre-2019 and showing robust pre-trends; (iii) building a credible treatment-intensity map (where 20mph actually applies / where reverted) for both crashes and housing exposure).**

---

**#2: Planning Protection or Housing Blockade? Article 4 Directions and Office-to-Residential Conversions in England**
- **Score: 67/100**
- **Strengths:** Sits squarely in the high-impact planning/housing constraints literature, and Article 4 is a concrete policy lever with clear welfare trade-offs (housing supply vs commercial space / local externalities). There’s a credible “gap”: lots on PDR, much less on the *withdrawal* via Article 4 at scale.
- **Concerns:** Adoption is likely **highly endogenous** (places adopt Article 4 when conversions are already booming or when political pressure rises), which can kill DiD credibility without stronger design. The biggest practical risk is geographic mismatch: Article 4 applies to **sub-LA polygons**, so LA-level DiD may attenuate or misclassify treatment.
- **Novelty Assessment:** **Medium-High.** PDR effects are studied; Article 4 as the main treatment is much less saturated, especially with broader outcomes (housing supply + firm dynamics).
- **Top-Journal Potential:** **Medium (with upside).** Could become very publishable in a top field journal if you can reframe as a sharp test of “planning as a supply throttle” and deliver a clean causal chain (Article4 → conversions → housing stock/prices → local economic activity). Top-5 requires especially convincing identification beyond “staggered DiD.”
- **Identification Concerns:** Standard staggered DiD will be vulnerable to selection-on-trends and anticipation (developers rush before enforcement). A stronger approach would exploit **within-LA boundaries** (treated polygons vs nearby untreated areas) plus event-study around enforcement dates, with tight spatial controls.
- **Recommendation:** **PURSUE (conditional on: (i) moving from LA-level DiD to polygon/LSOA/postcode-level exposure using Article 4 geographies; (ii) explicit anticipation tests; (iii) showing a “bite” first stage in actual conversion activity, not just prices).**

---

**#3: The Empty Homes Tax: Council Tax Premiums and Housing Vacancy in England**
- **Score: 58/100**
- **Strengths:** First-order policy question in a housing-crisis context, and the policy has clear incentives (taxing long-term vacancy). If the administrative CTB returns cleanly measure vacancy categories, the outcome is aligned with the lever.
- **Concerns:** Variation may be too thin for credible staggered designs because adoption became near-universal quickly; remaining “timing” is plausibly correlated with local housing stress and political choices. Annual, LA-level data also limits power and makes it hard to separate true vacancy reductions from **reclassification/avoidance** (e.g., second homes, exemptions, recording changes).
- **Novelty Assessment:** **Medium.** Vacancy taxes/premiums are studied in other settings (e.g., Vancouver-style empty homes taxes), but this specific English council-tax-premium regime has not been heavily mined in top economics outlets.
- **Top-Journal Potential:** **Low-Medium.** Likely reads as a competent policy evaluation unless it uncovers a surprising margin (e.g., large avoidance/relabeling; displacement to short-term lets; strong distributional incidence) or produces tight policy-relevant bounds on effects.
- **Identification Concerns:** Endogenous adoption and limited pre-periods for late adopters; staggered DiD can be misleading if already-trending high-vacancy places adopt earlier. Without micro property-level vacancy status, mechanisms are hard.
- **Recommendation:** **CONSIDER (conditional on: (i) verifying meaningful staggered variation and stable measurement in CTB returns; (ii) leveraging the 2018 cap increases as intensity shocks; (iii) adding falsification/avoidance tests—e.g., changes in exemptions/second homes if observable).**

---

**#4: Cumulative Impact Assessments and the Night-Time Economy: Alcohol Licensing Restrictions and Local Crime**
- **Score: 52/100**
- **Strengths:** Directly policy-relevant trade-off (crime vs night-time economy) and potentially large welfare stakes. If you can build a credible adoption dataset, the question is concrete and outcomes are measurable.
- **Concerns:** The two biggest risks are (i) **data construction** (no central CIA registry; hand-collection is costly and error-prone) and (ii) **endogeneity** (CIAs are usually adopted *because* crime/complaints are rising), making baseline DiD unconvincing. Also, many CIAs are **area-specific**, so LA-level treatment coding can misclassify exposure.
- **Novelty Assessment:** **Medium.** Alcohol availability and crime is heavily studied; CIAs specifically are less studied, but reviewers may see it as “another alcohol restriction paper” unless identification is unusually sharp.
- **Top-Journal Potential:** **Low-Medium.** Could reach a strong field journal if it convincingly shows net crime reduction vs displacement and quantifies economic costs; top-5 is unlikely without a quasi-experimental twist (e.g., boundary discontinuities or court-imposed changes).
- **Identification Concerns:** Strong selection-on-trends; high risk the event study shows pre-trends. Need micro-geographic CIA boundaries and crime at fine spatial scale to do treated-vs-nearby-untreated comparisons within the same city.
- **Recommendation:** **CONSIDER (conditional on: (i) building a defensible, reproducible CIA database with GIS boundaries and enforcement dates; (ii) using within-city spatial designs rather than LA DiD; (iii) explicit displacement tests).**

---

**#5: When It Rains, It Crimes? Extreme Rainfall and Street Crime in England**
- **Score: 45/100**
- **Strengths:** Weather is plausibly exogenous; data access is straightforward; can be executed quickly with transparent diagnostics. Useful as a measurement/replication-style contribution if positioned carefully.
- **Concerns:** Novelty is low (weather–crime is a crowded literature), and with crime only at **monthly resolution** in common UK open data, much of the identifying high-frequency variation in rainfall gets averaged away. The “IV via outdoor activity” story needs an actual first-stage activity measure; otherwise it’s a reduced-form correlation that is unlikely to move the literature.
- **Novelty Assessment:** **Low.** Many papers already study precipitation/temperature and crime; a UK replication with finer rainfall data is incremental unless it reveals a new mechanism or resolves a live puzzle.
- **Top-Journal Potential:** **Low.** Without a genuinely new object (e.g., a new activity measure, new policing channel, or a design that cleanly separates reporting vs incidence), it will likely be seen as competent but not exciting.
- **Identification Concerns:** Temporal aggregation (15-minute rain → monthly crime) risks attenuation and specification searching; rainfall may affect reporting/detection (policing patterns) as well as true crime.
- **Recommendation:** **SKIP (unless you can obtain daily crime/calls-for-service or strong mobility/footfall data to validate the mechanism and exploit short event windows around extreme storms).**

---

### Summary
This is a solid batch with two genuinely fundable directions. The Wales 20mph reform (#1) is the clearest “big, new policy + credible internal placebos,” and Article 4 directions (#2) has the best upside if you upgrade identification to micro-geographic boundary designs. The remaining ideas are policy-relevant but risk becoming either under-identified (CIAs, empty homes) or too incremental relative to a saturated literature (rainfall–crime).

---

## Gemini 3.1 Pro

**Tokens:** 7909

Here is my evaluation of the research proposals, ranked from most to least promising. As requested, I have applied a highly critical lens, grounding my assessments in the empirical realities of top-tier journal publishing and causal inference standards.

### Rankings

**#1: Slower Streets, Safer Streets? The Causal Effect of Wales's 20mph Default Speed Limit**
- **Score**: 88/100
- **Strengths**: This proposal tackles a highly salient, first-order policy shock with a beautifully layered identification strategy ("internal replication" via DiD, spatial RDD, and a built-in 40+mph placebo). The inclusion of property value capitalization elevates this from a standard public health evaluation to a compelling economic "trade-off discovery" (safety vs. commute time).
- **Concerns**: The post-treatment window is relatively short (15 months), which is adequate for high-frequency collision data but may be underpowered to detect slower-moving hedonic adjustments in the housing market. 
- **Novelty Assessment**: Extremely high. Universal default speed limit changes are rare, and the lack of a rigorous causal evaluation for a policy that generated the largest petition in Welsh history is a glaring academic gap.
- **Top-Journal Potential**: High. A top-5 or AEJ: Policy would find this exciting because it combines first-order stakes, a highly legible causal channel, and a multi-layered design that anticipates and kills the skeptic's best counterstories (via the A-road placebo). 
- **Identification Concerns**: The primary threat is concurrent Welsh-specific policies or localized COVID-recovery trends, but the spatial RDD (border matching) and the 40+mph placebo effectively neutralize these. 
- **Recommendation**: PURSUE (conditional on: verifying that 15 months of post-treatment Land Registry data provides sufficient transaction volume to power the hedonic pricing model).

**#2: The Empty Homes Tax: Council Tax Premiums and Housing Vacancy in England**
- **Score**: 58/100
- **Strengths**: It addresses a highly relevant policy question (housing crisis) using universally available administrative data. The staggered rollout theoretically allows for modern event-study estimators.
- **Concerns**: The limited variation in adoption timing (most adopted immediately) will severely weaken the statistical power of the staggered DiD. Furthermore, the outcome variable (reported empty homes) is highly susceptible to reclassification bias/tax evasion rather than genuine occupancy changes.
- **Novelty Assessment**: Medium. While the specific UK policy hasn't been exhaustively evaluated, the broader literature on vacancy taxes (e.g., Vancouver) is established. 
- **Top-Journal Potential**: Low. This reads exactly as the appendix warns: "technically competent but not exciting." It is a standard DiD with a predictable sign and lacks a surprising mechanism or broader welfare counterfactual.
- **Identification Concerns**: The most fatal threat is measurement error in the dependent variable: landlords may simply reclassify properties (e.g., as second homes or furnished) to avoid the premium, meaning you are estimating tax evasion, not housing supply.
- **Recommendation**: CONSIDER (conditional on: finding a way to measure *actual* vacancy or housing supply independently of the tax base returns, perhaps using utility data).

**#3: Planning Protection or Housing Blockade? Article 4 Directions and Office-to-Residential Conversions**
- **Score**: 45/100
- **Strengths**: The economic question is excellent—testing the exact mechanism of planning frictions on housing supply and commercial displacement. 
- **Concerns**: There is a fatal geographic mismatch between the treatment (Article 4 directions apply to highly specific zones/streets) and the proposed data/design (LA-level DiD). Aggregating a hyper-local policy to the LA level will result in massive attenuation bias.
- **Novelty Assessment**: Medium-High. The flip-side (granting PDR) has been studied, but the defensive use of Article 4 to block housing is an under-explored angle of the NIMBYism literature.
- **Top-Journal Potential**: Low. Top journals routinely reject papers where the treatment is measured at a much coarser level than it is applied, as it leads to underpowered nulls that cannot rule out plausible magnitudes.
- **Identification Concerns**: Beyond the geographic mismatch, Article 4 adoption is highly endogenous; LAs adopt them precisely when and where they anticipate a surge in profitable office conversions, violating parallel trends.
- **Recommendation**: SKIP (unless the researcher can geocode the exact Article 4 polygons and intersect them with property-level data for a boundary-discontinuity design).

**#4: Cumulative Impact Assessments and the Night-Time Economy**
- **Score**: 40/100
- **Strengths**: Explores a direct regulatory restriction with clear economic trade-offs (crime vs. hospitality sector growth).
- **Concerns**: The data feasibility is a nightmare; hand-collecting historical licensing statements across 300+ LAs is highly prone to error and survivorship bias. Like Idea 3, CIAs are zone-specific, making LA-level DiD inappropriate.
- **Novelty Assessment**: Medium. The trade-off between alcohol availability and crime is well-trodden, though the specific CIA mechanism is less studied.
- **Top-Journal Potential**: Low. The combination of a standard DiD, likely measurement error in treatment dates, and geographic mismatch makes this uncompetitive for top general-interest or field journals.
- **Identification Concerns**: Endogenous adoption is a severe threat—LAs implement CIAs exactly when local alcohol-related crime spikes, guaranteeing a violation of the parallel trends assumption (Ashenfelter's dip).
- **Recommendation**: SKIP.

**#5: When It Rains, It Crimes? Extreme Rainfall and Street Crime in England**
- **Score**: 32/100
- **Strengths**: The Environment Agency rainfall data is incredibly granular and high-quality.
- **Concerns**: The literature on weather and crime is entirely saturated. More fatally, there is a severe temporal mismatch: trying to use 15-minute rainfall shocks to explain monthly crime aggregates washes out the exact variation the design relies on.
- **Novelty Assessment**: Low. The weather-crime relationship has been studied to death (Jacob & Lefgren, Ranson, etc.). Replicating it in the UK with monthly crime data adds virtually nothing to the frontier of knowledge.
- **Top-Journal Potential**: Low. Top journals demand papers that answer a field-level puzzle or reveal a counter-intuitive mechanism. This does neither, and the temporal aggregation issue would be flagged as a fatal flaw by any empirical referee.
- **Identification Concerns**: Aggregating 15-minute extreme weather events to LSOA-month means destroys the exogenous high-frequency shock, inviting omitted variable bias (e.g., seasonal trends, monthly local economic shocks).
- **Recommendation**: SKIP.

### Summary

This batch presents a steep drop-off in quality after the first proposal. **Idea 1 (Wales 20mph)** is the only genuinely top-tier project; it is a beautifully designed, highly feasible study of a first-order policy shock that I strongly recommend pursuing immediately before someone else writes it. The remaining ideas suffer from either fatal geographic/temporal mismatches between the policy and the data (Ideas 3, 4, and 5) or read as competent but unexciting exercises that will struggle to place well due to endogenous policy adoption and measurement issues (Idea 2).

---

## Grok 4.1 Fast

**Tokens:** 6012

### Rankings

**#1: Idea 1: Slower Streets, Safer Streets? The Causal Effect of Wales's 20mph Default Speed Limit on Road Casualties and Property Values**
- Score: 82/100
- Strengths: Exceptionally novel evaluation of a high-profile, recent policy with massive backlash and no existing causal studies; multi-layered identification (DiD + border RDD + road-type placebo) with long pre-period, universe data, and mechanism decomposition into a clear causal chain (speed → casualties by user/time → property capitalization tradeoffs).
- Concerns: Short post-period (~15 months) risks underpowering long-run effects or dynamic responses; partial reversals in 2024 could contaminate later data without careful modeling.
- Novelty Assessment: Extremely high—no peer-reviewed causal evaluations exist despite political salience and descriptive reports; property value angle is entirely unstudied for speed limit reforms.
- Top-Journal Potential: High (top-5 or AEJ:EP viable). Uncovers potential tradeoffs (safety gains vs. commute costs capitalized in values) on a first-order policy with counterintuitive backlash despite casualty drops, fitting "trade-off discovery" and "legible causal channel" patterns; border placebo and universe STATS19 data provide scale and opponent-killers.
- Identification Concerns: Wales-wide policy minimizes spillovers but border RDD needed for local controls; exempt roads placebo strong but must verify no differential enforcement trends pre-2023.
- Recommendation: PURSUE (conditional on: extending post-period analysis into 2025 if data available; testing reversals as reverse-treatment design)

**#2: Idea 3: Planning Protection or Housing Blockade? Article 4 Directions and Office-to-Residential Conversions in England**
- Score: 68/100
- Strengths: Addresses first-order UK housing supply question with staggered adoption and accessible Article 4 dataset; builds on prior PDR work to quantify tradeoffs (housing vs. office preservation) with multi-outcome chain (conversions → supply/prices/firms).
- Concerns: Article 4 applies to sub-LA areas, risking ecological fallacy in LA-level DiD; staggered timing over 2013–2020 may entangle with other housing policies (e.g., Help to Buy).
- Novelty Assessment: High—prior studies (e.g., Cheshire 2022) cover PDR gains but not Article 4 blocks; no causal work on economic effects of these restrictions.
- Top-Journal Potential: Medium (top field journal like JUE or AEJ:EP). Housing supply stakes are huge with clear welfare tradeoffs, but sub-LA targeting dilutes "universe" scale; could win if framed as boundary test of conversion rights' net effects.
- Identification Concerns: Non-random sub-LA adoption invites selection (e.g., high-demand areas block more); LA-level aggregation blurs bite unless micro-data used for conversions.
- Recommendation: CONSIDER (conditional on: verifying sub-LA matching feasibility with planning apps data)

**#3: Idea 2: The Empty Homes Tax: Council Tax Premiums and Housing Vacancy in England**
- Score: 62/100
- Strengths: Timely for housing crisis with widespread policy adoption; staggered DiD feasible if adoption dates reconstructible, linking penalties to vacancy/prices in policy-relevant way.
- Concerns: Rapid early adoption (2013–2015) limits variation for staggered estimators, risking bias from never-takers or late trends; CTB data LA-level only, coarse for vacancy mechanisms.
- Novelty Assessment: Moderately high—no UK causal evals, though similar vacancy taxes studied peripherally elsewhere (e.g., US); housing angle fresh amid crisis.
- Top-Journal Potential: Medium-low. Competent policy ATE on vacancy but lacks counterintuitive channel or belief pivot; reads as "standard DiD on tax compliance" without strong mechanism map or scale to excite top-5.
- Identification Concerns: Heterogeneous adoption timing may correlate with vacancy pressures, violating parallel trends; Callaway-Sant'Anna sensitive to early bunching.
- Recommendation: CONSIDER

**#4: Idea 5: Cumulative Impact Assessments and the Night-Time Economy: Alcohol Licensing Restrictions and Local Crime**
- Score: 55/100
- Strengths: Clear policy tradeoffs (crime reduction vs. hospitality losses) with multi-outcome potential; staggered DiD straightforward if adoption dates compiled.
- Concerns: No central database for CIA dates requires labor-intensive scraping, delaying project; alcohol-crime link saturated, risking unsurprising results.
- Novelty Assessment: Moderate—no causal evals of CIAs specifically, but alcohol availability policies heavily studied (e.g., licensing hours, density effects).
- Top-Journal Potential: Low. Familiar alcohol-crime margin without novel mechanism or scale; "broad rollout → many outcomes" pattern likely discounted absent tight channel.
- Identification Concerns: Adoption endogenous to baseline crime/economy, threatening trends; non-adopters may differ systematically (e.g., rural vs. urban).
- Recommendation: SKIP

**#5: Idea 4: When It Rains, It Crimes? Extreme Rainfall and Street Crime in England**
- Score: 48/100
- Strengths: Exogenous weather shocks enable clean IV on activity-crime link with high-res UK data.
- Concerns: Monthly crime vs. 15-min rainfall aggregation loses precision; not a policy evaluation despite institute focus—more academic replication.
- Novelty Assessment: Low—US weather-crime papers (Jacob/Lefgren 2003; Ranson 2014) established framework; UK data finer but incremental.
- Top-Journal Potential: Low. Replication in new setting without policy stakes or puzzle-solving; lacks causal chain to welfare, fitting "competent but not exciting" losses.
- Identification Concerns: Common shocks across LSOAs risk spatial correlation; indoor/outdoor crime distinction weak if activity shifter imperfect.
- Recommendation: SKIP

### Summary
This is a strong batch overall, with Idea 1 standing out as genuinely top-journal caliber due to novelty, robust identification, and tradeoff potential amid political drama—pursue it first. Ideas 2–3 offer solid housing policy angles worth considering if data hurdles clear, but lower ones devolve into routine DiDs or non-policy shocks lacking excitement. Prioritize recent, universal rollouts with built-in diagnostics over staggered designs needing heavy cleanup.

