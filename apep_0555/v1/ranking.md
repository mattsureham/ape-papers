# Research Idea Ranking

**Generated:** 2026-03-09T15:29:59.739719
**Models:** GPT-5.4 (A), Gemini 3.1 Pro, GPT-5.4 (B)
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.4 (A) | Gemini 3.1 Pro | GPT-5.4 (B) |
|------|------|------|------|
| Demonetization by Design: The 2023 Niger... | PURSUE (75) | PURSUE (88) | PURSUE (77) |
| Trade Protection by Fiat: The Price Effe... | CONSIDER (60) | SKIP (55) | SKIP (54) |
| Pump Price Pass-Through After Nigeria's ... | SKIP (54) | SKIP (42) | CONSIDER (63) |

---

## GPT-5.4 (A)

**Tokens:** 10449

### Rankings

**#1: Demonetization by Design: The 2023 Nigerian Naira Redesign and the Cash-Mediation Channel in Food Markets**
- **Score:** 75/100
- **Strengths:** This is the best-designed idea in the batch: a very large, sudden policy shock paired with a within-market, across-commodity design that targets a clear mechanism rather than a generic before/after effect. Food prices are a first-order outcome, and the local-vs-imported rice comparison is an especially strong built-in validation.
- **Concerns:** The design hinges on cash-mediated and banking-mediated commodities having similar within-market trends absent the reform, which may fail if import exposure, seasonality, or commodity-specific supply shocks differed sharply in 2022-23. The March 2023 court reversal is useful, but legal reversal may not equal immediate restoration of cash in circulation.
- **Novelty Assessment:** Demonetization itself is a crowded literature because of India, so this is not a wholly new question. But this exact Nigerian episode, and especially the within-market commodity-channel design, seems meaningfully less studied and more novel than a standard demonetization paper.
- **Top-Journal Potential:** **Medium.** This has the right shape for a strong field-journal paper: first-order stakes, one sharp channel, and a dramatic policy episode. For a top-5, the paper would need either a genuinely surprising sign/result or unusually convincing mechanism evidence showing how cash frictions distort real markets.
- **Identification Concerns:** I would want strong pre-trend evidence for high- vs low-cash-mediation commodities within the same market, plus controls for commodity-specific seasonality and import/exchange-rate exposure. The cash-mediation index also needs external validation rather than ad hoc classification.
- **Recommendation:** **PURSUE** *(conditional on: validating the cash-mediation measure with external payment-mode evidence; showing strong pre-trends/placebos using close commodity pairs, especially local vs imported rice; treating the March 2023 court ruling as an imperfect reversal rather than a fully sharp second shock)*

**#2: Trade Protection by Fiat: The Price Effects of Nigeria's 2019 Land Border Closure**
- **Score:** 60/100
- **Strengths:** The policy is sudden, salient, and directly connected to an economically legible outcome—rice prices. Cross-border Benin/Niger data and placebo non-tradables make this better than a routine spatial DiD.
- **Concerns:** The core result is likely to be expected rather than field-changing: border closure raises prices near the border. Interior markets are not truly untreated in an integrated national market, and the overlap with COVID-era disruptions is a major threat.
- **Novelty Assessment:** The exact WFP implementation may be new, but the underlying question—how trade restrictions affect staple-food prices—is already well studied. This is more “new setting/data” than “new question.”
- **Top-Journal Potential:** **Low.** It could make a solid field-journal or policy paper, but absent a more surprising mechanism—market segmentation, smuggling substitution, welfare incidence—it risks reading as competent but unsurprising trade pass-through.
- **Identification Concerns:** Distance to border is correlated with remoteness, insecurity, smuggling intensity, and market integration, so pre-trends need to be very convincing. I would also want the main causal window either restricted to pre-COVID months or explicitly designed around pandemic confounding.
- **Recommendation:** **CONSIDER** *(best if reframed around market integration/smuggling and if the main analysis isolates the pre-COVID treatment window)*

