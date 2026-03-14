## Discovery
- **Idea selected:** idea_0895 — UK MUP and alcohol-specific mortality, staggered Scotland/Wales adoption
- **Data source:** OHID Fingertips API (England), NRS published tables (Scotland), ONS (Wales)
- **Key risk:** Only 2 treated units at country level limits statistical power

## Execution
- **What worked:** Fingertips API indicator 91380 worked reliably for England regional+national data. Published NRS/ONS national totals provided consistent Scotland/Wales series. The regional panel (11 units) gave enough power for cluster-robust inference.
- **What didn't:** fingertipsR and nomisr packages unavailable for R 4.3.2. NRS website restructured, breaking automated Excel downloads. Could not get council-level Scottish or Welsh LA-level data programmatically. statistics.gov.scot was unresponsive.
- **Data limitations:** Council/LA-level data for Scotland (32 councils) and Wales (22 LAs) would have made a much stronger paper with 54 treated units. The national-level design with only 2-3 treated countries limits causal inference credibility despite passing pre-trend tests.
- **Review feedback adopted:** (1) Reframed Scotland-only as primary estimate per both reviewers, (2) Added CI for deaths averted, (3) Better explained pre-trend 2014-15 spike as temporary NRS-documented increase unrelated to MUP, (4) Downplayed synthetic control as uninformative due to poor pre-fit (RMSPE=6.7), not competing evidence, (5) Added K70 composition note to strengthen mechanism link

## Key Takeaways
- UK public health data ecosystem is fragmented: England (Fingertips), Scotland (NRS/PHS), Wales (StatsWales/ONS) each have different systems and APIs
- For future UK papers: invest in manual downloads from NRS and ONS rather than relying on automated API access
- Country-level natural experiments with only 2-3 treated units need SCM or permutation inference, not standard DiD
