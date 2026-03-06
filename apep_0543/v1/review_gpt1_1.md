# GPT-5.4 (R1) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-06T19:30:21.364281
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 20718 in / 5795 out
**Response SHA256:** 0cd81151f7edc954

---

This paper asks an important and policy-relevant question: whether rent control is capitalized into residential asset prices. The setting is interesting, the use of administrative transaction data is promising, and the paper is commendably candid about important limitations, especially the lack of pre-treatment data for Paris and Lille and the heterogeneity of effects across cities. The main empirical message is also calibrated more honestly than in many papers: the identified-sample effect is modest, concentrated in Bordeaux, and not robust under randomization inference.

That said, for a top general-interest journal or AEJ: Economic Policy, the current version is not publication-ready. The main obstacles are not prose but scientific: the effective number of treated policy shocks is very small; the inference does not support the paper’s headline precision; the event-study evidence does not adequately test the identifying assumptions of the triple-difference design; and the substantive interpretation leans too heavily on a pooled estimate that appears to be driven by one city. In its current form, the paper is best viewed as a suggestive first pass rather than a convincing causal estimate of a general capitalization effect.

## 1. Identification and empirical design

### A. Core DDD idea is sensible, but credibility hinges on a demanding relative-trends assumption
The design compares small apartments (“investment-type”) to houses/large apartments (“owner-occupier-type”) in treated vs untreated cities before and after adoption (Section 5). This is a reasonable strategy in principle because the policy should affect rental-exposed properties more than owner-occupied ones.

However, the identifying assumption is strong: absent rent control, the **investment-vs-owner price gap** would have evolved similarly in treated and control cities. This is weaker than level parallel trends, but still far from innocuous in this context. Small urban apartments and houses/large apartments likely experienced different post-pandemic demand shifts, remote-work effects, compositional changes, and investor-demand shocks that varied systematically across cities. Those are exactly the kinds of shocks that can load onto the DDD term.

The paper acknowledges this in Section 5.3 and Section 7.3, but the current evidence does not convincingly rule it out.

### B. The identified sample is appropriately defined, but still very thin for dynamic identification
Excluding Paris and Lille from the main analysis is the right move. It is a major strength that the paper does not pretend those cities are causally identified (Sections 1, 5.2, Appendix B).

But even within the “identified sample,” pre-treatment support is limited:

- Plaine Commune has only 3,612 pre observations;
- Lyon-Villeurbanne 4,196;
- Est Ensemble 7,760;
- Montpellier 12,285;
- Bordeaux 13,281 (Appendix Table `tab:predata`).

More importantly, the issue is not total observations but **pre-treatment time support**. Several cohorts have less than two years of pre data, and the event study effectively has only one informative lead bin beyond the reference period.

### C. The event study does not test the relevant DDD identifying assumption
This is a central weakness.

The paper estimates event studies **separately for investment-type and owner-occupier-type properties** (Section 5.4; Figure 2). But the identifying assumption for the triple-difference is about the **difference between these two types within treated relative to control cities**, not about each series separately. Showing that each type lacks a significant pre-trend is not equivalent to showing that the relative gap is stable.

What is needed is a **DDD event study**: coefficients on event time interacted with treatment and investment exposure, plotted relative to a reference pre period. As written, Figure 2 is not the right diagnostic for the main identifying assumption.

This matters especially because the headline result is not visible in the type-specific event studies and emerges only in the interacted specification. That makes it even more important to validate the dynamic triple interaction directly.

### D. Treatment heterogeneity and “bindingness” are central, but not observed
The paper’s mechanism is explicitly about whether the rent ceiling binds (Sections 2.4, 3, 7.1). Yet the analysis does not observe:

- actual rents,
- local reference rents,
- furnishing status,
- building vintage,
- neighborhood ceiling category,
- or a property-level measure of expected regulatory bite.

That omission creates a major interpretation gap. The paper argues the strongest effects should appear where regulation binds most, but bindingness is inferred indirectly from city-level patterns and unit size. This is not fatal, but for a paper centered on capitalization of a rent cap, the absence of even a coarse property-level “bite” proxy is a substantial limitation. At minimum, the paper should merge local reference-rent schedules and construct a treatment-intensity proxy based on transaction characteristics and location.

