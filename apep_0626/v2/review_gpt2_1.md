# GPT-5.4 (R2) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-04-09T02:38:42.583844
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 20171 in / 5905 out
**Response SHA256:** 0817e47d8cc3eee7

---

This paper studies an important historical policy question with unusually rich linked census data and a clear substantive motivation: did the 1924 Johnson-Reed Act improve native workers’ economic outcomes in places most exposed to the restriction? The paper’s headline findings are a null effect on occupational upgrading and a negative effect on transitions into homeownership, especially for younger and urban native-born men.

The topic is of broad interest, and the data effort is impressive. However, in its current form the paper is not publication-ready for a top general-interest journal or AEJ: Economic Policy. The central problem is identification: the design does not credibly isolate the causal effect of the 1924 restriction from pre-existing differential county trends. In fact, the paper’s own placebo exercise shows strong differential pre-trends, which undermines rather than validates the baseline design. Several inference and interpretation issues further weaken confidence in the results, especially the stronger claims around homeownership and complementarity.

I organize the review around the requested criteria.

---

## 1. Identification and empirical design

### Main concern: the paper is not currently identified for the stated causal claim

The core specification in Section 4 regresses individual outcome changes from 1920 to 1930 on county exposure measured by the 1920 restricted-origin immigrant share, with state FE, occupation FE, and controls. This is described as exploiting quasi-random cross-county variation in pre-quota immigrant concentration.

That is not sufficient for causal identification. Counties with large 1920 Southern/Eastern European populations were not “as good as randomly assigned” conditional on state and occupation FE. They were disproportionately industrial, urban, high-growth, and on distinct long-run trajectories. The identifying assumption stated in Section 4.2 — that exposure is “as-if-randomly assigned conditional on state fixed effects and initial occupation” — is not credible.

More importantly, the paper’s own evidence contradicts it. Section 7 shows that high-exposure counties had substantially faster native occupational upgrading in 1910–1920. That is a direct violation of a parallel-trends-type assumption. The paper tries to argue that this “biases against” finding positive post effects, but this is not enough. If exposure predicts different pre-trends, then a simple cross-sectional post-period change regression does not identify the causal effect of restriction unless one explicitly models and nets out those differential trends.

Put differently: the current design cannot distinguish “restriction eliminated a positive trend” from “high-exposure counties mean-reverted / experienced unrelated shocks after 1920.” The placebo is therefore not supportive; it is diagnostic of identification failure.

### The treatment period is also not cleanly aligned with the policy

The paper attributes the shock to the 1924 Johnson-Reed Act, but the outcome window is 1920–1930. This decade includes several major immigration-policy and macro shocks:

- the 1921 Emergency Quota Act,
- the 1924 Johnson-Reed Act,
- post-WWI adjustment,
- the late-1920s boom,
- and the onset of the Depression by 1930.

Thus the “post” period is not a clean Johnson-Reed period, and the paper overstates timing sharpness in Sections 1–2. The statement that the quotas were “binding for the entire 1920–1930 intercensal period” is inaccurate. At minimum, the design identifies some bundled effect of the 1920s restriction regime plus contemporaneous differential local shocks, not a clean 1924 Act effect.

### The first stage is suggestive, but it does not solve the design problem

Table 6 shows that counties with higher exposure experienced larger declines in restricted-origin foreign-born shares from 1920 to 1930. That is useful descriptive evidence that exposure captured policy incidence. But it does not address the central endogeneity of settlement patterns, nor does it validate the reduced-form county-exposure design.

Also, the first stage uses county-level regressions with “IID standard errors” (Table 6 note). That is not appropriate for a weighted county-level regression with likely heteroskedasticity and spatial/state correlation. While the t-statistic is so large that significance is unlikely to disappear, inference should still be corrected.

### The paper needs a true difference-in-differences/event-study design at the county level

Given the available data, the more credible design would compare county outcomes over multiple decades with county FE and period FE, using exposure interacted with post-restriction indicators. The paper currently has two linked panels (1910–1920 and 1920–1930), but analyzes them separately. The obvious next step is to estimate something like:

