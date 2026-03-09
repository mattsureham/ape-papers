# Research Idea Ranking

**Generated:** 2026-03-09T11:05:36.799503
**Models:** GPT-5.4 (A), Gemini 3.1 Pro, GPT-5.4 (B)
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.4 (A) | Gemini 3.1 Pro | GPT-5.4 (B) |
|------|------|------|------|
| When the Canal Runs Dry: Climate Shocks,... | PURSUE (77) | SKIP (55) | PURSUE (79) |
| The Environmental Cost of Downstreaming:... | PURSUE (72) | PURSUE (72) | CONSIDER (66) |
| Do Export Controls Have Teeth? Product-L... | PURSUE (69) | PURSUE (88) | PURSUE (71) |
| Friendly Fire: How US Section 301 Tariff... | SKIP (52) | — | SKIP (54) |
| Friendly Fire: How US Section 301 Tariff... | — | CONSIDER (65) | — |

---

## GPT-5.4 (A)

**Tokens:** 10979

### Rankings

**#1: When the Canal Runs Dry: Climate Shocks, Trade Costs, and Consumer Prices**
- **Score: 77/100**
- **Strengths:** This has the best mix of novelty, clean quasi-exogenous variation, and broad economic stakes. The causal chain is compelling and editor-friendly: climate shock to infrastructure → trade disruption → import prices → consumer prices.
- **Concerns:** The paper will fail if it collapses into a loose East Coast vs. West Coast comparison. The CPI pass-through piece is the most fragile part and needs tight exposure mapping rather than suggestive correlations.
- **Novelty Assessment:** High. There is older work on major shipping-route disruptions and trade costs, but I do not know of a paper on the 2023–24 Panama drought using port-by-origin exposure and downstream price pass-through.
- **Top-Journal Potential: High**  
  This is the only idea here that naturally reads as a general-interest paper rather than a strong field paper: a climate shock hits a critical bottleneck and consumers pay. If the pass-through evidence is real and well-measured, this is plausibly top-5/AEJ:EP material.
- **Identification Concerns:** The main threat is that Canal dependence proxies for pre-existing differences across ports, products, and sourcing patterns. The design needs exposure fixed entirely pre-shock, flexible port/origin controls, and convincing placebo tests on routes that should not be affected.
- **Recommendation:** **PURSUE** *(conditional on: defining Canal exposure entirely from pre-2023 routing; making import-price pass-through the core downstream outcome, with CPI as secondary)*

---

**#2: The Environmental Cost of Downstreaming: Smelter-Level Pollution from Indonesia's Nickel Export Ban**
- **Score: 72/100**
- **Strengths:** Big policy question with clear welfare stakes: a celebrated industrial policy may have created substantial local pollution through smelter expansion and captive coal use. The move from district-level treatment to geocoded smelter sites plus wind-direction tests is the right instinct and materially improves the design.
- **Concerns:** Smelter siting and timing are not random, and global nickel demand is moving at the same time as the policy. If the paper can only show PM2.5 and not health or another hard welfare outcome, it becomes much less top-journal compelling.
- **Novelty Assessment:** High, though not completely untouched. There is growing work on Indonesia’s nickel policy and a large environmental-science literature, but I do not know a convincing economics paper causally estimating the pollution costs of the smelter boom itself.
- **Top-Journal Potential: Medium**  
  This could become a very good AEJ:EP/JDE-style paper, and it has some top-5 upside if it delivers a clean pollution mechanism plus health effects. A PM2.5-only paper is more likely to be seen as good but not field-changing.
- **Identification Concerns:** The key issue is endogenous placement: smelters are built where ore, infrastructure, and industrial growth already exist. The cleanest version is a very local upwind-vs-downwind design around construction/operation dates, not a broad district-level staggered DiD.
- **Recommendation:** **PURSUE** *(conditional on: making the local spatial/wind design the causal core; securing a credible welfare outcome beyond pollution alone if possible)*

---

