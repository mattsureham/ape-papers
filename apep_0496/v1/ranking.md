# Research Idea Ranking

**Generated:** 2026-03-03T20:07:55.426025
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| What’s in a Label? Education Priority Zo... | PURSUE (74) | — | — |
| The Private School Escape Valve: How Out... | CONSIDER (70) | — | — |
| Does Halving Class Sizes Capitalize into... | CONSIDER (58) | — | — |
| Gateway to the Elite: How CPGE Proximity... | SKIP (42) | — | — |
| Idea 3: The Private School Escape Valve:... | — | PURSUE (78) | PURSUE (70) |
| Idea 1: What's in a Label? Education Pri... | — | CONSIDER (58) | PURSUE (74) |
| Idea 2: Does Halving Class Sizes Capital... | — | SKIP (42) | CONSIDER (65) |
| Idea 4: Gateway to the Elite: How CPGE P... | — | SKIP (25) | SKIP (53) |

---

## GPT-5.2

**Tokens:** 6102

### Rankings

**#1: What’s in a Label? Education Priority Zones, School Quality Signals, and Housing Markets in France**
- Score: **74/100**
- Strengths: National-scale boundary RDD + difference-in-discontinuity around a major, discrete relabeling shock is unusually credible for the “school quality ↔ housing” space, and the DVF universe gives power and internal replication across many boundaries. The design has natural placebo boundaries that can be made a centerpiece rather than robustness.
- Concerns: The big threat is **sorting and simultaneous boundary-relevant changes** (catchment redefinitions, local urban renewal, school leadership changes) that coincide with REP reclassification; DiDisc helps, but only if catchment borders are stable and “switchers” aren’t systematically different. Another risk is interpretability: “REP label” bundles stigma, resources, and peer composition—top outlets will push hard on what exactly moved beliefs vs fundamentals.
- Novelty Assessment: **Moderate.** School-boundary capitalization is a large literature (esp. US/UK; France via Fack & Grenet), but *national France + a large policy-driven relabeling + internal replication/placebo battery* is a meaningful step beyond the canonical single-city boundary designs.
- Top-Journal Potential: **Medium-High.** A top field journal is very plausible; top-5 is plausible if you convincingly separate **signal/stigma vs resources/peer composition** and present a “policy labeling → beliefs → prices (and sorting)” chain with sharp falsification tests.
- Identification Concerns: Key gating items are (i) **no differential pre-trends** at switcher boundaries, (ii) **no manipulation/sorting** visible in housing turnover/composition right at the border, and (iii) confirmation that boundaries themselves didn’t move in ways correlated with price trends.
- Recommendation: **PURSUE (conditional on: verifying catchment-boundary stability 2014–2016; pre-registering the placebo/boundary battery; showing clean event-study dynamics around 2015 for switcher vs non-switcher boundaries)**

---

**#2: The Private School Escape Valve: How Outside Options Mediate the Capitalization of Education Priority Labels**
- Score: **70/100**
- Strengths: This is the most “mechanism-forward” idea: interacting the boundary design with outside options is exactly the kind of decomposition editors like (assignment rigidity vs neighborhood signal). It also generalizes the Paris-only private-school attenuation result to a national quasi-experiment.
- Concerns: **Private-school density is not exogenous**—it is historically shaped by neighborhood SES, religiosity, and political economy, which also shape housing demand elasticities and gentrification trends; even with RDD, heterogeneous treatment effects can be confounded by heterogeneous local trends unless you are extremely disciplined (boundary fixed effects, flexible local trends, pre-trend/event-study by density bins). A second concern is power/overfitting: triple-difference RDDs can become fragile if you slice the sample too finely.
- Novelty Assessment: **Moderate-High.** The “private option attenuates capitalization” idea exists, but a **policy-shock DiDisc + outside-option interaction at national scale** is meaningfully less studied and more publishable as a mechanism test.
- Top-Journal Potential: **High (for a field top journal) / Medium (top-5).** The pitch is sharper than Idea 1 because it answers *why* capitalization happens; it becomes top-5-relevant if you can convincingly rule out “private density is just SES” and show a clean mechanism pattern that survives aggressive checks.
- Identification Concerns: The core risk is **heterogeneous trends correlated with private-school supply** (e.g., richer areas both have more private schools and different post-2015 price trajectories). You need strong design discipline: boundary-pair fixed effects, pre-2015 event studies by private-density, and ideally historical (pre-2000) private-school presence as the moderator.
- Recommendation: **CONSIDER (as a second paper or as the mechanism spine inside Idea 1), conditional on: demonstrating moderator balance at boundaries; showing identical pre-trends by private-density; using pre-determined private-school measures (e.g., historical locations) rather than contemporaneous counts)**

---

