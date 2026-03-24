## Discovery
- **Idea selected:** idea_1679 — zero prior economics papers on cottage food laws despite enormous state-by-state variation; clean staggered DiD setting
- **Data source:** Census Nonemployer Statistics (NAICS 311) via API — reliable for 2012-2021; 2022 not yet released for NAICS2017 codes
- **Key risk:** state-level analysis is coarse, but the policy operates at state level

## Execution
- **What worked:** The NAICS code system changed between 2016/2017 (NAICS2012 → NAICS2017); handling this was critical for getting pre-2017 data. CS DiD produced clean pre-trends and growing effects. The "kitchen ceiling" framing gave the paper a memorable economic object.
- **What didn't:** CDC NORS data was too sparse for formal analysis (~1,900 private-home outbreaks across all states and 15 years). This left a gap in the welfare analysis. The bakery subsector (NAICS 3118) mechanism test was underpowered. BFS data isn't available by NAICS code at state level.
- **Review feedback adopted:** Added paragraph on missing food safety analysis; clarified comparison group composition; updated JEL codes. Deferred continuous permissiveness index and county-level analysis to potential V2.
