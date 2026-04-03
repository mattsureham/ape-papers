## Discovery
- **Idea selected:** idea_2021 — Mallinckrodt's oxycodone product-line expansion as a shift-share instrument for county-level potency. Chose for tournament-optimal profile: IV design, 178M-row microdata, first-order stakes, portable mechanism.
- **Data source:** DEA ARCOS on Azure (1.49 GB Parquet). No fetch issues; data was pre-staged from Washington Post bulk release.
- **Key risk:** Exclusion restriction — 2006 Mallinckrodt share could correlate with unobserved county demand trends. Mitigated by hydrocodone placebo (null) and LOO stability (55/55).

## Execution
- **What worked:** The shift-share instrument is clean and strong (β = 3.97, all 55 LOO same sign). The event study shows a sharp post-2008 break. The product expansion is observable down to the NDC level.
- **What didn't:** Hit an NA propagation bug where 33K rows with missing dose strings cascaded through R's `sum()` to wipe out 83% of counties. Cost ~15 minutes to diagnose and fix with `na.rm = TRUE`. Lesson: always check NA counts after SQL→R pipelines.
- **Review feedback adopted:** Clarified scope of inference (first-stage/reduced-form, not 2SLS health impact), added wild cluster bootstrap note, strengthened estimand discussion.
