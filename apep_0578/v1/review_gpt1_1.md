# GPT-5.4 (R1) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-10T14:05:43.486644
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 20160 in / 6090 out
**Response SHA256:** 608df0c6eebb0dd3

---

This paper asks an important and policy-relevant question: whether the post-2015 reintroduction of temporary Schengen internal border controls reduced economic activity in affected European border regions. The topic is clearly of broad interest, and the paper usefully emphasizes that the relevant policy counterfactual is not “collapse of Schengen” but the actual, selective controls implemented since 2015. The paper also shows awareness of modern staggered-DiD issues and does more than many papers by presenting TWFE, Sun-Abraham, Callaway-Sant’Anna, placebo exercises, and randomization inference.

That said, in its current form I do not think the paper is publication-ready for a top general-interest journal or AEJ: Economic Policy. The central empirical problem is that the design does not yet deliver a stable, clearly credible causal estimate of the effect of border controls per se. The paper’s preferred conclusion—essentially “no aggregate effect once national trends are absorbed”—is plausible, but the evidence remains too specification-sensitive and the inference too fragile to support that claim at the standard required for these outlets.

Below I organize the review around identification, inference, robustness, contribution, interpretation, and revision priorities.

---

## 1. Identification and empirical design

### 1.1 Core identification challenge is not yet resolved
The paper’s intended design is a staggered DiD comparing treated border regions to untreated border and interior regions, with treatment assigned at six border segments beginning in late 2015/early 2016 (Sections 2–4). The paper itself shows that the estimated effect is highly sensitive to which comparisons are used:

- Baseline TWFE: -2.7% (Table 1, col. 1).
- TWFE with country-by-year FE: 0.0004 (Table 1, col. 6).
- Border-only controls: +2.2%, insignificant (Section 5.5; Appendix Table \ref{tab:robustness}).
- Border-only + country-by-year FE: +5.7%, significant (Appendix Table \ref{tab:robustness}).
- CS aggregate ATT: -0.7%, insignificant (Table 1, col. 7).

This is not just a matter of “naive TWFE bad, robust estimators good.” Rather, the sign itself depends on whether interior regions are included and whether within-country comparisons are emphasized. That suggests the identifying comparisons are not yet convincing.

Most importantly, the paper’s own placebo evidence shows that **border regions and interior regions differ systematically even within country-year cells**:

- “Placebo borders + C × Y FE” remains large and significant: -0.054 (Appendix Section C; Table \ref{tab:robustness}).

This is a major issue. The preferred country-by-year FE specification is only persuasive if treated border regions are comparable to untreated regions within the same country-year. But the paper shows that untreated border regions are structurally different from interiors even after absorbing country-year shocks. That directly undermines the interpretation of a pooled within-country comparison mixing border and interior regions.

### 1.2 The paper has not isolated a clean control group
The untreated groups combine:
- unaffected border regions (e.g., Germany–Netherlands, Austria–Italy),
- interior regions in treated countries,
- and, depending on the estimator, possibly all never-treated regions.

These are economically very different objects. Border regions differ from interiors in trade exposure, commuting patterns, industrial structure, and likely trend sensitivity to EU integration and globalization. The placebo results confirm this.

A more credible design would likely compare:
1. treated border regions only,
2. to untreated border regions only,
3. within country or at least with much tighter geographic comparability.

But when the paper does something close to that (“Border only + C × Y FE”), it gets a **positive and significant** estimate (+0.057), which the manuscript currently dismisses as likely spurious (Section 5.5). That is not sufficient. Once the paper’s own preferred specification class produces a positive estimate, the null conclusion cannot be treated as established.

### 1.3 Country-by-year FE help, but do not by themselves solve identification
I agree with the paper that country-year shocks are critical, and Table 1, col. 6 is informative. However, the manuscript overstates what this accomplishes. Country-by-year FE remove national shocks common within country-year, but the remaining identifying variation is then driven by **differences between treated border, untreated border, and interior regions within country-year**. If border and interior regions have different exposure to macro shocks or secular trends, country-year FE do not solve that.

This is especially concerning because treatment assignment is not random across border segments:
- France’s “all borders” treatment is national and heterogeneous;
- Germany-Austria and Austria-Hungary are unusually integrated corridors;
- Nordic segments reflect different institutional and macro contexts.

The claim in Section 5.1 that the CS estimator “partially absorbs” country-specific trends is too loose for a top-journal causal paper. Callaway-Sant’Anna with country indicators is not equivalent to country-by-year saturation, and “doubly robust” does not rescue misspecified comparisons when untreated potential-outcome trends differ sharply across types of regions.

