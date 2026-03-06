# Research Idea Ranking

**Generated:** 2026-03-06T15:42:05.508294
**Models:** GPT-5.4 (A), Gemini 3.1 Pro, GPT-5.4 (B)
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.4 (A) | Gemini 3.1 Pro | GPT-5.4 (B) |
|------|------|------|------|
| The Metro Before the Metro: Construction... | PURSUE (66) | CONSIDER (58) | CONSIDER (61) |
| Does Transparency Reduce Corruption? Evi... | CONSIDER (55) | SKIP (38) | PURSUE (67) |
| The Price of Clean Air: Energy Transitio... | SKIP (47) | SKIP (32) | SKIP (44) |

---

## GPT-5.4 (A)

**Tokens:** 8419

### Rankings

**#1: The Metro Before the Metro: Construction-Phase Capitalization of Europe's Largest Transit Expansion**
- **Score:** 66/100
- **Strengths:** Exact policy novelty is real: I do not know of a serious causal paper on the Grand Paris Express using universe-scale transaction data. The setting is also unusually good for within-metro comparisons, and housing values are an immediate, policy-relevant outcome with plausible mechanisms.
- **Concerns:** The main risk is that the market priced much of this in long before 2020, so the proposed sample may miss the economically important anticipation window and mostly capture late-stage construction nuisance. Also, transit capitalization is a very mature literature, so this will read as incremental unless it is framed around **when** capitalization occurs and why.
- **Novelty Assessment:** **Moderately novel.** The GPE setting is new, but “new transit infrastructure affects nearby property values” is already heavily studied. The novelty is the policy/institutional setting and scale of data, not the core question.
- **Top-Journal Potential:** **Medium.** A top field journal could be interested if the paper becomes about the timing of capitalization under long-gestation infrastructure—announcement vs construction vs opening—and uses the universe data to rule out common objections. Top-5 is unlikely unless the paper delivers a more general insight about expectation formation or urban incidence than a standard transit-value gradient.
- **Identification Concerns:** Station placement is not random and likely correlated with redevelopment trends. More importantly, “later-opening” lines are not clean controls if households already anticipated them years before the sample starts; you really need a longer pre-period and a milestone-based design.
- **Recommendation:** **PURSUE (conditional on: extending the pre-period as far back as possible; reconstructing announcement/construction milestone dates, not just opening dates; making the paper explicitly about anticipation/construction timing rather than a generic transit ATE)**

**#2: Does Transparency Reduce Corruption? Evidence from France's Open Data Mandate**
- **Score:** 55/100
- **Strengths:** This has the best potential identification strategy among the bottom two ideas: a population-threshold mandate could produce a useful fuzzy RDD or strong first stage for compliance. Policymakers also care about whether transparency mandates have real effects or just symbolic ones.
- **Concerns:** As written, the outcomes do not measure corruption very well. Budget publication, elections, DVF, and firm entry are at best distant proxies, so the paper risks becoming a diffuse “open data affects many things a little” study rather than a sharp causal chain.
- **Novelty Assessment:** **Somewhat novel setting, not novel question.** Transparency and corruption is a crowded literature. The incremental contribution would be the French institutional setting and threshold-based design, not the underlying claim.
- **Top-Journal Potential:** **Low.** In its current form, this is unlikely to interest a top journal because the outcomes are too indirect and the mechanism is too vague. It becomes much stronger if redirected toward procurement competition, contract prices, audit flags, favoritism, or judicial corruption cases.
- **Identification Concerns:** French population thresholds often trigger multiple administrative rules, so the RDD may not isolate open-data obligations. Compliance timing is also likely fuzzy, which is fine in principle, but only if you can document a strong first stage and use outcomes tightly linked to transparency.
- **Recommendation:** **CONSIDER (conditional on: replacing proxy outcomes with direct procurement/audit/corruption measures; verifying that the relevant threshold is not bundled with other municipal rules; documenting a sharp compliance first stage)**