\[
\Delta Y_{ct} = \alpha_c + \lambda_t + \beta (\text{Exposure}_c \times Post_t) + \epsilon_{ct}
\]

or the individual analogue with county and cohort-period FE, where the identifying variation is the differential break in trends after restriction, not the level relation in one decade.

Even that would require caution because only two periods are shown and there are pre-trend concerns. But it would be much closer to a valid design than the current setup.

### Other identification threats not adequately addressed

1. **Selective linkage / sample selection into linked panels**  
   The paper relies entirely on linked MLP samples, but does not show whether linkage rates vary by exposure, mobility, occupation, race, or outcome-relevant factors. If linkage quality differs systematically across high- and low-exposure counties, coefficients may reflect sample selection rather than treatment effects.

2. **Survivorship and migration selection**  
   Linked 1920–1930 outcomes are observed only for people found in both censuses. Survival, name changes, and interstate migration may all be non-random. “Moved” is itself an outcome, but the ability to observe a move depends on being linked.

3. **Differential local industrial shocks**  
   State FE are too coarse. High-exposure counties were concentrated in industrial areas that experienced distinctive 1920s sectoral changes. Occupation FE do not absorb county-level industrial composition trends. At minimum, county baseline controls or pre-1920 trend controls are needed; ideally, county FE in a multi-period design.

4. **Interpretation of 1910 exposure robustness**  
   Using 1910 exposure in Appendix Table A3 helps with concerns about endogenous settlement from 1910 to 1920, but it does not fix the core issue that immigrant settlement itself reflects underlying county growth patterns.

---

## 2. Inference and statistical validity

### Main estimates report uncertainty, but key inference issues remain

The paper generally reports coefficients and standard errors for main results, which is good. Sample sizes are also reported and seem internally consistent.

However, several statistical-validity concerns remain.

### County-level treatment with 10 million individual observations raises finite-cluster concerns

Treatment varies at the county level, but regressions are run at the individual level with two-way clustering by state and county. County clustering is necessary and appropriate. State clustering may also be useful. But the effective variation is county-level, not individual-level, so the paper should demonstrate that inference is not being driven by the massive individual N.

I would strongly recommend:

- reporting county-level regressions as a check for main outcomes,
- using wild-cluster bootstrap inference at the state level if state clustering is retained,
- and clarifying the number of county clusters actually contributing to each specification.

### First-stage inference is not acceptable as currently reported

Table 6 uses IID standard errors. This should be replaced by heteroskedasticity-robust and preferably state-clustered inference, or justified otherwise. A top journal will not accept “IID SE” in this context.

### Homeownership specifications need clearer definition and coherent estimands

Table 2, column 5 uses “became owner” in the full sample, coded 1 if not owner in 1920 and owner in 1930, 0 otherwise. This combines those at risk of transition with those already owners in 1920, for whom “becoming owner” is mechanically impossible. That estimand is hard to interpret.

Table 3 then moves to a cleaner renters-only specification (column 1), which is the right object for entry into ownership. But the paper continues to emphasize the full-sample coefficient from Table 2 in the abstract, introduction, and discussion. That is not ideal.

Worse, Table 3 column 3 (“net ownership”) is statistically insignificant. So the strongest claim — that restriction reduced native homeownership — is not fully established if one focuses on a net transition measure rather than a renters-only entry hazard. The paper needs to be much more careful here.

### Multiple testing / selective emphasis

The paper studies many outcomes: OCCSCORE change, upgraded, farm exit, moved, SEI, became owner, ladder up, self-employment, subgroup splits by race, urban/rural, age, owners/renters, pre-period placebo, alternative exposures, leave-one-origin-out. The homeownership result is singled out as the “hidden cost” because it is significant while most other outcomes are not.

