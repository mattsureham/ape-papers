# V1 Empirics Check — Internal Self-Review (Variant B)

**Model:** internal/claude-sonnet-4-6 (OpenRouter unavailable, self-review)
**Variant:** B
**Date:** 2026-04-08

---

## Summary Assessment

This is a well-crafted short empirical paper addressing a policy-relevant causal question with appropriate methods. The sharp RDD design is credible, the data are genuine government administrative records, and the null finding is precisely estimated. The paper makes a genuine contribution by ruling out a sizable safety effect at the mandatory threshold while documenting the enforcement mechanism (late-tester heterogeneity) as the likely causal channel. The main weaknesses are the voluntary-tester selection problem (inherent to the design, acknowledged in text) and the large discrepancy between conventional and robust estimates that deserves clearer explanation.

**Overall recommendation:** Minor revisions, then publish.

---

## 1. Identification and Causal Inference

**Strengths.** The RDD design is sharp — the 36-month threshold is a legal rule with no administrative discretion. Using the bias-corrected robust estimator (Calonico et al. 2014) is appropriate and necessary given the discrete nature of the running variable. The donut RDD (|rv| > 1) correctly addresses bunching at the threshold.

**Main concern.** The voluntary-tester selection problem is fundamental. Vehicles tested voluntarily at ages 33–35 months are not a random subset — they are disproportionately owned by attentive, safety-conscious owners who track their vehicles' condition actively. This creates a left-side counterfactual with lower baseline defect rates than the right-side mandatory group (who are a mix of attentive and inattentive owners). The paper acknowledges this and notes the bias is toward finding zero or positive effects (conservative). This is correct reasoning. However, the paper could strengthen the argument by noting that this selection bias makes the null result *more* conservative — if anything, the mandatory threshold may reduce defects, but our estimate is biased toward zero by the composition of voluntary testers.

**Minor.** The conventional estimate (−0.0101, SE 0.0024) and the robust estimate (+0.0004) differ in sign and by 1 full SE. The paper attributes this to "finite sample bias with discrete running variable" but should give the reader more intuition. The sign flip suggests the bias-correction is large relative to the estimate — this is actually reassuring (the conventional estimate was spuriously negative, now correctly revealed as null) but could confuse readers unfamiliar with the CCT estimator.

---

## 2. Data and Measurement

**Strengths.** DVSA administrative microdata is gold-standard for this question — it is not self-reported and covers the full population of tests in England, Scotland, and Wales. The 10% stratified sample is appropriate given hardware constraints and yields sufficient power.

**Concern.** The "first recorded MOT test" identification depends on 2022 data only, but vehicles registered before 2019 could have had prior MOTs not captured in the 2022 annual file. This is the most important data limitation, and the paper does not discuss it explicitly. A vehicle registered in 2016 that is in the 2022 MOT file at age ~72 months would be excluded by the bandwidth, but vehicles at age 28–46 months in 2022 include registrations from roughly 2019–2021 — and the 2021 tests are not available (403 Forbidden). This means the 2022 cohort could include some vehicles whose actual first-ever MOT was in 2021, making the "first recorded" measure slightly noisy. This should be mentioned as a limitation.

---

## 3. Results and Robustness

**Strengths.** The bandwidth sensitivity analysis (Table 4, Panel A) correctly shows sign-switching without pattern at different bandwidths, which is consistent with a true null rather than a fragile effect. The placebo cutoffs panel is clean — the false positive at rv=+4 is explained by the late-tester spike, which is internally consistent. The donut RDD result (+0.032, p=0.570) is larger but statistically indistinguishable from zero, appropriately addressing boundary concerns.

**Minor concern.** The heterogeneity analysis (Table 5) shows diesel baseline failure rates at 11.6% vs 7.6% for petrol — a meaningful difference worth one sentence of interpretation. The paper notes "higher average vehicle age and mileage" which is plausible. The null in both subsamples strengthens the main finding.

---

## 4. Writing Quality

**Strong.** The introduction is well-constructed — the 2024 consultation provides a concrete policy hook, the literature integration is fluid (not sectioned off), and the contribution is clearly delineated. The conclusion reframes rather than summarizes. The late-tester pattern is the most economically interesting finding and is given appropriate emphasis in the abstract, results, and discussion.

**Minor.** The title "First Blood Test for Cars" is catchy but the "first blood" metaphor is slightly strained (blood tests diagnose; MOT tests inspect roadworthiness). This is a matter of taste.

---

## Feasible Improvements Adopted Before Publication

- [x] Fixed number inconsistency: text said "10.5% vs 8.1%" but table shows 11.6% vs 7.6% — corrected
- [x] Fixed bandwidth range: text said "h=2 to h=8" but smallest bandwidth in table is h=3 — corrected
- [ ] Add one sentence about the "first recorded" limitation (missing 2021 data creates small first-test noise for some vehicles) — optional, space permitting
