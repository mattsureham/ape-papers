## Discovery
- **Idea selected:** idea_1130 — Sweden's 2017 pay equity audit threshold reduction; sharp RDD design on paper, clean positioning vs. Bennedsen et al. (2022)
- **Data source:** Statistics Sweden (SCB) PxWeb API — AM0110 Wage Structure Survey + FDBR07N Enterprise Register
- **Key risk:** Firm-level microdata requires register access; public API only provides industry aggregates

## Execution
- **What worked:** Treatment intensity DiD using cross-industry variation in firm-size composition. Clean event study pre-trends, delayed buildup consistent with information channel. The "slow dividend" framing resonated with all reviewers.
- **What didn't:** Original RDD design impossible without confidential register data. SCB PxWeb API has significant quirks (auto_unbox serialization, nested JSON parsing). 19 industry clusters yields imprecise pooled estimates.
- **Review feedback adopted:** Tempered causal language throughout; explicitly acknowledged data constraints and ecological inference risks; added inference caveat about 19 clusters; reframed as suggestive evidence motivating firm-level investigation.
