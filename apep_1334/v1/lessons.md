## Discovery
- **Idea selected:** idea_2123 — examiner leniency IV for patent market outcomes. Novel angle: every prior paper uses this instrument for innovation; none for the market itself.
- **Data source:** Google BigQuery (PatEx + Assignment tables) — the join was non-trivial (3 tables via rf_id) and the server-side SQL approach was essential for performance.
- **Key risk:** Exclusion restriction — lenient examiners might affect claim breadth, not just binary grant. Mitigated by citing Feng & Jaravel (2020) and near-identity of OLS-IV.

## Execution
- **What worked:** BigQuery server-side joins saved 15+ minutes vs. client-side processing. The massive sample (4.4M) gave extraordinary statistical power (F = 14,949).
- **What didn't:** scl-librechat BigQuery project lost permissions; had to switch to gen-lang-client-0330172635. Initial smoke test suggested small-entity reversal that didn't survive the full specification.
- **Review feedback adopted:** Added assignment timing caveat (pre- vs post-disposal asymmetry), explained smoke-test discrepancy for small entities, nuanced NPE implications to acknowledge we can't distinguish productive transfers from rent extraction.
