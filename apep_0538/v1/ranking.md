# Research Idea Ranking

**Generated:** 2026-03-06T11:51:15.083254
**Models:** GPT-5.4 (A), Gemini 3.1 Pro, GPT-5.4 (B)
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.4 (A) | Gemini 3.1 Pro | GPT-5.4 (B) |
|------|------|------|------|
| Do Low-Emission Zones Gentrify? Vehicle ... | PURSUE (74) | — | PURSUE (75) |
| Do Fiber Broadband Networks Fuel Populis... | CONSIDER (64) | — | — |
| Russia's Gas Cutoff and European Industr... | SKIP (55) | — | CONSIDER (58) |
| Idea 1: Do Low-Emission Zones Gentrify? ... | — | PURSUE (88) | — |
| Idea 3: Do Fiber Broadband Networks Fuel... | — | SKIP (58) | — |
| Idea 2: Russia's Gas Cutoff and European... | — | SKIP (45) | — |
| Do Fiber Broadband Networks Fuel Populis... | — | — | SKIP (50) |

---

## GPT-5.4 (A)

**Tokens:** 7207

### Rankings

**#1: Do Low-Emission Zones Gentrify? Vehicle Bans, Air Quality, and Housing Price Capitalization in French Cities**
- Score: **74/100**
- Strengths: This is the strongest idea in the batch because the policy is important, current, and relatively under-studied in the French context, while the data are unusually strong: universe transaction data with exact timing and location. The best version has a compelling causal chain—**ZFE adoption → cleaner local air / lower traffic disamenity → housing price capitalization → potential regressive incidence**.
- Concerns: The title overreaches: DVF alone can identify capitalization, not “gentrification” or displacement, unless you add composition data on buyers/residents. The boundary design is also vulnerable because ZFE borders are not random and may coincide with city-center trends, redevelopment, transit upgrades, or pre-existing gentrification.
- Novelty Assessment: **Moderately high.** LEZ/ULEZ effects on pollution and traffic are already studied, and there is some broader literature on environmental amenity capitalization, but I am not aware of a well-known France-wide ZFE paper using administrative transaction data at this scale. The distributional/incidence angle is fresher than the basic housing-price question.
- Top-Journal Potential: **Medium.** A top field journal is realistic, and a top-5 is not impossible if the paper is framed as a surprising distributional tradeoff in environmental policy rather than a standard hedonic capitalization exercise. To get there, the paper needs a strong “opponent-killer” design and a clear mechanism, not just a DiD on prices.
- Identification Concerns: The main threat is **endogenous sorting across ZFE boundaries** and other simultaneously changing urban policies inside central zones. Also, transaction-composition changes can mimic price effects, so a repeat-sales design or very rich hedonic controls is important; and modeled air-quality data from Open-Meteo are weaker than regulatory monitors or satellite-based measures for the mechanism.
- Recommendation: **PURSUE (conditional on: reframing the core claim as capitalization/incidence unless composition data are added; using repeat-sales or parcel-level specifications plus strong boundary/event-study placebo tests; documenting a credible air-quality first stage with official monitor or satellite data)**

---

**#2: Do Fiber Broadband Networks Fuel Populism? France's Plan France Tres Haut Debit**
- Score: **64/100**
- Strengths: The question is politically salient and broad enough to matter beyond France, and the rollout generated a lot of cross-commune timing variation. If the institutional rules behind rollout timing can be turned into a genuinely exogenous design, this could speak to a major debate on how digital infrastructure reshapes politics.
- Concerns: The basic question—**internet access and anti-system politics**—is already crowded, and the likely sign is not very surprising. More importantly, rollout timing is not obviously exogenous: density, operator incentives, local state capacity, and commune characteristics all affect both fiber rollout and voting.
- Novelty Assessment: **Moderate to low.** Broadband and political outcomes have been studied extensively in Italy, Germany, the US, and elsewhere. France’s FTTH rollout is a useful setting, but the underlying question is not new.
- Top-Journal Potential: **Medium.** Political economy journals and AEJ: Policy could be interested if the design is unusually clean and the mechanism is sharp. For a top-5, it currently reads too much like “another broadband-and-politics paper” unless the French institutional thresholds generate unusually credible identification or a surprising mechanism.
- Identification Concerns: An IV based on zone classification is only convincing if the classification rules create quasi-random discontinuities; otherwise it just re-labels urbanization and investment attractiveness. Also, coverage is not the same as household adoption, and commune-level political outcomes may reflect many concurrent trends unrelated to fiber.
- Recommendation: **CONSIDER (conditional on: turning the rollout rules into a true threshold/RD or other quasi-experimental design; measuring take-up, not just availability; and showing strong pre-trend/placebo evidence around political outcomes)**

