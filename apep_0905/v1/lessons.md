## Discovery
- **Idea selected:** idea_1852 — Argentina aviation deregulation, chosen for sharp institutional lever (single decree), massive daily microdata (567K obs), and transportable mechanism
- **Data source:** ANAC datos.yvera.gob.ar — downloaded cleanly (253 MB), no API issues. Airport reference file was 404 but unnecessary since main data has province/city columns
- **Key risk:** Pre-trends between monopoly and competed routes given the 20x difference in traffic levels

## Execution
- **What worked:** The "competition illusion" framing emerged naturally from the data. The continuous HHI specification powerfully captures the dose-response relationship between pre-decree concentration and post-decree outcomes. The entry/exit analysis (67 new entries, 35 exits from monopoly routes) tells a compelling mechanism story.
- **What didn't:** The binary monopoly vs competed treatment is underpowered — the groups are too heterogeneous for a clean comparison. Route-specific linear trends absorb ~60% of the continuous estimate, revealing that differential secular trends (thin routes stagnating, thick routes growing) were confounded with the treatment effect.
- **Review feedback adopted:** (1) Added route-specific linear trend robustness (coefficient attenuates to -0.74 but stays significant), (2) reported joint F-test for pre-trends (p=0.054), (3) deepened mechanism analysis with airline-level exit data, (4) reconciled binary vs continuous results explicitly, (5) clarified log(1+x) transformation for zeros.
