## Discovery
- **Idea selected:** idea_0943 — Switzerland's 2020 GEA pay audit mandate at 100 employees. Bunching papers score highest in tournament (21.1 avg), and this was the first natural experiment of the EU Pay Transparency Directive.
- **Data source:** BFS PXWeb API (STATENT + LSE) — API required browser-like headers and explicit value queries. JSON-stat2 parser had dimension-ordering bug that scrambled all data initially.
- **Key risk:** Original bunching design was infeasible because BFS only publishes coarse size bins (50-249 as one class). Pivoted to continuous DiD using industry-level gender gap intensity.

## Execution
- **What worked:** The pivot to continuous DiD was clean — 76 industries × 26 cantons × 13 years gives a large panel with 9 pre-periods and 4 post-periods. The event study shows remarkably flat pre-trends for female share.
- **What didn't:** Statistical power is limited with 76 industry clusters. The MDE is ~5.5 pp, larger than effects found in comparable studies (Denmark 2 pp, UK 1-3 pp). The paper cannot distinguish modest positive effects from zero.
- **Review feedback adopted:** Tempered all null-result claims to acknowledge wide CIs. Removed claims about "no growth distortions" without firm-level data. Added MDE discussion. Reframed as "lower bound" evidence rather than definitive null.
