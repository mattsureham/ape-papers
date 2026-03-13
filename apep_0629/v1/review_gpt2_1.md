# GPT-5.4 (R2) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-13T15:15:11.673918
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 17015 in / 5801 out
**Response SHA256:** a80fdaa54af498b4

---

This is an original and potentially interesting measurement paper. Training a domain-specific autoregressive LM on congressional speech and using predictive performance to characterize legislative discourse is, in principle, a promising contribution. The paper is also admirably transparent about data provenance, training setup, and what is and is not being claimed.

That said, in its current form I do not think the paper is publication-ready for a top general-interest journal or AEJ:EP. The central concerns are not cosmetic; they are about the validity of the measurement construct, the absence of defensible statistical inference, and over-interpretation of descriptive differences as evidence about institutional design and deliberation.

My main recommendation is to substantially reframe the paper as a measurement/descriptive paper unless the authors can supply a much stronger identification strategy for the institutional claims. Even as a measurement paper, several core pieces need to be repaired before the results can be trusted.

## 1. Identification and empirical design

### A. The paper does not currently identify causal effects of institutional design

The introduction, results, and discussion repeatedly interpret the House-Senate gap as evidence that chamber rules and institutional design produce more/less predictable speech (Introduction; Sections 6.1, 7.1). But the empirical design does not identify that claim.

What is shown is a persistent descriptive difference in model-assigned predictability between House and Senate floor speech. That difference could reflect:

- chamber rules and procedural centralization,
- speaker composition,
- topic mix and agenda composition,
- differences in speech length,
- differences in presiding/procedural turns,
- differences in parsing quality or conversation segmentation,
- chamber-specific formulae,
- unequal prevalence of routine business vs substantive debate,
- differential rates of unseen speakers in the holdout period.

There is no strategy here that isolates rules from those other chamber-level differences. Because speakers are chamber-specific, the paper cannot use within-speaker variation across House and Senate. Because topics differ across chambers, topic composition is a first-order confound. Because floor procedures differ by construction, “institutional design” is bundled with everything else.

The causal language should therefore be sharply dialed back unless the authors add a real design. Plausible paths forward would include exploiting procedural rule changes, comparing similar classes of debates across chambers, or decomposing within narrowly matched bill/topic/procedural categories. As written, “consistent with institutional design theories” is fine; “provides direct evidence” is not.

### B. The Deliberation Index is not yet validated as a measure of deliberation

The conceptual move from “context improves next-token prediction” to “this is deliberation” is too strong. The paper acknowledges some of this in Sections 4.7 and 7.2, but the main text still interprets positive DI as “speakers are responding to context, not delivering pre-packaged monologues” (Section 6.2). That is not established.

A positive context effect could arise from:

- topic continuity,
- adjacency-pair regularities,
- formulaic procedural sequences,
- chamber conventions,
- turn-taking structure,
- predictable rhetorical sequencing within scripted partisan exchanges.

Those are not the same as deliberation in any normatively meaningful sense. The paper needs to either:
1. rename the measure more neutrally (e.g., contextual predictability gain / conversational coupling), or
2. provide validation against external markers of actual deliberation.

Without external validation, the paper currently overclaims.

### C. Major concern: holdout design and speaker-token construction may create leakage / comparability problems

This is one of the most serious issues in the paper.

The tokenizer includes one special token per speaker for all 1,701 speakers (Section 5.2; Appendix A). But the training set contains 1,081 unique speakers and the validation set 1,239 unique speakers, implying many holdout speakers are unseen in training (Table 1). This creates at least three problems:

1. **For unseen holdout speakers, the speaker embedding is untrained or near-untrained.**  
   Then marginal perplexity conditional on speaker identity alone is not meaningfully comparable across seen and unseen speakers.

2. **The paper does not say how DI is computed for speakers absent from training.**  
   If such turns are included, DI may be mechanically distorted. If excluded, sample selection must be reported.

3. **Even if the token inventory is fixed ex ante, using future-period speaker identities as atomic tokens changes the representation space using information from outside training.**  
   This is not necessarily fatal, but it must be explicitly justified and its implications explored.

