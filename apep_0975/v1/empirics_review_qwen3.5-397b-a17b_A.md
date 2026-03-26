# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant A)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** A
**Date:** 2026-03-26T11:55:48.716065

---

# Referee Report

## 1. Idea Fidelity

The paper largely pursues the original research question from the manifest but deviates in several important ways from the proposed identification strategy:

- **Treatment definition**: The manifest proposed contrasting 2 early transposers against 13 infringement-procedure countries. The implemented design uses three cohorts (2016, 2017, 2018) with 15 countries classified as "on time" in 2017. This is a material departure that weakens the natural experiment—the infringement proceedings were the clearest source of exogenous variation.

- **Control group**: The manifest identified Denmark and Ireland as never-treated controls due to opt-outs. The paper retains this, but the small control group (2 countries) creates serious identification concerns that the manifest did not adequately flag.

- **Outcome measures**: The manifest correctly identified ICCS categories, but the paper's distinction between "cross-border" and "domestic" crime categories is problematic—fraud and theft can be purely domestic, undermining the triple-difference logic.

These are not fatal deviations, but they do meaningfully alter the credibility of the causal claims relative to what the manifest promised.

---

## 2. Summary

This paper provides the first empirical evaluation of the European Investigation Order Directive's effect on crime, exploiting staggered transposition across EU member states. The author finds no evidence of deterrence but documents increased reporting of cross-border crime categories post-transposition, interpreting this as a detection channel rather than enforcement failure. The paper fills a genuine gap in the literature on EU criminal justice cooperation.

---

## 3. Essential Points

**1. The control group is too small and potentially non-comparable.** With only Denmark and Ireland as never-treated units, the parallel trends assumption rests on two countries that opted out of Justice and Home Affairs measures entirely. These are systematically different from participating states (e.g., different legal traditions, different relationships with EU law). The Callaway-Sant'Anna estimator helps with staggered timing, but it cannot solve the fundamental problem that the control group may not represent valid counterfactuals. *The author should either: (a) use all non-infringement countries as a control group with appropriate weighting, (b) employ synthetic control methods to construct a better comparator, or (c) acknowledge this as a first-stage descriptive exercise rather than causal inference.*

**2. The "cross-border" vs. "domestic" crime classification is conceptually flawed.** The triple-difference treats fraud, drugs, and theft as inherently cross-border crimes, and homicide/assault as inherently domestic. But most fraud is domestic, and some homicides involve cross-border elements. The EIO does not change whether a crime *is* cross-border—it changes whether evidence can be gathered across borders *when needed*. This misclassification biases the DDD interpretation. *The author should either: (a) find data on actual cross-border cases (e.g., Eurojust statistics on EIO usage), (b) reframe the DDD as "EIO-relevant" vs. "EIO-irrelevant" crimes with clearer justification, or (c) drop the DDD and focus on the staggered DiD with appropriate caveats.*

**3. The detection-channel interpretation needs stronger supporting evidence.** The claim that increased reporting reflects detection rather than actual crime increases is plausible but asserted rather than demonstrated. If detection improved, we might expect: (a) higher conviction rates for cross-border crimes, (b) shorter case processing times, or (c) increased EIO usage correlating with crime reporting changes. *The author should add at least one of these supporting tests, or substantially temper the causal language around the detection mechanism.*

---

## 4. Suggestions

**Empirical Strategy Refinements**

- **Event-study visualization**: The paper mentions testing parallel trends but does not include event-study plots. For an AER: Insights paper, a clear event-study figure showing pre-treatment trends across cohorts is essential. This would help readers assess whether the 2016 cohort (early transposers) differs systematically from later cohorts.

- **Infringement-based identification**: Return to the manifest's original insight—the 13 infringement-procedure countries represent a clearer treatment group. These countries faced Commission pressure and may have had different implementation incentives than voluntary early adopters. A simple treated (infringement) vs. control (no infringement) comparison, even if less sophisticated, may be more credible than the current three-cohort design.

- **Weighting by EIO usage**: If possible, weight countries by actual EIO usage statistics (available from Commission implementation reports). Countries that rarely use EIOs should not contribute equally to the treatment effect. This would strengthen the mechanism test.

**Data and Measurement**

- **Missing data transparency**: Table 1 shows Fraud N=182 but Drug offences N=405, despite the same country-year panel. Explain this discrepancy. Is fraud data missing for certain countries/years? If so, this could bias results if missingness correlates with treatment timing.

- **Alternative outcome metrics**: The paper acknowledges that conviction rates and case completion times would better capture EIO effectiveness. Even if these data are not available for all countries, the author could: (a) cite Commission implementation reports with aggregate statistics, (b) include a table summarizing known EIO usage by country, or (c) explicitly frame the paper as a "first cut" using the best available crime data.

- **COVID-19 handling**: The robustness check excludes 2020-2022, but the EIO's main effects may have occurred during pandemic disruption (travel restrictions affected cross-border crime differently). Consider including 2019 as a clean post-treatment year for countries that transposed in 2017-2018.

**Interpretation and Framing**

- **Null result framing**: The abstract says "no evidence that the EIO reduced fraud"—this is accurate. But the discussion could more explicitly address power. With 25 countries and crime rates that vary 5x across the EU, what minimum detectable effect does the design support? A power analysis would help readers interpret the null.

- **Policy implications**: The conclusion suggests the EIO may be "succeeding at exactly what its designers intended." This is speculative without conviction or clearance data. Reframe to: "If the EIO improved detection, we would expect X. Future work should measure Y."

- **Legal accuracy**: The paper states the EIO created "binding 90-day deadlines." In practice, these deadlines are frequently extended, and member states can refuse EIOs on fundamental rights grounds. A brief acknowledgment of implementation gaps would improve accuracy.

**Presentation**

- **Table 2 clarity**: The transposition table lists Czechia as 2016 "On time / 2017"—this is confusing. Either use the actual transposition year or the deadline year consistently.

- **Standardized effect sizes**: The appendix table reports SDE but the main text does not reference it. Include a sentence in the results section noting that even large standardized effects are statistically insignificant.

- **Replication materials**: For an AER: Insights paper, indicate whether code and data construction scripts will be made available. Given the complex Eurostat/EUR-Lex data merging, this is particularly important.

**Substantive Additions That Would Strengthen the Paper**

1. **Eurojust data**: Eurojust publishes annual statistics on cross-border cases. Even if not country-specific, trend data could support the detection-channel narrative.

2. **Heterogeneity by border length**: Countries with longer internal EU borders (e.g., Germany, Poland) should benefit more from the EIO than island states. A heterogeneity test could strengthen the mechanism argument.

3. **Comparison to mutual legal assistance trends**: If the EIO improved detection, pre-EIO trends in cross-border crime reporting should differ from post-EIO trends. A simple interrupted time-series for high-EIO-usage countries could be informative.

---

**Overall Assessment**: This is a timely and important topic with genuine novelty—no empirical economics paper has evaluated the EIO. The null deterrence finding is itself valuable. However, the identification strategy requires strengthening, particularly around the control group and crime classification. With the suggested revisions, this could be a solid AER: Insights contribution. I recommend **revise and resubmit** with attention to the three essential points above.
