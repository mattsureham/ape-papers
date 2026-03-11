# GPT-5.4 (R1) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-11T10:41:27.101688
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 14918 in / 5613 out
**Response SHA256:** c102435532bbd546

---

**Summary and recommendation**

This paper studies Spain’s 2022 labor reform using regional variation in pre-reform temporary employment shares in a continuous-treatment DiD. The question is important, the institutional setting is policy-relevant, and the paper’s core descriptive fact—a very large decline in measured temporary employment after the reform—is undeniable. The manuscript is also admirably clear about one key limitation: contract-type aggregates alone cannot directly measure worker welfare.

That said, in its current form the paper is **not publication-ready for a top general-interest journal or AEJ: Economic Policy**. The main problems are not cosmetic; they concern identification, interpretation, and the mapping from evidence to the headline claim. The paper’s strongest causal result is that higher-exposure regions saw larger declines in measured temporary shares after the reform. But the paper’s central substantive conclusion—“the reform changed labels, not jobs”—is not established by the current design. A null effect on total employment is not sufficient to distinguish relabeling from genuine improvements in job quality within existing jobs. Moreover, the preferred weighted specification drives the headline significance, yet its estimand and inferential properties are insufficiently justified, especially with only 19 clusters.

Below I organize the review around identification, inference, robustness, contribution, and claim calibration, then give a prioritized revision list.

---

## 1. Identification and empirical design

### 1.1 What the design credibly identifies
The core specification in Section 4,
\[
Y_{rt} = \alpha_r + \gamma_t + \beta(Z_r \times Post_t) + \varepsilon_{rt},
\]
with \(Z_r\) equal to the region’s 2021 temporary share, can identify whether **regions with higher pre-reform temporary intensity experienced larger post-reform changes** in outcomes than lower-intensity regions. For the temporary-share outcome, that is a reasonable reduced-form question.

The national reform timing is clean in the sense that the treatment was not chosen by regions, which removes one common source of endogeneity. The use of long pre-period data is also potentially valuable.

### 1.2 The central identifying assumption is too weakly defended
The identifying assumption is a parallel-trends condition across regions with different baseline temporary-employment intensity. This is a substantial assumption here because baseline temporary shares are not quasi-random; they reflect persistent differences in sector mix, tourism intensity, seasonality, labor-market institutions, public-sector composition, and exposure to COVID recovery dynamics. Those same characteristics are highly likely to shape post-2022 labor-market evolution.

The paper acknowledges this in Section 4.2 but does not adequately address it. In particular:

- **Baseline temporary share is itself an equilibrium outcome** of local industrial structure and labor-market composition.
- The post-2022 period in Spain features major shocks—tourism rebound, energy/inflation shocks, and uneven sectoral recovery—that plausibly differentially affected high-temporary regions.
- High-temporary regions are likely more exposed to agriculture, tourism, hospitality, and construction; this makes post-reform differential trends especially plausible even absent the reform.

The current design would be more convincing if the authors showed that results are robust to allowing for **differential post paths by pre-determined sector composition**, e.g. region-specific exposure to tourism, agriculture, construction, and hospitality interacted with time effects. As written, the claim that “major macroeconomic shocks … affected all regions through common national channels” (Section 4.1) is too strong and not credible.

### 1.3 Treatment timing is not fully coherent
The paper defines \(Post_t=1\) from **2022Q2 onward**. But the reform took effect on **March 30, 2022**, so 2022Q2 is mostly post-treatment, while 2022Q1 is almost entirely pre-treatment. That is defensible, but only if implementation is immediate and quarter-level aggregation is appropriate.

However, the paper itself emphasizes a transition period and gradual contract conversion. That creates ambiguity about treatment timing. The “early” and “late” timing checks in the robustness appendix are useful, but not enough. A cleaner approach would be:

- treat **2022Q2 as a transition quarter** and exclude it from the main analysis;
- show results for alternative windows explicitly as main-table sensitivity;
- explain how pre-existing temporary contracts were allowed to run out and how that affects the expected dynamic path.

### 1.4 Mean reversion is a real concern
Because treatment intensity \(Z_r\) is the **2021 average of the outcome variable itself**, mean reversion is a first-order issue, especially after COVID-era labor-market volatility. The paper notes this, but the fixes are weak:

- “No pre-trends” in an event study does not rule out mean reversion concentrated around an unusually high 2021 baseline.
- Region-specific linear trends are not a full solution when the concern is a transitory spike in the treatment-defining year.
- Using 2021 as the treatment-defining year is especially problematic because 2021 was not a normal year.

A much more convincing strategy would be to define exposure using **pre-pandemic years only** (e.g. 2018–2019 average temporary share), or use a leave-future-out measure based on a longer pre-period. At minimum, the paper should present side-by-side results using 2019, 2018–2019, and 2016–2019 exposure measures.

### 1.5 The “shift-share” framing is somewhat misleading
The paper repeatedly invokes shift-share/Bartik logic (Section 4.1, Appendix B), but empirically the treatment is not a standard shift-share instrument; it is a **single cross-sectional exposure interacted with a post dummy**. That is just a continuous-treatment DiD with a cross-sectional exposure measure. The Bartik discussion does not add much and may distract from the actual identifying assumptions, which remain about exposure-driven parallel trends.

I would strongly recommend simplifying the framing: call this a **continuous-exposure DiD** and focus on its own assumptions.

### 1.6 The key causal claim is too ambitious relative to the design
The paper’s title and abstract advance the claim that the reform mainly generated **relabeling rather than real reform**. But the design only directly shows:

1. larger declines in measured temporary shares in high-exposure regions; and
2. no detectable differential effect on total wage-earner employment.

That is not enough to establish “relabeling” in a strong sense. The paper does **not** observe:
- fixed-discontinuous status directly at the regional level,
- worker transitions across contract types,
- job durations,
- recall patterns,
- separations,
- wages,
- hours,
- inactivity/unemployment spells.

Without those outcomes, the paper cannot distinguish:
- pure relabeling with unchanged job quality,
- relabeling plus improved legal protections,
- conversion into more stable ongoing relationships with unchanged employment levels,
- or offsetting extensive- and intensive-margin effects.

This is the single biggest issue in the paper.

---

## 2. Inference and statistical validity

### 2.1 Few-cluster inference is acknowledged, but the headline still rests on a fragile result
The paper is right to worry about only **19 clusters**. It is good that cluster-robust SEs, wild-cluster bootstrap p-values, and randomization inference are reported.

However, the inferential bottom line is awkward:

- The **unweighted main effect on temporary share is not statistically distinguishable from zero** (Table 1, col. 1).
- The **employment effect is also insignificant** (Table 1, col. 2).
- The headline significance comes from the **population-weighted specification** (Table 1, col. 3).

That is not fatal in itself, but then the paper needs to be much more careful about which estimand it wants to prioritize and why. As written, the weighted result appears to be promoted because it is significant, not because its causal estimand is clearly preferable.

### 2.2 The weighted specification needs much stronger justification
The weighted coefficient is over twice as large in magnitude as the unweighted one and has an SE that is tiny by comparison (-0.462, SE 0.046 versus -0.220, SE 0.205). That gap is striking and demands deeper scrutiny.

Issues that need attention:

- What is the target estimand under weighting? Is it the average effect on a worker, on a region, or something else?
- Why is weighting by 2021 employment appropriate when 2021 itself may be affected by pandemic distortions?
- Are results driven by a small number of large regions such as Madrid, Catalonia, and Andalusia?
- Does weighting interact mechanically with treatment intensity and variance structure?

The current leave-one-out discussion does not solve this because it is not clear whether the figure pertains to the weighted specification, and even if it does, dropping one region at a time is not enough when a few large regions dominate weighted estimation.

At minimum, the paper should report:
- weighted and unweighted event studies,
- leverage/influence diagnostics for the weighted regression,
- results excluding Madrid/Catalonia/Andalusia,
- CR2/CRV3 or other small-sample corrected inference,
- and a clear discussion of the estimand.

### 2.3 The event-study pre-trend test is not persuasive as presented
The paper reports an event study with **45 pre-treatment coefficients** and a joint pre-trend p-value of **0.999** (Section 4.1; Appendix B). With only 19 clusters, this is not very informative. A very high p-value in such a high-dimensional pre-trend test more likely reflects low power and unstable covariance estimation than strong evidence for parallel trends.