**#3: Pump Price Pass-Through After Nigeria's 2023 Fuel Subsidy Removal**
- **Score:** 54/100
- **Strengths:** This is a highly important policy, and the geography-based exposure measure is intuitive. If linked convincingly to transport fares and household real outcomes, it could still produce a useful policy paper.
- **Concerns:** As framed, the main question is too close to the treatment itself: subsidy removal causing larger price increases where distribution costs are higher is not very surprising. Since all states are treated at once, identification rests almost entirely on cross-sectional geography, and the household-data component looks thin.
- **Novelty Assessment:** Fuel subsidy removal and pass-through are heavily studied topics internationally. The 2023 Nigerian episode is new, but the question is not; “using a new dataset on a recent reform” does not by itself create much novelty.
- **Top-Journal Potential:** **Low.** Without a sharper downstream causal chain—fuel subsidy removal → transport costs → food prices/real incomes/firm behavior—this looks like pass-through accounting rather than a paper that would excite a top journal.
- **Identification Concerns:** Distance to import terminals may proxy for remoteness and baseline cost trends, not just exposure to subsidy removal. With one national shock and only 37 state units, inference is limited, and I am not confident the GHS panel timing is clean enough for household-level causal claims.
- **Recommendation:** **SKIP** *(unless substantially reframed around downstream welfare effects with stronger micro data)*

### Summary

This is a decent batch, but only **Idea 1** looks genuinely promising as a research paper rather than a competent policy note. I would **pursue Idea 1 first**, **keep Idea 2 as a secondary field-journal/policy project**, and **drop or heavily redesign Idea 3** unless much better downstream outcome data become available.

---

## Gemini 3.1 Pro

**Tokens:** 6758

Here is my evaluation of the research proposals, ranked from most to least promising, applying the criteria and editorial patterns provided.

### Rankings

**#1: Demonetization by Design: The 2023 Nigerian Naira Redesign and the Cash-Mediation Channel in Food Markets**
- **Score**: 88/100
- **Strengths**: The within-market, across-commodity design is exceptionally elegant, and the built-in placebo (local vs. imported rice) isolates a very sharp mechanism. The Supreme Court reversal provides a rare, clean "off" switch to the policy shock, allowing for a compelling temporal test.
- **Concerns**: Rigorously defining "cash-mediation intensity" across 43 commodities may require strong assumptions or external data that is difficult to validate. Furthermore, imported goods have differential exposure to exchange rate shocks, which could confound the commodity-level variation.
- **Novelty Assessment**: High. While India's 2016 demonetization is well-studied (e.g., Chodorow-Reich et al.), Nigeria's 2023 episode is fresh. More importantly, the specific micro-identification strategy (commodity-level cash dependence within the same market) is highly novel and a major step up from standard macro event studies.
- **Top-Journal Potential**: High. This perfectly matches the editorial archetype of "first-order stakes + one sharp channel." By testing competing hypotheses (supply disruption vs. transaction cost inflation) using a clever built-in placebo, it elevates a developing-country macro shock into a top-tier micro-empirical paper that reveals a specific causal mechanism.
- **Identification Concerns**: Market-by-time fixed effects absorb *market-level* exchange rate shocks, but they do *not* absorb commodity-specific exchange rate pass-through. Because Nigeria experienced severe FX shortages and parallel market volatility during this exact period, the price of imported rice could spike due to FX constraints simultaneously with the cash shock, confounding the DiD.
- **Recommendation**: PURSUE (conditional on: rigorously validating the cash-mediation index; explicitly controlling for or ruling out commodity-specific exchange rate confounding during the treatment window).

