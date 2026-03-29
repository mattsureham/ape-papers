## Discovery
- **Idea selected:** idea_2114 — Payday crime cycle in Buenos Aires using ANSES DNI-digit payment calendar
- **Data source:** Buenos Aires City Open Data crime CSVs (2019-2023) — fetched cleanly, 644K records across 5 years
- **Key risk:** City-level aggregation of staggered payments leaves limited identifying variation

## Execution
- **What worked:** The payment calendar construction was clean; permutation test was the strongest analytical contribution; the null is credible and well-powered
- **What didn't:** The city-level design masks spatial heterogeneity; a commune-day panel with local beneficiary weights would be much stronger but requires EPH processing
- **Review feedback adopted:** Switched to month-clustered SEs (addressed serial correlation); moderated strongest claims about "filling the gap"; added explicit limitation paragraph about aggregation; acknowledged that city-level treatment is mechanically tied to calendar structure
- **Key insight:** When treatment varies smoothly within a deterministic calendar (10 groups paid sequentially), permutation inference is essential — standard SEs can produce spurious significance that permutation destroys (p=1.0)
