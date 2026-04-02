## Discovery
- **Idea selected:** idea_0742 — EPA enforcement shift-share. Memorable object ("marginal product of a federal inspector"), timely with EPA restructuring.
- **Data source:** EPA AQS (ambient air quality), ICIS (inspection counts), EPA budget documents (OECA staffing). Pivoted from TRI (too large for API) to AQS (pre-built annual downloads, 4MB/year).
- **Key risk:** Pre-trends. Regional enforcement share might correlate with other regional trends (industrial composition, wildfire exposure, economic growth).

## Execution
- **What worked:** AQS data was fast and clean. Shift-share design yielded a significant, economically meaningful coefficient (β=0.687, p<0.001). LOO was very stable (range 0.506-0.752).
- **What didn't:** Pre-trends fail the joint F-test decisively. The 2010 and 2013 event study coefficients are large and significant. This prevents a strict causal claim.
- **Review feedback adopted:** Added state-specific linear trends (β attenuated only to 0.647 from 0.687). Added region-clustered SEs (SE=0.131 vs 0.178). Strengthened limitations discussion on facility-level data gap, PM2.5 noise, and few-cluster inference. Reviewers wanted facility-level TRI data — infeasible for V1 due to API pagination limits (3.2M records/year), but should be done in V2 via bulk file downloads.
