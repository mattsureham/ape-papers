# GPT-5.4 (R1) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-11T15:29:35.784258
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 19542 in / 5336 out
**Response SHA256:** c55599decec8afdf

---

This paper asks an important and policy-relevant question: whether EU-subsidized student mobility through Erasmus+ undermines regional human capital accumulation, especially in poorer peripheral regions that are simultaneously targeted by Cohesion Policy. The topic is interesting, the data assembly is ambitious, and the paper is unusually transparent about several weaknesses in its own design. That transparency is commendable. However, for a top general-interest journal or AEJ: Economic Policy, the current version is not publication-ready because the central causal claim is not convincingly identified.

The core problem is not that the paper lacks suggestive patterns. It has many. The problem is that the patterns do not survive the paper’s own most relevant identification stress tests, and the remaining results are difficult to interpret as causal. In particular: (i) the main NUTS2 panel effect disappears with country-by-year fixed effects; (ii) the NUTS3 long-difference design has a weak first stage and an outcome that is only an indirect proxy for human capital; (iii) randomization inference indicates the shift-share design is not clearly identified off shocks; and (iv) the paper leans heavily on heterogeneity and placebo results that are not sufficient to rescue the main identification problem.

Below I organize the review around identification, inference, robustness, contribution, interpretation, revision priorities, and overall assessment.

---

## 1. Identification and empirical design

### A. The central causal design is not yet credible enough for the stated claims

The paper’s principal claim is that Erasmus outflows “reduce regional human capital,” with effects concentrated in peripheral regions (Abstract; Introduction; Sections 5–8). The main statistically significant estimate supporting this is the NUTS2 panel 2SLS estimate in Section 5.3/Table 4: a one-unit increase in outflow rate lowers tertiary share among 25–34-year-olds by 0.39 percentage points. But this result is substantially undermined by the paper’s own diagnostic that adding country-by-year fixed effects eliminates the effect entirely.

That specification is not a minor robustness check; it is a central identification test. Since Erasmus policy, higher education institutions, labor market conditions, macro shocks, migration policy, and educational reforms are strongly country-time specific, country-by-year fixed effects are close to the natural benchmark for a design that claims subnational causal identification. Once these are added, the effect becomes essentially zero (Table 4, col. 4). That means the primary signal is not robust to absorbing national shocks and national policy changes. The manuscript acknowledges this, but then still treats the baseline estimate as the main causal result. That calibration is too strong.

### B. The NUTS3 “go/no-go” diagnostic is useful but does not solve the identification problem

Section 4.4 shows that the NUTS3 Bartik has substantial within-country variation and a strong first stage even with country-by-year fixed effects. This is a useful diagnostic. But it demonstrates only that the instrument predicts treatment variation at NUTS3; it does not show that the resulting variation is exogenous for the outcome of interest. The paper overstates what this diagnostic establishes.

In fact, the outcome available at NUTS3 is not human capital stock but the youth population share (Sections 3.2 and 4.1). That is a very imperfect proxy for “brain drain” or tertiary human capital depletion. Changes in the 25–34 share of population can reflect fertility history, non-Erasmus migration, refugee inflows, internal migration, aging, housing markets, and denominator effects. So the strong NUTS3 first stage does not bridge to the paper’s central claim unless the reduced form and IV at NUTS3 are also convincing on a human-capital-relevant outcome, which they are not.

### C. The NUTS3 long-difference specification is weakly identified

In Table 3, the NUTS3 long-difference 2SLS has a first-stage F of 6.5–9.4 depending on calculation. The paper candidly notes weak-instrument concerns. That should be taken more seriously. A just-below-10 first stage in a clustered cross-sectional setting with a shift-share IV is not adequate for a headline result, especially when the reduced-form relationship appears positive in Figure 3 while the IV estimate is negative. This sign pattern may be possible, but it heightens concern that the estimate is unstable and heavily driven by the instrument’s structure.

Moreover, the first-stage sign in Table 2, col. 1 is negative: higher predicted destination growth is associated with lower outflow rates. The paper offers a “competition for slots” interpretation. That is possible, but this sign reversal is conceptually awkward for a Bartik intended to proxy exogenous increases in destination attractiveness. It raises the question of whether the constructed shift is mapping onto the intended economic object. At minimum, this needs much deeper conceptual and empirical validation.

### D. The NUTS2 long-difference estimate is difficult to interpret

