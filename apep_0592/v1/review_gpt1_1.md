# GPT-5.4 (R1) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-11T13:02:13.197321
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 21855 in / 6042 out
**Response SHA256:** 6646cdbc8db2a084

---

This paper tackles an interesting and potentially important question: whether the destruction of a major sector—the saloon/alcohol economy under state prohibition—had spillover effects on workers outside the directly affected industry. The linked full-count census panels are potentially powerful, and the paper is commendably transparent that the core causal interpretation is fragile. That said, for a top general-interest journal or AEJ:EP, the current draft is not close to publication readiness. The main reason is not novelty or data, but identification: the paper’s preferred estimates are not credibly causal, several key design choices induce interpretational problems, and many of the paper’s strongest claims rest on estimates the paper itself shows are undermined by differential pre-trends.

I would encourage the author(s) to think of this manuscript as having the ingredients for a strong historical descriptive paper, but not yet a causal policy-evaluation paper. Below I explain why.

## 1. Identification and empirical design

### A. The central identification strategy is not credible for the stated causal claim

The main design interacts county alcohol share with a treated-state indicator for whether a state adopted prohibition at any time during 1907–1919, using 1910–1920 occupational change as the outcome (\S\ref{sec:strategy}, equation (1)). This is described as exploiting “cross-state timing and within-state variation,” but in practice the preferred specification largely **collapses staggered timing into a binary ever-treated-by-1920 indicator**. That creates several problems:

1. **Treatment timing heterogeneity is ignored in the main specification.**  
   A state treated in 1907, 1911, and 1919 all receive the same `Treated=1` coding in the main model, despite very different exposure lengths within 1910–1920. This is not a minor detail; it is first-order for interpretation. The coefficient is not a clean treatment effect of prohibition, but a weighted comparison of counties with differing alcohol shares in states with very different treatment timing.

2. **The treatment indicator is partly post-baseline and partly pre-baseline.**  
   Five states were already dry by 1910 (\S\ref{sec:background}; \S\ref{sec:threats}). For those states, the 1910 baseline occurs after treatment onset. Others are treated during the 1910–1920 window, and controls are only untreated until national prohibition in 1920. This mixes already-treated, newly treated, and not-yet-treated units in a way that is hard to map to a coherent estimand.

3. **The preferred specification does not actually exploit within-state policy variation in a clean way.**  
   The paper claims to rely on “within-state variation in alcohol share intensity,” but the main identifying contrast is still **treated vs. control states** interacted with county exposure. Since treated and control states are very different economically and politically (\S\ref{sec:data}, Table \ref{tab:summary}), this is vulnerable to differential trends in exposed counties across these state groups.

4. **The state fixed effects model does not identify the treatment effect at all.**  
   The paper correctly notes that Column 4 of Table \ref{tab:main} is not the prohibition effect because the interaction is collinear with alcohol share when state FE are included. But this means the paper’s only “more demanding” specification is not informative about the causal quantity of interest.

In short, the current design is closer to an exposure-interacted treated-state comparison than to a credible DiD. That can be valuable descriptively, but it does not support the paper’s causal language, even with caveats.

### B. The paper’s own earlier-period evidence strongly rejects the key identifying assumption

The most serious problem is the earlier-period comparison in Appendix Table \ref{tab:pretrend} and discussed in \S\ref{sec:threats} and \S\ref{sec:robust}. The coefficient for 1900–1910 is **+5.34 (SE 1.93)**, far larger than the main 1910–1920 estimate of **+0.80**.

The paper is commendably honest that this is a serious concern. I agree. In fact, I think it is fatal in the current version.

Yes, the author notes this is not a perfect pre-trend test because five states were treated during 1907–1909. But that caveat does not rescue the design:

