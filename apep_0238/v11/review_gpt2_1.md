# GPT-5.4 (R2) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-27T01:56:16.392152
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 14487 in / 6126 out
**Response SHA256:** 6f400f2d5d4a0ca8

---

This paper studies whether labor-market scarring differs across recessions by comparing state-level employment dynamics after the Great Recession and the COVID-19 recession. The core claim is that “demand recessions scar, supply recessions don’t,” and that the mechanism is a “duration trap”: prolonged nonemployment in the Great Recession versus temporary layoffs and recall during COVID. The paper is clearly motivated, asks an important macro-labor question, and has some appealing features: same 50 states in both episodes, transparent episode-specific exposure measures, and an effort to move beyond documenting persistence toward mechanism.

That said, in its current form I do not think the paper is publication-ready for a top general-interest journal or AEJ: Economic Policy. The central empirical evidence is weaker than the framing suggests, the main Great Recession “scarring” estimate is not statistically persuasive, the mechanism exercise relies on post-treatment controls in a way that cannot bear the causal interpretation assigned to it, and the cross-episode comparison is too confounded to support the title-level claim. I think the project is potentially salvageable, but it would require substantial redesign and recalibration.

## 1. Identification and empirical design

### A. The paper’s strongest design feature is within-episode cross-state variation, not the cross-episode comparison
The manuscript itself appropriately notes in the Introduction and Section 4.1 (“What this comparison can and cannot identify”; “Why These Two Episodes”) that the cross-episode comparison is not a clean causal estimate of demand versus supply shocks. That caveat is correct and important. Unfortunately, the title, abstract, and conclusion overrun it. What the design can identify is:

- within-Great-Recession associations between housing-boom exposure and later employment;
- within-COVID associations between sectoral/Bartik exposure and later employment;
- a descriptive contrast in the persistence of those gradients across two very different episodes.

What it cannot cleanly identify is the causal effect of “demand recessions” versus “supply recessions” as such, because the episodes differ simultaneously in:
- fiscal policy scale and timing,
- monetary environment and ZLB conditions,
- temporary layoff/recall institutions,
- sectoral composition of the shock,
- public-health restrictions,
- remote work feasibility,
- household balance sheets and wealth effects,
- labor supply responses (health, caregiving, schooling disruptions).

The paper says this, but then repeatedly interprets the contrast as evidence that the nature of the shock is the key causal force. For publication, the causal claim has to be narrowed or the design materially strengthened.

### B. Great Recession identification is plausible but notably imperfect
Section 4.2 uses state-level 2003Q1–2006Q4 house price growth as exposure, following Mian-Sufi style logic and instrumenting with Saiz supply elasticity. This is the most credible part of the design, but there are several unresolved issues.

#### 1. Pre-trends are not benign
The paper acknowledges in Section 8 that a 36-month pre-trend regression shows differential trends among high-HPI states (\(p=0.009\)). This is a major issue, not a footnote. If high-boom states were already on differential employment trajectories before the recession peak, then cross-state post-peak differences are not easily interpretable as scarring rather than continuation/reversal of pre-existing dynamics tied to construction booms, migration, and local cyclical exposure.

The manuscript argues that this is “plausible” because the boom itself raised employment. True, but that does not solve the identification problem; it sharpens it. The same force generating the treatment may also generate nonparallel outcome dynamics.

A single 12-month pre-trend check is not sufficient. For this design to be credible, the paper needs a much fuller event-time display of pre-period coefficients and a design that explicitly absorbs differential pre-trends or conditions on richer pre-boom covariates. As written, the baseline OLS specification is vulnerable to omitted local growth dynamics.

#### 2. The result appears concentrated in a handful of “sand states”
Table 6, Panel C shows that dropping Nevada, Arizona, Florida, and California attenuates the coefficient from \(-0.057\) to \(-0.025\) and renders it even less informative. That is substantively important. If the result is largely a “sand states” phenomenon, the paper should say so clearly and investigate whether the mechanism is really general labor-market hysteresis or something more specific to housing/construction overhang, mortgage distress, and Sun Belt boom-bust dynamics.

