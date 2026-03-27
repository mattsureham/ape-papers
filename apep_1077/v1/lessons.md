## Discovery
- **Idea selected:** idea_1666 — child labor law rollbacks, decisive null on a major lever
- **Data source:** Census QWI via Azure — no API issues, fast pull (~1 min for 547K rows)
- **Key risk:** Short post-treatment window (2022-2024 rollbacks, data through 2025Q1)

## Execution
- **What worked:** DDD design (state x industry x age) absorbs most confounds cleanly. RI p-value of 0.93 is the strongest evidence — permutation distribution centers squarely on the observed coefficient.
- **What didn't:** fwildclusterboot R package unavailable for this R version — substituted randomization inference (actually a better test for this design).
- **Review feedback adopted:** Strengthened mechanism discussion (legal vs economic non-bindingness), added Limitations section (QWI age-bin, aggregation caveats), expanded policy implications and external validity. All three reviewers validated the core finding.