The NUTS2 long-difference estimate is positive (Table 3, col. 3), opposite-signed relative to the NUTS2 panel estimate. The paper interprets this as “brain circulation” over longer horizons. That is possible, but the current evidence does not separate that interpretation from simpler possibilities: compositional changes, trend differences, measurement error smoothing, changing treatment intensity, sample selection, or instrument non-comparability across specifications.

A sign flip between the two main outcome specifications is not a minor nuance; it is central to the paper’s interpretation. As presented, the paper treats this as substantively interesting rather than as a major challenge to design coherence. That is not convincing.

### E. Key identifying assumptions are not made sufficiently operational or testable

The manuscript correctly cites Borusyak-Hull-Jaravel and Goldsmith-Pinkham-Sorkin-Swift, but it does not fully operationalize the assumptions needed in this setting.

For example:

- What exactly are the shocks? Growth in destination inflows may reflect destination labor demand, university expansion, language-policy changes, visa rules, and network formation. Many of these may be correlated with origin-region trajectories through migration systems or macro integration.
- Why should pre-period shares be conditionally exogenous after country FE only? The paper itself shows that they may not be, via RI.
- What is the exclusion restriction for tertiary share? Erasmus outflows may affect local university quality, admissions behavior, local labor demand for graduates, or compositional selection into the measured population. The paper does not clearly distinguish these channels from the claimed “drain.”

The paper needs a more explicit causal estimand and a more disciplined account of the identifying variation that remains after the relevant fixed effects.

### F. Treatment timing and exposure mapping remain underdeveloped

The paper notes the mismatch between Erasmus participation ages and later observed tertiary shares (Section 4.3; Table 5). But the timing logic is still not fully coherent. The outcome is the share of 25–34-year-olds with tertiary education in region-year \(t\), while treatment is annual outflow rate in the same region-year. This is not obviously the right contemporaneous exposure. Current tertiary share partly reflects cohorts whose Erasmus decisions occurred several years earlier and may be affected by migration after graduation, not just immediate outflows. The lag exercise is helpful but rudimentary.

A more credible design would define cohort-relevant exposure more explicitly, e.g. stacked event-time or cohort-exposure measures tied to ages at likely Erasmus participation, and then examine downstream regional residence outcomes.

---

## 2. Inference and statistical validity

### A. The paper reports uncertainty measures, but inference is not fully aligned with design risk

A strength is that standard errors, sample sizes, and first-stage diagnostics are generally reported. The paper also presents clustered SEs and a two-way cluster variant in the NUTS2 panel. That is good practice.

However, because the central design is shift-share, valid inference requires more than conventional region clustering. The paper’s “AKM-type” inference is not convincing as currently implemented. Section 7.2 says it “approximates AKM-type standard errors by assigning each region to its primary (modal) destination and clustering at the destination level.” That is not an established substitute for AKM or AKM0 inference. It is an ad hoc approximation that could easily misstate uncertainty. It should not be treated as evidence that baseline SEs are conservative.

If the paper wants to rely on shift-share identification, it should implement design-appropriate inference directly, not a heuristic clustering proxy.

### B. Randomization inference strongly weakens the paper’s causal claims

The RI p-values of 0.49 and 0.44 (Section 7.1) are highly consequential. They imply the observed estimates are not unusually large relative to estimates generated by permuting the shocks. For a paper whose identification rests on exogenous destination shocks, this is a major failure. The manuscript is transparent about it, but the substantive claims still read as too affirmative throughout the Abstract, Introduction, Discussion, and Conclusion.

This issue is not cosmetic. A top-journal empirical paper cannot frame results as causal or even “strongly suggestive” when the primary shock-based randomization test is this uninformative, unless there is another independent source of identification. Here there is not.

### C. Sample coherence is acceptable but should be made cleaner

The paper is mostly transparent about different sample sizes across OLS, IV, panel, and long-difference specifications. Still, a reader is left with uncertainty about exact sample transitions, especially between Table 2, Table 3, and Table 4. A formal sample accounting table would help. More importantly, the fact that IV requires dropping zero-pre-period Erasmus regions is not innocuous: that changes the estimand and could select toward more internationally connected places. The paper should treat this as a substantive issue, not just a data requirement.

### D. Weak instrument concerns in the NUTS3 design are serious

Given the first-stage F below 10 in Table 3 and the unusual first-stage sign, weak-IV robust inference is necessary. The paper currently reports conventional 2SLS estimates and standard errors. It should report Anderson-Rubin confidence sets, weak-IV robust p-values, and perhaps LIML/Fuller estimates for the NUTS3 cross-section. Without those, the NUTS3 IV result is not statistically credible.