- The earlier-period coefficient is **huge** relative to the main effect.
- Even if part reflects early treatment in those five states, the magnitude strongly suggests that high-alcohol-share counties in eventually treated states were on very different trajectories.
- Since the paper’s identifying assumption is essentially a parallel-trends-style assumption on the interaction term, this evidence substantially undermines causal interpretation.

The manuscript tries to pivot by saying the main contribution is the decomposition, heterogeneity, and reversal, “regardless” of whether the level is causally identified (\S\ref{sec:threats}, \S\ref{sec:robust}, Conclusion). But this does not follow. If the aggregate interaction is contaminated by differential trends, then:
- subgroup “mechanisms” may simply reflect heterogeneity in those same trends,
- immigrant/native and high/low occupation-score splits may reflect differential trend heterogeneity,
- and the long-run reversal may reflect differential mean reversion or decade-specific growth patterns rather than treatment dynamics.

Once the identifying assumption fails, all downstream interpretations become descriptive correlations unless re-anchored in a more credible design.

### C. Exposure is measured post-treatment for early adopters

As noted in \S\ref{sec:threats}, five states adopted before 1910, yet 1910 county alcohol share is used as exposure for all states. That is a classic bad-control/post-treatment-measurement problem.

The paper argues this should attenuate estimates. Perhaps. But attenuation is not the only issue:
- Prohibition may have altered the measured county alcohol share in ways correlated with local economic adjustment.
- Early adopters may have had selective suppression of the alcohol industry precisely where saloons were most important, distorting relative exposure rankings.
- If county exposure is endogenous to treatment for some states and pre-treatment for others, the treatment variable lacks a consistent interpretation across units.

A minimum fix would be to exclude pre-1910 adopters from the main analysis or build a design around states untreated at baseline. Better would be a design using pre-treatment exposure from 1900 or some other source, while addressing changes in county industrial structure directly.

### D. The outcome specification raises additional concerns

The preferred model uses **change in OCCSCORE** as the outcome and then conditions on **initial OCCSCORE** (Table \ref{tab:main}, Column 3). The paper explicitly notes the sign flip once baseline OCCSCORE is included. This should raise alarms.

Including lagged outcome when the dependent variable is a change can be reasonable in some settings, but here:
- it risks inducing a regression-to-the-mean correction that is highly sensitive to measurement error,
- linked historical data have nontrivial linkage error,
- OCCSCORE is itself a noisy proxy for latent occupational standing.

The fact that the estimated effect changes from negative to positive solely when baseline OCCSCORE is added suggests the result is heavily dependent on functional-form choices rather than robust design-based variation. At minimum, the paper needs a much deeper justification and alternative estimators:
- levels with baseline controls,
- rank outcomes,
- inverse-hyperbolic-sine or categorical mobility outcomes,
- transition matrices,
- residualized outcomes,
- county-by-baseline-occupation trends or matched samples.

### E. The 1920–1930 “long-run” design is not a credible persistence test

The 1920–1930 analysis (\S\ref{sec:longrun}, Table \ref{tab:longrun}) is presented as “differential persistence,” but after January 1920 all states are under national prohibition. Thus the treated-vs-control state contrast no longer identifies policy variation.

What remains is a comparison of high-alcohol-share counties in **early-adopting states** versus **late-adopting states** during the 1920s. That comparison is confounded by essentially everything that differed between those state groups:
- regional industrial growth,
- postwar adjustment,
- urbanization,
- immigration restriction and assimilation dynamics,
- differential exposure to the 1920–21 recession and later 1920s expansion,
- state-level enforcement differences,
- selection into the 1920–1930 linked panel.

The paper acknowledges some of this, but still builds an interpretive narrative around “social infrastructure destruction.” That narrative is not supported by the design. I would not treat the 1920–1930 result as evidence of a dynamic treatment reversal.

## 2. Inference and statistical validity

### A. Inference is reported, but the uncertainty evidence is internally inconsistent

The paper does report clustered standard errors, randomization inference, and wild cluster bootstrap. That is good. However, the inferential story is not coherent enough to support publication in its current form.