That may be substantively real, but the paper should address multiple-hypothesis concerns, especially because the central positive result comes from one among many outcomes and then several subgroup splits. At minimum, it should discuss family-wise interpretation or report sharpened q-values / Romano-Wolf / Benjamini-Hochberg adjustments for a defined family of outcomes.

---

## 3. Robustness and alternative explanations

### Current robustness is not enough for the causal claims

The existing robustness checks are useful but largely orthogonal to the main threat.

- Leave-one-origin-out does not address differential trends.
- Non-movers only does not address differential trends.
- Alternative exposure year does not address differential trends.
- Broader exposure measure does not address differential trends.
- State-only clustering does not address differential trends.

The core omitted variable is county-specific trend heterogeneity correlated with immigrant settlement. None of the main robustness checks solve that.

### The placebo is meaningful, but currently misinterpreted

The 1910–1920 result is treated as evidence of complementarity and used to bolster the story that restriction disrupted positive immigrant-native interactions. That is plausible as interpretation, but econometrically the placebo first tells us that treated and control counties were on very different paths before 1924.

As written, the paper too quickly jumps from “positive pre-period association” to “restriction destroyed complementarity.” That is one interpretation, but not the only one. Other explanations include:

- differential sectoral expansion pre-1920 in immigrant-heavy counties,
- mean reversion by the 1920s,
- differential postwar industrial restructuring,
- geographic changes in farm-to-city mobility,
- or changes in cohort composition among linked natives.

The paper needs to distinguish much more sharply between:
1. reduced-form descriptive contrasts,
2. causal effects of restriction,
3. and mechanism evidence on complementarity.

Right now these are conflated.

### Mechanism evidence is suggestive, not demonstrated

The construction/housing-supply complementarity mechanism in Section 6 is interesting, but there is no direct evidence presented on:

- construction employment,
- housing construction,
- rents,
- housing values,
- building permits,
- local credit conditions,
- or occupational shifts into/out of construction-related sectors.

Without such evidence, the homeownership channel remains speculative. For a paper highlighting homeownership as the “central contribution,” mechanism support needs to be stronger.

### External validity and limits should be more candid

Section 9 briefly notes that the 1920s do not mechanically map to the present. That is appropriate, but the paper still sometimes implies a broader lesson about immigration restriction generally. Given the historical specificity — national-origin quotas, interwar labor markets, male-only linked sample, county-level immigrant enclaves, severe measurement limitations — the policy extrapolation should be more restrained.

---

## 4. Contribution and literature positioning

### The substantive question is important and potentially publishable

The paper’s strongest asset is the question. There is clear value in studying the local economic incidence of the 1920s restriction regime using linked microdata. The homeownership margin is also potentially novel.

### But the contribution relative to existing work needs tightening

The paper positions itself relative to Goldin, Tabellini, Sequeira et al., Borjas, Ottaviano-Peri, Moretti, etc. That is a reasonable start, but two literatures are underdeveloped:

1. **Shift-share / immigrant-settlement identification critiques**  
   Because the design explicitly relies on historical settlement patterns and a national shock, the paper needs to engage the modern methodological literature on the assumptions behind such designs and their failure modes.

   Concrete citations to add:
   - Jaeger, Ruist, and Stuhler (2018), “Shift-Share Instruments and the Impact of Immigration”
   - Goldsmith-Pinkham, Sorkin, and Swift (2020), “Bartik Instruments: What, When, Why, and How”
   - Borusyak, Hull, and Jaravel (2022), “Quasi-Experimental Shift-Share Research Designs”

   These matter because the paper’s own identifying language invokes “standard shift-share logic.”

2. **Historical immigration restriction / quota-era economic effects**  
   The literature review would benefit from closer engagement with work specifically on quotas and interwar immigration changes, not only broader historical immigration inflows. If there are papers on the 1921/1924 restrictions’ local effects, quota allocation, or interwar immigrant adjustment, those need to be discussed. Even if the paper is the first on this exact margin, it should more explicitly differentiate itself from nearby historical and political economy papers on the restriction era.