---

## 3. Robustness and alternative explanations

### A. Some robustness exercises are useful, but the most important robustness check fails

The paper includes placebo age-group analysis, leave-one-country-out, no-COVID estimation, lags, heterogeneity, and pre-trends. This is a substantial battery.

But robustness is not about quantity of checks; it is about whether the crucial identifying threats are addressed. Here the main threat is national confounding and share-driven identification. On those dimensions:

- country-by-year FE kills the main effect;
- RI does not support shock exogeneity.

These two facts dominate many of the more supportive checks.

### B. The placebo test is suggestive, not decisive

The 25–64 placebo null is directionally sensible (Table 6). But this is not a clean placebo because the broader age group dilutes exposure mechanically and is governed by different secular education trends. A null on 25–64 does not strongly validate the causal mechanism for 25–34. A better placebo would involve outcomes less plausibly affected by Erasmus but similarly measured at the regional level, or older cohorts with fixed educational attainment and limited migration responsiveness.

### C. The “pre-trend” test is not well aligned with the design

Section 7.4 describes a pre-trend test regressing tertiary share on predicted outflow using 2014–2019. This is not really a pre-trend test in the DiD sense, since the treatment is already active and the Bartik itself is time-varying over that period. Also, the paper’s narrative emphasizes the 2021 budget expansion, but the data start in 2014 and the panel estimate is not an event-study around 2021. As written, the test does not convincingly establish absence of differential pre-trends.

### D. Mechanism claims remain underidentified

The manuscript uses language of “brain drain,” “return incentives,” and “brain circulation,” but the evidence is reduced-form on regional stocks, not on actual return migration or post-study location choice. The positive long-difference result is interpreted as return migration, but there is no direct evidence on returns. Likewise, the null receiver-side result is attributed to measurement or absorption into stocks, but that too is speculative.

Mechanism discussion is acceptable if clearly labeled as conjectural. In the current draft, some of it is too close to causal interpretation.

### E. Alternative explanations are plausible and not fully ruled out

Several alternatives remain live:

1. **University expansion / institutional changes in destinations and origins**  
   Destination growth in Erasmus inflows may reflect university-level initiatives correlated with origin-country educational reforms.

2. **Internal migration of graduates**  
   Regional tertiary share among 25–34 may respond to domestic mobility toward capitals or metro areas, independent of Erasmus.

3. **Selective denominator movements**  
   Changes in tertiary share may arise from non-tertiary outmigration or inflows rather than tertiary outflows.

4. **Macro shocks and accession dynamics**  
   The Rotemberg discussion suggests Poland, Ireland, Hungary, etc. carry large weights. Those shocks are not plausibly orthogonal to broader European labor market integration or accession-related trends.

5. **Measurement issues in LFS regional estimates**  
   NUTS2 tertiary share may be noisy or revised, and annual variation may reflect sampling rather than true stock changes.

The paper should do more to isolate Erasmus-specific effects from broader youth mobility and regional sorting.

---

## 4. Contribution and literature positioning

### A. The question is interesting and potentially publishable

The paper’s main contribution—linking student mobility subsidies to spatial inequality and place-based policy—is novel and potentially important. The “mobility versus cohesion” framing is strong and attractive for a broad audience.

### B. But the empirical contribution relative to recent work needs sharper differentiation

The manuscript cites recent Erasmus/regional studies but does not convincingly establish what is learned here beyond them. The key purported distinction is NUTS3 bilateral data and the within-country Bartik diagnostic. That is meaningful, but because the substantive causal results do not survive the strongest tests, the current empirical contribution is more methodological/diagnostic than substantive.

The paper should more clearly state whether it is:
1. primarily a cautionary paper about the limits of regional causal inference in Erasmus settings;
2. a paper documenting suggestive patterns of peripheral human capital loss; or
3. a paper making a strong causal claim.

At present it tries to be all three.

### C. Literature coverage is decent but several references/streams should be incorporated more concretely

For method and interpretation, the paper should engage more directly with:

- **Adão, Kolesár, Morales (2019, QJE)** on valid shift-share inference, beyond citation.
- **Borusyak, Hull, Jaravel (2022, Econometrica/QJE depending cited version)** with a more concrete mapping of assumptions to this setting.
- **Goldsmith-Pinkham, Sorkin, Swift (2020, AER)**, especially on share endogeneity and the relevance of shares vs shocks.
- If using panel event-time or staggered treatment logic anywhere implicitly, the paper should clarify why modern DiD concerns are not central here, or adapt the design.
- Literature on **brain circulation / skilled migration returns**, e.g. Beine, Docquier, Rapoport more systematically, if long-difference interpretation is retained.
- Literature on **place-based policy and mobility** could include work on local human capital externalities and migration responses to regional policy in Europe more specifically.