Right now the manuscript interprets this as supporting the mechanism because the largest shock should have the largest scarring. Perhaps. But it also means the evidence for a broad demand-recession mechanism outside those states is weak.

#### 3. The IV evidence is only supportive and weaker than the text implies
The Saiz IV first stage is reported as \(F=11.4\) (Section 5.1; Appendix IV). This is not obviously fatal, but it is not strong enough to lean on heavily, especially with 50 observations and potentially heterogeneous first-stage strength. Moreover, the exclusion restriction is far from trivial: geographic housing supply elasticity may be correlated with longer-run urban growth trajectories, industrial composition, migration, and agglomeration forces that can independently affect labor-market recovery. The paper mentions the IV as “supporting evidence,” which is the right tone, but elsewhere it is used as if it resolves the pre-trend concern. It does not.

### C. COVID Bartik identification requires much more care
The COVID exposure is a state-level shift-share measure using 2019 industry shares and leave-one-out national industry employment changes (Section 4.2). This is a common starting point, but for a top-field or general-interest outlet the identification discussion is currently too thin.

Key concerns:

#### 1. Exogeneity of industry shares is not defended
Industry composition in 2019 is not random. States more exposed to leisure/hospitality, tourism, energy, or large metros differ systematically in amenities, urban density, public-health restrictions, remote-work potential, housing markets, and migration patterns. These factors may independently predict the path of recovery.

The paper includes only log employment, pre-trend growth, and census region fixed effects, with an added robustness including construction/manufacturing shares. That is not enough for a Bartik design in this context. At minimum, the paper should address:
- pre-COVID trends by Bartik exposure,
- remote-work exposure,
- urbanization/density,
- initial virus severity and shutdown intensity,
- tourism dependence,
- demographic composition,
- state policy responses.

#### 2. Shift-share inference literature is under-engaged
A modern Bartik paper needs to grapple with the identifying variation and inference issues emphasized by Adão, Kolesár, and Morales (2019), Goldsmith-Pinkham, Sorkin, and Swift (2020), and Borusyak, Hull, and Jaravel (2022). The current paper cites Borusyak et al. and Goldsmith-Pinkham et al. for construction, but does not use the framework to justify identification or inference. In particular, with only 50 states and a common national shock vector, one wants a clearer statement of whether identification is coming from shares, shocks, or both, and what the relevant sampling uncertainty is.

#### 3. “Full recovery” is relative, not absolute
The paper interprets a zero exposure gradient at months 24–48 as “full recovery.” More precisely, it shows that states with worse predicted COVID exposure had, by that window, no systematically worse employment outcomes relative to less exposed states. That is a relative result, not evidence that there was no aggregate scarring, compositional change, participation loss, or sectoral reallocation.

### D. The pooled interaction is not meaningful as presented
Section 5.3 properly says the pooled interaction is hard to interpret because the outcome windows differ across episodes. I would go further: the pooled specification in Table 3 does not add much and may mislead. If the outcomes are averaged over months 48–120 for one episode and 24–48 for the other, the interaction coefficient is not a clean test of “greater scarring” in any comparable unit. I would recommend dropping this unless the authors harmonize the estimand.

### E. Timing and estimand comparability are a serious design problem
The paper’s “single estimand” compares:
- Great Recession: average outcome over months 48–120 post-peak;
- COVID: average outcome over months 24–48 post-peak.

This is understandable given data availability, but it weakens the central comparison materially. A non-result over 24–48 months after COVID is not directly comparable to a negative estimate over 48–120 months after the Great Recession. If the claim is about persistence asymmetry, the comparison should be placed on a more harmonized footing:
- same horizons since peak,
- same horizons since trough,
- same horizons since employment reattains some benchmark,
- or a clearly justified dynamic summary metric.

As written, the central asymmetry is partly a comparison of different windows.

## 2. Inference and statistical validity

This is the most serious concern.

### A. The headline Great Recession result is not statistically persuasive
The abstract highlights a Great Recession scarring coefficient of \(-0.057\) with permutation \(p \approx 0.13\). Table 1 reports HC1 SE 0.0467. This is not conventionally significant by either asymptotic or permutation standards. For a top journal, a central headline result that is both economically modest and statistically inconclusive cannot bear the weight of the paper’s title and policy claims.