**#3: Does Halving Class Sizes Capitalize into Housing Prices? Evidence from France’s Dédoublement Policy**
- Score: **58/100**
- Strengths: The question is genuinely new in this niche: class-size reforms are studied almost entirely through test scores, not revealed preference in housing markets. The rollout creates clear timing variation and large-scale administrative exposure.
- Concerns: Identification is the weak point: treatment is targeted to REP/REP+ areas that likely have **different housing trends, renewal programs, and compositional changes**, and “near an elementary school” is often a noisy proxy for actual school assignment/choice (elementary assignment can be less binding than collège). Staggered DiD in a setting with heterogeneous treatment effects invites specification fragility unless you use modern estimators and very transparent event studies.
- Novelty Assessment: **High (outcome novelty), but on a familiar policy family.** Many papers on class size and many on housing capitalization; the *intersection* is much less studied.
- Top-Journal Potential: **Low-Medium.** Even with perfect execution, top outlets may view it as “competent but not exciting” unless you (i) show a clear belief-vs-reality wedge (prices move even when achievement doesn’t), and (ii) nail assignment/first-stage salience (families actually perceive/expect class-size changes and can access them).
- Identification Concerns: Parallel trends between REP and non-REP neighborhoods is a major stretch; within-commune comparisons don’t guarantee comparability at the micro-neighborhood level. You also need to show **policy salience timing** (announcement vs implementation) and avoid contamination from concurrent REP-related reforms.
- Recommendation: **CONSIDER (conditional on: a boundary-based design around REP/REP+ elementary catchments or eligibility thresholds; strong event-study pre-trends; and a clear “first stage” showing realized class-size changes by school-year actually occurred as measured)**

---

**#4: Gateway to the Elite: How CPGE Proximity Shapes Local Housing Markets in France**
- Score: **42/100**
- Strengths: CPGEs are a distinctive French institution and “access to elite pipelines” is a compelling object with intuitive willingness-to-pay implications. Data on placements/quality is available and DVF is powerful.
- Concerns: As written, this is mostly **hedonic selection**: high-performing CPGEs sit in high-amenity, high-SES neighborhoods, and “within-commune” won’t purge the correlated unobservables that drive both CPGE quality and housing prices. Openings/closures are rare and likely endogenous (often responding to demand/local politics), so IV is unlikely to rescue credibility.
- Novelty Assessment: **Moderate.** The specific CPGE angle is less studied, but the underlying “elite school quality capitalizes into housing” is very well trodden, and without clean quasi-experimental variation it will read as another hedonic correlation.
- Top-Journal Potential: **Low.** Without a sharp shock (unexpected closures, admissions-rule changes, or boundary discontinuities tied to CPGE access), it is hard to see this clearing a top field-journal bar.
- Identification Concerns: Omitted-variable bias is first-order and likely sign-consistent; credible instruments are hard. Any quality changes are slow-moving and confounded with neighborhood change.
- Recommendation: **SKIP (unless you can locate a genuinely exogenous shock: e.g., sudden CPGE closure mandates, major national rule change affecting effective access, or a defensible boundary/assignment discontinuity)**

---

### Summary

This is a strong batch because Ideas 1 and 3 (especially 1) pair **unusually rich national data** with plausibly credible quasi-experimental variation and built-in placebo structure. I would pursue **Idea 1 immediately**, and treat **Idea 3** as either (i) the mechanism section that upgrades Idea 1 to a more top-journal narrative or (ii) a second paper once the baseline discontinuities are established. Ideas 2 and 4 are interesting objects but need substantially stronger identification to be competitive.

---

## Gemini 3.1 Pro

**Tokens:** 8948

Here is my evaluation of the research proposals, ranked from most to least promising. As requested, I have applied a highly critical lens, prioritizing mechanism-driven causal designs over standard ATE estimation and heavily penalizing flawed identification.

### Rankings

**#1: Idea 3: The Private School Escape Valve: How Outside Options Mediate the Capitalization of Education Priority Labels**
- **Score**: 78/100
- **Strengths**: Elevates a standard capitalization paper into a mechanism test, cleanly separating the "information/stigma" channel from the "assignment rigidity" channel. Exploiting private school density as a structural escape valve is a clever way to test competing stories.
- **Concerns**: A triple-difference boundary RDD is extremely demanding on statistical power. Furthermore, private school density is not randomly assigned, meaning high-density areas might have different underlying housing price trends.
- **Novelty Assessment**: High. While the cross-sectional observation exists (Fack & Grenet 2010), testing this causally with a policy shock to decompose the exact mechanism of capitalization is novel and pushes the frontier of the school choice literature.
- **Top-Journal Potential**: Medium-High. A top-5 or top field journal (like *AEJ: Economic Policy*) would find this exciting because it fits the winning architecture: "Puzzle → Design that isolates competing stories → Mechanism trace." It doesn't just measure an ATE; it explains *why* the ATE exists by separating information from regulation.
- **Identification Concerns**: The main threat is that neighborhoods with high private school density are fundamentally different (e.g., wealthier, different gentrification trends), which could violate the parallel trends assumption in the DiDisc component.
- **Recommendation**: PURSUE (conditional on: verifying sufficient transaction density at boundaries to power a triple-diff; establishing strict pre-trend checks across high/low private school areas).