### The paper overstates novelty of complementarity interpretation

The complementarity framing is plausible but not new by itself. What could be novel is: “in the quota-restriction setting, exposed counties did not exhibit native occupational gains and may have seen reduced ownership entry.” That is a defensible contribution. The current broader framing — that the paper adjudicates the substitution vs complementarity debate using a “rare opportunity” — is too ambitious given the empirical limitations.

---

## 5. Results interpretation and claim calibration

### The occupational null is fairly well supported descriptively, but not causally

A fair reading is: across many specifications, there is little evidence that high-exposure counties saw greater native occupational upgrading from 1920 to 1930. That descriptive fact seems robust.

But the stronger causal claim — “the 1924 restriction delivered no measurable occupational gains” — is not yet warranted, because the design does not identify the counterfactual trend absent restriction.

### The homeownership claims are overstated relative to the evidence

This is the most overclaimed part of the paper.

Issues:

1. The abstract and introduction present the negative homeownership effect as a central causal finding.
2. The baseline “became owner” result uses the full sample, not the at-risk renter sample.
3. The net ownership effect is insignificant in Table 3, column 3.
4. Mechanisms are not directly tested.
5. Multiple testing concerns are not addressed.

A more calibrated statement would be that the paper finds suggestive evidence that exposure was associated with lower transitions into ownership among renters, especially younger and urban men, but that this channel requires stronger validation.

### The placebo does not justify the “restrictionist mirage” claim as currently framed

The phrase is rhetorically effective, but scientifically it moves too far ahead of what is shown. The pre-period positive association could reflect complementarity, but it also demonstrates confounding. The paper needs to either:
- redesign the empirical strategy to identify a post-1924 break, or
- downgrade the claims to descriptive historical patterns.

### Some reported magnitudes need contextualization

The paper helpfully translates coefficients into effects for a one-SD increase in exposure. That should be done systematically in the main text for all headline results, not just in the appendix/discussion. It would help readers assess whether “null” means economically tiny or merely imprecisely estimated. For OCCSCORE, the CI around the main estimate still permits modest positive or negative effects; the paper should report confidence intervals in substantive units.

---

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

#### 1. Redesign identification around differential breaks, not one-period cross-sectional change
- **Issue:** The current baseline is not causally identified because exposure predicts pre-1924 trends.
- **Why it matters:** This is the central credibility problem. Without fixing it, the paper cannot support causal claims about Johnson-Reed.
- **Concrete fix:** Recast the design as a county-by-period panel using at least 1910–1920 and 1920–1930 changes, with county FE and period FE, and estimate the post-restriction break in the exposure gradient. If possible, add earlier periods or external county-level data to assess pre-trends more directly.

#### 2. Reinterpret the placebo correctly and address pre-trend failure explicitly
- **Issue:** The 1910–1920 result is currently used as supportive evidence, but it primarily shows identification failure for the baseline.
- **Why it matters:** A top journal will view this as a major internal contradiction.
- **Concrete fix:** Rewrite Section 7 so that the placebo is first treated as a threat. Then show whether a redesigned specification can accommodate differential pre-trends (e.g., county trends, stacked first differences, or break-in-trend specifications).

#### 3. Clarify policy timing and isolate the treatment period more carefully
- **Issue:** The 1920–1930 window conflates 1921 and 1924 restrictions and other 1920s shocks.
- **Why it matters:** The paper currently over-attributes the decade effect to Johnson-Reed specifically.
- **Concrete fix:** Reframe as the interwar quota regime unless you can isolate post-1924 timing with finer data. At minimum, acknowledge the Emergency Quota Act and temper “virtually overnight” claims.

#### 4. Address linkage/sample-selection concerns
- **Issue:** Linked-sample selection may vary by exposure and outcome.
- **Why it matters:** This could bias all estimates.
- **Concrete fix:** Report linkage rates by county exposure quartile and baseline characteristics; test whether exposure predicts being linked; reweight for linkage propensity if feasible; compare linked sample to full-count or broader census aggregates.