- Main estimate in Table \ref{tab:main}, Col. 3: **SE 0.277, p=0.004**
- Randomization inference: **p = 0.098**
- Wild cluster bootstrap: **p = 0.002**

Those are dramatically different assessments of significance. With only 45 state clusters and treatment assigned at the state level, the RI result is arguably the most design-consistent inferential exercise among those reported. If so, the main result is at best marginal. The paper says this, but then often continues to discuss effects as established.

This discrepancy needs fuller explanation:
- What exact assignment mechanism is being permuted?
- Are the five pre-1910 adopters held fixed? If so, why?
- Is the RI two-sided or one-sided?
- How are covariates handled under permutation?
- How is the bootstrap implemented with only 45 clusters and a treatment at the cluster level?

At present, the reader cannot assess whether the RI or WCB procedure is correctly targeted.

### B. Sample sizes are large, but effective variation is limited

The paper often emphasizes millions of linked workers. But the effective treatment variation is at the **state level**, with the treatment interacted with county exposure. The relevant number for statistical leverage is therefore much closer to the number of policy clusters than to 8.7 million.

The manuscript should reorient the discussion away from large N and toward:
- number of treated and control states,
- distribution of county exposure within states,
- leverage of major states,
- variance decomposition of the interaction term.

The leave-one-out exercise helps, but more diagnostic evidence is needed.

### C. Some reported significance claims are inconsistent

There are a few substance-level inconsistencies in the interpretation of estimates:

- In \S\ref{sec:robust}, the binary high-exposure specification is described as yielding a “positive, significant coefficient,” but Table \ref{tab:robustness} reports **p = 0.197**. That is not significant.
- The paper states that leave-one-out estimates are significant at 5% in 38 of 40 iterations and at 10% in the remaining two, but no supporting table is shown. Given how important this is for reassurance, the underlying estimates and p-values should be reported.
- The women’s result is described as “marginally significant at the 10% level” (\S on women’s employment), which is acceptable, but readers should be reminded that under the paper’s own concerns about cluster-level inference, a 0.07 conventional p-value is weak evidence.

### D. No serious attempt is made to model multi-level dependence

County exposure is measured at the county level, treatment at the state level, and outcomes at the individual level. The paper clusters by state only. That may be appropriate for treatment assignment, but it would still be helpful to show robustness to:
- county-level aggregation of outcomes,
- state-by-exposure-bin collapsing,
- randomization/permutation at the state level on county-cell outcomes,
- weighted county-level regressions.

Given the enormous micro sample and relatively coarse treatment variation, collapsing to the level at which identifying variation is transparent would materially improve credibility.

## 3. Robustness and alternative explanations

### A. Current robustness checks do not address the main identification threat

The placebo in zero-exposure counties is not very informative against the key threat. If the concern is that high-alcohol counties in future-treated states were on different trajectories than high-alcohol counties in control states, a placebo among zero-exposure counties says little. Those counties are, by construction, not where the problematic trend heterogeneity would show up.

Similarly:
- leave-one-out does not address bias,
- alternative exposure measures do not address confounding,
- non-South only is helpful but limited.

The robustness section needs designs aimed at the actual threat: differential trends in high-exposure places.

### B. Mechanism claims are substantially overstated

Table \ref{tab:mechanisms} is presented as “mechanism tests,” but these are not mechanism tests in a causal sense. They are subgroup correlations subject to the same identification concerns as the main estimate.

Moreover, some interpretations are speculative or contradictory:

- The positive effect for “supply chain workers” is said to be contrary to prediction, then reinterpreted as evidence of more-than-offsetting reallocation.
- The positive effect for manufacturing is attributed to reduced labor market competition, but one could equally posit increased competition from displaced alcohol workers depressing incumbents.
- The self-employment decline is attributed to loss of saloon-based entrepreneurship/credit, but could also reflect differential urban retail consolidation or measurement/composition changes.
- The null migration result is taken as evidence of occupational rather than geographic adjustment, but county movers are an imperfect measure of mobility and may suffer linkage selection.