**#2: Idea 1: What's in a Label? Education Priority Zones, School Quality Signals, and Housing Markets in France**
- **Score**: 58/100
- **Strengths**: The identification strategy (Boundary RDD + DiDisc) is exceptionally clean, and the built-in placebos provide a highly credible framework. The data is fully open and perfectly suited for the design.
- **Concerns**: The core research question is well-trodden; we already know parents value school quality and labels. It risks being a purely administrative exercise.
- **Novelty Assessment**: Low-Medium. It is essentially a national, quasi-experimental update to existing literature (e.g., Figlio & Lucas 2004; Fack & Grenet 2010). The method is an upgrade, but the economic question is not new.
- **Top-Journal Potential**: Low. This is the textbook definition of "technically competent but not exciting." As noted in the editorial appendix, standard RDDs with unsurprising signs on narrow outcomes without mechanism decomposition routinely lose out at top journals.
- **Identification Concerns**: Anticipation effects are the primary threat. If the 2015 reform was debated beforehand, housing prices might have adjusted prior to the official boundary changes, muddying the DiDisc.
- **Recommendation**: CONSIDER (as a baseline or first chapter, but pivot quickly to Idea 3 for the main contribution).

**#3: Idea 2: Does Halving Class Sizes Capitalize into Housing Prices? Evidence from France's Dédoublement Policy**
- **Score**: 42/100
- **Strengths**: Connects a massive, high-profile, €1.3 billion policy to a revealed-preference welfare measure (housing prices) rather than just test scores.
- **Concerns**: The identification strategy is fundamentally flawed, and the economic premise is shaky (parents are unlikely to buy a house solely for a 2-year class size reduction in grades 1 and 2).
- **Novelty Assessment**: Medium. Capitalization of class size specifically is rare, but the novelty does not overcome the severe design flaws.
- **Top-Journal Potential**: Low. The editorial appendix warns against "admitted identification failure." A staggered DiD comparing highly disadvantaged REP schools to non-REP schools will almost certainly fail parallel trends due to divergent neighborhood gentrification dynamics.
- **Identification Concerns**: Severe selection bias and parallel trend violations. REP and non-REP zones are on completely different socioeconomic trajectories; they are not valid counterfactuals for each other without a boundary RDD or strict matching.
- **Recommendation**: SKIP.

**#4: Idea 4: Gateway to the Elite: How CPGE Proximity Shapes Local Housing Markets in France**
- **Score**: 25/100
- **Strengths**: Focuses on a uniquely French, high-stakes institution with clear, publicly observable quality metrics.
- **Concerns**: The identification relies on outdated hedonic regressions, and the mechanism is practically flawed since 18-year-old CPGE students often rent small apartments or live in boarding houses rather than their parents buying family homes nearby.
- **Novelty Assessment**: Low. Hedonic pricing of school proximity is an old literature, and applying it to higher education without a credible shock is a step backward methodologically.
- **Top-Journal Potential**: Low. Papers relying on cross-sectional hedonics or underpowered IVs (rare school openings) do not survive modern peer review at top journals. It lacks the "hard constraints" diagnostics required for top-tier consideration.
- **Identification Concerns**: Massive omitted variable bias. Elite CPGEs (like Henri-IV or Louis-le-Grand) are located in historically elite, expensive neighborhoods. Controlling for "lycée quality" cannot isolate the CPGE effect from the deep spatial sorting of wealth.
- **Recommendation**: SKIP.

### Summary

This batch presents a classic trade-off between clean but boring designs (Idea 1) and interesting but flawed ones (Ideas 2 and 4). Idea 3 is the clear standout, as it elevates a standard capitalization exercise into a structural test of how private outside options mediate public policy, fitting the "mechanism trace" preferred by top journals. I strongly recommend focusing your institute's resources on Idea 3, using Idea 1's pristine empirical framework as the foundation to build the mechanism decomposition.

---

## Grok 4.1 Fast

**Tokens:** 7354

### Rankings

