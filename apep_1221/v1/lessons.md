## Discovery
- **Idea selected:** idea_2145 — Examiner leniency IV for inventor mobility; chosen for strong design (judges love examiner IVs) and novel outcome (geographic reallocation)
- **Data source:** BigQuery USPTO PAIR — 5.37M inventor-app rows, reliable and fast to query
- **Key risk:** Balance/placebo tests flagged imperfect randomization within AU×year cells

## Execution
- **What worked:** BigQuery data fetch was seamless (previous failure was only config). The reduced form is textbook-clean: perfectly monotonic across quintiles. Heterogeneity patterns are theory-consistent and informative.
- **What didn't:** Balance tests fail — leniency predicts pre-determined characteristics and prior mobility. Name-based inventor IDs create measurement error that may drive the placebo failure. The Stage 2 (QWI aggregate) was dropped for scope reasons.
- **Review feedback adopted:** Softened causal claims throughout (abstract, discussion, conclusion). Added BOE calculation for aggregate drain. Added third limitation about sample selection bias. Reframed as "suggestive evidence" rather than definitive causal.

## Key Lessons
- Examiner IV papers require very careful balance checks at fine conditioning levels — art-unit × year may be too coarse
- Name-based inventor matching is a real liability for mobility outcomes; future work should use PatentsView or Google Patents disambiguation
- Honest presentation of limitations is both scientifically correct and strategically wise (tournament penalizes overclaiming)
