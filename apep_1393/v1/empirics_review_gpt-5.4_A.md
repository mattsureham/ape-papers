# V1 Empirics Check — openai/gpt-5.4 (Variant A)

**Model:** openai/gpt-5.4
**Variant:** A
**Date:** 2026-04-07T21:49:50.819478

---

## 1. Idea Fidelity

The paper clearly pursues the core question in the manifest: whether merger-induced branch closures widen racial gaps in mortgage lending, using FDIC branch data, FDIC merger histories, and post-2018 HMDA. It also adopts the intended IV logic based on local exposure to recently merged institutions and frames the contribution relative to Nguyen (2019).

That said, the implementation departs from the original idea in several important ways. First, the manifest envisioned tract-level or loan-level analysis exploiting richer HMDA controls (DTI, LTV, AUS) and within-county spatial variation; the paper instead aggregates to the county-year-race level and largely does not use the expanded HMDA underwriting variables in the main design. Second, the manifest proposed MSA-year or otherwise fine market-time fixed effects, whereas the paper’s main specification uses only state and year fixed effects, leaving substantial concern that the identifying variation is cross-county rather than plausibly quasi-random. Third, the paper’s exclusion restriction is weaker than in the original idea because merger exposure may affect mortgage outcomes through channels other than branch closure, including lender identity, underwriting, and post-merger portfolio reallocation. So the paper follows the spirit of the manifest, but not yet the stronger empirical design it implied.

## 2. Summary

This paper studies whether bank mergers, through subsequent branch consolidation, widen racial disparities in mortgage lending. Using county-year data linking FDIC branch panels, FDIC merger events, and HMDA applications for 20 states from 2018–2023, the paper instruments branch change rates with local merger exposure and finds that merger-induced branch closures increase the Black-White denial gap, with little effect on the Asian-White gap.

The topic is important and timely, and the paper asks a policy-relevant question. However, the current empirical design does not yet convincingly isolate the causal effect of branch closures per se, and the aggregation and fixed-effects structure are not well aligned with the mechanism the paper emphasizes.

## 3. Essential Points

1. **The exclusion restriction is not credible in the current design.**  
   The instrument is the share of county branches belonging to recently merged institutions. But mergers can directly change mortgage outcomes even absent branch closures: the merged bank may alter underwriting standards, product menus, staffing, pricing, CRA strategy, automated underwriting, or branch-to-loan-officer matching. In other words, “merger exposure” is not a clean shifter of physical access only; it is also a shifter of lender composition and lending behavior. This is especially problematic because the outcome is a mortgage denial gap, which can move because the set of active lenders in the county changes. The paper therefore does not identify the effect of branch closures unless it can rule out these non-closure channels much more convincingly.

2. **The identifying variation is too coarse, and the fixed effects are too weak for the claims being made.**  
   The main specification includes only state and year fixed effects. With six years of data, this means the IV estimate is driven importantly by persistent differences across counties in exposure to banks that happen to merge. Those differences are likely correlated with local banking structure, demographics, urbanization, competition, fintech penetration, and secular changes in mortgage markets. The fact that county fixed effects cause the first stage to weaken is itself informative: the preferred results appear to rely heavily on cross-county variation, which is the least credible source for this question. A paper making strong causal claims about local access should, at minimum, move much closer to county-by-time or market-by-time identification, or else substantially moderate its claims.

3. **The empirical approach does not match the mechanism or the available data closely enough.**  
   The paper repeatedly argues for “relationship destruction” and highlights the value of expanded HMDA controls, but the main analysis is county-year-race aggregates. This creates two problems: (i) the outcome conflates applicant composition, lender composition, and underwriting decisions; and (ii) the paper cannot test whether effects are stronger near actual closed branches, among applicants more reliant on branch-based intermediation, or after conditioning on DTI/LTV/AUS. As written, the analysis is closer to documenting a county-level correlation between consolidation exposure and racial gaps than to establishing that branch closures causally reduce mortgage access for comparable Black borrowers.

## 4. Suggestions

This is a promising paper, and I think the question is worth pursuing. My main recommendation is to redesign the empirical strategy so that the identifying variation more closely matches the mechanism and so that the instrument can be defended as shifting branch presence rather than broader merger-induced lending behavior.

**1. Move the analysis down to a finer geographic unit, ideally tract-year or branch/tract-distance cells.**  
The manifest’s original tract-level vision is much stronger than the current county-year design. If the mechanism is loss of nearby branches, then the treatment should vary meaningfully within counties. A tract-level panel would let you compare tracts in the same county or MSA that were differentially exposed to merger-related closures because of pre-merger branch overlap. That would absorb many county-level confounds and align the treatment more directly with borrowers’ actual access. Even a “distance to nearest closed branch” design, or counts of merged-bank closures within 1/3/5 miles of a tract centroid, would be more persuasive than aggregate county branch change rates.

**2. Separate the effect of mergers from the effect of closures.**  
Right now the instrument may move outcomes through merger-related lender changes, not just closures. A better design would isolate closure propensity from merger incidence. For example:
- Construct predicted closure exposure based on **pre-merger overlap** between acquirer and target branch networks in local markets. Branch overlap is much closer to the cost-synergy motive for closures and less plausibly related to county mortgage shocks.
- Use only closures of overlapping branches by merged institutions, rather than all branch declines.
- Show that merger exposure predicts **branch exits specifically among merged institutions**, not general county branch contraction.
- Include controls for lender market shares and lender-entry/exit, or estimate effects within lender-market cells where possible.