---

**#3: Russia's Gas Cutoff and European Industrial Restructuring**
- Score: **55/100**
- Strengths: The policy shock is unquestionably first-order, and the broad question—how energy shocks reshape industrial structure—is important. A strong version could illuminate reallocation across sectors and countries rather than just short-run output losses.
- Concerns: This is the weakest proposal on novelty and identification. The core variation—pre-war Russian gas dependence across countries—is highly endogenous to industrial mix, geography, infrastructure, and policy, and the design relies on a small number of country-level treated units facing a common macro shock.
- Novelty Assessment: **Low to moderate.** There is already a large post-2022 literature on Russian gas dependence, European energy prices, and industrial impacts. “Industrial restructuring” is a somewhat less-studied angle, but not enough to make this close to first-mover territory.
- Top-Journal Potential: **Low.** The topic is important, but as written it risks becoming a competent cross-country DiD with unsurprising results: energy-dependent economies get hit harder. Without sharper microdata or a more convincing design, it is unlikely to stand out at the top-journal level.
- Identification Concerns: Country-level dependence is not plausibly exogenous, and national responses—price caps, subsidies, storage policy, LNG access, industrial support—are bundled with the shock. With only 27 EU countries, inference is fragile, and pre-trends may reflect exactly the structural differences that generate gas dependence in the first place.
- Recommendation: **SKIP** *(unless radically upgraded to plant/firm-level microdata with a triple-difference design exploiting sector energy intensity and more granular exposure measures)*

### Summary

This is a decent batch, but only **Idea 1** looks clearly worth pushing hard right now. I would pursue it first, with a tighter claim and much stronger attention to boundary endogeneity and composition effects. **Idea 3** is worth keeping alive only if the institutional rollout rules can deliver much cleaner identification than is currently described; **Idea 2** is too crowded and too weakly identified in its current form.

---

## Gemini 3.1 Pro

**Tokens:** 6106

Here is my evaluation of the research proposals, ranked from most to least promising, applying the criteria and editorial patterns provided.

### Rankings

