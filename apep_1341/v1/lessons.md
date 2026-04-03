## Discovery
- **Idea selected:** idea_2304 — RCRA hazardous waste generator thresholds, bunching at 1,000 kg/month
- **Pivots:** First tried Swiss HAT (idea_1304, failed: BFS data too recent), then Denmark property tax (idea_1889, 62% overlap with apep_1220)
- **Data source:** EPA Envirofacts API for biennial report waste quantities; ECHO bulk download for facility universe
- **Key risk:** EPA API extremely slow, partial national coverage only (15 states)

## Execution
- **What worked:** The "characterization margin" concept resonated with all 3 reviewers as a genuine contribution. The paper's honest treatment of a near-null result was viewed as intellectually honest.
- **What didn't:** EPA Envirofacts API pagination yielded only 7K handlers vs 130K+ in the manifest. Annual-to-monthly conversion adds measurement noise. Placebos at round numbers undermine causal claim.
- **Review feedback adopted:** Acknowledged power limitations, measurement attenuation, and placebo complications more prominently in the text.
- **Key insight for future:** For bunching papers, need the FULL administrative universe. Partial API downloads destroy power. Future work should try direct bulk downloads from RCRAInfo or EPA data.gov rather than the Envirofacts REST API.
