## Discovery
- **Idea selected:** idea_0388 — IPEDS higher education funding with Bartik IV
- **Data source:** NCES IPEDS bulk download (CSV) — Azure DuckDB connection failed, had to download 181 files directly from NCES website
- **Key risk:** Bartik IV too weak (F-stat = 0.3), pivoted to continuous treatment DiD

## Execution
- **What worked:** IPEDS data is massive, clean, and well-structured. Panel of 702 institutions across 51 states is robust. The tuition null is the cleanest and most interesting finding — states that cut more did NOT raise tuition more, which contradicts the standard narrative.
- **What didn't:** Bartik IV failed completely because with institution + year FE, the national shock is absorbed. Should have anticipated this — Bartik needs state-specific shocks, not national ones. Pell share result is confounded by demand-side recession effects — all three reviewers flagged this correctly.
- **Review feedback adopted:** Moderated all causal language to "documents patterns" rather than "identifies causal effects." Added explicit discussion of demand-side confounding. Acknowledged pre-trend limitations. Reframed contribution around tuition stickiness (supply-determined, more credible) rather than composition displacement (demand-confounded).