### 1.4 Treatment definition is coarse relative to the policy
The paper repeatedly notes that controls were selective and concentrated at major crossings, with smaller crossings often unaffected (Section 2.2). Yet treatment is assigned to all adjacent NUTS3 regions on a treated segment. This likely introduces large measurement error in exposure.

That is not fatal, but it matters for interpretation:
- the estimate is for “being adjacent to a segment with reintroduced controls,” not for actual exposure intensity;
- attenuation may be substantial and heterogeneous;
- “null effect” may simply reflect severe treatment mismeasurement.

At a minimum, the paper should exploit available variation in likely intensity: major corridor crossings, commuter-heavy regions, highway/rail exposure, or pre-2015 commuting/trade intensity.

### 1.5 Timing is awkward for annual data
Treatment begins in September/November 2015 or January 2016, but the main annual coding sets \( G_i = 2015 \) for late-2015 starts (Section 3.3). The paper acknowledges that 2015 contains only 3–4 months of exposure. This creates several problems:

- event time 0 is mechanically diluted;
- annual GDP may not respond in such short windows;
- the distinction between 2015 and 2016 cohorts is partly administrative rather than economically meaningful;
- comparisons may be contaminated by anticipation and partial exposure.

I appreciate that the paper notes this issue. But for a design resting on staggered timing across only two effective cohorts, this timing coarseness is a first-order limitation, not a minor caveat. A cleaner design might start treatment in 2016 for the late-2015 adopters and estimate intent-to-treat from first full exposure year, with sensitivity to alternative timing codings.

### 1.6 Spillovers likely violate SUTVA
Section 4.3 acknowledges spillovers, but the implications are larger than the paper allows. Untreated nearby borders and interior regions may be affected by rerouted traffic, commuting, logistics, tourism, or substitution. This is especially problematic because the control groups are spatially and economically linked to treated regions. If unaffected borders gain activity when treated borders become slower, untreated border regions are not valid controls. If interiors absorb displaced activity, they are also contaminated.

Given the policy, spillovers are highly plausible and directional. The paper treats them as a source of attenuation, but in practice they could also flip signs depending on the control group used—exactly what the paper finds.

### 1.7 French treatment is conceptually different
The “France—all borders” treatment is unusual both in motive (terrorism rather than migration) and geographic breadth (Section 2.2). Pooling that treatment with corridor-specific controls elsewhere risks comparing fundamentally different interventions. Moreover, French controls may affect airports, ports, tourism, and national mobility in ways not localized to border NUTS3 regions. That makes the “treated border region” definition especially questionable for France.

I would strongly encourage separating France from the main causal estimate and treating it as a distinct case study or excluding it from the headline specification.

---

## 2. Inference and statistical validity

This is the most serious barrier to publication in its current form.

### 2.1 Main uncertainty is not computed at the effective assignment level
Treatment is effectively assigned at the border-segment level, and there are only six treated segments (Sections 1, 4.4, 5.5). Yet most tables report region-clustered standard errors. The paper itself recognizes this may understate uncertainty and presents segment-level randomization inference.

That is good, but it creates a problem: once the paper acknowledges the effective number of treated shocks is tiny, region-clustered asymptotics are no longer an acceptable basis for inference on the main estimates. This affects:
- TWFE estimates,
- segment-specific regressions,
- event-study plots,
- and arguably the CS standard errors as well.

For top-journal standards, the segment-level assignment problem must be central, not supplementary.

### 2.2 Randomization inference is informative but inconsistently integrated
The segment-level RI result \( p = 0.67 \) is important (Abstract; Section 5.5; Appendix Table \ref{tab:robustness}). It substantially weakens the apparent significance of the baseline TWFE estimate. However:

- the paper continues to discuss many region-cluster-significant results as if they were reliable;
- the RI appears tied only to the naive TWFE estimate, not to the preferred estimands/specifications;
- it is unclear exactly how the segment permutations are defined, especially given heterogeneous segment sizes and one “FR-all” segment versus narrower bilateral segments.

This should be clarified and expanded. If treatment is assigned at segment level, then inference for the main conclusions should be based on procedures valid for few treated clusters/segments across the preferred specifications.

### 2.3 Internal inconsistency on RI p-values
There is a serious contradiction between the Introduction and the rest of the paper:

- Abstract: segment-level RI \( p = 0.67 \).
- Section 5.5: segment-level RI \( p = 0.67 \).
- Conclusion: segment-level RI \( p = 0.67 \).
- But Introduction states: “The randomization inference \( p \)-value is 0.002 … the issue is not detectability but attribution.”