### E. Control group selection is ad hoc and not fully justified
The control group is 20 large non-adopting cities chosen by population threshold (Section 4.2; Appendix A). That may be practical, but it does not establish comparability on pre-policy dynamics in the relevant relative price gap.

Given the small number of treated groups, control-city composition matters a lot. I would expect at least one of the following:

- matched control selection based on pre-policy housing market characteristics,
- reweighting / entropy balancing at the city level,
- leave-one-control-city-out or regional leave-out checks,
- or synthetic-control-style validation of pre-trends for the investment-owner gap.

At present, the control group feels more convenience-based than design-based.

### F. City-level heterogeneity undermines the pooled causal interpretation
The pooled identified-sample DDD is modest and only significant with controls (Table 1, col. 4), while city-by-city estimates show:

- Bordeaux: large and significant,
- Montpellier: borderline,
- Plaine Commune / Est Ensemble / Lyon-Villeurbanne: null (Table 2).

Dropping Bordeaux reduces the pooled DDD from -0.055 to -0.031 and makes it clearly insignificant (Table 3). This is not a mere robustness wrinkle; it substantially changes what can be claimed. The evidence is not that French rent control generally depressed property values. The evidence is that **one city, plausibly with high bite, shows a negative relative price shift**.

That is still potentially interesting, but the design and claims should be reorganized around that fact.

## 2. Inference and statistical validity

This is the most serious problem in the paper.

### A. The current standard errors are not appropriate for the effective level of treatment variation
Main specifications cluster at the commune level (Section 5.6; Table 1 notes). But the policy varies at the **city-group adoption level**, not at the transaction or commune level in the usual sense. Communes within Plaine Commune or Est Ensemble share the same treatment timing and policy shock. Clustering at the commune level therefore risks substantial overstatement of precision.

The paper itself recognizes that “the effective number of treatment clusters is small” (Section 5.6). I agree. But the pragmatic response adopted here is not sufficient.

For the identified sample, there are effectively only **five treated city groups**. That is too few for conventional cluster-robust asymptotics to be reassuring, especially when the headline result relies on a p-value of 0.017 under commune clustering.

At minimum, the paper needs:
- inference at the city-group level where possible,
- wild cluster bootstrap procedures tailored to few treated clusters,
- and/or a Conley-Taber / randomization-based design-appropriate inference strategy.

### B. Randomization inference directly contradicts the paper’s headline significance
The paper’s most important inferential fact is not the 0.017 p-value; it is that the randomization inference does **not reject** for either the uncontrolled or controlled DDD:
- uncontrolled RI p = 0.46,
- controlled RI p = 0.65
(Section 6.6; Appendix B.2).

For a paper with very few treated groups, that should substantially dominate the interpretation. Instead, the abstract and conclusion still foreground the p = 0.017 result. I do not think that is an appropriate weighting of the evidence.

If one inferential procedure tailored to sparse treatment variation says “significant” and another says “not unusual under placebo timing,” the paper cannot present the estimate as established in a publication-ready way. At the very least, the abstract and framing should be revised so the central message is: **point estimates are negative and suggestive, but inference is weak and does not survive randomization-based testing**.

### C. The randomization inference design itself is not ideal
Even setting aside power, the RI procedure is not especially compelling. Treatment dates are shifted by ±1 to 3 years within a short 2020H2–2024 window (Appendix B.2). That placebo design can create unnatural timing configurations and does not mimic the actual policy assignment process. More importantly, the placebo distribution has mean -0.040, while the observed uncontrolled estimate is -0.055. That is concerning: it suggests the design may mechanically generate negative coefficients even under placebo timing.

A more persuasive RI exercise would permute treatment **assignment across candidate cities/city-groups**, or use adoption timing draws constrained by the actual staggered rollout structure, rather than arbitrary date shifts.

### D. The event study has too little pre-treatment support to validate assumptions
The paper notes only one meaningful lead bin (`k=-2`) beyond the omitted period, and that it is populated only by later adopters (Section 6.2). That makes the “no pre-trend” statement very weak. A non-significant single lead with short pre-periods is not strong support for parallel trends.