**#2: Trade Protection by Fiat: The Price Effects of Nigeria's 2019 Land Border Closure**
- **Score**: 55/100
- **Strengths**: The sudden, unannounced nature of the policy provides a clean temporal shock, and the inclusion of non-tradeable placebos (firewood, charcoal) is a smart addition to the design.
- **Concerns**: Spatial difference-in-differences for a national border closure suffers from severe SUTVA (Stable Unit Treatment Value Assumption) violations. Interior markets are highly likely to be affected by general equilibrium price effects and rerouted smuggling, making them invalid controls.
- **Novelty Assessment**: Low to Medium. Spatial DiDs on trade shocks are a very mature literature. While the specific Nigerian context is important, the methodological approach to this specific 2019 event has likely already been explored in working papers or World Bank reports.
- **Top-Journal Potential**: Low. This reads exactly as the appendix warns: "technically competent but not exciting." It estimates a standard average treatment effect for a trade shock without revealing a counter-intuitive mechanism or overturning how the field thinks about trade protection.
- **Identification Concerns**: Interior markets (>300km) are not valid counterfactuals for border markets because food markets are spatially integrated; a massive supply shock at the border will propagate inland. Additionally, straight-line distance is a poor proxy for trade costs compared to actual road networks and travel times.
- **Recommendation**: SKIP

**#3: Pump Price Pass-Through After Nigeria's 2023 Fuel Subsidy Removal**
- **Score**: 42/100
- **Strengths**: Addresses a massive, highly salient policy change with clear, immediate welfare implications for a large population.
- **Concerns**: The identification relies on a single national shock interacted with distance to ports, which is highly vulnerable to concurrent macro shocks. Extracting and cleaning PDF data from the NBS across 36 states will also be highly labor-intensive with a low ceiling for publication payoff.
- **Novelty Assessment**: Low. Fuel subsidy pass-through is a heavily saturated literature, and distance-to-port continuous treatment designs are standard textbook exercises in trade and development economics.
- **Top-Journal Potential**: Low. It lacks a clean control group and relies on a diffuse "policy affects many things" narrative. Top journals routinely reject single-national-shock papers unless they feature an inescapable, highly novel micro-data linkage (which this lacks).
- **Identification Concerns**: Nigeria unified its exchange rate in June 2023, almost exactly coinciding with the May 2023 fuel subsidy removal. Distance to port is highly correlated with distance to FX-intensive import hubs (like Lagos). The design cannot cleanly separate the inflation caused by fuel transport costs from the inflation caused by the simultaneous currency devaluation.
- **Recommendation**: SKIP

### Summary

This batch presents a clear standout alongside two standard, unexciting proposals. **Idea 1 (Naira Redesign)** is the only proposal that clears the bar for top-tier research; it features a highly creative identification strategy that isolates a specific mechanism (cash-mediation) within a massive policy shock. Ideas 2 and 3 suffer from fatal identification flaws (SUTVA violations and concurrent macro confounders, respectively) and represent the kind of "competent but unexciting" ATE estimation that top journals routinely reject. I strongly recommend directing all resources toward Idea 1.

---

## GPT-5.4 (B)

**Tokens:** 8165

### Rankings

**#1: Demonetization by Design: The 2023 Nigerian Naira Redesign and the Cash-Mediation Channel in Food Markets**
- **Score: 77/100**
- **Strengths:** This is the most novel idea in the batch and the one with the sharpest mechanism: a sudden cash collapse should differentially affect goods whose supply chains rely on cash transactions. The within-market, across-commodity design with a policy reversal in March 2023 gives this more bite than a simple before/after national shock.
- **Concerns:** The key vulnerability is whether “cash-mediated” versus “banking-mediated” commodities are truly comparable rather than just different goods with different seasonality, import exposure, storage, and exchange-rate sensitivity. If the cash-mediation measure is ad hoc, referees will worry the paper is relabeling commodity heterogeneity rather than isolating a channel.
- **Novelty Assessment:** Demonetization itself is heavily studied, especially for India, but the 2022-23 Nigeria redesign is much less worked over, and this exact within-market commodity strategy looks genuinely fresh. So: high novelty on setting and design, moderate novelty on the broader concept.
- **Top-Journal Potential:** **Medium.** This has a plausible “first-order stakes + one sharp channel” structure: cash withdrawal → market trading frictions/liquidity collapse → relative food-price effects. I can imagine a strong AEJ: Economic Policy or JDE paper here; top-5 potential exists only if the mechanism validation is unusually tight and the paper speaks to broader monetary transmission in cash-heavy economies.
- **Identification Concerns:** You need strong evidence of parallel pre-trends in relative prices for treated vs. control commodities within markets, plus controls for commodity-specific seasonality and broader import/local shocks. I would especially want pairwise tests like local rice vs. imported rice and a convincing institutional validation of the cash-mediation classification.
- **Recommendation:** **PURSUE (conditional on: externally validating cash-mediation intensity; showing clean within-market pre-trends; using the March 2023 Supreme Court reversal as a decisive validation test)**