That 0.002 appears to refer to **region-level** RI, not segment-level RI. This is not a prose quibble; it is a substantive inconsistency that changes the inference. It must be fixed.

### 2.4 Event-study inference is weak
The event studies (Section 5.2; Appendix Table \ref{tab:event_study}) show:
- several significant long pre-trends in SA;
- some individually significant long leads in CS;
- endpoint significance in late post-treatment periods with sparse support.

The manuscript downplays these as artifacts of unbalanced support or long-lead noise. That may be right, but for a paper leaning on “parallel trends look okay,” the pre-trend evidence is not reassuring. The claimed CS pre-test \( p=0.9999 \) sits uneasily next to visible/significant long-lead coefficients. The paper explains why a joint test may not reject, but the broader takeaway should be caution, not reassurance.

Also, the paper refers to HonestDiD/Rambachan-Roth sensitivity, but provides no substantive quantitative display beyond the statement that the null is robust for \( \bar M \le 2 \) (Section 5.2; Appendix B). For publication, this needs fuller reporting.

### 2.5 Segment-specific heterogeneity estimates are over-precisely reported
Table \ref{tab:heterogeneity} reports very tight standard errors for segment-specific regressions, e.g.:
- France-all: -0.1388 (0.0089),
- Germany-Austria: 0.0396 (0.0096),

with region clustering. But each “treatment” here is still one segment. These SEs are not credible as causal uncertainty measures at the level of treatment assignment. They are descriptive associations, not well-identified causal segment effects.

### 2.6 Sample/cohort counts need clarification
There are small coherence issues that should be cleaned up because they affect credibility of the empirical design:

- Section 3 says 134 treated regions; Figure \ref{fig:sa_event} note refers to “188 treated and control border regions,” implying border-only sample size, which is fine, but readers need a clearer accounting.
- Summary stats notes say pre-treatment period is “2003–2014,” whereas the text says “2000–2014.”
- Column 7 in Table 1 uses 12,340 observations from a balanced 617-region sample over 2003–2022; fine, but the exact reasons for dropping one region and the implications for comparability should be more transparent in the main text.

These are not fatal, but top-field referees will notice them.

---

## 3. Robustness and alternative explanations

### 3.1 Robustness exercises reveal instability more than robustness
The paper frames Section 5.5 as showing robustness of the null. I do not think that is the correct reading. Rather, the exercises show that the estimate is **unstable across plausible comparison sets**:

- mixed controls + year FE: negative;
- mixed controls + country-year FE: zero;
- border-only + country-year FE: positive and significant;
- CS aggregate: mildly negative and insignificant.

This is evidence that the design has not pinned down the causal parameter, not evidence of a robust null.

### 3.2 Placebos are informative but under-interpreted
The placebo exercises are among the strongest parts of the paper. Especially valuable:
- fake treatment timing in 2010/2012,
- fake treatment on unaffected borders,
- versions with country-by-year FE.

But the interpretation should be sharper. The persistent border placebo with country-by-year FE is not just “a reason for caution.” It suggests the main identifying contrast using interiors is invalid for causal purposes. This should force a redesign of the baseline, not just a caveat.

### 3.3 Mechanism claims are too speculative for the evidence
The paper discusses selective enforcement, adaptation, and local employment generation via enforcement/infrastructure (Section 6.1), and interprets trade/transport declines as sectoral reallocation (Section 6.2). These are plausible stories, but they are not directly tested.

In particular:
- the +1.5% employment effect is surprising and could easily reflect confounding;
- the -8.4% trade/transport GVA result is on a selected subsample of 185 regions and cannot be estimated with country-by-year FE;
- no direct evidence on commuter flows, border wait times, trade by corridor, or firm relocation is presented.

Mechanism discussion should be clearly labeled as conjectural unless the paper adds direct evidence.

### 3.4 External validity is appropriately bounded, but policy rhetoric still runs ahead
The paper is careful in places to say it studies actual selective controls, not full Schengen collapse. That is good. But the broader interpretation occasionally slides into stronger statements that current controls are “economically innocuous” or that the economic case against them is “less clear-cut” (Section 6.4). Given the identification and power problems, the evidence supports a narrower claim: the paper does not detect robust effects on annual regional GDP aggregates.

That is different from demonstrating absence of economically meaningful costs.

---

## 4. Contribution and literature positioning

### 4.1 Topic is important and potentially publishable
The question is novel and relevant, and the paper addresses a policy issue that has been discussed mostly through simulations rather than quasi-experimental evidence. That is a genuine strength.