This is especially problematic because DI depends critically on conditioning on speaker identity. A large share of the key measure may be driven by whether a speaker was seen during training.

At minimum, the authors need to report:
- share of validation turns from speakers seen in training,
- DI separately for seen vs unseen speakers,
- whether the House-Senate gap persists when restricted to speakers observed in training,
- whether results are robust to replacing speaker-ID tokens with coarser attributes (party/state/chamber) or no speaker token.

If this issue materially affects results, the current DI evidence is not credible.

### D. Structural break / source-change confounding is not adequately handled for several headline results

The authors appropriately recognize that the HuggingFace-era and GovInfo-era data differ in conversation granularity and parsing (Section 3; Appendix A), and they therefore restrict DI to 2015–2024 GovInfo holdout data. That is good.

However, several other substantive results still rely on the full 1994–2024 series:
- speaker identification trends (Section 6.3),
- neural vs classical comparison and the “2011 structural break” interpretation (Section 6.4),
- long-run time-series claims in Section 6.1.

Those analyses remain confounded by the source/segmentation change around 2011. In particular, the claim that the SVM’s break around 2011 reflects a substantive political change is not credible unless the authors show it is not induced by the data-source/segmentation break. Given the acknowledged heterogeneity in how “conversations” are defined pre/post 2011, this alternative explanation is obvious and currently unresolved.

For top-journal standards, these analyses need to be either:
- restricted to a uniform data regime, or
- accompanied by explicit bridging exercises showing comparability.

## 2. Inference and statistical validity

This is currently the paper’s weakest area, and it is disqualifying in its present form.

### A. The paper lacks valid statistical inference for the main claims

The paper reports means, ranges, and standard deviations, but almost no inferential statistics for the main estimates.

Examples:
- No confidence intervals or standard errors for the House-Senate perplexity gap.
- No uncertainty for the mean DI.
- No test/CI for the House-Senate difference in DI.
- No inferential treatment of the 85% positive-turn share.
- The “paired test across years” in Section 6.1 is not specified, not tabulated, and uses only 10 yearly observations in the holdout period.

For publication in the target outlets, the paper needs formal uncertainty quantification that matches the dependence structure in the data. Because turns are nested within conversations and years, simple iid SEs would not be appropriate. Cluster/bootstrap procedures at least at the conversation level are needed, and probably multi-level reporting (turn-, conversation-, and year-level summaries).

### B. The Deliberation Index is defined on the wrong scale

This is a central measurement problem.

The paper defines:
- “conditional perplexity” \(H_c\),
- “marginal perplexity” \(H_m\),
- and the Deliberation Index \(DI = H_m - H_c\).

But perplexity is an exponential transform of cross-entropy. Differences in perplexity are not additive information quantities and do not have the information-theoretic interpretation the paper assigns to them.

If the authors want an information-theoretically meaningful gap, they should compare:
- average negative log-likelihood / cross-entropy / surprisal, not raw perplexity;
- ideally in bits or nats per token.

Then the relevant object is a difference in cross-entropy:
\[
\Delta H = H_m - H_c
\]
where \(H\) is entropy/cross-entropy, not perplexity.

As written, statements like “A mean DI of +2.52 implies that context reduces the effective number of plausible next words by approximately 2.5” (Section 6.2) are not correct. A reduction from PPL 45 to 42.5 does not mean “2.5 fewer plausible next words” in an interpretable linear sense. This issue affects the core estimand and the paper’s interpretation throughout.

This must be fixed before the measure can be evaluated scientifically.

### C. Sample design for DI is underpowered and not clearly justified

The headline DI analysis uses only 832 turns from five odd-numbered holdout years (Section 6.2). For a paper built around this measure, this is too thin.

Problems:
- The sampling procedure is not described in enough detail.
- It is not clear whether sampling weights are needed.
- Some cells are very small (e.g., 70 turns in 2017).
- The paper itself admits substantial heterogeneity and potential sampling noise.
- The House/Senate split is unbalanced (578 vs 254 turns).