I would also recommend adding some direct literature on regional sorting and higher-education-related migration within Europe, because many of the alternative explanations operate through internal graduate mobility rather than Erasmus per se.

---

## 5. Results interpretation and claim calibration

### A. The paper over-claims relative to its own evidence

The biggest issue in interpretation is mismatch between evidence strength and framing. The Abstract currently foregrounds a negative panel estimate and strong peripheral heterogeneity, but only later notes that the result attenuates under country-by-year FE and RI yields p = 0.44. For a top-journal abstract, those caveats are not secondary—they are central.

Likewise, the Introduction says “I find exactly this” for heterogeneity and speaks of a “fundamental tension” revealed by the evidence. That goes too far. What the paper currently shows is suggestive evidence of a tension, with serious unresolved identification concerns.

### B. Policy implications are too strong for the identification quality

Section 8.5 proposes return incentives, compensating transfers, and receiver-side contributions. These are interesting ideas, but the policy discussion is too assertive given that the main effect vanishes under country-by-year FE and the design fails RI. A more proportionate conclusion would be that the findings motivate better monitoring and evaluation of spatial incidence, not that Erasmus spending is demonstrably undermining Cohesion Policy.

### C. Magnitude interpretation needs caution

The calculations translating coefficients into tertiary-share declines and implied wage losses (Section 8.3) are too ambitious for the evidence base. In particular:

- The baseline coefficient is annual/panel and should not be extrapolated naively into cumulative sample-period effects without a clear dynamic model.
- The peripheral-region calculations are based on a split-sample estimate that itself is vulnerable to the same identification concerns as the baseline.
- Mapping tertiary share changes into wage externalities using U.S.-based Moretti elasticities is highly speculative in this context.

These back-of-the-envelope magnitudes should be presented as highly tentative or removed.

### D. There are important internal tensions across reported results

Several internal contradictions need fuller treatment:

- Main NUTS2 panel effect negative; NUTS2 long-difference positive.
- NUTS3 first stage strong in panel with country-year FE, but NUTS2 outcome effect disappears under country-year FE.
- Reduced-form figure for NUTS3 appears positive while IV effect is negative.
- First-stage sign in NUTS3 cross-section is negative.

These may not be fatal individually, but together they suggest the paper does not yet have a coherent empirical narrative.

---

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

#### 1. Rebuild the causal design around a specification that survives the relevant fixed effects
- **Issue:** The main NUTS2 causal result disappears with country-by-year fixed effects.
- **Why it matters:** Without robustness to country-time shocks, the estimated effect is likely confounded by national trends, policies, and macro conditions.
- **Concrete fix:** Re-center the paper on a design where identification is explicitly within-country and within-time. If that is impossible with current outcomes, the paper should not claim causal regional human capital effects. Consider obtaining NUTS3 or microdata outcomes, or redesigning around a source of plausibly exogenous institutional variation (e.g., destination-specific shocks with stronger exclusion, program reforms, or university agreement changes).

#### 2. Implement proper shift-share inference and weak-IV robust inference
- **Issue:** The paper uses conventional clustering and an ad hoc “AKM-type” approximation; NUTS3 IV is weak.
- **Why it matters:** Inference may be invalid, and weak-IV estimates can be severely misleading.
- **Concrete fix:** Implement formal AKM/AKM0-style inference where appropriate; for weak-IV designs report Anderson-Rubin tests/confidence sets, LIML/Fuller estimates, and discuss whether conclusions survive.

#### 3. Reassess the randomization inference failure as central, not ancillary
- **Issue:** RI p-values around 0.44–0.49 indicate the shock-based identification is not persuasive.
- **Why it matters:** This directly undermines the claim that quasi-random destination shocks identify the treatment effect.
- **Concrete fix:** Either develop a different identification strategy not reliant on this assumption, or reposition the paper as descriptive/suggestive and rewrite Abstract, Introduction, Discussion, and Conclusion accordingly.

#### 4. Clarify and validate the economic meaning of the instrument, especially the negative first-stage sign
- **Issue:** In the NUTS3 cross-section, higher Bartik growth predicts lower outflows.
- **Why it matters:** If the instrument does not map cleanly to destination attractiveness-induced outflows, the interpretation of 2SLS is unclear.
- **Concrete fix:** Provide a decomposition and validation exercise showing why this sign arises mechanically/economically, whether it is common across destinations/countries, and whether alternative instrument constructions yield more interpretable first stages.

