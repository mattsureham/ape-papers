## Discovery
- **Idea selected:** idea_1635 — Lactation accommodation laws and maternal employment retention (DDD)
- **Data source:** Census QWI from Azure (sex×age panel) — fast, reliable
- **Key risk:** Population dilution — only ~4% of women 25-34 are postpartum in any quarter

## Execution
- **What worked:** DDD design with two clean placebos (male p=0.86, older female p=0.83). QWI Azure pipeline continues to be the fastest data path.
- **What didn't:** The aggregate null is hard to interpret — can't distinguish "no effect on mothers" from "effect diluted 25:1 in aggregate data." Reviewers correctly flagged this. Also, the 2010 ACA federal floor muddies post-2010 state law estimates.
- **Review feedback adopted:** Added population dilution arithmetic (4% postpartum share → 0.04pp detectable effect per 1pp maternal effect), ACA federal floor discussion, reframed abstract/conclusion to present three-way interpretation rather than asserting laws don't work.
- **Lesson for future papers:** When the treatment only affects a small subgroup of the measured population, front-load the dilution math. Don't wait for reviewers to flag it — compute the implicit MDE for the affected subgroup and report it alongside the aggregate estimate. Also: staggered state DiD papers should explicitly address federal policy floors that change the estimand mid-sample.
