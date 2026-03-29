## Discovery
- **Idea selected:** idea_0828 — SFFA v. Harvard enrollment effects using IPEDS universe. Chose for first-order stakes (most consequential US higher ed policy in decades), clean continuous treatment design, and confirmed data on Azure DuckDB.
- **Data source:** IPEDS on Azure DuckDB (`raw/ipeds/ipeds.duckdb`). Enrollment (effy) through 2024, admission rates through 2023. Immediate access, no API calls needed.
- **Key risk:** Only one full post-treatment year (Fall 2024). Pre-trend instability at longer horizons.

## Execution
- **What worked:** The "admissions illusion" framing — all three reviewers validated the core insight that the Asian-White margin dominates the URM decline. Prior-ban states placebo (β = 0.013, p = 0.98) is the strongest identification card. DuckDB + Azure pipeline was instant — zero data access friction.
- **What didn't:** Event study pre-trends show instability at t-4. The 12-month enrollment stock measure dilutes freshman cohort effects by ~4x. Sample restricted to 1,835 institutions (vs 6,000+ in IPEDS) because only schools with admission rates provide the treatment intensity measure.
- **Review feedback adopted:** Added explicit event study table (all three reviewers demanded it), expanded sample construction discussion, quantified stock vs flow dilution in limitations, and acknowledged composition constraint.