**#2: Pump Price Pass-Through After Nigeria's 2023 Fuel Subsidy Removal**
- **Score: 63/100**
- **Strengths:** This is a first-order policy reform with immediate, policy-relevant outcomes, and the geographic exposure measure is intuitive: once national price controls disappear, distance to import terminals should matter. For pump prices and transport fares, this could produce a clean and publishable pass-through paper.
- **Concerns:** As framed, the headline risks being obvious: after subsidy removal, places farther from supply points saw larger price increases. That is credible, but not very surprising, and the household-welfare extension looks much weaker unless the survey timing lines up tightly with the reform.
- **Novelty Assessment:** Fuel subsidy removal and fuel price pass-through are already large literatures. The Nigeria 2023 episode is new, but the empirical question is familiar rather than novel.
- **Top-Journal Potential:** **Low-Medium.** A top field journal is plausible if the paper builds a fuller chain—subsidy removal → fuel pass-through → transport costs → household real-income losses—and shows something non-obvious about incidence. On current framing, it looks more like a competent policy evaluation than a paper that would shift how the field thinks.
- **Identification Concerns:** There is no untreated group, so everything rests on differential exposure by distance, which is correlated with many regional characteristics. The design is strongest for pump prices themselves; it is much less persuasive for broader household outcomes because simultaneous macro changes, especially exchange-rate reforms and distribution disruptions, muddy interpretation.
- **Recommendation:** **CONSIDER (best if narrowed to pump prices and transport fares, with household claims kept modest unless the panel timing is much better than it currently appears)**

**#3: Trade Protection by Fiat: The Price Effects of Nigeria's 2019 Land Border Closure**
- **Score: 54/100**
- **Strengths:** The policy shock was abrupt, salient, and economically important, and food prices are exactly the kind of outcome policymakers care about. The presence of cross-border market data from Benin and Niger is a real asset and could help with interpretation.
- **Concerns:** The core question is quite conventional—trade barriers raise prices—and the treatment window quickly runs into COVID, which is a major contamination problem. With only 34 markets and border distance as the key source of variation, inference is likely to feel fragile.
- **Novelty Assessment:** The exact Nigeria 2019 closure is less studied than standard tariff episodes, but the broader question is very well worn. This is not a novel policy mechanism, just a new instance of a familiar one.
- **Top-Journal Potential:** **Low.** The likely main result is exactly what readers expect, and that makes it hard to package for a top outlet absent a sharper mechanism such as smuggling, market segmentation, or welfare incidence. As written, it reads as “competent but not exciting.”
- **Identification Concerns:** Distance to border is not remotely exogenous and may proxy for trade dependence, infrastructure, conflict exposure, and different secular trends. More importantly, interior markets are probably not clean controls because the closure affects national spatial equilibrium, and COVID arrives during the post period.
- **Recommendation:** **SKIP (unless redesigned around a short pre-COVID window or a much stronger cross-border market-integration design)**

### Summary

This is a decent batch, but only **Idea 1** looks genuinely promising enough to prioritize. **Idea 3** is serviceable as a narrower field-journal paper if kept tightly focused on price pass-through, while **Idea 2** is too conventional and too exposed to contamination to be a priority in its current form.

