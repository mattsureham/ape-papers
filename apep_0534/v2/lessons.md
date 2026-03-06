# Lessons: apep_0534 v2

## Discovery
- BigQuery PatEx data (application-level with abandonments) is a genuine advance over PatentsView grants-only for examiner IV designs
- The idea manifest for v1 claimed "examiner grant rate" but only used PatentsView (grants-only); v2 fixed this by using PatEx
- Subclass imputation for abandoned applications (modal subclass from art unit) is a significant measurement concern

## Review Insights
- **Pseudo-replication is the central issue:** When 640K observations share 96 unique outcome values, application-level inference is unreliable. All four advisor models and all three external reviewers flagged this.
- **Aggregation sensitivity reveals design instability:** Subclass-year collapse (significant) vs art-unit-year collapse (null) shows the result depends on which aggregation preserves which dimension of variation.
- **"Bad controls" (zero-coded abandonments):** Claims/citations coded as zero for abandonments mechanically proxy grant status. First stage drops from 0.151 to 0.018 with controls. Lesson: always present uncontrolled spec as baseline when controls are post-treatment.
- **Citation mechanical contamination:** Abandoned apps literally can't be cited → large positive citation effect is mostly mechanical. Must always check if outcome construction introduces mechanical correlations.
- **Over-determined specs trigger persistent false positives:** Domain × year FE on top of AU × year FE pushed R² to 0.9999. Removed from main table after 3 rounds of advisors flagging it.
- **Placebo construction matters:** Original placebo summed application-level follow-on (double-counting within cells), producing SE=0.000001. Fixed to deduplicate at subclass-year level → SE=0.000310 but now significant (mechanical complement).

## Summary
The paper's core contribution is methodological: demonstrating how application-level PatEx data enables proper first-stage estimation in examiner IV designs. The downstream causal evidence is mixed — negative at subclass-year level, null at AU-year level — and honestly presented as such. The paper was revised from a "blocking effect" story to an honest acknowledgment that the design cannot cleanly identify downstream effects with the available aggregated outcome.

Key decision: reframing the contribution from "causal blocking estimate" to "methodological + descriptive" was the right call given reviewer consensus. The paper is more honest and defensible as a result.