These results should be reframed as descriptive heterogeneity, not mechanism evidence.

### C. External validity and limitations need more discipline

The paper does acknowledge limitations. But the interpretation often outruns them. The social-infrastructure story is interesting and plausible, yet the empirical evidence in the paper does not isolate it from other county or state characteristics. For a top journal, mechanism discussion needs either direct evidence or far more caution.

### D. Critical robustness exercises that are missing

Several high-value checks are absent:

1. **Exclude the five pre-1910 adopters from the main analysis.**  
   This is essential given post-treatment exposure measurement and contaminated baseline.

2. **Restrict to states adopting after 1910 and estimate dose by years dry before 1920.**  
   The years-of-prohibition specification in Table \ref{tab:main}, Col. 5 is underdeveloped and not clearly preferred.

3. **Event-time or cohort-specific analysis at the county/state-cell level.**  
   Even with decadal panels, one can construct cohort-by-state exposure designs or compare 1900–1910 and 1910–1920 changes in a stacked triple-difference framework.

4. **Border-county design.**  
   Comparing counties near state borders with different prohibition timing would materially improve identification by reducing broad regional confounding.

5. **County-level controls and trend interactions.**  
   At minimum: baseline urbanization, manufacturing share, immigrant share, Black share, literacy, initial OCCSCORE, population, and perhaps region-specific alcohol-share slopes.

6. **Tests for linkage/composition bias.**  
   Are linkage rates or survival into linked panels correlated with treatment intensity? The current discussion of false matches as “classical attenuation” is too optimistic; in historical linked data, linkage success can be systematically related to mobility, nativity, naming conventions, and treatment exposure.

## 4. Contribution and literature positioning

### A. The topic is potentially publishable, but the contribution is not yet well differentiated at the causal level

The paper’s substantive contribution—spillovers of industry destruction on adjacent workers—is appealing. The historical setting is novel. The linked census data are rich. These are strengths.

But for top-journal placement, the paper needs either:
- a clearly credible causal design, or
- a much stronger descriptive contribution than currently delivered.

Right now it is in an uneasy middle: it uses causal language and regression architecture, but the paper itself concedes the core estimate is not causally identified. That makes it difficult to assess contribution relative to existing historical descriptive work or modern local labor market papers.

### B. Methodological literature coverage is incomplete for the actual design

The paper cites Goodman-Bacon, Callaway-Sant’Anna, and Sun-Abraham, but those are not the central methodological issue here, because the paper does **not** estimate a standard staggered DiD. It is closer to a continuous-exposure interacted design, with similarities to Bartik/shift-share logic and to difference-in-differences with continuous treatment.

The paper should engage that literature directly. Concrete references to add and discuss:

- **Borusyak, Hull, and Jaravel (2022, QJE)** on quasi-experimental shift-share designs: highly relevant because the treatment is an interaction between location-specific exposure and broader policy timing.
- **Goldsmith-Pinkham, Sorkin, and Swift (2020, AER)** on Bartik instruments: useful for decomposing identifying variation and diagnosing whether a few states/counties drive results.
- **de Chaisemartin and D’Haultfoeuille (2020, AER)** on DiD with variation in treatment: relevant for weighting and nonstandard designs.
- **Athey and Imbens (2022, JOE)** or related work on design-based analysis under staggered adoption.
- If the author wants to maintain a continuous-treatment DiD framing, the manuscript should engage the relevant recent literature on **continuous treatment DiD/event-study estimands**.

### C. Domain literature could be broadened

The paper covers classic Prohibition references, but for labor-market and historical-network interpretation it would benefit from engagement with:
- work on occupational mobility and linked historical census data,
- literature on immigrant enclaves and labor-market networks,
- economic history of urban institutions and social capital.