**#3: The Price of Clean Air: Energy Transition and Industrial Employment in French Communes**
- **Score:** 47/100
- **Strengths:** The policy stakes are large and first-order: decarbonization, local job loss, and spatial redistribution are important questions. If cleanly identified, the tradeoff between cleaner air and local labor-market damage could be compelling.
- **Concerns:** As proposed, the treatment is effectively “plant closure,” and closure timing is highly endogenous to profitability, productivity decline, ownership decisions, and local demand shocks. The sample may also be too small if restricted to coal plants, or too heterogeneous if broadened to many polluting facilities.
- **Novelty Assessment:** **Limited novelty.** The French setting is less studied, but plant closures, deindustrialization, coal transitions, and local employment effects are already a crowded literature.
- **Top-Journal Potential:** **Low.** The question is important, but the current design looks like a standard closure event study with obvious selection problems. Without a quasi-exogenous margin—regulatory thresholds, legal rulings, unexpected shutdown mandates, or predetermined emissions exposure—it is unlikely to travel far.
- **Identification Concerns:** EU ETS Phase IV affects many firms simultaneously; closure is an endogenous response, not exogenous policy assignment. Pre-trend tests will not rescue a design where treated places were already on different trajectories because the plant was failing.
- **Recommendation:** **SKIP**

### Summary

This is a mixed batch with **one clearly viable project and two that need substantial redesign**. I would pursue the **Grand Paris Express** paper first, but only if the team can recover a longer pre-period and frame the contribution around **timing of capitalization under long-gestation infrastructure**. The open-data idea is salvageable with much better outcome data; the plant-closure idea is not credible enough in its current form.

---

## Gemini 3.1 Pro

**Tokens:** 7133

Here is my evaluation of the research proposals, ranked from most to least promising. As requested, I have applied a highly critical lens, particularly regarding the empirical realities of publishing in top economics journals.

### Rankings

**#1: The Metro Before the Metro: Construction-Phase Capitalization of Europe's Largest Transit Expansion**
- **Score**: 58/100
- **Strengths**: This proposal features excellent, universe-scale administrative data (DVF) and a highly credible, modern staggered difference-in-differences design with built-in placebos. The feasibility is near-certain, and the spatial precision is excellent.
- **Concerns**: It is fundamentally estimating another Average Treatment Effect (ATE) of transit on housing prices, which is one of the most saturated literatures in urban economics. The "construction phase" angle is a nice twist, but it is unlikely to change how the field thinks about urban spatial structure.
- **Novelty Assessment**: Low to Medium. While the specific decomposition of the construction phase at this scale is somewhat new, the broader topic of transit capitalization has been exhaustively studied (e.g., Gibbons & Machin, Redding & Turner). 
- **Top-Journal Potential**: Low for Top-5, High for Top Field (JUE, AEJ: Policy). As noted in the Editorial Pattern Appendix, the most common failure mode for technically sound papers is being "competent but not exciting." Without a surprising mechanism or a challenge to conventional wisdom, this will struggle at the AER/QJE level, though it is a lock for a good urban/regional journal.
- **Identification Concerns**: Very clean overall, though anticipation effects are a threat. The Grand Paris Express was officially announced in 2011, meaning baseline prices in the 2020-2025 sample window may already price in the transit expansion, muting the estimated effects.
- **Recommendation**: CONSIDER (conditional on: pivoting the main outcome away from a standard price ATE toward a novel mechanism, such as how construction phases alter local firm entry/exit networks or trigger early demographic sorting).

