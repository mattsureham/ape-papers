## Discovery
- **Idea selected:** idea_0941 — Municipal corporate tax competition and public goods provision in Swiss municipalities. Selected for massive N (2,137 municipalities), clean within-unit variation, and first-order policy relevance (OECD Pillar Two).
- **Data source:** Canton Zurich opendata.swiss (Steuerfuss, Jahresrechnungen), BFS PXWeb API (STATENT, population). No API keys needed. CSV parsing required careful handling of comma-in-field issues.
- **Key risk:** Short panel overlap (6 years) between Steuerfuss (2012+) and Jahresrechnungen (up to 2017).

## Execution
- **What worked:** The Steuerfuss panel has genuinely rich variation — 57% of municipality-years see changes, with both cuts and increases common. The null result is well-powered (MDEs rule out >7% effects).
- **What didn't:** The Jahresrechnungen CSV had comma-in-field problems that silently dropped 140K rows. Also discovered corporate and natural-person rates are correlated at 0.995, limiting the placebo test.
- **Review feedback adopted:** Added lagged specification (found significant delayed revenue effect β=-14.94, p=0.02), anticipation test with leads, expanded MDE interpretation with concrete welfare benchmarks, strengthened limitations section acknowledging lockstep confound and fiscal equalization.