**#1: Idea 1: What's in a Label? Education Priority Zones, School Quality Signals, and Housing Markets in France**
- **Score**: 74/100
- **Strengths**: Exceptional identification via national-scale boundary RDD with DiDisc reform shock and built-in placebos (non-REP and REP boundaries), leveraging universe DVF data for precise housing capitalization estimates; novel pivot to government label effects (vs. actual quality) with potential channel exploration.
- **Concerns**: Risks being viewed as a scaled-up extension of Fack & Grenet (2010) rather than a field-changer; short post-reform window (2015-2024) may limit long-run insights unless explicitly framed as short-run.
- **Novelty Assessment**: Moderately studied—one seminal Paris paper (Fack & Grenet 2010), but no national analysis, no reform shock exploitation, and no explicit label-vs-quality distinction.
- **Top-Journal Potential**: Medium (A top-5 journal could bite if packaged as a "label signal → housing capitalization chain" with welfare implications for priority zoning costs, akin to editorial wins on mechanism traces and universe-scale RDDs; national multi-boundary replication beats single-city priors).
- **Identification Concerns**: Parallel trends must hold in pre-2015 DiDisc (gating per appendix); boundary density discontinuities could signal sorting, requiring manipulation tests.
- **Recommendation**: PURSUE (conditional on: strong pre-trends/placebo diagnostics; mechanism traces like parent search or school choice data)

**#2: Idea 3: The Private School Escape Valve: How Outside Options Mediate the Capitalization of Education Priority Labels**
- **Score**: 70/100
- **Strengths**: Clever triple-difference boundary RDD decomposes capitalization mechanism (assignment rigidity vs. neighborhood signals) using private school density as a quasi-moderator, building on the same strong REP reform data as Idea 1.
- **Concerns**: Private school density is likely endogenous (correlated with wealth/socioeconomics), risking omitted variables; incremental to Idea 1 or Fack & Grenet if pursued separately.
- **Novelty Assessment**: Somewhat studied—Fack & Grenet (2010) showed cross-sectional attenuation in Paris, but no causal reform-shock test or national boundary design.
- **Top-Journal Potential**: Medium (Fits editorial pattern of "mechanism decomposition" winners like EPC info-vs-regulation RDDs; could excite if it rules out/in assignment channel with clear welfare pivot, but niche France setting limits unless framed as generalizable outside-option test).
- **Identification Concerns**: Triple-diff assumes private density orthogonal to unobservables (plausible threat: richer areas have more privates and flatter gradients); needs balance on private density across boundaries.
- **Recommendation**: CONSIDER (conditional on: robustness to private density instruments or fixed effects; pursue after Idea 1)

**#3: Idea 2: Does Halving Class Sizes Capitalize into Housing Prices? Evidence from France's Dédoublement Policy**
- **Score**: 65/100
- **Strengths**: Highly novel revealed-preference angle on class sizes (unexplored in vast literature focused on student outcomes), with policy bite (€1.3B cost) and dose-response from phased rollout.
- **Concerns**: Staggered DiD by REP status risks heterogeneous trends (disadvantaged areas baseline differences); no RDD precision, harder to sell as "bulletproof" vs. boundary designs.
- **Novelty Assessment**: Highly novel—no papers link class size reductions to housing capitalization, distinct from mixed dédoublement student effect evaluations.
- **Top-Journal Potential**: Medium-Low (New object is promising per appendix, with potential surprise if parents value despite null student effects; but standard DiD ATE on "familiar policy" without deep chain risks "competent but not exciting" rejection).
- **Identification Concerns**: REP/REP+ selection on disadvantage confounds trends (appendix flags group DiD pitfalls); needs event-study pretrends and secondary-school placebos to gate.
- **Recommendation**: CONSIDER

**#4: Idea 4: Gateway to the Elite: How CPGE Proximity Shapes Local Housing Markets in France**
- **Score**: 53/100
- **Strengths**: Fresh niche question on elite education gateways (uniquely French CPGEs), with public quality data for hedonic variation.
- **Concerns**: Weak identification—no sharp discontinuities or policy shocks, relying on hedonic/IV with rare openings/closures (underpowered); outcome misalignment (proximity premium conflates access with prestige).
- **Novelty Assessment**: Highly novel—zero prior papers on CPGE-housing link.
- **Top-Journal Potential**: Low (Niche institution without clean causal design or first-order stakes; appendix notes hedonic/rare-event IVs lose to precise RDD/DiDs, reads as descriptive unless major surprise).
- **Identification Concerns**: Endogenous location (high-quality CPGEs in desirable areas); rare shocks limit power, no pre-trends or exogeneity for IV.
- **Recommendation**: SKIP

### Summary
This is a strong batch of feasible, data-rich proposals exploiting French open admin data, with clean RDDs elevating Ideas 1-3 above typical policy evals. Idea 1 stands out for top-journal-ready identification and scale—pursue it first as the foundational paper, potentially spawning Idea 3; skip Idea 4 due to fatal ID flaws. Overall quality skews promising but capped by niche setting (few global implications).