Relatedly:
- Quarter-by-quarter interacted coefficients with only 19 regional clusters are noisy.
- The paper appears to interpret “failure to reject” as strong support, which is too strong.
- The event-study confidence intervals are cluster-robust, but no few-cluster correction is mentioned for the dynamic graph.

The paper should avoid strong language such as “providing strong evidence against differential pre-reform dynamics.” At most, the event study shows no obvious visible pre-trend.

### 2.4 Randomization inference is useful but does not support strong claims
The randomization-inference p-value of **0.179** is not compelling evidence. The text says this is “suggestive but not definitive”; that is fair. But elsewhere the paper leans heavily on the overall pattern as if significance were established. For a top journal, inference needs to be cleaner and claims more disciplined.

### 2.5 Sample sizes are coherent, but outcome construction raises interpretation issues
The panel structure and N are coherent. But the paper should clarify whether the “total wage earners” outcome excludes self-employed workers and whether reform-induced substitution between wage employment and self-employment could matter. If the policy changed composition within employment relationships but also induced movement into non-wage forms, “no effect on wage earners” is not equivalent to “no employment effect.”

---

## 3. Robustness and alternative explanations

### 3.1 Robustness is incomplete on the key identification margin
The paper includes alternative timing, shorter pre-period, trends, and exclusion of COVID years. Those are useful but not sufficient. The most important omitted robustness checks are those that address **differential sectoral shocks**.

Specifically, the authors should control for:
- pre-reform sector shares interacted with quarter effects;
- tourism dependence interacted with quarter effects;
- agriculture/construction dependence interacted with quarter effects;
- possibly baseline unemployment or cyclical sensitivity interacted with time.

Without these, the design risks confounding reform exposure with differential post-2022 recovery.

### 3.2 Sectoral evidence is descriptive, not causal
Table 2 and Figure 5 provide national sectoral trends showing larger declines in agriculture and construction. These patterns are consistent with the relabeling story, but they are **not causal tests**. They are national series with no counterfactual and could reflect the direct sectors most affected by the reform, shifts in labor demand, or recovery patterns.

Moreover, the sectoral evidence is not actually linked to the regional-exposure design. A stronger mechanism test would exploit **regional variation in exposure to seasonal sectors** and estimate triple-difference style specifications:
\[
Y_{rst} = \alpha_{rs} + \gamma_{st} + \delta_{rt} + \beta (Post_t \times HighSeasonal_s \times Z_r) + \varepsilon_{rst}.
\]
As written, the sector evidence is suggestive but insufficient to support the mechanism claim.

### 3.3 The paper lacks meaningful placebo tests
A convincing paper in this design should include placebo outcomes or placebo reforms. For example:
- outcomes plausibly less affected by relabeling, such as self-employment or non-wage employment;
- placebo implementation dates in pre-2022 years;
- placebo treatment intensity using unrelated baseline shares.

These would help assess whether the design is simply picking up differential post-2022 changes in high-temporary regions.

### 3.4 Mechanism claims are not cleanly separated from reduced-form findings
The manuscript often moves from “consistent with relabeling” to “the reform changed labels, not jobs.” That leap is not justified by the data. The reduced-form findings are solidest on measured contract composition; the mechanism remains inferred, not shown. The paper should use much more disciplined language throughout.

### 3.5 External validity and limitations need a sharper boundary
The discussion of limitations is thoughtful, especially on wages and job quality. But the external-validity claims are too broad when the evidence is so aggregate. The paper should be more explicit that it identifies regional differential responses in **official contract classifications among wage earners**, not overall worker welfare or the full economic incidence of the reform.

---

## 4. Contribution and literature positioning

### 4.1 The question is important and timely
This is a highly policy-relevant reform in a canonical dual labor market. A credible design-based evaluation would indeed be of wide interest.

### 4.2 The “first design-based evaluation” claim should be softened unless thoroughly verified
The paper repeatedly says it provides the “first design-based evaluation.” That is a strong novelty claim and risky unless the authors have exhaustively verified the literature, including recent working papers and Spanish-language studies. I would advise softening this to “one of the first causal/design-based regional evaluations” unless the claim can be documented more carefully.

### 4.3 Literature coverage is decent on classic dual-labor-market theory, but thin on recent empirical methods and current Spain-specific evidence
The paper cites foundational labor-market-dualism papers well. But the methods and reform-evaluation literatures could be better aligned with the actual design.

