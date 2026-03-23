## Discovery
- **Idea selected:** idea_1756 — WIC EBT mandates, vendor exits, and infant health. Chose for vivid first-order outcome (infant health), large sample (50 states × 15 years), and building on AER benchmark (Meckel 2020).
- **Data source:** County Health Rankings (state-level LBW rates). CDC natality microdata was the ideal source but proved inaccessible via API — WONDER requires interactive DUA, Socrata endpoints lack state-level breakdowns.
- **Key risk:** State-level aggregation masks heterogeneous local effects. CHR multi-year averages blur treatment timing.

## Execution
- **What worked:** Staggered DiD panel construction, Callaway-Sant'Anna estimation, comprehensive robustness battery (bootstrap, HonestDiD, placebo).
- **What didn't:** CDC data access — spent ~15 min cycling through API endpoints before pivoting to CHR. The Bartik IV (pre-EBT vendor share × adoption) was infeasible without vendor-level data.
- **Review feedback adopted:** Reframed paper as reduced-form EBT→health test (not structural vendor access test), added MDE discussion, tempered conclusions about what the state-level null can and cannot show.
- **Key lesson:** When the ideal data (microdata) isn't accessible, be upfront about what the available data (aggregates) can and cannot identify. Don't overclaim based on data you don't have.
