# Reply to Reviewers — Round 1

## Reviewer 1 (GPT-5.4 R1): REJECT AND RESUBMIT

**Core concern: Paper should be re-centered around heterogeneity-robust estimators.**

We agree that the heterogeneity-robust CS-DiD should be the primary estimator and have revised the abstract, introduction, and results sections accordingly. The CS-DiD ATT of -62 is now presented as the primary estimate, with metro-TWFE and entropy-balanced TWFE described as descriptive benchmarks. We explicitly acknowledge the metro-only CS-DiD of -21 (imprecise) and widen the credible range accordingly.

**RI p=0.113:** We have tempered all significance claims in the abstract and introduction. The RI result is no longer dismissed as merely conservative; instead, we acknowledge that inferential confidence should be tempered by the small number of treated units. Implementing RI for all specifications and WCB (requested) is deferred to the next revision due to software compatibility issues.

**Homicide analysis:** Demoted in abstract and introduction to "exploratory." Language now explicitly states the data are "too limited for confident causal claims."

**Treatment validation, stacked DiD, imputation estimators:** These are important suggestions that we plan to implement in a future revision when additional data and methods can be brought to bear.

**Mechanism claims:** Softened throughout. The compositional mechanism is now presented as "the most plausible interpretation" requiring case-level data for validation, rather than as established fact.

---

## Reviewer 2 (GPT-5.4 R2): MAJOR REVISION

**Core concern: TWFE-centered conclusions with staggered adoption + weak inference.**

Same response as R1 — CS-DiD is now primary, TWFE is descriptive. Metro CS-DiD divergence is directly acknowledged.

**Parallel trends:** We agree that pre-trend evidence could be strengthened with trend-balance tests in matched samples. This is planned for the next revision.

**Entropy balancing:** The concentration of weights (max 8.1, mean 0.008) is a valid concern. Effective sample size and weight diagnostics are planned for the next revision.

**Treatment coding:** We agree that a transparent coding appendix with sensitivity analysis would strengthen the paper. Planned for the next revision.

**Homicide rolling average timing:** We have added explicit discussion of the temporal misalignment between 3-year rolling averages and treatment timing (Section 3.2). The homicide analysis is now clearly labeled as exploratory.

**Fiscal savings:** These are illustrative calculations and are labeled as such. We have not changed them but agree they should be clearly framed as rough upper bounds.

---

## Reviewer 3 (Gemini-3-Flash): MINOR REVISION

**RI for metro and DDD specs:** We agree this would strengthen the paper. Due to computational cost, only the baseline specification has RI. We plan to extend this in the next revision.

**Homicide data:** We now explicitly acknowledge that the CHR 3-year rolling average creates temporal misalignment. Obtaining annual CDC Wonder data is the top priority for the next revision.

**Weighting discussion (ATT vs ATE):** We agree that the divergence between unweighted (-179) and population-weighted (-55) estimates deserves more discussion. This is addressed implicitly by centering the narrative on CS-DiD (-62) rather than TWFE.

**External validity:** The geographic concentration of treatment in coastal/Great Lakes states is acknowledged in Section 3.3. We agree that external validity to Southern or non-metro contexts is limited.

---

## Summary of Changes Made

1. **Abstract:** Rewrote to center CS-DiD as primary estimator, acknowledge magnitude uncertainty, demote homicide to exploratory
2. **Introduction:** Softened "credible range" to acknowledge estimator sensitivity; demoted homicide; added "to my knowledge" qualifier
3. **Results (5.3):** Mechanism language softened from "is compositional" to "most plausible mechanism" requiring case-level data
4. **Section 3.2:** Added discussion of rolling-average timing misalignment
5. **Throughout:** Removed meta-references to v1 reviewers; calibrated certainty of claims