Concrete additions worth considering:

- **de Chaisemartin and D’Haultfoeuille** on DiD with treatment heterogeneity and interpretation of weighted estimands, because the paper relies heavily on weighted versus unweighted comparisons.
- **Rambachan and Roth** on sensitivity to violations of parallel trends, especially since the event-study pre-trend evidence is weakly informative.
- Recent empirical work on **Spain’s 2021/2022 labor reform**, including institutional/descriptive analyses from Banco de España, OECD, ILO, or Spanish labor-economics working papers, especially on fijo discontinuo and job duration. If such work exists and is not cited, it is a notable omission.
- Literature on measuring **job quality beyond contract labels**, which would help discipline the paper’s central interpretation.

### 4.4 The contribution is currently overstated relative to the data
The paper’s strongest contribution is not that it proves relabeling; rather, it shows that **measured declines in temporary employment were largest where baseline temporary intensity was highest, with no detectable effect on total wage-earner employment**. That is already a useful contribution. The current framing overreaches.

---

## 5. Results interpretation and claim calibration

### 5.1 The strongest over-claim: null employment effect implies relabeling
This is the manuscript’s central inferential error. The paper states, in essence, that because total employment did not move, the reform changed labels not jobs. That is not a valid inference.

A null effect on employment is consistent with many possibilities:
- relabeling with no substantive change,
- improved legal security for incumbent workers without employment expansion,
- improved expected tenure but unchanged headcount,
- offsetting job creation and destruction,
- intensive-margin changes in hours or earnings rather than employment counts.

So while the employment null is informative against certain macro-employment channels, it is **not a discriminating test** between relabeling and genuine improvement in job quality.

### 5.2 The discussion repeatedly treats descriptive sector patterns as proof
Statements such as “What changed is the label on the contract, not the work it governs” are not supported by the reported estimates. The sectoral patterns are consistent with the story but not decisive.

### 5.3 The weighted/unweighted contrast is interpreted too confidently
The paper interprets the larger weighted estimate as evidence that “the reform’s labeling effect was concentrated in Spain’s major economic centers” and attributes this to “administrative capacity” or “compliant employers.” That is speculative. There is no direct evidence presented on compliance, monitoring, or administrative capacity.

### 5.4 Policy implications outrun the evidence
The concluding claim that policymakers risk “rewarding reforms that change classification schemes rather than improve workers’ lives” is plausible, but the paper does not observe worker-level welfare outcomes. The policy lesson should therefore be narrower: official temporary-rate declines should not be interpreted as sufficient evidence of improved job quality absent corroborating data on tenure, recall, hours, wages, and separation dynamics.

### 5.5 The paper would benefit from reporting implied magnitudes more concretely
For the main coefficient, the text appropriately translates a 10 pp exposure difference into a 2.2 pp larger decline. The same should be done systematically for the weighted estimate and for the employment null, ideally with confidence intervals in economically interpretable units. That would also help readers see how much uncertainty remains.

---

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

**1. Reframe the central claim from “relabeling proven” to “patterns consistent with relabeling, but not dispositive.”**  
- **Why it matters:** The current headline conclusion is stronger than what the data identify. This is the main publication-readiness issue.  
- **Concrete fix:** Rewrite the abstract, introduction, discussion, and conclusion so that the paper claims: (i) large exposure-driven declines in measured temporary employment; (ii) no detectable differential effect on total wage-earner employment; and (iii) evidence consistent with substantial relabeling, but not sufficient to rule out some genuine improvements in job quality.

**2. Address the key confound: differential post-2022 shocks correlated with baseline temporary shares.**  
- **Why it matters:** Parallel trends is not credible without showing robustness to sectoral/cyclical composition.  
- **Concrete fix:** Add specifications controlling for pre-determined region characteristics interacted with time, especially sector shares (agriculture, construction, services/tourism, industry), tourism dependence, and possibly pre-reform unemployment. A useful benchmark is region-specific exposure controls interacted with quarter fixed effects.

**3. Redefine or thoroughly justify the treatment-intensity measure.**  
- **Why it matters:** Using the 2021 average temporary share invites mean-reversion and COVID-recovery concerns.  
- **Concrete fix:** Report the full main table using alternative exposure definitions: 2019 only; 2018–2019 average; 2016–2019 average; 2021Q4 only. If results differ materially, discuss why.

