## Discovery
- **Idea selected:** idea_0239 — Deutschlandticket labor market effects; chose for sharp institutional lever (uniform EUR 49 replacing heterogeneous pricing), large effective N (38 NUTS2 regions), and policy relevance across the EU
- **Data source:** Eurostat (lfst_r_lfu3rt, lfst_r_lfe2emprt) — annual frequency, not quarterly as initially assumed. Worked smoothly via `eurostat` R package.
- **Key risk:** Data granularity insufficient to detect small effects at commuting-zone scale

## Execution
- **What worked:** Clean treatment-intensity construction from Verkehrsverbund prices; the `eurostat` R package made data fetching trivial; the null result with power calculation is an honest contribution
- **What didn't:** Pre-trend joint F-test rejects, partly due to COVID-era differential shocks and long-run East-West convergence. This limits causal interpretation. Should have checked pre-trends before committing to this identification strategy.
- **Review feedback adopted:** Added joint F-test reporting, MDE/power discussion, tempered causal language throughout, acknowledged pre-trend concerns explicitly in results section
- **Lesson for future:** Always run the joint pre-trend test BEFORE writing the paper. If it fails, consider region-specific trends or shorter pre-periods. Also: verify data frequency before designing the analysis — "quarterly" in the research plan turned out to be annual.