**#2: Does Transparency Reduce Corruption? Evidence from France's Open Data Mandate**
- **Score**: 38/100
- **Strengths**: The proposal attempts to leverage a specific legal mandate to answer a classic political economy question, and the idea of using population thresholds for a sharp RDD is theoretically elegant.
- **Concerns**: The proposal falls into a classic institutional trap: the 3,500 population threshold in France is famously confounded by major changes in electoral rules, making it impossible to isolate the effect of the open data mandate. Furthermore, the effect of open data on corruption in a sleepy town of 3,501 people is likely a precise zero.
- **Novelty Assessment**: Medium. While open data mandates specifically are under-evaluated causally, the broader transparency-corruption link is very well-trodden (e.g., Ferraz & Finan).
- **Top-Journal Potential**: Low. The appendix notes that null results only win if they provide a "decisive bound on an important claim." A null result here would likely be dismissed as a weak first stage (nobody actually reads the municipal open data) rather than a profound statement on transparency.
- **Identification Concerns**: Fatal compound treatment. In France, crossing the 3,500 population threshold triggers a change in the municipal voting system (from *scrutin majoritaire* to *scrutin de liste* with proportional representation) and enforces strict gender parity rules on candidate lists. This violently violates the RDD exclusion restriction.
- **Recommendation**: SKIP (unless redesigned around a different, unconfounded population threshold, such as the 50,000 threshold, though N will be much smaller).

**#3: The Price of Clean Air: Energy Transition and Industrial Employment in French Communes**
- **Score**: 32/100
- **Strengths**: The proposal addresses a highly policy-relevant topic—the "just transition" and the local labor market impacts of decarbonization—which is currently a priority for European policymakers.
- **Concerns**: The proposal suffers from a severe lack of statistical power and fundamental endogeneity. France's electricity grid is ~70% nuclear; the 2019 law targeted exactly *four* remaining coal power plants, making a staggered DiD impossible.
- **Novelty Assessment**: Low. The local employment effects of deindustrialization and coal closures have been exhaustively studied in the US (e.g., Autor) and Germany. This is merely a geographic port of existing literature to a setting where the treatment is a minor part of the economy.
- **Top-Journal Potential**: Low. The appendix emphasizes that "niche settings only win when they crack a general puzzle." Porting a well-known US/German coal shock to France does not crack a new puzzle, and the diffuse "policy package affects many things" framing lacks the sharp causal channel required for top journals.
- **Identification Concerns**: Beyond the fatal N=4 problem for coal plants, expanding the sample to "heavy-polluting facilities" introduces severe endogeneity. Plants do not close randomly; they close when they become unprofitable, which is heavily correlated with unobservable local economic decline. Finding "demographically similar communes" does not solve this.
- **Recommendation**: SKIP.

### Summary

This batch of proposals leans heavily on standard applied microeconomics toolkits (DiD, RDD) but generally lacks the conceptual innovation required for top-tier economics journals. Idea 1 is by far the most technically competent and feasible, but it suffers from the "competent but not exciting" syndrome; I recommend pursuing it only if the authors can find a surprising mechanism to elevate it beyond a standard capitalization exercise. Ideas 2 and 3 suffer from fatal institutional and identification flaws (N=4 for French coal; compound treatments at the French 3,500 population threshold) and should be discarded.

---

## GPT-5.4 (B)

**Tokens:** 7520

### Rankings

**#1: Does Transparency Reduce Corruption? Evidence from France's Open Data Mandate**
- **Score: 67/100**
- **Strengths:** This is the most conceptually interesting question of the three: transparency, corruption, and accountability are first-order policy objects, and a threshold-based design could be substantially cleaner than a standard adoption DiD. The French mandate also looks meaningfully less mined than the broader transparency literature, so there is room for a genuinely useful paper.
- **Concerns:** As written, the proposal does not actually measure corruption well. Budget aggregates, property transactions, and firm entry are weak proxies; without procurement irregularities, audit findings, favoritism, or legal enforcement outcomes, the paper risks becoming “transparency affects some municipal outcomes” rather than “transparency reduces corruption.”
- **Novelty Assessment:** **Moderately high.** There is a large literature on transparency and political accountability, but much less on mandatory municipal open-data rules with quasi-experimental variation, especially in France. So this is not a blank slate, but it is clearly less saturated than transit capitalization or plant-closure employment effects.
- **Top-Journal Potential: Medium.** A top field journal could plausibly be interested if the paper shows a sharp chain like **open-data mandate → procurement transparency/fiscal discipline → electoral accountability**. Top-5 potential is only real if the outcomes are much sharper than the current proxy set and the threshold design survives serious institutional scrutiny.
- **Identification Concerns:** The proposed RDD may be less clean than it sounds because French municipal population thresholds often trigger multiple legal and political changes, not just open-data obligations. If compliance is gradual and endogenous, the design may become a fuzzy first-stage with weak treatment timing.
- **Recommendation:** **PURSUE (conditional on: replacing proxy outcomes with direct corruption/procurement measures; verifying that the relevant population threshold is not bundled with other major institutional discontinuities; documenting compliance timing cleanly)**