Because the paper leans heavily on saloons as labor-market infrastructure, it needs stronger empirical and historical linkage to that mechanism than citation to Powers (1998) alone.

## 5. Results interpretation and claim calibration

### A. The paper often over-claims relative to the evidence

The abstract is better calibrated than the body, but the paper still repeatedly slides from “associated with” to substantive causal interpretation. Examples include:
- “prohibition induced labor market churning” (\S Results, mechanisms),
- “patterns consistent with a labor demand reallocation story” stated too assertively,
- “Together, the mechanism results paint a picture of creative destruction,”
- “The most striking finding… short-run gains reversed into long-run losses.”

Given the identification problems, these statements need to be toned down substantially unless the design is redesigned.

### B. The magnitudes are modest for the main effect and large for some margins; both require more calibration

The preferred main estimate is small in standardized terms (0.018 SD), as the paper notes. That is fine. But some binary-outcome effects appear large relative to plausible baseline rates:
- self-employment: -0.061 per 1 percentage point of exposure,
- occupation switching: +0.039 per 1 percentage point.

Given that county alcohol shares can reach multiple percentage points, implied effects could become very large in high-exposure counties. The paper should provide benchmark baseline probabilities and realistic treatment contrasts (e.g., 10th to 90th percentile exposure) rather than per-unit exposure effects alone.

### C. The long-run reversal should not be highlighted as a core finding in the current version

Because the 1920–1930 design does not identify a treatment contrast after national prohibition, the “dynamic reversal” should not be treated as a centerpiece result. At most, it is a descriptive pattern comparing early- and late-prohibition states during the 1920s.

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

#### 1. Redesign the empirical strategy around a credible estimand
- **Issue:** The current treated-state × county-exposure design is not credibly causal; it collapses staggered timing and is invalidated by strong earlier differential trends.
- **Why it matters:** This is the core scientific problem. Without a more credible design, the paper cannot support its central claims.
- **Concrete fix:** Rebuild around one of:
  - a sample restricted to states untreated at baseline, with exposure measured pre-treatment;
  - a border-county design exploiting neighboring counties across state lines with different adoption timing;
  - a stacked cohort/triple-difference design comparing 1900–1910 and 1910–1920 changes by exposure and treatment cohort;
  - a county-level event-time design using repeated decadal outcomes where feasible.

#### 2. Remove or sharply qualify causal claims unless identification is repaired
- **Issue:** The paper continues to present induced effects, mechanisms, and dynamic reversal despite admitting the core pre-trend problem.
- **Why it matters:** Claim calibration is central for publication readiness.
- **Concrete fix:** If the design remains as is, recast the paper as descriptive historical evidence and strip causal language from abstract, introduction, results, and conclusion.

#### 3. Address post-treatment exposure measurement
- **Issue:** 1910 alcohol share is post-treatment for the five early adopters.
- **Why it matters:** Treatment intensity is inconsistently defined across units and may be endogenous.
- **Concrete fix:** Exclude pre-1910 adopters from the main specification, or construct pre-treatment exposure from 1900 and show stability of county rankings and implications for measurement error.

#### 4. Reassess the 1920–1930 analysis
- **Issue:** After national prohibition, the early-vs-late state comparison does not identify a policy effect.
- **Why it matters:** The long-run reversal is currently overinterpreted.
- **Concrete fix:** Either drop it as a headline result or reframe it strictly as a descriptive persistence comparison. If retained, provide stronger controls for 1920s differential trends and no causal narrative.

#### 5. Resolve inference inconsistencies
- **Issue:** Clustered p=0.004, RI p=0.098, WCB p=0.002 tell very different stories.
- **Why it matters:** A paper cannot pass without trustworthy inference.
- **Concrete fix:** Fully document the RI and bootstrap procedures; increase permutations/replications; report exact randomization distribution details; consider design-based county/state-cell aggregation.

