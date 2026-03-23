## Discovery
- **Idea selected:** idea_0617 — Test-optional admissions (COVID forced transition). Chose because IPEDS data was already on Azure (zero data risk), 1,084 treated units, and front-page policy relevance.
- **Data source:** IPEDS DuckDB on Azure (1.1GB, 23 tables) — seamless access. Column names differed from standard IPEDS docs (paulgp harmonized version), required iteration.
- **Key risk:** COVID confounds. Addressed with intensity design within treated group instead of binary treated-control comparison.

## Execution
- **What worked:** The intensity design (SAT 25th percentile as continuous treatment) produced clean pre-trends while the binary DiD had problematic pre-trend divergence. Naming the finding ("application illusion") gave the paper a memorable hook.
- **What didn't:** Binary DiD pre-trends were badly violated, killing the simplest specification. The Pell share analysis wasn't ready for inclusion (variable construction unclear).
- **Review feedback adopted:** Added explicit language that binary DiD is illustrative only; added stock-to-flow back-of-envelope calculation; expanded event study presentation with exact coefficients in main text.
- **Key insight:** The application-enrollment disconnect is the paper's real contribution. Applications surged 14% but enrollment composition barely moved — a "volume without reallocation" pattern that applies to many access policies.
