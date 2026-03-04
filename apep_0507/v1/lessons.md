## Discovery
- **Policy chosen:** Swiss municipal mergers (Gemeindefusionen), 2000–2024 — 352 merger events dissolving 931 municipalities. Chosen for massive variation (staggered over 25 years), precise treatment dates from SMMT, and rich outcome data from swissdd referendum database.
- **Ideas rejected:** Energy law reform (only 8 cantons, clustering concerns), tax competition (well-studied by Brülhart et al.), physician restrictions (only 6 years of BFS data), financial management reform (only 4 cantons listed). Municipal mergers dominated on data quality and novelty.
- **Data source:** BFS AGVCH Mutations API for merger dates (confirmed working, CSV format, 2,525 rows), swissdd R package for municipal referendum results (1981–present). BFS PXWeb for population controls.
- **Key risk:** Endogeneity of voluntary mergers — municipalities that merge may be on different pre-existing trajectories. Mitigated by event-study pre-trends, matching, and cantonal incentive instruments.

## Review
- **Advisor verdict:** 3 of 4 PASS (6 attempts; hardest issues: vote-date vs year FE mismatch, CS-DiD SE text/table discrepancy, count harmonization)
- **Top criticism:** GPT-5.2 raised unit-of-analysis construction concern (2024 successor mapping creates artificial pre-merger bundles) — a deep identification critique
- **Surprise feedback:** Code already used eligible-voter weighting but paper text said "population-weighted" — a textual error that generated a "must-fix" from two referees
- **What changed:** Added placebo test, single-merger robustness, fixed FE to vote-date level, rewrote prose, added citations

## Summary
- **Key lesson:** The advisor review loop consumed 6 attempts mostly on text-table consistency. Setting up vote-date FE from the start and doing a systematic text-matches-code audit before first advisor submission would save 3-4 cycles.
- **Time sink:** Count discrepancies (2,156 vs 2,157) and stale text triggered multiple failures.