The manuscript repeatedly compensates by appealing to:
- early-horizon LP significance,
- supportive IV,
- a horse race,
- mechanism attenuation.

But those do not substitute for a statistically convincing main long-run estimate.

### B. The inference framework is not fully justified
The paper states that permutation inference with random reassignment of the exposure measure is the primary device because \(N=50\). This may be attractive, but the exact validity of permutation tests depends on exchangeability conditions that are not discussed. With:
- region controls,
- spatially clustered exposures,
- strongly structured economic geography,
- potentially non-exchangeable states,

it is not obvious that random reassignment across all 50 states delivers exact finite-sample validity. At minimum, the paper should explain the permutation scheme in detail and justify why the null distribution is valid. If reassignment ignores the exposure-generating process or geographic structure, the reported permutation \(p\)-values may not have the interpretation claimed.

Relatedly, the number of permutations is inconsistent across tables: Section 4.4 says 2,000 random reassignments, while Table 6 and Appendix Table A1 report 1,000. This needs to be made consistent.

### C. Statistical significance markings are inconsistent with the paper’s own inference claims
Table 4 (mechanism table) uses significance stars based on HC1 standard errors, but the text says conventional significance at longer horizons is limited and references permutation inference. There are visible inconsistencies:
- In Table 4, Great Recession \(h=6\) is *** with SE 0.411, but \(h=12\) has no stars despite 1.349/0.941 ≈ 1.43, which would be marginal at best.
- The text says only \(h=3,6,12\) achieve conventional significance under permutation inference for the Great Recession mechanism; Table 4 does not report permutation \(p\)-values.
- Appendix Table A1 reports permutation \(p\)-values for employment LPs, not unemployment LPs.

The inference conventions need to be unified. A paper cannot oscillate between HC1 stars, permutation p-values, and visual patterns depending on which is favorable.

### D. Multiple testing / horizon-by-horizon interpretation remains a concern
The paper says the single-estimand approach avoids multiple-testing concerns, but then leans heavily on dynamic LP significance at selected horizons. If the dynamic evidence is substantively important, the paper should either:
- adjust for multiple-horizon inference,
- pre-specify a small set of key horizons and stick to them,
- or present simultaneous confidence bands.

Right now the dynamics are used narratively without a coherent inferential framework.

### E. Sample size and leverage require more diagnostic work
With 50 states and several controls, results may be fragile to leverage and influential observations. Given the attenuation when dropping four states, the paper should report:
- leverage/influence diagnostics,
- leave-one-out or leave-k-out robustness,
- robust regression or jackknife checks.

For top-journal standards, these are especially important when the sample is small and exposure is highly concentrated.

## 3. Robustness and alternative explanations

### A. Existing robustness is not sufficient
The paper does include useful checks:
- alternative averaging windows,
- adding construction/manufacturing shares,
- dropping sand states.

But these are not enough given the design’s vulnerabilities.

Needed robustness for the Great Recession side:
- richer pre-boom and pre-recession controls,
- explicit event-study pre-trends,
- controls for construction share, debt growth, credit supply, migration, population changes, foreclosure intensity,
- leave-one-region-out and leave-one-state-out checks,
- weighting vs unweighted regressions,
- population employment rate rather than payroll employment level changes.

Needed robustness for the COVID side:
- controls for state shutdown stringency,
- pre-pandemic industry trends,
- density/urbanization,
- remote-work feasibility,
- tourism share,
- initial infection severity,
- fiscal take-up / PPP intensity if mechanism claims rely on match preservation.

### B. Mechanism claims are not adequately distinguished from reduced form
The paper’s mechanism section overstates what can be learned from the available data.

#### 1. National aggregate series do not identify the state-level mechanism
Figure 4 (national long-term unemployment and temporary layoffs) is useful background, but it is not evidence that state-level cross-sectional Great Recession scarring operated through duration in the same states exposed to HPI booms. National patterns can motivate a mechanism; they cannot test it in this design.