#### 5. Tighten the estimand and outcome mapping
- **Issue:** “Regional human capital” is measured at NUTS2 by tertiary share and at NUTS3 by youth population share.
- **Why it matters:** These are conceptually different outcomes, and the NUTS3 proxy is weak for the central claim.
- **Concrete fix:** Either secure a more direct NUTS3 human capital outcome, or clearly limit the NUTS3 analysis to demographic composition rather than human capital depletion.

### 2. High-value improvements

#### 6. Provide a clearer design-based decomposition of identifying variation
- **Issue:** It is unclear how much identifying power comes from shocks versus shares, from within-country versus cross-country variation, and from a few heavily weighted destinations.
- **Why it matters:** This is central to whether the design is believable.
- **Concrete fix:** Add a decomposition table showing variance shares, Rotemberg weights, effective number of shocks, and estimates using alternative trimming/exclusion of top-weight destinations.

#### 7. Strengthen treatment timing and cohort mapping
- **Issue:** Contemporaneous annual outflows are not obviously the right exposure for 25–34 tertiary shares.
- **Why it matters:** Misaligned timing can produce spurious or attenuated effects.
- **Concrete fix:** Construct cohort-based exposures or distributed-lag models that better align likely Erasmus participation ages with later observed regional residence/education stocks.

#### 8. Probe alternative explanations directly
- **Issue:** Internal migration, labor-market shocks, educational reforms, and denominator changes remain plausible.
- **Why it matters:** These could generate the observed stock changes independently of Erasmus.
- **Concrete fix:** Add controls or auxiliary outcomes for overall youth migration, domestic migration, employment growth, university enrollment capacity, and non-tertiary population changes; test whether effects concentrate where Erasmus exposure is high but broader migration pressure is low.

#### 9. Rework the placebo/pre-trend framework
- **Issue:** Current placebo and pre-trend exercises are not fully compelling.
- **Why it matters:** Better falsification is needed given weak core identification.
- **Concrete fix:** Use outcomes and cohorts less plausibly affected by Erasmus but measured similarly; if possible, exploit pre-exposure trends using shares constructed from an earlier base period or pseudo-treatment windows.

#### 10. Address sample selection from zero-pre-period Erasmus regions
- **Issue:** IV sample excludes regions without baseline Erasmus links.
- **Why it matters:** This changes the population studied and may bias toward connected regions.
- **Concrete fix:** Characterize excluded regions, discuss the local average treatment population, and test whether results are sensitive to alternative baseline windows or inclusion rules.

### 3. Optional polish

#### 11. Improve calibration of claims throughout
- **Issue:** Framing remains stronger than the evidence warrants.
- **Why it matters:** Credibility depends on matching claims to identification quality.
- **Concrete fix:** Rephrase “reveals,” “confirms,” and “measurably deplete” language to “suggests,” “is consistent with,” etc., unless the design is materially strengthened.

#### 12. Consolidate the empirical narrative
- **Issue:** The paper currently presents several partially contradictory specifications without a clear hierarchy.
- **Why it matters:** Readers need to know which estimate they should trust.
- **Concrete fix:** State explicitly which specification is preferred, why, and what evidence would falsify that preference.

---

## 7. Overall assessment

### Key strengths
- Important and timely question with broad policy interest.
- Ambitious data assembly using bilateral Erasmus flows at fine geographic resolution.
- Strong motivation linking mobility policy and place-based redistribution.
- Commendable transparency about non-robust findings and limitations.
- Heterogeneity and placebo exercises are interesting and potentially useful if embedded in a stronger design.

### Critical weaknesses
- Main causal result disappears with country-by-year fixed effects.
- Randomization inference does not support shock-based identification.
- NUTS3 outcome is an indirect proxy; NUTS3 IV is weakly identified.
- Sign reversals across specifications and unusual first-stage behavior remain unexplained.
- Inference is not yet appropriate for the shift-share design.
- Policy conclusions are stronger than the evidence supports.

### Publishability after revision
In its current form, this is not ready for a top field or general-interest outlet as a causal paper. The project is promising, but it needs either a substantially redesigned empirical strategy or a major reframing as a suggestive/descriptive paper with more modest claims. The current version does not clear the bar for causal identification and inference required by the journals listed in the prompt.

DECISION: REJECT AND RESUBMIT