## Discovery
- **Idea selected:** idea_1692 — FTS x drug-type DDD tests information-revelation mechanism
- **Data source:** CDC VSRR API — clean fetch, 81,900 rows, no rate limiting issues
- **Key risk:** Statistical power with annual state-level data proved to be the binding constraint

## Execution
- **What worked:** The DDD design with methadone as negative control is methodologically sound. The drug-type dimension provides genuine within-state variation. CDC VSRR API was fast and reliable.
- **What didn't:** Three issues: (1) workspace collision with concurrent session required reserving apep_1074 after apep_1073 was taken; (2) CDC SODA API URL encoding needed query params instead of raw URL construction; (3) annual aggregation loses granularity but was necessary to avoid suppressed cells.
- **The result:** DDD beta = -6.22 (SE = 10.46), direction-consistent but insignificant. Methadone negative control violated expectations (+2.29, p=0.047), revealing bundled harm-reduction expansion. This is an honest null with a methodological insight.
- **Review feedback adopted:** Added power/MDE discussion, strengthened methadone bias analysis, added control group shrinkage discussion per Codex-Mini and Qwen-3.5 reviews