Given that the paper explicitly states the full-corpus DI computation is feasible in ~20 hours (Section 7.3), it is hard to justify not doing it. For a top-journal submission, a sampled computation is not enough for the central result.

### D. Several reported significance-style claims are not statistically persuasive

For example, Section 6.1 says the probability of seeing a House advantage in 10 out of 10 holdout years by chance is <0.1%. That is not a sufficient inferential framework for the substantive claim. Years are not independent draws from a coin-flip process, and this ignores the magnitude and within-year variation. Similar issues arise in interpreting year-to-year spikes and party differences.

### E. Speaker-identification evaluation is not a convincing validation exercise in current form

The speaker-ID exercise is interesting, but its inferential/statistical role is unclear.

Concerns:
- pre-2015 results are in-sample, which weakens their interpretation;
- the denominator for “chance” is not necessarily 1/1701 if the set of active speakers varies by year and context;
- accuracy varies enormously, suggesting instability;
- party prediction is below the majority baseline on average, so the exercise does not strongly validate the substantive construct.

As presented, this is more a diagnostic than a validation test.

## 3. Robustness and alternative explanations

The paper currently lacks the robustness architecture expected for this kind of measurement paper.

### A. No robustness to alternative model specifications

Section 4.6 explicitly says model-size robustness is left for future work. That is not acceptable if the main contribution is a new measurement instrument. At minimum, the paper needs:
- smaller and larger model variants,
- robustness to context-window length,
- robustness to training duration/checkpoint choice,
- robustness to tokenization choices,
- robustness to including/excluding speaker tokens.

Without this, it is hard to know whether the results are properties of Congress or of this specific undertrained model.

### B. No robustness to procedural / formulaic turns

Because the measure may be heavily influenced by highly predictable procedural speech, the paper should show results:
- excluding presiding-officer turns,
- excluding very short turns,
- excluding common procedural formulae,
- separately for substantive debate vs procedural business.

This matters especially for the House-Senate comparison, since the frequency and structure of procedural speech likely differ by chamber.

### C. No topic-composition controls

The House-Senate differences and crisis spikes may simply reflect topic mix. The paper should at least show:
- within-topic or within-bill comparisons where possible,
- estimates controlling for topic/date fixed effects in a downstream regression,
- decomposition by policy area.

Given the data structure, this seems feasible for the GovInfo era.

### D. No falsification/placebo tests

Useful placebo exercises would include:
- shuffled turn order within conversation,
- context drawn from another conversation on the same day/topic,
- conditioning on previous speech from the same speaker only,
- random speaker labels,
- DI computed after removing the immediately preceding turn,
- placebo “future context” tests to diagnose mechanical artifacts.

These would help distinguish genuine conversational dependence from modeling artifacts or topic persistence.

### E. Mechanism claims outrun evidence

The paper repeatedly advances mechanisms—e.g., House rules “force direct engagement,” Senate looseness allows “self-contained speeches,” crisis events create “no template”—without direct tests. Those are reasonable hypotheses, but they are not established by the reported evidence. The paper should clearly distinguish:
- reduced-form descriptive findings,
- interpretation,
- speculation.

## 4. Contribution and literature positioning

The paper’s broad contribution is potentially interesting, but the literature positioning is somewhat underdeveloped.

### A. Strength: the paper is differentiated from standard bag-of-words political text work

The contrast with Gentzkow et al.-style lexical measures is clear and helpful.

### B. The paper needs to engage more directly with language-model-as-measurement work

Even if the immediate domain application is novel, the broader methodological claim is that LM predictive performance can serve as a social-scientific measurement instrument. The paper should more explicitly situate itself relative to:
- work on language-model evaluation as estimation of surprisal/predictability,
- contamination and benchmark leakage in foundation models,
- validation of NLP-derived constructs in social science.

Concrete additions that would strengthen positioning:
- **Bommasani et al. (2021), “On the Opportunities and Risks of Foundation Models”** — for contamination/pretraining and domain adaptation context.
- **Bender et al. (2021), “On the Dangers of Stochastic Parrots”** — not because the paper is about ethics, but because claims about what models “know” and what predictive performance means should be carefully framed.
- **Grimmer, Roberts, and Stewart (2022), *Text as Data*** — for construct validity in political text measurement.
- If there is recent work specifically on surprisal/perplexity as a social measure in political or institutional text, that literature should be added explicitly.