#### 2. State unemployment-rate persistence is an imperfect proxy for unemployment duration
Section 6 uses state unemployment-rate responses as a proxy for duration accumulation. But unemployment rate persistence is not the same as duration. It conflates inflows, outflows, participation, migration, and compositional shifts. If the central mechanism is duration, the paper needs either:
- direct state-level duration measures,
- flows data,
- long-term unemployment shares at state level,
- or much more careful language about proxies.

#### 3. The attenuation exercise is not causal mediation
Table 5 is the weakest part of the paper conceptually. Adding unemployment at \(h=24\) or \(h=48\) as a “mediator” in a regression of long-run employment on HPI exposure and interpreting the attenuation as evidence that duration explains scarring is not valid causal mediation. The mediator is a post-treatment variable and likely mechanically related to the outcome. Conditioning on it can induce bad-control bias, soak up shared variance by construction, and does not identify the share of the treatment effect operating through duration.

This is especially problematic because the dependent variable is average log employment over months 48–120, while the mediator is unemployment change at \(h=24\) or 48. Of course persistent unemployment is highly predictive of later employment; that does not show that “duration, not initial job loss per se, is a primary driver of permanent damage” in a causal sense.

At most, this is a descriptive decomposition: states with greater housing exposure also had more persistent unemployment, and controlling for that persistence reduces the residual HPI-employment association. The paper must stop short of causal mediation language unless it adopts a formal design capable of identifying mediated effects under strong assumptions.

### C. Alternative explanations remain live
Several plausible alternatives are not ruled out:

- **Structural reallocation / overbuilding:** Great Recession states may have suffered from construction-specific overexpansion and subsequent sectoral reallocation rather than general “demand recession” scarring.
- **Household debt deleveraging:** The mechanism may run through debt overhang and weak local demand rather than duration-driven human capital erosion.
- **Migration/compositional change:** Although the paper cites Yagan and Dao et al., citing prior work is not the same as testing whether state payroll dynamics are contaminated by migration and labor-force composition in this sample.
- **Policy differences:** The paper says policy and shock type are inseparable, but then often interprets the result as shock-type specific. If PPP and enhanced UI are crucial, then the paper’s practical conclusion may be about match-preserving policy capacity, not “supply recessions” per se.

## 4. Contribution and literature positioning

### A. The question is important and potentially publishable
The general idea—comparing persistence across a balance-sheet/demand crisis and a pandemic recession, with a focus on duration and recall—is interesting and policy relevant. There is room for a paper that cleanly documents and explains why some recessions lead to longer-lasting employment effects than others.

### B. But the paper currently overstates novelty relative to existing work
The paper positions itself against hysteresis and local labor market adjustment literatures, but the differentiation from closely related work is still somewhat loose. For example:
- local labor market persistence after adverse shocks is a large literature;
- the importance of temporary layoffs and recall in COVID is well known;
- the Great Recession’s long-duration unemployment mechanism is also well established.

The novel step should be the clean empirical comparison and mechanism adjudication. That is exactly where the current design is weakest.

### C. Important references to add / engage more directly
For methods and identification:
- Adão, Rodrigo, Michal Kolesár, and Eduardo Morales (2019), “Shift-Share Designs: Theory and Inference,” *QJE* — essential for Bartik inference.
- Goldsmith-Pinkham, Paul, Isaac Sorkin, and Henry Swift (2020), “Bartik Instruments: What, When, Why, and How,” *AER* — essential for interpreting the shift-share design.
- Borusyak, Kirill, Peter Hull, and Xavier Jaravel (2022), “Quasi-Experimental Shift-Share Research Designs,” *Review of Economic Studies* or working paper versions depending bibliography timing — already cited, but should be substantively used.

For local labor market persistence / scarring:
- Yagan (2019) is cited and should be more central in framing how much of state employment persistence reflects individual scarring versus migration/composition.
- Hershbein and Stuart? Depending exact angle, literature on local labor market recovery and participation after the Great Recession could be strengthened.
- Autor, Dorn, Hanson style local shock persistence papers are cited, but more explicit comparison to why this paper is not simply another local-shock persistence paper would help.

