## Discovery
- **Idea selected:** idea_1430 — occupational licensing deregulation and Hispanic earnings; chose for novel angle (QWI ethnicity panel + licensing reform), clean DDD design, and first-order policy stakes
- **Data source:** QWI race/ethnicity panel from Azure — worked well after fixing integer division bug (DuckDB float vs integer) and lowercase state file naming
- **Key risk:** Pre-trend contamination between reform and non-reform states — materialized

## Execution
- **What worked:** Azure QWI queries, treatment timing construction from IJ/legislative sources, fixest DDD estimation
- **What didn't:** Pre-period placebo test failed (p=0.008), meaning the DDD captures differential pre-trends, not causal effects. Placebo industries showed similar magnitudes to licensed industries.
- **Key insight from reviewers:** ULR addresses interstate mobility for *already-licensed* workers, not initial licensure barriers that most constrain Hispanic workers. This mobility-vs-entry mismatch is the fundamental reason the policy doesn't close the gap.
- **Review feedback adopted:** Reframed from "null" to "no evidence of positive effects" with CIs; strengthened mobility-vs-entry discussion; added conclusion about targeting initial licensure barriers