---

**#2: The Metro Before the Metro: Construction-Phase Capitalization of Europe's Largest Transit Expansion**
- **Score: 61/100**
- **Strengths:** The data are excellent and the object is concrete: a huge transit expansion with many transactions, direct welfare-relevant outcomes, and some built-in placebo structure from staggered openings. As a France-focused policy paper, this could become the benchmark study on GPE capitalization.
- **Concerns:** The main problem is that this is a very crowded literature. More importantly, property markets may have capitalized expected access long before 2020, so the current sample may miss the most relevant treatment margins and turn “construction-phase effects” into a muddled mix of pre-existing anticipation, nuisance, and local trend differences.
- **Novelty Assessment:** **Moderate at best.** The exact GPE setting is new, and the French universe-scale transaction data are valuable, but transit expansions and housing-value capitalization are among the most studied topics in urban economics. “No paper on this exact project” is helpful, but not enough by itself.
- **Top-Journal Potential: Low-Medium.** This is more likely a solid field-journal paper than a top-5 paper. To rise above “another transit capitalization estimate,” it would need a sharper mechanism—e.g. showing how prices respond to uncertainty resolution, construction disamenities, or business formation before service actually begins.
- **Identification Concerns:** Station placement is highly endogenous, and the control group may not provide credible counterfactual trends. The short pre-period relative to route announcement and planning decisions is a serious threat, because capitalization may have happened years earlier.
- **Recommendation:** **CONSIDER**  
  *(It becomes much more attractive if you can extend the transaction panel further back, map announcement/revision dates rather than only opening dates, and lean heavily on repeat-sales and very local ring comparisons.)*

---

**#3: The Price of Clean Air: Energy Transition and Industrial Employment in French Communes**
- **Score: 44/100**
- **Strengths:** The policy stakes are real: energy transition, local labor-market decline, and spatial reallocation are important and politically salient. If plant closures were truly regulation-driven and numerous enough, the question could matter a lot for French industrial policy.
- **Concerns:** As proposed, the design is weak. Plant closures are usually endogenous to economic decline, technological obsolescence, and long-run local trends, so a staggered DiD on closure dates is unlikely to identify policy effects cleanly; on top of that, the treated sample in France may be very small.
- **Novelty Assessment:** **Low to moderate.** There is already a large literature on plant closures, deindustrialization, and the labor-market costs of decarbonization. The French setting is less studied, but the underlying question is not especially new.
- **Top-Journal Potential: Low.** In its current form, this reads like a standard closure-effects paper in a small setting. To become exciting, it would need either a much cleaner source of exogenous variation or a sharper mechanism—say, linking regulation-induced closures to political backlash, migration, or long-run local fiscal collapse.
- **Identification Concerns:** Closure timing is almost certainly selected, anticipation effects are likely large, and commune boundaries are a poor unit for labor-market exposure because workers commute across communes. With few treated plants, staggered DiD inference will also be fragile.
- **Recommendation:** **SKIP**  
  *(Unless you can anchor the design on a genuinely exogenous regulatory shock, court ruling, or eligibility cutoff and move from communes to local labor markets.)*

---

### Summary

This is a decent batch, but only one idea looks clearly worth prioritizing right now. **Idea 3** has the best upside because the question is first-order and the design could be strong, but only if you upgrade the outcome measures and validate the threshold design. **Idea 1** is feasible and likely publishable somewhere good, but it is crowded and currently underspecified on the key anticipation problem; **Idea 2** is the weakest and I would not allocate scarce institute time to it without a much cleaner source of identification.