For COVID labor-market dynamics:
- Forsythe et al. is cited; the paper should also engage more directly with work on recall expectations, temporary layoffs, and sectoral reallocation during COVID.
- There is also a literature on remote work and state-level heterogeneity in COVID recovery that should inform controls and interpretation.

## 5. Results interpretation and claim calibration

### A. The title and abstract overclaim relative to the evidence
“Demand Recessions Scar, Supply Recessions Don’t” is much stronger than the evidence supports. The paper does not estimate causal effects of recession type, and the main Great Recession long-run estimate is statistically inconclusive. A title and abstract for a top journal must reflect that this is evidence from two episodes showing a contrast consistent with a duration-trap mechanism, not a general theorem about recession types.

### B. Magnitudes are not always discussed consistently
The paper says “roughly one in every hundred workers was still missing from payrolls four to ten years later.” But the main coefficient is \(-0.0567\) on a one-unit increase in log HPI boom. Since observed HPI boom variation is much smaller than one unit, the implied effect over realistic cross-state exposure differences should be translated explicitly. Otherwise readers may misread the economic magnitude.

### C. Policy claims outrun identification
The conclusion claims:
- speed of fiscal response matters enormously,
- match-preserving programs work for temporary supply disruptions,
- demand recessions require demand stimulus,
- duration-targeted interventions may be cost-effective.

These may well be true, but this paper does not credibly estimate the causal effects of fiscal timing or specific programs. The COVID episode bundles shock type and extraordinary policy. Policy implications should be presented as informed conjectures rather than findings.

### D. There are some internal tensions in interpretation
The paper says:
- the cross-episode contrast is not a clean causal comparison;
- yet the title and policy discussion treat it as such.
It also says:
- the single long-run estimand is the headline because it avoids multiple testing;
- yet the interpretation leans heavily on selected dynamic horizons and ancillary specifications.
These tensions should be resolved.

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

#### 1. Reframe the central claim and title
- **Issue:** The title, abstract, and conclusion claim more than the design identifies.
- **Why it matters:** Causal overstatement is a major publication barrier.
- **Concrete fix:** Retitle and rewrite around “evidence from two episodes consistent with a duration-trap mechanism” unless a stronger design is added. Replace universal claims about “demand” and “supply” recessions with episode-specific conclusions.

#### 2. Address the weak statistical support for the headline Great Recession result
- **Issue:** The main long-run GR estimate has permutation \(p \approx 0.13\).
- **Why it matters:** A paper cannot rest its central conclusion on an imprecise flagship estimate.
- **Concrete fix:** Either strengthen identification/power with a redesigned estimator and richer data, or downgrade the claim sharply. If possible, move beyond 50-state cross-sections by using substate labor markets, counties/CZs, or repeated cross-sections with a more powerful panel/event-study design.

#### 3. Remove or fundamentally reinterpret the “mediation/attenuation” exercise
- **Issue:** Table 5 uses post-treatment unemployment as a mediator and interprets attenuation causally.
- **Why it matters:** This is not valid mediation and risks serious misinterpretation.
- **Concrete fix:** Recast as descriptive correlation only, or replace with a proper mechanism design using direct duration measures and a transparent sequential empirical framework. Do not claim that the attenuation “confirms” duration as the driver.

#### 4. Confront pre-trends directly
- **Issue:** Significant 36-month pre-trends undermine OLS identification.
- **Why it matters:** This is a core threat to causal interpretation.
- **Concrete fix:** Show full pre-period event-study coefficients; allow differential pre-trends; control more flexibly for boom-period trajectories; report specifications designed to absorb pre-boom differential growth. If the result survives only in IV, make IV the main design and defend its exclusion restriction more carefully.

#### 5. Harmonize or redesign the cross-episode estimand
- **Issue:** Comparing GR months 48–120 to COVID months 24–48 is not apples-to-apples.
- **Why it matters:** The central asymmetry may partly reflect different follow-up windows.
- **Concrete fix:** Present matched-horizon comparisons as the main analysis: e.g., both episodes at 24, 36, and 48 months; or both relative to recovery date. Keep longer GR follow-up as supplementary.