**4. Justify the weighted specification or stop treating it as the headline result.**  
- **Why it matters:** The preferred significant result comes almost entirely from weighting, yet the estimand is unclear and may be driven by leverage.  
- **Concrete fix:** Explicitly define the estimand under weighting; report influence diagnostics; show results excluding the three largest regions; and provide small-sample corrected inference (e.g. CR2/CRV3 in addition to wild bootstrap). If the weighted result remains central, defend why worker-weighted rather than region-weighted effects are the policy-relevant estimand.

**5. Fix the interpretation of the employment null.**  
- **Why it matters:** This is currently used as a decisive mechanism test, which it is not.  
- **Concrete fix:** Recast the employment result as ruling out large extensive-margin employment effects, not as proving no substantive improvement. Add discussion of alternative margins: tenure, recall, hours, wages, unemployment spells, and self-employment.

### 2. High-value improvements

**6. Add stronger placebo/falsification exercises.**  
- **Why it matters:** These would materially improve credibility of the design.  
- **Concrete fix:** Estimate placebo reforms in pre-2022 periods; use placebo exposure variables; consider placebo outcomes less plausibly affected by relabeling.

**7. Strengthen the mechanism evidence with better data or tighter design.**  
- **Why it matters:** The paper’s novelty rests on the relabeling mechanism.  
- **Concrete fix:** If possible, add data on fijo discontinuo counts by region or sector; worker-flow data; unemployment/inactivity transitions; job duration distributions; or a triple-difference design exploiting sectoral seasonality. Even imperfect mechanism data would substantially strengthen the paper.

**8. Tone down over-interpretation of the event-study pre-trend test.**  
- **Why it matters:** With 19 clusters and many leads, a p-value of 0.999 is not “strong evidence” of parallel trends.  
- **Concrete fix:** Replace strong claims with a more modest statement that no obvious differential pre-trends are visible. If feasible, use lower-dimensional pre-trend summaries.

**9. Clarify the population under study and possible substitution margins.**  
- **Why it matters:** The outcome is wage earners, not total employment broadly defined.  
- **Concrete fix:** Show whether self-employment or overall employment moves differentially by exposure; clarify in text that the null pertains to wage-earner employment unless broader outcomes are analyzed.

### 3. Optional polish

**10. Simplify the methodological framing.**  
- **Why it matters:** The shift-share/Bartik discussion currently overcomplicates the design and invites unnecessary critique.  
- **Concrete fix:** Frame the paper as a continuous-exposure DiD and move the Bartik discussion to a short footnote or appendix.

**11. Moderate novelty claims.**  
- **Why it matters:** “First design-based evaluation” is a risky claim.  
- **Concrete fix:** Replace with “a design-based regional evaluation” unless exhaustive literature review supports the stronger statement.

**12. Improve transparency around dynamic treatment timing.**  
- **Why it matters:** Quarter-level treatment coding is important in this setting.  
- **Concrete fix:** Add a brief institutional timeline and a main-text figure/table showing expected treatment dynamics and alternative coding choices.

---

## 7. Overall assessment

### Key strengths
- Important and timely policy question in a canonical labor-market setting.
- Clear institutional motivation and intuitive empirical setup.
- Honest acknowledgment of some data limitations.
- Appropriate concern about few-cluster inference.
- Useful reduced-form evidence that high-exposure regions saw larger measured declines in temporary employment after the reform.

### Critical weaknesses
- The paper’s central substantive claim (“labels, not jobs”) is not identified by the available outcomes.
- The parallel-trends assumption is insufficiently defended against obvious sectoral and cyclical confounds.
- The key treatment measure may suffer from mean reversion and COVID-era contamination.
- The statistically strong result relies on a weighted specification that is not adequately justified.
- Descriptive sectoral patterns are treated as mechanism proof when they are not.

### Publishability after revision
This paper is **potentially salvageable**, but only with substantial redesign of the argument and stronger empirical work on identification and mechanism. The reduced-form finding on measured temporary employment is promising. However, to reach top-journal or AEJ:EP standards, the paper would need a more disciplined claim, more credible handling of confounds, and ideally better evidence on whether contract conversion represented mere relabeling or substantive improvement.

**DECISION: MAJOR REVISION**