**#3: Do Export Controls Have Teeth? Product-Level Evidence from Russia Sanctions Enforcement**
- **Score: 69/100**
- **Strengths:** This is extremely policy-relevant and genuinely novel at the policy-margin level: it asks whether the specific enforcement fix, not sanctions in general, worked. The CHPL vs. non-CHPL comparison within similar product space is a smart design feature.
- **Concerns:** As written, the time aggregation is a serious weakness: with annual data, a May 2023 intervention leaves very little clean post-treatment variation. Mirror trade data are noisy, and substitution into nearby HS codes could make the results hard to interpret.
- **Novelty Assessment:** Very high. I know papers on Russia sanctions evasion and rerouting, but not a clean causal evaluation of the CHPL enforcement layer itself.
- **Top-Journal Potential: Medium**  
  This feels more like a strong policy/trade field-journal paper than an obvious top-5 paper. To break through, it would need to show not just trade suppression but a convincing mechanism that materially constrains militarily relevant supply chains.
- **Identification Concerns:** CHPL products were selected because they showed up in weapons forensics, so designation may correlate with unusual pre-existing rerouting dynamics or mean reversion. The current annual panel also gives too little post-policy information to really stress-test parallel trends or dynamic effects.
- **Recommendation:** **CONSIDER** *(upgrade to PURSUE if monthly product-level trade data or additional post-periods can be obtained; and if product-substitution across nearby HS codes can be addressed)*

---

**#4: Friendly Fire: How US Section 301 Tariff Exclusions Picked Winners and Losers Among American Importers**
- **Score: 52/100**
- **Strengths:** There is a real policy question here, and the exclusion/expiration waves do create potentially useful variation. If matching from exclusion notices to trade data is feasible, there is enough sample size for a competent paper.
- **Concerns:** The exclusion process is heavily endogenous and politically mediated, so the central comparison is not very credible causally. More importantly, the proposed public data do not identify importers, so the paper’s headline claim about “winners and losers among American importers” is not actually testable with the stated data.
- **Novelty Assessment:** Moderate to low. The Section 301 literature is already crowded, and exclusions are a narrower slice of a heavily studied episode.
- **Top-Journal Potential: Low**  
  As written, this reads as a competent extension of the China tariff literature rather than a paper that changes how the field thinks. Without importer-level data or a much sharper identification strategy, it is unlikely to stand out.
- **Identification Concerns:** Exclusions were petition-based and discretionary, likely correlated with exactly the product characteristics that predict import responses. Many exclusions were also description-specific rather than clean HS10 treatments, creating potentially severe measurement error in the match.
- **Recommendation:** **SKIP**

---

### Summary

This is a stronger-than-average batch, but only one idea clearly looks like a high-priority bet: **Idea 3**. I would pursue **Idea 2** next if the team can make the spatial/wind design central and secure a hard welfare outcome; **Idea 1** is genuinely novel and policy-relevant, but I would not greenlight it without more granular post-treatment data.

---

## Gemini 3.1 Pro

**Tokens:** 7877

Here is my evaluation of the research proposals, ranked from most to least promising. As requested, I have applied a highly critical lens, grounding my assessments in the empirical realities of top-tier editorial preferences and data feasibility.

### Rankings

**#1: Do Export Controls Have Teeth? Product-Level Evidence from Russia Sanctions Enforcement**
- **Score**: 88/100
- **Strengths**: This proposal perfectly executes the "first-order stakes + one sharp channel" formula. By shifting the focus from the well-documented phenomenon of sanctions evasion to the efficacy of a specific, targeted policy response (the CHPL), it answers a critical, unresolved policy question using a highly elegant Triple-Difference design with a built-in placebo.
- **Concerns**: The mirror statistics approach assumes transit countries accurately report their exports to Russia; if transit countries began masking their CHPL exports in response to Western pressure, the observed drop might be a reporting artifact rather than a real reduction in trade.
- **Novelty Assessment**: Highly novel. While the broader topic of Russian sanctions evasion is becoming crowded, evaluating the CHPL as a "policy-within-a-policy" using product-level variation is entirely fresh and moves the literature from descriptive to causal.
- **Top-Journal Potential**: High. A top-5 journal would find this exciting because it addresses a massive geopolitical issue with a highly credible, narrow identification strategy. The ability to estimate a "sanctions leakage rate" provides the exact kind of economically legible welfare object that editors look for.
- **Identification Concerns**: The primary threat is substitution to non-CHPL products that serve similar military functions, which could violate the SUTVA assumption for the control group (non-CHPL sanctioned goods in the same HS2 chapter). 
- **Recommendation**: PURSUE (conditional on: verifying that transit countries did not simply stop reporting CHPL-specific trade data to UN Comtrade post-2023).

