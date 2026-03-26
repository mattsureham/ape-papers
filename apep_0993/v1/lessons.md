## Discovery
- **Idea selected:** idea_1197 — South Korea's 52-hour workweek reform with staggered firm-size thresholds
- **Data source:** ILO ILOSTAT SDMX API — industry-level hours by ISIC4 section. ILO rplumber API was dead; had to discover the sdmx.ilo.org endpoint and figure out exact dimension counts.
- **Key risk:** Industry-level analysis limits power (21 clusters) and cannot directly identify the firm-size mechanism

## Execution
- **What worked:** Clean pre-trends, stable LOO, the continuous overtime-gap specification (p=0.09) is the most convincing result. The "compliance cascade" framing gives the paper a memorable name even though the mechanism is exploratory.
- **What didn't:** Original RDD design was infeasible — KLIPS, SBA, and KOSIS data aren't accessible via API. Pivoting to industry-level DiD sacrificed the manifest's core identification advantage. RI p-value of 0.137 means the binary result isn't definitive.
- **Review feedback adopted:** Softened cascade language to "exploratory hypothesis," emphasized continuous spec as preferred, expanded COVID confounding discussion, added three limitations (ecological fallacy, few clusters, endogenous treatment). Reviewers unanimously wanted firm-level data — legitimate but infeasible for V1.