**#1: Idea 1: Do Low-Emission Zones Gentrify? Vehicle Bans, Air Quality, and Housing Price Capitalization in French Cities**
- **Score**: 88/100
- **Strengths**: This proposal perfectly pairs a first-order policy debate (the equity of climate mandates) with a massive, high-quality administrative dataset (the DVF universe). It proposes a compelling "mechanism surprise"—that environmental improvements might act as a regressive tax via housing capitalization and displacement.
- **Concerns**: Spatial boundary designs can be fragile if the boundaries were drawn endogenously to protect certain neighborhoods or if there are spillover effects (e.g., traffic simply rerouting to the streets just outside the ZFE). 
- **Novelty Assessment**: High. While LEZs have been studied for air quality and health, the literature on their housing market and distributional/gentrification impacts is remarkably thin. Using a universe of administrative transaction data rather than scraped real estate listings is a major step up from the existing European literature.
- **Top-Journal Potential**: High. This fits the exact profile of a top-5 or AEJ: Policy winner: "Scale is treated as scientific content" (millions of admin records) combined with a "mechanism surprise" (environmental policy causing gentrification). It addresses a highly salient policy trade-off with clear welfare implications.
- **Identification Concerns**: The spatial boundary design (1km inside vs outside) risks endogenous sorting at administrative boundaries, a known editorial killer. The authors must lean heavily on the staggered rollout and the dose-response (Crit'Air tier tightening) to separate the ZFE effect from underlying urban gentrification trends.
- **Recommendation**: PURSUE (conditional on: demonstrating that ZFE boundaries do not perfectly overlap with pre-existing demographic fault lines, and including a robust test for traffic/pollution spillovers just outside the zone).

**#2: Idea 3: Do Fiber Broadband Networks Fuel Populism? France's Plan France Tres Haut Debit**
- **Score**: 58/100
- **Strengths**: The institutional setting provides clear, rule-based variation (population density thresholds and operator zones) that is highly amenable to standard quasi-experimental methods. The data is easily accessible and perfectly measured at the commune level.
- **Concerns**: The literature on broadband and political polarization/populism is heavily saturated (Campante, Guriev, Zhuravskaya, etc.), making this feel like a replication in a new geography. Furthermore, population density is a massive confounder for political voting.
- **Novelty Assessment**: Low. The "internet causes populism" question has been studied extensively over the last decade. Applying it to France is an incremental geographic extension, not a conceptual breakthrough.
- **Top-Journal Potential**: Low. This is the textbook definition of the "modal loss" described in the appendix: "technically competent but not exciting." It is a standard DiD/IV with an unsurprising outcome, lacking a novel mechanism decomposition or a belief-changing pivot. 
- **Identification Concerns**: Using population density thresholds as an IV for broadband rollout is highly problematic because density violates the exclusion restriction; the urban/rural divide is the primary driver of anti-system voting in France (e.g., the *Gilets Jaunes* movement). 
- **Recommendation**: SKIP (unless the authors can pivot to a completely novel outcome variable, such as firm-level remote-work restructuring or local tax base impacts, rather than populism).

**#3: Idea 2: Russia's Gas Cutoff and European Industrial Restructuring**
- **Score**: 45/100
- **Strengths**: The proposal targets a massive, historically significant macroeconomic shock with undeniable real-world consequences. 
- **Concerns**: Eurostat Structural Business Statistics (SBS) is aggregated at the sector-country level, not true firm-level microdata, meaning the "firm restructuring" angle cannot be cleanly observed. The treatment variable is hopelessly confounded with other macro shocks.
- **Novelty Assessment**: Low to Medium. The 2022 energy shock has generated a flood of macro-energy papers over the last two years. While the firm-level angle is slightly fresher, the proposed data cannot actually deliver on that promise.
- **Top-Journal Potential**: Low. This falls into the "confounded treatment bundles with no separation strategy" trap. Top journals will reject this because the causal channel is entirely illegible amidst the noise of inflation, fiscal responses, and the broader economic fallout of the Ukraine war.
- **Identification Concerns**: Pre-war Russian gas dependence is not exogenous; it is deeply correlated with geographic proximity to the conflict, historical institutional ties, and domestic fiscal capacity to shield firms. A continuous DiD here will just capture the difference between Eastern and Western Europe's broader economic trajectories in 2022-2023.
- **Recommendation**: SKIP.

### Summary

This batch presents a clear winner and two highly flawed proposals. **Idea 1 (ZFE Gentrification)** is an exceptionally promising project that leverages universe-scale administrative data to uncover a counter-intuitive, policy-relevant mechanism (environmental gentrification); it should be pursued immediately. Ideas 2 and 3 suffer from fatal flaws common to rejected papers: Idea 3 is technically competent but conceptually stale, while Idea 2 tackles a massive macro shock with hopelessly confounded identification and inadequate aggregated data.

---

## GPT-5.4 (B)

**Tokens:** 7514

### Rankings

**#1: Do Low-Emission Zones Gentrify? Vehicle Bans, Air Quality, and Housing Price Capitalization in French Cities**
- **Score:** 75/100
- **Strengths:** This is the most novel of the three and has unusually strong data: universe-scale administrative transactions plus staggered rollout across multiple cities. The best version has a clean and legible causal chain—ZFE adoption → cleaner air / traffic changes → housing price capitalization → distributional incidence.
- **Concerns:** The main risk is that ZFE boundaries are not quasi-random; they map onto central urban areas with very different underlying price dynamics and lots of concurrent policy changes. Also, “gentrification” is stronger than what DVF alone can establish; without resident-composition data, this may end up being a capitalization paper rather than a displacement paper.
- **Novelty Assessment:** High. There is adjacent LEZ/clean-air/property-value literature in Germany and the UK, but the exact France ZFE + DVF administrative-transactions setup appears lightly studied and the distributional framing is fresher than the median housing-capitalization paper.
- **Top-Journal Potential:** **Medium-High.** A top field journal is plausible, and top-5 is not impossible if the paper convincingly shows incidence and rules out competing urban-policy explanations. If it ends up as “clean-air policy raised nearby prices,” that is publishable but probably not top-5 material.
- **Identification Concerns:** The inside/outside boundary design is vulnerable because ZFE perimeters trace neighborhoods with different secular trends, transit access, and redevelopment patterns. I would want very tight boundary bandwidths, repeat-sales or parcel fixed effects, strong pre-trend evidence, and placebo boundaries / placebo outcomes; I would also be wary of relying on coarse modeled pollution data for the mechanism.
- **Recommendation:** **PURSUE** *(conditional on: using a tighter design than a simple inside/outside DiD; adding repeat-sales/parcel FE and strong placebo tests; either measuring composition/displacement directly with auxiliary census data or reframing from “gentrification” to “capitalization/incidence”)*

---

**#2: Russia's Gas Cutoff and European Industrial Restructuring**
- **Score:** 58/100
- **Strengths:** The stakes are first-order and policymakers care a lot about industrial reallocation after the 2022 energy shock. The sectoral heterogeneity angle gives the project a plausible mechanism rather than just a reduced-form macro correlation.
- **Concerns:** This literature moved fast, so novelty is lower than it first appears. More importantly, treatment intensity—pre-war Russian gas dependence—is deeply endogenous to long-run industrial structure, geography, and national energy policy, and the shock was bundled with sanctions, fiscal support, and other war-related disruptions.
- **Novelty Assessment:** Medium-Low. There are already many papers on the European gas shock and Russian energy exposure; the “industrial restructuring” angle is somewhat less saturated, but this is not a greenfield topic.
- **Top-Journal Potential:** **Medium-Low.** The object is important enough for top journals to care, but the likely headline—energy-intensive, gas-dependent economies were hit harder—is not very surprising. To break through, it would need a sharper mechanism or counterintuitive reallocation result, not just exposure-based losses.
- **Identification Concerns:** With treatment varying mainly at the country level, you effectively have only 27 clusters, and they differ in many ways that also shape post-2022 outcomes. A stronger design would be a country × sector triple-difference using pre-war Russian dependence and sector energy intensity, plus explicit handling of national mitigation policies.
- **Recommendation:** **CONSIDER** *(conditional on: upgrading to a country-sector triple-diff; carefully addressing endogenous exposure and differential national policy responses; showing that results are not driven by a few high-exposure countries)*

---

**#3: Do Fiber Broadband Networks Fuel Populism? France's Plan France Très Haut Débit**
- **Score:** 50/100
- **Strengths:** The question is broad-interest and politically salient, and the commune-level scale is attractive. France’s rollout does offer institutional structure that could, in principle, be useful if there is a genuinely sharp assignment rule.
- **Concerns:** This is the most crowded topic of the three, and the proposed identification is the weakest. Broadband rollout timing is heavily tied to density, profitability, remoteness, and public-investment capacity—exactly the factors that also predict populist voting trends.
- **Novelty Assessment:** Low-Medium. Broadband/internet and political behavior/populism is already a dense literature; France is a new setting, but not a fundamentally new question.
- **Top-Journal Potential:** **Low-Medium.** A top journal would need either a very sharp quasi-experiment or a strongly unexpected mechanism. As currently framed, this reads like another staggered-rollout broadband-politics paper in an already crowded space.
- **Identification Concerns:** “Zone classification” is not an obviously valid instrument because density-based classifications directly proxy for urban-rural political geography and economic trajectories. Unless there is a clean local-threshold RDD with convincing continuity, reviewers will likely view this as endogenous rollout plus shaky parallel trends.
- **Recommendation:** **SKIP**

### Summary

This is a mixed batch: **Idea 1** is the clear priority because it combines real novelty, excellent administrative data, and a policy question that is timely and potentially packageable as a compelling causal chain. **Idea 2** is important but identification is substantially weaker than the proposal suggests, and the novelty margin has narrowed. **Idea 3** is the least promising: the literature is crowded and the proposed design is unlikely to persuade a skeptical top-field referee.