### 4.2 Contribution relative to prior empirical work needs tightening
The paper claims to provide the “first quasi-experimental evidence” on this question (Introduction). That may be true, but the comparison to existing empirical work is too thin. The contribution would be stronger if the manuscript more clearly distinguished:
- effects of Schengen introduction/removal on trade vs. regional output,
- national-level vs. subnational designs,
- actual selective controls vs. hypothetical hard-border simulations,
- soft frictions vs. full border effects.

### 4.3 Methods literature should be updated/clarified
The staggered-DiD discussion is generally competent, but the paper should better position its estimator choice and inference limits. Useful additions/clarifications would include:

- Borusyak, Jaravel, and Spiess (2024, RESTUD) on imputation-based event studies and efficient estimation under staggered adoption.
- Roth, Sant’Anna, Bilinski, and Poe (2023, QJE or working-paper variants depending citation style) / Roth (2022/2023) on pre-trend testing and event-study interpretation if not already properly cited.
- Ferman and Pinto (2019) and related few-treated-cluster inference work are relevant and already partly cited; the paper should lean more heavily on this literature given its design.

### 4.4 Domain literature could be broadened
On the policy/domain side, the paper would benefit from more engagement with:
- Schengen and intra-EU mobility/commuting evidence,
- border region adjustment and cross-border labor markets,
- empirical studies of temporary border frictions, commuter disruptions, or transport shocks in Europe.

I cannot verify exact missing citations from the source alone, but the literature discussion currently feels somewhat gravity-heavy and somewhat light on border-region labor-market evidence.

---

## 5. Results interpretation and calibration of claims

### 5.1 Main claim should be weakened
The manuscript currently concludes that the apparent negative effect “is driven by differential national economic trends rather than border-specific effects” and that the preferred estimate is essentially zero (Abstract, Conclusion). That is too strong given the evidence.

A more defensible conclusion is:

> The paper finds no stable or robust evidence that post-2015 temporary Schengen controls reduced annual NUTS3 GDP per capita; estimates are highly sensitive to the comparison group and inference procedure, suggesting the available design/data are insufficient to isolate a precise aggregate effect.

That is still valuable, but more accurate.

### 5.2 The paper cannot simultaneously argue “precisely zero” and “underpowered”
The manuscript says:
- the design “lacks power to detect moderate effects” (Abstract),
- but also that the country-by-year estimate is “precisely estimated at zero” (Section 6.1).

These are in tension. With six treated segments and coarse annual regional outcomes, the paper should be modest about precision. A failure to find effects on annual GDP aggregates is not the same as showing economically small true effects.

### 5.3 The trade/transport result is over-emphasized
The -8.4% trade/transport GVA estimate is interesting, but given:
- severe sample selection (185 of 618 regions),
- inability to include country-by-year FE,
- likely sector-specific national shocks,
it should not be presented as a strong substantive finding. Right now it is discussed too prominently relative to its evidentiary basis.

### 5.4 Contradictions need correction
Several substantive inconsistencies should be fixed:

1. **Randomization inference p-value**:
   - Introduction reports 0.002 as if it were the relevant RI result.
   - Elsewhere segment-level RI is 0.67.
   This is a material contradiction.

2. **Summary-statistics period**:
   - text says pre-treatment 2000–2014;
   - table note says 2003–2014.

3. **Interpretation of CS estimator**:
   - the manuscript sometimes implies it solves country-level confounding;
   - the evidence provided does not establish that.

---

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

#### 1. Redesign the baseline identification strategy around credible within-type comparisons
**Issue:** The current design mixes treated border, untreated border, and interior regions, but the paper’s own placebo tests show border and interior regions are not comparable even within country-year cells.  
**Why it matters:** This undermines the main identifying variation behind the preferred country-by-year FE specification.  
**Concrete fix:** Rebuild the baseline around border-to-border comparisons only, ideally within country or closely matched corridors. If that is impossible, the paper should explicitly state that no clean comparison group exists and downgrade the causal claim. At minimum, present matched/pre-trend-balanced border-only estimates as the central analysis.

#### 2. Make assignment-level inference the default, not a robustness check
**Issue:** Main inference relies on region-clustered SE despite only six treated border segments.  
**Why it matters:** Statistical significance is overstated if uncertainty is evaluated below the treatment-assignment level.  
**Concrete fix:** For every headline estimate, report inference valid under few treated segments: segment-level RI, wild-cluster procedures where appropriate, or other justified few-cluster methods. Relegate region-clustered SE to secondary status.