### E. Sample sizes are coherent, but the key variation is much smaller than N suggests
The paper reports large transaction counts, which is good, but the effective identifying variation is at the city-group × time × property-type level. The very large micro N should not be allowed to create a false sense of precision. In this design, the relevant sample size for inference is much closer to the number of treated policy groups than to 451,685 transactions.

### F. Staggered-adoption concerns are partially addressed but not fully resolved
It is good that the paper does not rely only on naive TWFE and reports stacked DDD checks (Sections 5.6, 6.6). That said, the claim that DDD is “less susceptible” to negative weighting does not eliminate the need for careful treatment of staggered identification. The stacked approach is helpful and reassuring on point estimates, but it does not solve the central small-cluster inference problem.

## 3. Robustness and alternative explanations

### A. Some robustness checks are useful, but they do not address the main threat
The paper provides:
- excluding COVID quarters,
- post-COVID adopters only,
- stacked DiD,
- dropping room controls,
- leave-one-out,
- size-gradient analysis
(Sections 6.5–6.6).

These are all useful. But most of them speak to **specification stability**, not to the core concern that unobserved city-specific shocks may differentially affect small vs large units around adoption.

### B. Bordeaux-specific confounds remain underexplored
The paper itself notes potential Bordeaux-specific confounds such as:
- long-run boom dynamics,
- high-speed rail effects,
- tourism/Airbnb regulation,
- demographics
(Section 7.3).

Because Bordeaux drives the pooled result, these possibilities need much more serious treatment. For example:

- Was there contemporaneous short-term rental regulation in Bordeaux affecting small apartments?
- Were investor taxes or local housing policies changing around 2022?
- Did small vs large apartment prices already begin diverging before adoption relative to controls?
- Does Bordeaux remain significant relative to a narrower set of comparable southwestern cities?

Without deeper work here, the Bordeaux result remains suggestive rather than clean.

### C. Composition and selection into transaction are not fully addressed
The paper discusses this well conceptually (Sections 3.1, 7.3, 7.4), but empirical treatment is limited. If policy affects which units come to market, the observed transaction-price effect may reflect changing composition rather than capitalization of the stock.

Adding surface and room controls helps with observable composition, but not with unobserved quality, occupancy status, tenant in place, furnishing, building condition, or seller type. Since the main estimate becomes significant only after controls, composition concerns should be treated as first-order.

At minimum, I would want:
- tighter within-cell comparisons (e.g., commune × quarter × room-count × size-band),
- hedonics with richer fixed effects,
- repeated-sales or parcel/building-level methods if possible,
- and evidence on transaction counts by fine property type, not just the investment-share figure.

### D. The mechanism evidence is suggestive, not decisive
The apartment-size gradient (Table 4) is probably the strongest result in the paper. It is coherent with the capitalization story.

Still, it is not uniquely diagnostic. Small apartments may be more sensitive to:
- investor demand shifts,
- Airbnb regulation,
- financing conditions,
- student-market shocks,
- migration changes,
- or pandemic-related amenity repricing.

The current draft sometimes treats the gradient as “precisely what the model predicts” and therefore strong mechanism validation. That overstates what the test can do absent direct evidence on rent-ceiling bite.

### E. External validity is limited and should be stated even more sharply
The conclusion already notes heterogeneity and concentration in Bordeaux/Paris. I would go further: the paper does not identify a general effect of rent control in France. It identifies, at best, suggestive evidence of capitalization in a subset of tighter markets.

## 4. Contribution and literature positioning

### A. The topic is important and potentially publishable
This is a meaningful question with broad relevance: asset-price capitalization is a major but understudied margin in rent-control debates. The French setting is interesting, and the use of transaction microdata is promising.

### B. The paper’s contribution relative to existing work is plausible but not yet field-shaping
The paper distinguishes itself from decontrol papers (Autor, Palmer, Pathak 2014; Sims 2007) and from Berlin work on contemporary rent regulation. That is fine. But for a top journal, the contribution currently looks incremental because the empirical design is not convincing enough to settle the core question.

