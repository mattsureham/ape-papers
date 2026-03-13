## Discovery
- **Idea selected:** idea_0565 — UK Police Austerity and Criminal Justice Quality (charge rates)
- **Data source:** Home Office open data (police workforce ODS, crime outcomes ODS/XLSX) — URLs required WebFetch to find current versions; historical outcomes used text labels requiring mapping to numeric codes
- **Key risk:** Original IV strategy (council tax precept share) was infeasible — precept data only available in PDF Police Grant Reports, not machine-readable. Pivoted to TWFE.

## Execution
- **What worked:** TWFE with force + year FE produced strong, robust results (β=12.9, p<0.001). Offense-type heterogeneity clearly supports investigative capacity mechanism. Pre-trend test clean for 2008-2009.
- **What didn't:** IV-DiD was the manifest's core identification, but precept data wasn't available as open data. TWFE is a valid fallback but reviewers correctly noted it weakens causal claims. The 2014 outcomes framework break forced restricting main analysis to 2014-2021, losing the austerity implementation period.
- **Review feedback adopted:** Tempered causal language throughout, acknowledged IV infeasibility explicitly, fixed pre-trend discussion to note 2010-2013 overlaps with treatment rollout, expanded limitations section.
- **Key lesson:** When proposing IV strategies in idea manifests, verify that instrument data is actually available in machine-readable form before claiming the idea. For UK police data, Home Office open data tables are comprehensive for workforce and outcomes but funding breakdowns by source (grants vs precepts) require PDF scraping.
