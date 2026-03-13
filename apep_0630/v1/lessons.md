## Discovery
- **Idea selected:** idea_0077 — Surprise billing laws and ED quality via PE staffing channel
- **Data source:** NBER Hospital Compare archive (CMS OP-18b, OP-22) — inconsistent file naming across years required extensive mapping; date parsing was non-trivial (MM/DD/YYYY vs YYYY-MM-DD)
- **Key risk:** Limited treatment intensity due to ERISA preemption (~40% of commercially insured)

## Execution
- **What worked:** Sun-Abraham estimator handled unbalanced panel well; 3,063 hospitals across 50 states gave adequate power; staggered adoption across 4 cohorts provided good variation
- **What didn't:** Callaway-Sant'Anna failed even on balanced subsets (too few hospitals per cohort-year cell); fwildclusterboot not available for R 4.3.x; NBER downloads timed out for some years requiring curl fallback; only 9 treated clusters limits inference
- **Review feedback adopted:** Added MDE/power discussion; strengthened pre-trend interpretation (composition vs violation); expanded limitations paragraph covering ERISA, unmeasured margins, few-cluster inference; improved placebo discussion acknowledging concurrent state reforms; quantified revenue shock attenuation
- **Key lesson:** For staggered DiD with few treated states, plan for inference challenges upfront. The significant placebo (OP-20) was the single most damaging finding — a true inpatient placebo would have been much stronger.
