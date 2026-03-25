## Discovery
- **Idea selected:** idea_1786 — Oklahoma injection well volume caps, chosen for novel labor market angle on seismicity regulation
- **Data source:** BLS QCEW via per-county API — API format required 5-digit FIPS, not state-level; 2012-2013 unavailable
- **Key risk:** Oil price crash coinciding with regulation; addressed via time FEs, oil extraction controls, and DDD

## Execution
- **What worked:** The null finding is the contribution — contrary to Greenstone/Walker/Curtis, seismicity regulation imposed no measurable employment costs. DDD cleanly separates regulatory from oil price channels.
- **What didn't:** BLS QCEW API is slow (one call per county per quarter) and 2012-2013 data was unavailable, limiting the pre-period to 2014-2015.
- **Review feedback adopted:** All three reviewers flagged missing first-stage (OCC 1012D injection volume data) and oil price confound concerns. Added power analysis (MDE = ~5%), explicit limitations section acknowledging lack of volume-based treatment, and tempered "free lunch" claim. Added caveat about concurrent oil price collapse potentially making regulation non-binding.