#### 3. Resolve the inconsistency and ambiguity around the RI results
**Issue:** The Introduction states RI \( p=0.002 \), while the abstract and later sections state segment-level RI \( p=0.67 \).  
**Why it matters:** This changes the core inferential message.  
**Concrete fix:** Clearly distinguish region-level from segment-level RI everywhere, state which is relevant for causal inference, and revise all interpretations accordingly.

#### 4. Recalibrate the main claim from “null causal effect” to “design does not robustly identify an aggregate effect”
**Issue:** The paper currently overstates what the design supports.  
**Why it matters:** Publication readiness depends on claim-evidence alignment.  
**Concrete fix:** Rewrite the abstract, introduction, discussion, and conclusion to reflect specification instability and limited power/precision.

#### 5. Address treatment measurement and timing more rigorously
**Issue:** Annual treatment coding for late-2015 adoption and coarse region-level exposure likely induce attenuation and heterogeneity.  
**Why it matters:** A null finding may reflect mismeasurement rather than absence of effect.  
**Concrete fix:** Re-estimate using first full-exposure year coding (e.g., 2016 for late-2015 starts), report sensitivity to alternative treatment timing, and, if possible, construct treatment intensity measures based on major crossings, commuting, or corridor exposure.

### 2. High-value improvements

#### 6. Treat France separately or exclude it from the headline estimate
**Issue:** France-all-borders is a qualitatively different intervention and dominates some negative results.  
**Why it matters:** Pooling it with corridor-specific treatments may mask incomparable effects.  
**Concrete fix:** Present France as a separate case study, or provide headline results excluding France and discuss how much the conclusions depend on it.

#### 7. Strengthen the pre-trend and sensitivity analysis
**Issue:** Event studies show concerning long-lead patterns, and HonestDiD is only briefly summarized.  
**Why it matters:** Parallel trends are central and currently not convincingly established.  
**Concrete fix:** Report support by event time, simultaneous bands, stacked/matched event studies, and fuller Rambachan-Roth sensitivity outputs.

#### 8. Add direct exposure heterogeneity
**Issue:** The policy likely matters most where cross-border commuting/trade is intense.  
**Why it matters:** Average effects over all adjacent NUTS3 regions may wash out economically relevant effects.  
**Concrete fix:** Interact treatment with pre-2015 commuter intensity, crossing density, trade exposure, highway/rail corridors, or urban cross-border integration.

#### 9. Be much more cautious with the sectoral and employment findings
**Issue:** These are likely confounded and based on weaker data.  
**Why it matters:** Over-interpretation weakens the paper.  
**Concrete fix:** Recast them as exploratory unless they can be supported with stronger identification and assignment-level inference.

### 3. Optional polish

#### 10. Clarify sample construction and timing counts in the main text
**Issue:** There are minor inconsistencies in periods and sample sizes.  
**Why it matters:** Clarity matters for replication credibility.  
**Concrete fix:** Harmonize all references to pre-treatment periods, balanced vs. unbalanced panels, and border-only sample counts.

#### 11. Tighten literature positioning on few-treated-cluster inference and staggered DiD
**Issue:** The paper is method-aware but could be sharper.  
**Why it matters:** Better positioning helps justify design choices and limitations.  
**Concrete fix:** Add/update citations on imputation/event-study methods and few-treated-cluster inference, and explain why the chosen estimator/inference combination is appropriate here.

---

## 7. Overall assessment

### Key strengths
- Important and policy-relevant question.
- Good instinct to distinguish actual selective Schengen controls from hypothetical hard-border collapse.
- Awareness of modern staggered-DiD pitfalls.
- Useful placebo exercises and welcome attention to assignment-level inference.
- Honest acknowledgment of some limitations.

### Critical weaknesses
- Identification is not stable across plausible control groups/specifications.
- Main preferred design is undermined by the paper’s own placebo evidence.
- Inference is not centered on the true treatment-assignment level.
- Claims are stronger than the design supports.
- Treatment timing/exposure are coarse relative to the policy.
- Key conclusions hinge heavily on how France and interiors are handled.

### Publishability after revision
I think there is a potentially interesting paper here, but it needs substantial redesign and reframing before it could be considered publishable in the target outlets. The current manuscript is strongest as a careful demonstration that naive cross-region DiD is misleading in this setting and that annual NUTS3 data with six treated segments may be insufficient to identify the aggregate effect cleanly. That is not yet the same as a convincing causal estimate of “no effect.”

DECISION: MAJOR REVISION