A particularly useful decomposition would be: merger exposure → closure of merged-bank branches → change in local lender availability → racial outcomes. At present, the first and second arrows are bundled together.

**3. Strengthen the fixed-effects structure substantially.**  
State and year FE are not enough. At a minimum I would want:
- county fixed effects and year fixed effects;
- ideally MSA-by-year or county-by-year comparisons across tracts;
- possibly bank-by-year or lender composition controls if the unit remains aggregated.

If the within-county first stage is weak, that is not a reason to prefer the weaker specification; it is evidence that the causal design may not have enough identifying power in the current sample. You may need a longer panel, a more targeted treatment variable, or a different unit of analysis rather than relying on cross-county comparisons.

**4. Use the loan-level HMDA data that motivate the paper.**  
The introduction promises a decomposition with DTI, LTV, AUS, and richer underwriting controls, but the core regressions do not deliver it. At the loan level, you could estimate whether closure exposure affects denial probabilities conditional on applicant and loan observables, with tract or county fixed effects and year effects. Even if race-gap estimation is your target, a more direct model would be:
- denial on Black × closure exposure,
- controlling for income, loan amount, DTI, LTV, occupancy, tract characteristics, and AUS recommendation,
- with tract, lender, and time fixed effects as feasible.

This would not solve identification by itself, but it would sharply reduce the concern that changing applicant composition drives the results.

**5. Revisit the event-study design.**  
The current event study based on “first year merger exposure exceeds the median” is not closely tied to treatment. Crossing the median is an arbitrary threshold and may mechanically sort places with different exposure distributions. A more convincing event study would be centered on:
- actual branch closure events by merged institutions;
- or merger completion dates interacted with pre-merger branch overlap;
- with leads and lags estimated relative to those events.

If treatment is continuous, use a modern staggered event-study approach that explicitly handles continuous intensity or repeated events rather than a binary threshold rule. Also, pre-trends should be shown for the actual endogenous regressor and for key observables, not only for the final outcome.

**6. Clarify magnitudes and units; some are currently hard to interpret.**  
The first stage says a one-unit increase in merger exposure lowers branch change by 1.8 percentage points, while the second stage implies a one-percentage-point branch closure change raises the gap by 1.67 percentage points. That produces very large implied effects relative to the outcome variation. The standardized effect sizes reported in the appendix are implausibly enormous and should be reconsidered; they suggest either a unit mismatch or an interpretation problem. I strongly recommend:
- defining all variables in levels vs percentage points very carefully;
- presenting effects for realistic shocks, e.g. a 10 p.p. increase in merger exposure or one branch closure per 10 pre-existing branches;
- showing reduced-form effect sizes alongside first-stage and IV magnitudes.

**7. Improve the discussion of sample construction and representativeness.**  
The paper says 20 states cover about 70% of originations, but it is not clear why these states are selected or whether selection is endogenous to data processing constraints. Since the identifying variation appears partly cross-sectional, sample composition matters. Please provide:
- the exact list of states and rationale for inclusion;
- comparisons of included vs excluded states;
- robustness on a broader sample if possible.

Also, the merger exposure mean of nearly 0.70 is surprisingly high. That deserves validation and explanation. If most county-year observations are highly exposed by construction, then the variation may be less informative than it sounds.

**8. Probe alternative channels more seriously.**  
The paper’s preferred interpretation is “relationship destruction,” but current evidence is indirect. To distinguish mechanisms, consider:
- effects by purchase vs refinance, conforming vs jumbo, or smaller vs larger lenders;
- whether effects are strongest in tracts where the closed branch was especially nearby;
- whether rates of application, denial conditional on AUS recommendation, and pricing move differently;
- whether nonbank lending substitutes in exposed areas.

In particular, if branch closures mainly reallocate borrowers toward nonbanks, that is a different mechanism from relationship loss within banks.

**9. Placebos should be more demanding.**  
The Asian-White null is useful but not decisive. Better placebo tests would include:
- outcomes unlikely to be affected by branch access but sensitive to local shocks;
- pre-determined tract characteristics;
- merger exposure predicting racial gaps in periods before the closure window;
- or “future merger exposure” as a falsification test.

Also, the low-exposure placebo is not very informative because branch changes in those places are generated by a different process.

**10. Tone down the strongest causal and policy claims unless the design is tightened.**  
Phrases such as “first causal estimate,” “stark,” or claims that the paper identifies a “consolidation tax” are premature in the current version. I would recommend reframing the contribution more modestly as evidence consistent with merger-related local banking consolidation worsening racial mortgage disparities, while emphasizing the design limitations. If the revised paper can implement a tract-level or loan-level design with stronger fixed effects and a cleaner instrument tied to branch overlap, then stronger language would be warranted.

Overall, this paper addresses an important question and has assembled valuable data. But in its current form, the identification strategy is not yet persuasive enough for the central causal claim. The good news is that the paper can be improved substantially by exploiting the granularity of the underlying data more fully and by sharpening the distinction between merger effects and branch-closure effects.
