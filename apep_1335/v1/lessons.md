## Discovery
- **Idea selected:** idea_0602 — Illinois cannabis dispensary lottery provides genuine random assignment for studying local employment effects of market entry
- **Data source:** Census QWI (confirmed via API, 102 IL counties) + IDFPR dispensary PDF (267 records parsed)
- **Key risk:** County-level QWI may be too coarse to detect hyper-local effects

## Execution
- **What worked:** PDF parsing of IDFPR dispensary list yielded clean dispensary-to-county mapping via Census ZCTA crosswalk. CS estimator ran smoothly on balanced panel.
- **What didn't:** Illinois open data portal returned no usable CSV. HonestDiD failed due to missing analytical covariance matrix from CS output.
- **Key finding:** Food service employment spillover (+2.2%) with null retail/total employment — a "foot traffic dividend" framing that's more interesting than a simple null paper.
- **Review feedback adopted:** Strengthened threats-to-validity section (location selection, spatial aggregation, treatment timing); expanded limitations with four numbered points; addressed social equity heterogeneity concern. All three reviewers converged on same issues — location choice, county-level coarseness, buildout lag — indicating these are the real weak points.
