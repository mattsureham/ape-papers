## Discovery
- **Idea selected:** idea_0858 — Nursing home workforce exodus demographic anatomy. Chose for QWI data availability (on Azure), first-order stakes, and novel demographic decomposition angle.
- **Data source:** QWI via Azure Blob Storage — fast and reliable. 4M sex-by-age rows, 3M race rows.
- **Key risk:** Pre-trends in the DDD event study. Mandate states had widening 623/624 gap before mandates hit.

## Execution
- **What worked:** The triple-diff design with NAICS 624 cleanly identifies the sector-wide effect (-17.6%). QWI demographic breakdowns are powerful. The "null on mandates, huge on sector" framing is strong.
- **What didn't:** The original "mandate sieve" narrative was wrong. Data showed uniform effects across demographics and mandates explaining at most a small share. Had to pivot framing entirely.
- **Review feedback adopted:** (1) Toned down causal claims per all three reviewers, (2) Added magnitude interpretation in headcount/percentages per Mistral/GPT-OSS, (3) Strengthened comparison sector justification, (4) Acknowledged underpowered demographic heterogeneity test, (5) Added Rambachan-Roth mention for pre-trend sensitivity.
- **Key lesson:** Let the data speak. The paper is stronger as "blaming the mandate is wrong" than as "mandates caused the exodus." Tournament values honest nulls that settle something important.