### C. Methodological literature on inference with few treated groups should be strengthened
A key omission is the literature on DiD/statistical inference when there are few policy changes. The paper cites Goodman-Bacon, de Chaisemartin and D’Haultfoeuille, Callaway-Sant’Anna, Sun-Abraham, but not the small-cluster/few-treated inference literature that is central here.

Concrete citations to add:
- **Bertrand, Duflo, and Mullainathan (2004)** — serial correlation and DiD inference.
- **Conley and Taber (2011)** — inference with few policy changes.
- **MacKinnon and Webb (2017, 2020)** — wild bootstrap / inference with few treated clusters.
- Depending on implementation, also **Ferman and Pinto (2019)** on inference in DiD with small numbers of groups.

These are not cosmetic adds; they are directly relevant to whether the main estimate is statistically credible.

### D. If available, the France-specific policy literature should include more on compliance and local bite
Because the paper’s interpretation depends on bindingness and compliance, it should engage more directly with empirical work on how binding the French caps actually were by city/neighborhood/property type. If such papers exist beyond those cited, they are essential.

## 5. Results interpretation and claim calibration

### A. The paper is more honest than average, but still overstates the certainty of the main effect
The abstract leads with: “The pooled DDD estimate is -0.093 with controls (p = 0.017).” But in the same abstract it also states RI does not reject (p = 0.46). That combination should not be presented as a clean positive result.

Given the design, a more accurate summary would be:
- negative point estimates in the identified sample,
- stronger effects in Bordeaux,
- suggestive size-gradient evidence,
- but weak inferential support overall because randomization-based tests do not reject and effects are concentrated in one city.

### B. “Does not depress property values on average” vs “headline result” is somewhat inconsistent
Section 6.1 begins: “Rent control does not depress property values on average.” But then the paper immediately presents a 9.3% negative DDD estimate as the headline result. The text oscillates between “null overall average” and “significant headline capitalization effect.” The actual evidence supports a more restrained message: no robust average effect across cities, but suggestive differential price declines for rental-exposed units in some markets.

### C. The Paris discussion should be further demoted
The paper is appropriately cautious that Paris is not causally identified (Sections 1, 6.3, 7.2). Still, the Paris estimate and its implied welfare numbers take up substantial rhetorical space. Because Paris lacks any pre-treatment observations, these results should be sharply separated from the causal analysis, perhaps moved entirely to an appendix or a brief descriptive subsection. In the current draft, they risk dominating interpretation despite not being identified.

### D. Welfare calculations are not supported by the evidence
Section 7.5 offers back-of-envelope wealth-transfer calculations for Bordeaux and especially Paris. Given:
- weak inference in the identified sample,
- one-city concentration,
- no direct measure of bindingness,
- no stock-wide effect estimate,
- transaction-selection concerns,
- and non-causal Paris estimates,

these welfare calculations are too speculative for the current empirical base. They are likely to be viewed as overreach by top-journal readers.

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

#### 1. Rebuild inference around the true level of treatment variation
- **Issue:** Commune-clustered SEs are not credible with only five treated city-groups; RI does not reject.
- **Why it matters:** The paper cannot pass with invalid or overstated statistical significance.
- **Concrete fix:** Re-estimate main specifications using inference procedures suited to few treated clusters: wild cluster bootstrap at the city-group level where feasible, Conley-Taber-type inference, and a redesigned randomization/permutation test based on reassignment across candidate cities or adoption cohorts. Reframe the main conclusions around those results, not around commune-clustered p-values.

#### 2. Estimate a proper DDD event study
- **Issue:** Current event studies by property type do not test the identifying assumption of the triple-difference.
- **Why it matters:** The key causal assumption concerns the treated-control evolution of the investment-owner gap.
- **Concrete fix:** Estimate and plot an event-study specification with event-time × treated × investment exposure interactions. Show pre-period coefficients for the triple interaction, with appropriate simultaneous confidence bands if possible.

#### 3. Address Bordeaux dependence directly
- **Issue:** The main result is largely driven by Bordeaux.
- **Why it matters:** The pooled claim of a general effect is not supported if one city drives everything.
- **Concrete fix:** Reframe the paper explicitly as heterogeneity-first; add Bordeaux-focused diagnostics against more comparable controls, pre-trend validation for the relative price gap, and discussion of contemporaneous Bordeaux-specific policies affecting small apartments.