### C. Deliberation literature positioning should be more cautious

The current framing suggests the paper offers a scalable operationalization of Habermasian deliberation. That is too ambitious given the current validation. The better claim is that it offers a scalable measure of contextual coupling or predictability in legislative speech, which may be one ingredient of deliberation.

## 5. Results interpretation and calibration of claims

This is another area where the paper needs tightening.

### A. Over-claiming on “deliberation”

The headline “The Deliberation Index is positive in 85% of turns, confirming that Congressional debate is, at least partially, a genuine conversation” is too strong. At most, the evidence suggests that immediate conversational context improves prediction for most turns under this model.

### B. Over-claiming on institutional theory

The paper says it provides “direct evidence” for mechanisms of institutional design (Introduction; Section 7.1). The evidence is descriptive and consistent with the theory, but it does not isolate the mechanism.

### C. Magnitude interpretations are not valid on the perplexity scale

As noted above, several interpretations of “3–8 perplexity points” or “2.5 fewer plausible next words” are not properly grounded. This matters because the paper leans heavily on magnitude.

### D. The House-higher-DI result is intriguing but unstable

The paper builds an interpretive story around the House having higher DI than the Senate. But with only 832 sampled turns and no uncertainty intervals, this is not a stable enough fact to support extensive theorizing.

### E. The neural-vs-classical divergence is interesting but not yet interpretable

Because the 2011 break may coincide with a source/segmentation break, Section 6.4 currently cannot support strong conclusions about a divergence between lexical polarization and conversational dynamics over time.

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

#### 1. Redefine the core estimand on an appropriate information scale
- **Issue:** DI is defined as a difference in perplexities, which is not information-theoretically meaningful.
- **Why it matters:** This is the paper’s central measure; if it is malformed, the core result is not interpretable.
- **Concrete fix:** Recompute all main quantities using average negative log-likelihood / cross-entropy / surprisal (bits or nats per token). Define the context gain as a difference in cross-entropies, not perplexities. Rewrite all magnitude interpretations accordingly.

#### 2. Resolve the unseen-speaker / speaker-token leakage problem
- **Issue:** Holdout includes many speakers not in training, yet DI conditions on speaker identity.
- **Why it matters:** The main measure may be biased or undefined for unseen speakers.
- **Concrete fix:** Report seen/unseen speaker shares in holdout; present results separately; either restrict DI to seen speakers, use a coarser identity representation, or redesign the marginal baseline. Explain exactly how unseen speaker tokens are handled.

#### 3. Add valid statistical inference for all headline findings
- **Issue:** No SEs/CIs/tests for key estimates.
- **Why it matters:** A paper cannot pass without valid inference.
- **Concrete fix:** Provide cluster-robust or bootstrap confidence intervals for mean DI, positive-DI share, chamber gaps, and time-series differences. Make the unit of inference explicit (turn, conversation, or year) and justify clustering.

#### 4. Compute DI on the full holdout corpus
- **Issue:** The central result is based on a very small sample despite full computation being feasible.
- **Why it matters:** Current estimates may be noisy and unrepresentative.
- **Concrete fix:** Run the two-pass computation for all 2015–2024 GovInfo turns, or at least for a very large, transparently sampled and weighted subset with precision targets.

#### 5. Reframe or identify the institutional claim
- **Issue:** The paper makes causal claims it does not identify.
- **Why it matters:** Overstating descriptive evidence undermines credibility.
- **Concrete fix:** Either (a) reframe all House-Senate claims as descriptive correlations consistent with theory, or (b) add a design that isolates institutional mechanisms (e.g., matched debate types, procedural-rule changes, fixed-effects decomposition).

#### 6. Remove or repair analyses confounded by the 2011 source change
- **Issue:** Several trend claims may reflect a data break.
- **Why it matters:** The most dramatic time-series interpretations may be artifacts.
- **Concrete fix:** Restrict those analyses to a uniform data regime or provide bridging evidence showing comparability across sources and segmentation schemes.

