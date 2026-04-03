## Discovery
- **Idea selected:** idea_2140 — Inspector-leniency IV for Ofsted, "tournament gold" per lessons
- **Data source:** Ofsted MI (GOV.UK), HM Land Registry PPD — both free, reliable
- **Key risk:** Inspector identity linkage — turned out to be infeasible (scraping blocked)

## Execution
- **What worked:** Pivot from IV to event study DiD was quick and productive. The deprivation heterogeneity emerged as a genuine finding — stronger than the pooled result. Ofsted MI + Land Registry linkage via postcode district worked smoothly. 10.2M transactions × 9,780 schools gave ample power.
- **What didn't:** Inspector scraping (reports.ofsted.gov.uk blocked all 30 requests). Original IV design would have been much stronger. Postcode district is coarse (median 4.2 schools). RI p-value of 0.126 for pooled effect means the aggregate result is fragile.
- **Review feedback adopted:** Softened causal language, added explicit design limitation paragraph, cited Bokhove et al. for inspector variation. Both reviewers noted departure from original IV — honest about it.
