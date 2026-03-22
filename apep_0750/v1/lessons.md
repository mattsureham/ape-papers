## Discovery
- **Idea selected:** idea_0909 — EU Preventive Restructuring Directive, first causal evaluation of the largest coordinated insolvency reform in history
- **Original idea (idea_0918):** Pivoted from EU AI Act patent study after BigQuery API was inaccessible
- **Data source:** Eurostat sts_rb_q (quarterly bankruptcy index) — fetched seamlessly via `eurostat` R package, no API key needed
- **Key risk:** COVID-era bankruptcy moratoria creating confounding variation

## Execution
- **What worked:** Eurostat data quality was excellent (26 countries, 44 quarters, clean panel). The staggered transposition created 11 distinct treatment cohorts. CS-DiD ran without major issues after handling missing values.
- **What didn't:** BigQuery access was completely broken (API not enabled on the GCP project). G-N services sector was missing from the Eurostat data. The `fwildclusterboot` R package wasn't available for this R version.
- **Key finding:** Precisely estimated null (ATT = 0.10, SE = 0.25). Sign-unstable across functional forms (positive in logs, negative in Poisson/levels) — hallmark of a true zero.
- **Review feedback adopted:** Softened reclassification language (all 3 reviewers flagged this as speculative). Added treatment intensity heterogeneity split. Fixed summary stats mismatch between Table 1 and text.
