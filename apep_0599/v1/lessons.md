## Discovery
- **Policy chosen:** Denmark's 2013 disability pension reform — age-graded treatment intensity (under-40 ban) creates clean triple-diff, massive first stage (33% decline), and an unanswered substitution question
- **Ideas rejected:** N/A (pinned idea from database)
- **Data source:** Statistics Denmark StatBank API (AUK01, RAS301, INDKP111) — free, no auth, quarterly municipality × age × benefit type
- **Key risk:** The reform bundled three changes simultaneously (under-40 ban, resource scheme, flexjob expansion); separating their individual contributions may be difficult. The age-group comparison assumes no other age-differential policy changes around 2013.

## Review
- **Advisor verdict:** 3 of 4 PASS (attempt 4)
- **Referee verdicts:** GPT R1 = MAJOR REVISION, GPT R2 = REJECT AND RESUBMIT, Gemini = MAJOR REVISION
- **Top criticism:** Moulton-type inference problem in simple DiD (treatment varies at age×time, SEs clustered by municipality) — R2's strongest point
- **Surprise feedback:** Employment event study revealed 4/4 significant pre-trends, completely invalidating the simple DiD employment claim. Employment DDD only -0.59 vs DiD of -3.52 — most of the "effect" was age-specific secular trends.
- **DDD event study validation:** 0/19 pre-trends significant for DP and resource scheme — the DDD design is clean
- **What changed:** (1) Added DDD event study as centerpiece validation, (2) Downgraded simple DiD to descriptive, (3) Sharply reduced employment claims, (4) Added Moulton discussion, (5) Rewrote abstract and conclusion to be more cautious, (6) Added stock-vs-flow limitations discussion, (7) Reframed "where applicants went" as "which stocks rose"