#### 6. Clarify and justify inference
- **Issue:** Permutation inference is under-justified and inconsistently implemented.
- **Why it matters:** Valid inference is a pass/fail issue.
- **Concrete fix:** Explain the permutation scheme precisely; justify exchangeability; use a single number of randomizations; report exact p-values consistently; consider randomization schemes respecting geographic structure if appropriate; unify stars and p-values across tables.

### 2. High-value improvements

#### 7. Strengthen the COVID Bartik design
- **Issue:** Industry-share exposure may proxy for many confounders.
- **Why it matters:** The “full recovery” result is only as credible as the exposure design.
- **Concrete fix:** Add controls/robustness for urbanization, density, tourism, remote-work feasibility, COVID severity, shutdown stringency, and pre-pandemic industry trends. Show pre-2020 placebo tests.

#### 8. Expand robustness around influential observations
- **Issue:** Results seem concentrated in a few states.
- **Why it matters:** Small-sample leverage could be driving the findings.
- **Concrete fix:** Report leave-one-out and leave-four-out robustness, Cook’s distance/leverage diagnostics, and possibly robust regression estimates.

#### 9. Use more direct mechanism data if feasible
- **Issue:** Unemployment rates are a noisy proxy for duration.
- **Why it matters:** The paper’s distinctive contribution is mechanism.
- **Concrete fix:** Build state-level long-term unemployment, temporary layoff, and participation measures from CPS/LAUS where possible. Even noisy direct duration metrics would be more persuasive than unemployment-rate persistence alone.

#### 10. Reassess the horse-race interpretation
- **Issue:** The GR Bartik coefficient is positive in the horse race and the text offers speculative interpretation.
- **Why it matters:** This could signal collinearity, bad controls, or mismeasurement rather than meaningful “mean reversion.”
- **Concrete fix:** Diagnose correlation and variance inflation; report unconditional and conditional relationships; avoid causal channel language unless the design can support it.

### 3. Optional polish

#### 11. Drop the pooled interaction unless outcomes are made comparable
- **Issue:** Table 3 is hard to interpret.
- **Why it matters:** It adds noise and invites overreading.
- **Concrete fix:** Remove or replace with a harmonized pooled event-time design.

#### 12. Translate coefficients into economically meaningful cross-state contrasts
- **Issue:** One-unit exposure effects are not intuitive.
- **Why it matters:** Readers need realistic magnitudes.
- **Concrete fix:** Report effects for interquartile-range exposure differences and for key state comparisons.

#### 13. Tighten contribution relative to existing literature
- **Issue:** Novelty currently rests on a mechanism claim the evidence does not yet fully establish.
- **Why it matters:** Clear positioning improves publication chances.
- **Concrete fix:** Emphasize what is genuinely new after redesign: e.g., comparative persistence using harmonized event-time estimands and direct duration measures.

## 7. Overall assessment

### Key strengths
- Important question at the intersection of macro, labor, and regional economics.
- Clear motivation and intuitive conceptual framework.
- Sensible instinct to compare the two largest modern U.S. labor-market contractions.
- Transparency about some design limitations.
- Effort to go beyond reduced-form persistence toward mechanism.

### Critical weaknesses
- Main Great Recession long-run estimate is statistically weak.
- Cross-episode claim is more causal than the design allows.
- Pre-trends are a substantial threat to identification.
- Mechanism evidence relies on invalid causal mediation logic with post-treatment controls.
- COVID Bartik identification and inference need substantially more methodological care.
- Key comparison uses non-comparable outcome windows.

### Publishability after revision
In current form, I do not think the paper is close to acceptance at the outlets listed. However, I do think there is a potentially interesting paper here if the authors are willing to narrow the claims and substantially redesign the empirical strategy. The most promising path would be:
1. make within-episode identification the real core;
2. harmonize the cross-episode comparison;
3. upgrade the inference and robustness substantially;
4. replace the attenuation exercise with more defensible mechanism evidence.

Without those changes, the paper reads as an appealing narrative wrapped around suggestive but insufficiently compelling evidence.

DECISION: REJECT AND RESUBMIT