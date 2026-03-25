## Discovery
- **Idea selected:** idea_1858 — Dominican Republic MIPYME procurement set-asides. Chose for rich transaction-level data (655K awards), sharp quasi-experiment, and globally relevant question.
- **Data source:** DGCP open data (datos.gob.do) — three CSV files downloaded cleanly. Date format was m/d/Y, not d/m/Y. Agency linking required building a crosswalk between acronyms in contract codes and numeric IDs in process records.
- **Key risk:** Treatment endogeneity — ΔMIPYME is realized compliance, not quasi-random assignment.

## Execution
- **What worked:** The supplier decomposition with firm age data was the strongest contribution. Relabeled firms (median 9.7 years) vs new MIPYMEs (median 2.5 years) made the relabeling story concrete and testable.
- **What didn't:** The initial specification overstated the supplier decline. Controlling for procurement volume eliminated the effect — the decline was driven by procurement consolidation, not supplier exclusion. This required reframing the story mid-paper.
- **Review feedback adopted:** Added composition channel discussion (procurement consolidation drives supplier decline), firm age evidence, levels interpretation (2.4 fewer suppliers per agency-quarter), and explicit acknowledgment of treatment endogeneity with suggestions for future instrumentation.