### 2. High-value improvements

#### 7. Add validation against external measures of deliberation or responsiveness
- **Issue:** The construct validity of DI is currently weak.
- **Why it matters:** Without validation, “deliberation” remains mostly a label.
- **Concrete fix:** Compare DI to hand-coded responsive turns on a subsample, debate-quality annotations, interruptions, amendment discussion, or citation/quotation of prior speakers.

#### 8. Add robustness to alternative model choices
- **Issue:** Results come from one small model and one training run.
- **Why it matters:** The measurement instrument may be model-specific.
- **Concrete fix:** Replicate main patterns across model sizes, checkpoints, context windows, and tokenization/specification variants.

#### 9. Separate procedural speech from substantive speech
- **Issue:** Procedural formulae may dominate predictability.
- **Why it matters:** Chamber differences may mostly reflect procedural language.
- **Concrete fix:** Re-estimate core findings excluding procedural turns, presiding-officer turns, and common formulaic phrases; report substantive-only results.

#### 10. Add placebo/shuffle tests
- **Issue:** No evidence that context effects are truly conversational.
- **Why it matters:** DI may mostly capture topic persistence or sequencing artifacts.
- **Concrete fix:** Shuffle turn order within conversation, replace context with matched placebo contexts, and show the context gain collapses under these falsifications.

#### 11. Control for topic and composition in chamber comparisons
- **Issue:** House-Senate gaps may be agenda-driven.
- **Why it matters:** Topic composition is an obvious confound.
- **Concrete fix:** Estimate chamber differences within topic/date cells or matched bill categories; add decomposition tables.

### 3. Optional polish

#### 12. Clarify the unit of observation throughout
- **Issue:** The paper sometimes shifts between tokens, turns, conversations, years.
- **Why it matters:** Interpretation of averages and uncertainty depends on the unit.
- **Concrete fix:** State clearly for each result whether it is token-, turn-, conversation-, or year-weighted.

#### 13. Improve transparency on sampling and preprocessing
- **Issue:** Some design choices are underdescribed.
- **Why it matters:** Reproducibility and interpretation depend on them.
- **Concrete fix:** Add an appendix table with exclusions, sampling strata, seen/unseen speaker counts, and the prevalence of procedural turns.

#### 14. Tone down claims of “clean instrument”
- **Issue:** The model is less contaminated than a web-pretrained model, but not therefore a clean causal instrument.
- **Why it matters:** “Instrument” suggests a level of identification and validity not yet demonstrated.
- **Concrete fix:** Use “measurement model” or “domain-specific predictive model” unless formal validation is supplied.

## 7. Overall assessment

### Key strengths
- Original and creative use of autoregressive language modeling in a political-economy setting.
- Transparent description of data and training pipeline.
- Sensible instinct to avoid generic pretrained models for this application.
- Potentially useful distinction between lexical polarization and sequential/conversational structure.
- The House-Senate descriptives are interesting and may ultimately prove important.

### Critical weaknesses
- The core measure is defined on an inappropriate scale.
- Statistical inference is largely absent.
- The main “institutional design” interpretation is not identified.
- The DI construct lacks validation and is overinterpreted as deliberation.
- Speaker-token handling raises a serious seen/unseen holdout comparability problem.
- Several headline time-series interpretations are confounded by the 2011 source/segmentation break.
- The central DI analysis is based on too small a sample given the stakes and feasibility of full computation.

### Publishability after revision
I think there is a potentially publishable paper here, but it would require substantial reworking. The most plausible route is as a **measurement/descriptive paper** with:
- a corrected information-theoretic estimand,
- full-holdout computation,
- valid uncertainty quantification,
- careful treatment of seen/unseen speakers,
- stronger validation and placebo evidence,
- and a much more restrained interpretation of what the measure captures.

If the authors want to retain strong claims about institutional design or deliberation quality, they need considerably more design and validation work than is currently present.

DECISION: REJECT AND RESUBMIT