## Discovery
- **Idea selected:** idea_0741 — Federal procurement SAT threshold increase ($150K→$250K). Selected after 3 parallel scouts explored US regulatory, EU/UK environment, and developing country policy. Won on massive potential sample, confirmed API access, and genuine economic puzzle.
- **Data source:** USAspending.gov FPDS-NG — API has severe pagination limits (10K per query), sorting issues, and intermittent 500 errors. Bulk download endpoint works but takes 30+ minutes per request. The individual award detail endpoint (`/api/v2/awards/{id}/`) is the most reliable path for enriching search results with FPDS competition fields.
- **Key risk:** API data quality and coverage proved to be the main challenge, not identification.

## Execution
- **What worked:** Two-stage fetch strategy (search for IDs, then detail enrichment) delivered complete competition data for ~12K contracts. The null finding is honest and interpretable — framing as "inframarginal" regulation gives the paper a clear hook.
- **What didn't:** First fetch attempt returned data sorted by award amount descending, putting all contracts in the above-control band. USAspending `spending_by_award` endpoint returns `{}` for most FPDS-specific fields — need the individual award detail endpoint for NAICS, competition status, offers. Bulk download API is unpredictable (30+ min queue, intermittent 403s).
- **Review feedback adopted:** Added sample size limitation discussion, noted missing speed/cost outcomes as future work. Gemini caught a table inconsistency (pre-treatment means) — fixed.
