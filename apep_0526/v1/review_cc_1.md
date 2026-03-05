# Internal Review — Round 1

**Paper:** Symbolic Legislation and Innovation Markets: The Effect of Right-to-Try Laws on U.S. Clinical Trials
**Reviewer:** Claude Code (self-review)
**Date:** 2026-03-05

## Verdict: **MINOR REVISION**

## Summary

This paper tests whether state Right-to-Try laws (2014–2018) disrupted the U.S. clinical trial market using ClinicalTrials.gov data and a staggered DiD design (Callaway–Sant'Anna). The main finding is a precisely estimated null: no detectable effects on trial site counts, enrollment, or terminal-condition trials. The paper is well-powered (MDE = 7.7%) and supported by a comprehensive robustness toolkit.

## Strengths

1. **Novel question and data**: First causal evaluation of Right-to-Try laws' market effects using ClinicalTrials.gov as a universe administrative dataset. The data construction is impressive (75,426 trials, 342,547 facility records).
2. **Well-powered null**: The MDE of 7.7% is tight enough to be policy-relevant. The paper correctly frames this as the main contribution.
3. **Comprehensive diagnostics**: Bacon decomposition, randomization inference (p = 0.948), Rambachan–Roth sensitivity, leave-one-out, region×quarter FE, donut specification. This is a full toolkit.
4. **Built-in placebos**: Three placebo outcomes (non-terminal, Phase I, observational) all pass, strengthening the identification.
5. **Writing quality**: The introduction hook is effective, the results tell a story, and the conclusion lands well.

## Weaknesses / Concerns

1. **Never-treated group composition**: Only 13 states (+ DC) never passed state laws. The paper should discuss whether these states are systematically different in biomedical research infrastructure. Several are major biotech hubs (MA, NY, NJ) — this is addressed in the LOO analysis but could be discussed more explicitly.

2. **Enrollment measurement**: Total enrollment is assigned fully to each state (not divided). This means a single large multi-site trial inflates the enrollment measure for all states. This should be acknowledged more explicitly as a measurement limitation.

3. **Terminal condition classification**: Text matching on condition descriptions is reasonable but imperfect. The paper acknowledges this but doesn't report the classification accuracy or show sensitivity to alternative term lists.

4. **Missing welfare analysis**: The research plan mentioned a welfare/cost-benefit section, but the paper doesn't include one. Even a brief back-of-envelope (e.g., "the MDE bounds imply <X trials displaced, valued at <Y in consumer surplus") would strengthen the contribution.

5. **Late adopter post-treatment window**: 2017 cohorts have only 1–4 quarters of post-treatment data. While the event study shows no delayed effects, this limits what we can say about medium-run responses.

## Minor Issues

- The `\citeauthor{darrow2018practical}` entry has year=2015 in the bib but key says 2018 — potential confusion in text citations.
- The number of treated states is reported as both 32 (in power analysis) and 38 (in text). The panel runs 2008–2017, so 2018 adopters (NE, WI) are excluded from the treated group, but this should be stated more clearly.
- Consider adding a brief note on the FDA Amendments Act of 2007 requiring registration — this is what makes ClinicalTrials.gov a universe dataset starting 2008.

## Recommendation

Proceed with minor revisions addressing the enrollment measurement note, clarifying the 32 vs 38 treated states distinction, and fixing the bib entry. The paper is strong and ready for external review.