**#2: The Environmental Cost of Downstreaming: Smelter-Level Pollution from Indonesia's Nickel Export Ban**
- **Score**: 72/100
- **Strengths**: This addresses a massive, globally relevant policy shift (green transition resource nationalism) and introduces a crucial, unpriced externality (pollution/health) to a literature currently obsessed only with employment and trade flows. The spatial decay and wind-direction designs are rigorous and editorially popular.
- **Concerns**: The data feasibility for the health outcomes is highly suspect; Indonesian district-level health data (Susenas/BPJS) is notoriously noisy, difficult to access, and may lack the spatial granularity needed to match the 1km PM2.5 grids. 
- **Novelty Assessment**: Medium-High. The policy itself is known, but the environmental/health angle is unstudied causally. It successfully overturns the "green transition" narrative by exposing local brown costs.
- **Top-Journal Potential**: Medium-High. If the health data holds up, this is a classic "complete causal narrative" (Export Ban → Smelter Construction → PM2.5 via wind → Mortality). It translates institutional detail into clear welfare stakes (who dies for the green transition).
- **Identification Concerns**: Small-N (43 smelters clustered in a few regions) makes standard clustering unreliable. Randomization inference helps, but if smelter placement is endogenous to local environmental laxity, the CEM matching must be perfectly executed.
- **Recommendation**: PURSUE (conditional on: securing high-quality, granular mortality/morbidity data before spending months on the PM2.5 spatial analysis).

**#3: Friendly Fire: How US Section 301 Tariff Exclusions Picked Winners and Losers**
- **Score**: 65/100
- **Strengths**: It takes an over-studied topic (Section 301 tariffs) and finds a genuinely interesting micro-level mechanism (the political economy of exclusions), effectively creating a natural experiment in selective protection.
- **Concerns**: Massive data feasibility red flag. USTR exclusions are frequently granted based on highly specific *product descriptions* (e.g., "AC motors under 18W with specific dimensions") that do not map cleanly to a 10-digit HS code. Census data cannot separate the excluded specific product from the non-excluded products sharing that same HS10 code.
- **Novelty Assessment**: Medium. The macro effects of the tariffs are heavily studied. The exclusion process is known descriptively, but a causal evaluation of within-product winners and losers is a nice, albeit incremental, addition.
- **Top-Journal Potential**: Medium. It reveals a new mechanism (selective protection), but it risks reading as a niche administrative paper unless it can definitively prove that the exclusion process caused massive misallocation or was driven by political favoritism.
- **Identification Concerns**: Measurement error in the treatment variable. If you cannot perfectly map USTR text to Census HS10 codes, your "treated" HS10 groups will contain untreated goods, severely attenuating the DiD estimates.
- **Recommendation**: CONSIDER (conditional on: proving that a sufficient sample of USTR exclusions map *perfectly and exclusively* to 10-digit HS codes without text-description overlap).

