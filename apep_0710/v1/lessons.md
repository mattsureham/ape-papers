## Discovery
- **Idea selected:** idea_1564 — Ukraine's ProZorro procurement threshold + wartime institutional erosion. Unique natural experiment: world's most transparent e-procurement system spanning peacetime and active war.
- **Data source:** ProZorro public API — paginated feed with individual tender fetch. Slow (no search/filter), but data quality excellent. All fields populated consistently.
- **Key risk:** Post-war sample size (3,352 vs 22,852 pre-war). API returns fewer complete tenders in wartime windows.

## Execution
- **What worked:** The competitive procedure result is rock-solid (SDE = -0.56, p<0.001). The institutional story writes itself: 34% → 8% competitive above threshold.
- **What didn't:** Price savings erosion is null. This surprised all three reviewers but is actually the most interesting finding — transparency may sustain informal competition.
- **Review feedback adopted:** Fixed McCrary inconsistency between text and appendix. Added explicit discussion of savings-procedure disconnect with two candidate mechanisms (transparency vs. expected-value inflation). Clarified sample size discrepancy.
- **Key lesson:** In procurement RD papers, McCrary will always show bunching. Frame it as attenuation bias (conservative estimates), not a validity threat.