### 2. High-value improvements

#### 6. Add robustness checks targeted to the actual threat
- **Issue:** Existing placebo and leave-one-out checks do not address differential trends in exposed counties.
- **Why it matters:** Robustness should speak to the key identifying assumption, not peripheral concerns.
- **Concrete fix:** Add:
  - exclusion of early adopters,
  - county/state baseline covariate interactions,
  - matched treated/control counties on pre-1910 observables,
  - placebo outcomes less likely to respond to prohibition,
  - sensitivity to urban/rural splits and initial industrial structure.

#### 7. Rework the outcome specification
- **Issue:** The result’s sign depends on including baseline OCCSCORE in a change regression.
- **Why it matters:** This suggests heavy dependence on functional form and possible regression-to-the-mean artifacts.
- **Concrete fix:** Show parallel results for:
  - level outcomes with baseline control,
  - rank/rank changes,
  - transition probabilities to higher/lower occupation bins,
  - county-level average changes.

#### 8. Reframe “mechanisms” as descriptive heterogeneity unless directly tested
- **Issue:** Mechanism interpretations are stronger than the design supports.
- **Why it matters:** Overstated mechanism claims weaken credibility.
- **Concrete fix:** Rename to “heterogeneity by baseline sector and outcome margin,” and separate empirical findings from conjectured channels.

#### 9. Analyze selection into linkage more seriously
- **Issue:** The paper assumes false matches mainly attenuate effects.
- **Why it matters:** Linkage and survivorship can be systematically related to nativity, mobility, and treatment exposure.
- **Concrete fix:** Report linkage rates by state and exposure, test whether treatment predicts linkage/survival observables, and consider reweighting or bounds.

### 3. Optional polish

#### 10. Improve literature positioning around shift-share/continuous-treatment designs
- **Issue:** The current methodological framing overemphasizes staggered-DiD papers that do not directly solve this paper’s problem.
- **Why it matters:** Better positioning clarifies what assumptions the design really requires.
- **Concrete fix:** Add Borusyak-Hull-Jaravel, Goldsmith-Pinkham-Sorkin-Swift, and related continuous-treatment design references.

#### 11. Report underlying robustness outputs
- **Issue:** Some claims rely on unreported details (leave-one-out significance, non-South estimates, etc.).
- **Why it matters:** Transparency matters especially when identification is contested.
- **Concrete fix:** Put the full robustness tables in the appendix.

#### 12. Harmonize significance language with reported estimates
- **Issue:** At least one textual significance claim contradicts the table (binary high-exposure specification).
- **Why it matters:** These inconsistencies undermine trust.
- **Concrete fix:** Audit all result descriptions against tables and appendices.

## 7. Overall assessment

### Key strengths
- Original and interesting question.
- Rich historical linked-census data with large coverage.
- Ambitious attempt to study spillovers on non-alcohol workers rather than directly treated workers.
- Commendable transparency about some threats, especially the earlier-period differential trend.

### Critical weaknesses
- Main identification strategy is not credible for causal claims.
- The paper’s own earlier-period evidence substantially undermines parallel trends.
- Exposure is post-treatment for key early adopters.
- The preferred estimate is highly specification-sensitive.
- The 1920–1930 “reversal” is not credibly identified.
- Mechanism and policy claims exceed what the design can support.
- Inference evidence is inconsistent and insufficiently explained.

### Publishability after revision
In its current form, I do not think the paper is publishable in a top general-interest journal or AEJ: Economic Policy. However, the topic and data are promising. A major redesign could make this into a valuable paper. The most realistic path is either:
1. a substantially stronger quasi-experimental design, or  
2. an explicit repositioning as a careful descriptive historical paper with much more modest claims.

As written, the manuscript has enough promise that I would not recommend outright rejection without possibility of return, but it requires deep empirical redesign rather than incremental revision.

**DECISION: REJECT AND RESUBMIT**