## Discovery
- **Idea selected:** idea_0690 — Predictive scheduling laws and service-sector workforce dynamics via DDD
- **Data source:** Census QWI (LEHD) on Azure Parquet — zero API friction, data pulled in <2 minutes
- **Key risk:** Treatment dilution (city-level ordinances measured at county level)

## Execution
- **What worked:** QWI on Azure is a massive advantage — 150M+ rows ready to query. The DDD design with industry placebo produced a compelling identification story. The "predictability premium" framing gives the paper a clear puzzle.
- **What didn't:** Event study within treated counties showed messy pre-trends due to industry-specific seasonal patterns. The CS estimator on the DD sample gave opposite-sign results, which is expected (no industry control dimension) but could confuse readers.
- **Review feedback adopted:** Strengthened treatment dilution discussion with city employment shares (Seattle 40%, Chicago 70%), added Pre-Trends subsection explaining why DDD FE structure addresses parallel trends, prominently flagged hours limitation. Reviewers universally praised the placebo null (p=0.86).
- **Lesson for future papers:** When using DDD, the within-unit event study (comparing treated vs control industries within treated areas only) is NOT a valid pre-trends test — it conflates industry-specific trends with pre-treatment divergence. The proper evidence is the placebo on untreated industries.
