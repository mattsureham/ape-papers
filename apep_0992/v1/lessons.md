## Discovery
- **Idea selected:** idea_1272 — Argentina differential export tax liberalization (DDD with within-department across-crop variation)
- **Data source:** MAGyP Estimaciones Agrícolas via CKAN API — direct URLs failed, CKAN package_show endpoint worked
- **Key risk:** Pre-trends volatility and concurrent macro shocks (devaluation, ROE elimination)

## Execution
- **What worked:** The DDD design with dept×crop + dept×year FEs cleanly isolates the differential tax effect. Raw variation is very large (corn +56%, wheat +40%), and the preferred estimate (0.356) is robust across 10 specifications.
- **What didn't:** Initial specification with crop×year FEs was collinear — treatment varies only at crop×time level, so you can't absorb crop-year shocks AND identify the treatment. Pre-trends are volatile and jointly significant, which is an honest limitation. Sunflower's null response despite the largest tax cut weakens the pooled estimate.
- **Review feedback adopted:** Added sunflower exclusion robustness check (estimate rises to 0.512), strengthened pre-trends discussion with F-test details, added fiscal constraint explanation for soybean treatment, clarified event study interpretation.
