# Internal Review — Round 1

**Paper:** apep_0584 — The Symmetric Test: Drug Decriminalization and Recriminalization in Oregon
**Reviewer:** Claude Code (Internal)
**Date:** 2026-03-10

## Overall Assessment

**Verdict: Minor Revision**

This paper makes a genuine methodological contribution by formalizing the symmetric test design and applying it to a timely policy question. The writing is strong, the institutional background is well-researched, and the drug decomposition analysis is the paper's most valuable contribution. Several issues should be addressed before external review.

## Strengths

1. **Innovative design.** The symmetric test is a clever exploitation of Oregon's policy reversal. The paper clearly articulates why two-switch designs provide stronger identification than single-switch designs.

2. **Drug decomposition.** The finding that fentanyl accounts for 86% of the Design 1 effect is the paper's most important result. It directly addresses the central confounding concern and is well-presented.

3. **Honest interpretation.** The paper does not overclaim. The discussion presents both the causal and confounding interpretations fairly, which strengthens credibility.

4. **Good pre-treatment fit.** Design 1 RMSPE of 0.54 is excellent for state-level overdose data.

## Weaknesses and Suggestions

### Methodology

1. **Table 2 notes reference augmented SCM but code uses tidysynth.** The table notes mention "Augmented synthetic control estimates (Ben-Michael et al., 2021) with ridge augmentation" but the actual implementation uses standard SCM via tidysynth. This is a factual error that must be corrected.

2. **SE interpretation.** The conventional p-value (0.229) and RI p-value (0.020) tell very different stories. The paper discusses this tension well but should be more explicit about which inference to prefer and why.

3. **Independence assumption in symmetric test.** The paper acknowledges the assumption is "strong" but should discuss what happens under positive correlation — the true SE would be smaller, making the test more powerful and potentially rejecting the null.

### Presentation

4. **Table 1 is not referenced in the main text by label.** Add a proper \Cref{tab:summary} reference.

5. **The paper could benefit from one more figure:** a placebo spaghetti plot showing all donor state gaps alongside Oregon's, which is standard in the SCM literature.

### Content

6. **Missing discussion of anticipation effects.** Measure 110 was passed in November 2020 but took effect February 2021. Was there anticipation? Similarly, HB 4002 was signed March 2024 but took effect September 2024 — a 6-month anticipation window.

7. **Limited post-treatment period for Design 2.** The paper acknowledges this but could be more quantitative about statistical power.

## Required Changes

1. Fix table notes (remove "augmented" language)
2. Add anticipation effects discussion to threats section