#### 5. Fix inference in Table 6 and strengthen cluster-robust uncertainty throughout
- **Issue:** First-stage IID SE are not acceptable; cluster robustness should reflect the treatment variation.
- **Why it matters:** Statistical validity is non-negotiable.
- **Concrete fix:** Re-estimate county-level regressions with robust and state-clustered SE; consider county-level aggregation checks for main outcomes and wild-cluster bootstrap inference where relevant.

### 2. High-value improvements

#### 6. Rework homeownership analysis around clearly defined at-risk samples
- **Issue:** The full-sample “became owner” measure is hard to interpret.
- **Why it matters:** The paper’s strongest positive finding currently rests on an awkward estimand.
- **Concrete fix:** Make renters-only transition to ownership the primary ownership outcome; present owners-only loss and net ownership as secondary. Revise the abstract/introduction accordingly.

#### 7. Address multiple-hypothesis testing
- **Issue:** Many outcomes and subgroup analyses are explored, with one significant family emphasized.
- **Why it matters:** The homeownership finding could be a false positive absent adjustment.
- **Concrete fix:** Define outcome families and report adjusted p-values/q-values, at least for the main occupational and ownership outcomes.

#### 8. Add county baseline controls / sectoral composition checks
- **Issue:** Exposure is correlated with urbanization and industrial structure.
- **Why it matters:** These are likely confounders for both occupational mobility and homeownership.
- **Concrete fix:** Add 1920 county controls such as manufacturing share, agriculture share, urbanization, baseline homeownership, foreign-born share by unrestricted origins, and perhaps interacted region trends.

#### 9. Provide direct evidence for the housing/complementarity mechanism
- **Issue:** Mechanism claims are currently speculative.
- **Why it matters:** The paper’s policy punchline rests heavily on this mechanism.
- **Concrete fix:** Examine construction employment, building activity, housing stock growth, rent/value measures, or sectoral occupational changes using census or historical county data.

#### 10. Report substantive confidence intervals for headline effects
- **Issue:** “Null” and “small” are not always clearly quantified.
- **Why it matters:** Readers need to know what magnitudes are ruled out.
- **Concrete fix:** Report 95% CIs translated into one-SD treatment changes and percentages of baseline means.

### 3. Optional polish

#### 11. Tighten contribution claims
- **Issue:** The paper sometimes overstates that it adjudicates the general immigration debate.
- **Why it matters:** Better calibration will improve credibility.
- **Concrete fix:** Frame contribution more narrowly around historical restriction incidence and specific local outcomes.

#### 12. Expand literature engagement on shift-share methods
- **Issue:** Methodological positioning is incomplete.
- **Why it matters:** Reviewers in top journals will expect it.
- **Concrete fix:** Add and discuss Jaeger-Ruist-Stuhler (2018), Goldsmith-Pinkham et al. (2020), and Borusyak-Hull-Jaravel (2022), especially in the identification section.

---

## 7. Overall assessment

### Key strengths
- Important and timely substantive question.
- Very large linked microdata sample with rich individual outcomes.
- Clear exposition of the historical policy setting.
- Broad set of outcome measures.
- Potentially interesting and novel ownership margin.

### Critical weaknesses
- The causal design is not currently credible.
- The placebo reveals differential pre-trends and thus undermines the main identifying assumption.
- Policy timing is overstated and bundled with other 1920s shocks.
- Homeownership claims are stronger than the evidence supports.
- Linkage selection and some inference issues are not adequately addressed.

### Publishability after revision
I do think there is a potentially publishable paper here, but it would require substantial redesign of the empirical strategy and significant recalibration of claims. This is not a case of polishing a basically sound design. The core causal architecture needs to be reworked.

If the authors can re-estimate the question using a genuine differential-break framework, address selection/inference issues, and present the homeownership evidence more carefully, the paper could become a serious contribution. In its current form, however, it is not ready.

DECISION: REJECT AND RESUBMIT