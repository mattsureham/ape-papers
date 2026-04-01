## Discovery
- **Idea selected:** idea_1917 — QWI four-way flow decomposition of paid sick leave effects
- **Data source:** Census QWI from Azure (derived/qwi/sa/n3/) — fast, reliable, 454K rows total
- **Key risk:** Whether flow-level effects would be detectable given state-level clustering with 9 treated states

## Execution
- **What worked:** The QWI churning measure (TurnOvrS) revealed a clear, significant effect (−3.7%, p<0.01) even with state-level clustering. Azure data pipeline was smooth after fixing the connection string issue (shell truncates at semicolons — must read .env directly in R).
- **What didn't:** The four-way flow decomposition — the paper's original contribution promise — yielded null results on all individual components. Had to pivot the narrative from "mandates reduce separations" to "mandates compress churning." This is arguably more interesting but requires careful explanation.
- **Review feedback adopted:** Added MDE/power discussion for null flow results, expanded TurnOvrS mechanics explanation, strengthened limitations section (quit-vs-layoff ambiguity, firm-size exemptions), added pre-trend evidence paragraph.

## Technical Notes
- Azure connection string contains semicolons; shell `source .env` truncates it. Read `.env` directly in R.
- QWI industry column in n3 files is integer (722), but in ns files it's string ("44-45"). Can't mix in one query.
- QWI file names on Azure are lowercase state abbreviations (ct.parquet, not CT.parquet).
