## Discovery
- **Idea selected:** idea_0842 — PSL mandates and workplace injuries via OSHA ITA data
- **Data source:** OSHA ITA 300A summaries (2017-2023) — 2016 file returned 404; integer64 corruption in 2020-2023 files required `integer64 = "double"` fix in fread
- **Key risk:** Large-establishment sample selection (250+ employees) limits external validity; most firms already offered PSL before mandates

## Execution
- **What worked:** Clean staggered DiD design with 8 treated states and 37 never-treated controls; CS, SA, and TWFE all implemented; wild cluster bootstrap for few-cluster inference; death rate placebo passed
- **What didn't:** DJTR initially appeared significant under CS (-0.23***) but dissolved under SA/bootstrap — fragile result driven by cohort weighting, not robust treatment effect
- **Review feedback adopted:** Reframed the null as "cannot rule out moderate effects" rather than "no effect"; explicitly reported minimum detectable effect (17% of mean); elevated large-firm selection bias from minor limitation to primary concern; addressed DJTR discrepancy across estimators directly in results text