**#4: When the Canal Runs Dry: Climate Shocks, Trade Costs, and Consumer Prices**
- **Score**: 55/100
- **Strengths**: The data is highly accessible, the pre-period is long, and the continuous DiD design comparing East vs. West coast ports is logically sound and easy to implement.
- **Concerns**: This is the definition of "technically competent but not exciting." We already have a vast literature showing that supply chain shocks and increased freight costs pass through to consumer prices. 
- **Novelty Assessment**: Low-Medium. The specific drought is new, but the economic mechanism is entirely standard. It does not challenge conventional wisdom or reveal a counter-intuitive mechanism.
- **Top-Journal Potential**: Low. A top-5 journal would likely reject this as an incremental ATE of a specific weather event. It lacks the "opponent-killing" or paradigm-shifting narrative required for top general-interest journals. It belongs in a solid field journal.
- **Identification Concerns**: The Red Sea crisis (Houthi attacks starting Nov 2023) perfectly coincides with the peak of the Canal drought. Global shipping capacity is fungible; the Red Sea shock raised rates globally, severely confounding the macro price pass-through estimates, even with the European placebo.
- **Recommendation**: SKIP.

### Summary

This is a strong batch of proposals, but **Idea 1 (Export Controls)** is the clear standout and should be your institute's top priority; it combines a highly credible identification strategy with a first-order geopolitical question that policymakers are actively struggling with right now. **Idea 2 (Nickel Downstreaming)** is also highly promising and could be a top-tier publication if the health data proves feasible, as it brilliantly highlights the hidden environmental costs of the green transition. I recommend abandoning Idea 3, which reads as a routine supply-shock paper, and heavily scrutinizing the data mapping feasibility of Idea 4 before committing any resources to it.

---

## GPT-5.4 (B)

**Tokens:** 10580

### Rankings

**#1: When the Canal Runs Dry: Climate Shocks, Trade Costs, and Consumer Prices**
- **Score:** 79/100
- **Strengths:** This is the cleanest big-question paper in the batch: an exogenous climate shock to critical infrastructure with a very legible causal chain—canal capacity shock → trade rerouting/freight costs → import prices/consumer prices. The topic is novel, high-stakes, and naturally interesting beyond trade specialists.
- **Concerns:** The main risk is that this is still a one-shock paper, so separating the canal drought from the Red Sea crisis, post-pandemic normalization, and other shipping-market movements is essential. The downstream CPI pass-through step is also harder than the port/import effect and could end up too noisy for a flagship paper.
- **Novelty Assessment:** **High.** The exact 2023–24 Panama drought is, to my knowledge, essentially unstudied in economics, though there is adjacent work on Suez, COVID shipping disruptions, and trade-cost shocks.
- **Top-Journal Potential:** **High.** If executed well, this has the editorial shape that travels: first-order stakes, an obvious exogenous shock, and a sharp mechanism from climate risk to consumer welfare. It could plausibly fit a top-5 or AEJ: Economic Policy.
- **Identification Concerns:** Exposure must be measured credibly—ideally with historical AIS/canal-usage data, not just mechanical route-miles. You also need convincing evidence that treated and less-treated port-origin cells were on parallel trends and that the Red Sea shock is not driving the results.
- **Recommendation:** **PURSUE (conditional on: building a strong pre-drought route-exposure measure; cleanly separating Panama effects from Red Sea/post-pandemic shocks; showing at least one convincing price pass-through result)**

**#2: Do Export Controls Have Teeth? Product-Level Evidence from Russia Sanctions Enforcement**
- **Score:** 71/100
- **Strengths:** This is a very novel and policy-relevant question: not “do sanctions get evaded?” but “does targeted enforcement reduce leakage for militarily critical inputs?” The within-sanctions comparison—CHPL goods versus non-CHPL sanctioned goods in the same product families—is the right instinct and gives the design more bite than a descriptive rerouting paper.
- **Concerns:** The biggest issue is timing and data resolution: with annual Comtrade data, the May 2023 intervention is only imperfectly observed, leaving very little clean post-treatment variation. Mirror-trade data through transit countries are also noisy, and broader sanctions tightening may be hard to disentangle from CHPL-specific enforcement.
- **Novelty Assessment:** **Very high.** I do not know of a causal paper on the CHPL itself; the broader sanctions-evasion literature exists, but this specific enforcement margin appears genuinely new.
- **Top-Journal Potential:** **Medium.** This is more likely AEJ: Economic Policy or a strong field journal than a top-5 unless the paper can deliver a really sharp welfare object, such as a credible estimate of how much weapons-relevant leakage CHPL eliminated. The policy stakes are large, but the setting is somewhat specialized.
- **Identification Concerns:** The product list may be “exogenous to trade” in the narrow sense, but CHPL items were selected precisely because they were weapons-critical, so they may have different post-2022 demand dynamics than other sanctioned goods. Annual data also make event-study validation and precise treatment timing quite weak.
- **Recommendation:** **PURSUE (conditional on: obtaining monthly trade data or a cleaner post-enforcement window; showing CHPL products were not already reverting relative to controls; stress-testing mirror-data reliability across transit countries)**

