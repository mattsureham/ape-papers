## Discovery
- **Idea selected:** idea_0290 — fracking sex ratios, chosen for large N (1,351 counties), rich QWI microdata, clean geological instrument
- **Data source:** Census QWI API + ACS API — QWI fetch took 25min, ACS 5-year estimates only start 2009 (no pre-boom sex ratios)
- **Key risk:** ACS timing killed the sex ratio causal analysis; pivoted to QWI-only outcomes

## Execution
- **What worked:** Triple-diff design produced clean, significant results with strong placebos (healthcare null, construction null). Naming the effect "roughneck externality" gives the paper identity.
- **What didn't:** Sex ratio analysis was planned but infeasible due to ACS 5-year estimate start date. The first-stage collinearity issue with binary treatment × county FE wasted time — should always start with continuous treatment in fixest.
- **Review feedback adopted:** Added inference discussion (24 clusters borderline), expanded limitations on composition bias, added pre-trend language. Did not add event study figure (V1 format prohibits figures).
