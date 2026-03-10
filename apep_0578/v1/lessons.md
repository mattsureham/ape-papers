## Discovery
- **Policy chosen:** Temporary Schengen border control reintroductions (2015+) — a novel natural experiment testing whether integration gains are reversible
- **Ideas rejected:** No alternatives considered; this was a pinned idea (idea_0516) with READY feasibility grade and confirmed Eurostat data access
- **Data source:** Eurostat NUTS3 regional accounts (nama_10r_3gdp, nama_10r_3gva, nama_10r_3empers) — no API key needed, 22-year panel
- **Key risk:** Refugee crisis confounding (simultaneous shock at same borders); addressed via placebo on non-migration-route borders and COVID truncation robustness

## Review
- **Advisor verdict:** 3 of 4 PASS (attempt 5; GPT R2 failed on claim calibration)
- **Top criticism:** Inference at wrong level — region-level clustering is anti-conservative when treatment is assigned at only 6 border segments. Segment-level RI (p=0.67) fundamentally changed the paper's narrative from "precise null" to "insufficient power."
- **Surprise feedback:** Border-only + country×year FE yielded a *positive* significant effect (+0.057***), the opposite sign from baseline TWFE. This likely reflects growth differences among the small set of untreated border segments rather than a real positive effect of controls.
- **What changed:** (1) Added segment-level RI as primary inference; (2) Recalibrated all claims — removed "precisely estimated null" language; (3) Added placebos under C×Y FE; (4) Added CS with country covariates; (5) Cited Conley-Taber, Ferman-Pinto, MacKinnon-Webb few-cluster literature.

## Summary
- **Key takeaway:** With only 6 treatment units (border segments), no amount of individual-region observation inflates statistical power. The segment-level RI is the honest test. This paper is a cautionary tale about confusing sample size with effective sample size.
- **What worked well:** Eurostat data was clean and accessible; the CS estimator ran smoothly; exhibit and prose reviews improved presentation significantly.
- **What didn't work:** 06_tables.R auto-generation overwrote manual Table 2 edits twice — need to either update the R script or stop regenerating tables after manual edits.
- **For future EU papers:** Always check the effective number of treatment units before committing to DiD. EU-wide policy variation often has far fewer independent policy changes than the number of affected regions suggests.