**#3: The Environmental Cost of Downstreaming: Smelter-Level Pollution from Indonesia's Nickel Export Ban**
- **Score:** 66/100
- **Strengths:** The question is important and policy-relevant: it speaks directly to the hidden local costs of “green transition” industrial policy and resource nationalism. The proposed design is thoughtfully improved relative to a crude district DiD—site-level exposure, staggered openings, wind direction, and placebo sectors all help.
- **Concerns:** The core causal problem remains serious: smelters are not randomly sited or timed, and local industrial growth around nickel hubs may itself drive pollution. Also, annual PM2.5 in Indonesia is heavily affected by regional haze and fires, which may swamp or contaminate the local industrial signal.
- **Novelty Assessment:** **Moderately high.** I am not aware of a clean causal paper on the pollution consequences of Indonesia’s nickel downstreaming push, though there is broader work on mining pollution and emerging work on the ban’s economic effects.
- **Top-Journal Potential:** **Medium.** The topic is consequential, but “smelters increase pollution” is not itself surprising enough for top-5 placement. It becomes much more exciting if the paper can establish a welfare chain—export ban → smelter expansion → downwind pollution → health damage.
- **Identification Concerns:** Site selection and construction timing are plausibly endogenous to expected industrial expansion, and small-N inference is still a concern despite smelter-level staggering. You will need very strong pre-trends, downwind/upwind contrasts, and haze/fire controls.
- **Recommendation:** **CONSIDER (conditional on: obtaining credible health outcomes or a stronger welfare margin; demonstrating robust effects with wind-based exposure; convincingly addressing wildfire/haze confounding and endogenous siting)**

**#4: Friendly Fire: How US Section 301 Tariff Exclusions Picked Winners and Losers Among American Importers**
- **Score:** 54/100
- **Strengths:** There is real policy relevance, and the exclusion/expiration margins are potentially useful sources of variation. If perfectly measured, the reversal when exclusions expire is a nice feature.
- **Concerns:** I am skeptical on both identification and measurement. Exclusions were granted through a highly selective petition process, so treatment is endogenous, and many exclusions may not map cleanly to HS10 trade data because of product-description granularity. Also, the title promises effects on “American importers,” but the proposed data are product-level imports, not importer-level outcomes.
- **Novelty Assessment:** **Moderate to low.** The broader Section 301 literature is already crowded; the exclusions angle is less studied, but it is not a blank slate.
- **Top-Journal Potential:** **Low.** Even if competently executed, this risks reading as a narrow trade-policy carve-out paper with expected results: tariff relief increases imports from China. Without firm-level data or a sharper rent-seeking/welfare mechanism, it is unlikely to excite a top general-interest journal.
- **Identification Concerns:** Exclusion approval is likely correlated with product characteristics, lobbying strength, supply substitutability, and pre-existing import trends. Treatment misclassification could be substantial if excluded items are narrower than reported HS10 categories.
- **Recommendation:** **SKIP**

### Summary

This is a good batch overall: two ideas are genuinely worth serious attention, one is worth developing if the design can be tightened, and one should probably be dropped. I would pursue the **Panama Canal drought** project first because it has the best combination of novelty, broad appeal, and a compelling causal chain; the **CHPL sanctions-enforcement** paper is the best niche-policy project but needs higher-frequency data to become convincing.