#### 4. Substantially temper the headline claims
- **Issue:** The abstract and conclusions still foreground a significant pooled estimate despite non-rejecting RI and one-city concentration.
- **Why it matters:** Claim calibration must match evidentiary strength.
- **Concrete fix:** Rewrite the abstract/introduction/conclusion so the central takeaway is “suggestive, heterogeneous, and inferentially weak,” not “headline 9% capitalization effect.”

### 2. High-value improvements

#### 5. Incorporate treatment-intensity / bindingness measures
- **Issue:** The mechanism depends on regulatory bite, but bite is not observed.
- **Why it matters:** Without intensity, the paper cannot distinguish rent-control capitalization from other shocks to small urban units.
- **Concrete fix:** Merge local reference-rent schedules and construct property-level or neighborhood-level bite proxies using room count, location, vintage categories where possible, and perhaps external rent data. Show larger effects where predicted bite is stronger.

#### 6. Improve control-group design
- **Issue:** Control cities are selected ad hoc.
- **Why it matters:** With few treated groups, control choice can drive results.
- **Concrete fix:** Use matched/reweighted controls based on pre-treatment housing-market characteristics and pre-trends in the investment-owner price gap; report sensitivity to alternative control sets.

#### 7. Tighter composition controls / more demanding fixed effects
- **Issue:** Composition shifts remain a major alternative explanation.
- **Why it matters:** The main estimate becomes significant only after controls.
- **Concrete fix:** Add richer comparisons such as commune × quarter × property-type-cell fixed effects, narrow size-band analyses, apartment-only specifications with more granular room/surface interactions, and if feasible repeated-sales or building-level approaches.

#### 8. Strengthen transaction-selection analysis
- **Issue:** Transaction prices may reflect selection into sale.
- **Why it matters:** A composition effect can mimic capitalization.
- **Concrete fix:** Examine effects on transaction counts by fine property category, time on market if available externally, and whether observed characteristics of sold units shift after adoption within treated cities relative to controls.

### 3. Optional polish

#### 9. Move non-identified Paris/Lille analyses out of the main narrative
- **Issue:** Non-causal estimates currently receive disproportionate attention.
- **Why it matters:** They risk confusing the reader about what is actually identified.
- **Concrete fix:** Keep them in an appendix or clearly labeled descriptive section, with no welfare extrapolation from Paris unless causal identification is improved.

#### 10. Expand the methodological literature discussion
- **Issue:** Small-number-of-treated-groups inference literature is under-cited.
- **Why it matters:** It is directly relevant to the paper’s central credibility problem.
- **Concrete fix:** Add and engage Bertrand-Duflo-Mullainathan (2004), Conley-Taber (2011), MacKinnon-Webb, and related work.

## 7. Overall assessment

### Key strengths
- Important question with broad policy relevance.
- Interesting institutional setting and high-quality administrative transaction data.
- Appropriate decision to exclude Paris/Lille from the identified main sample.
- Honest acknowledgment of heterogeneity, limited pre-treatment support, and non-rejecting randomization inference.
- Size-gradient result is suggestive and potentially informative.

### Critical weaknesses
- Inference is not credible at current headline precision given only five treated city-groups.
- Randomization inference fails to reject, undermining the main statistical claim.
- Event-study evidence does not test the actual DDD identifying assumption.
- Main pooled result appears driven by Bordeaux.
- Bindingness/mechanism is not directly measured.
- Control-group construction and alternative explanations are not yet sufficiently addressed.

### Publishability after revision
There is a potentially worthwhile paper here, but it needs substantial redesign of inference, sharper identification diagnostics, and more disciplined claim calibration. The current draft does not yet meet the standard of a top general-interest journal or AEJ: Economic Policy. The main result is too fragile and too weakly identified to support the current framing. If the authors can rebuild inference appropriately, provide a true DDD event study, and either validate the Bordeaux-driven effect much more convincingly or reframe the paper around heterogeneity and treatment intensity, the project could become publishable in a strong field journal and perhaps eventually competitive for a policy journal. In its present form, however, the revisions required are fundamental rather than incremental.

DECISION: REJECT AND RESUBMIT