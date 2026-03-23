## Discovery
- **Idea selected:** idea_0652 — MSHA mine inspections and establishment-level employment dynamics. Selected from 10 random draws; stood out for its dream-data setup (all 3 datasets from one agency, freely downloadable, linked by MINE_ID/EVENT_NO).
- **Data source:** MSHA Open Government Data (Inspections.zip, Violations.zip, MinesProdQuarterly.zip) — zero API calls, just ZIP downloads
- **Key risk:** Pre-trends due to selection (mines already declining get more severe violations)

## Execution
- **What worked:** Data pipeline was extremely smooth — download, unzip, read. All three files link perfectly by EVENT_NO and MINE_ID. 4.1M panel rows constructed cleanly. Dose-response gradient is monotonic and compelling. Coal vs metal split reveals the mechanism (coal mines have much larger employment declines).
- **What didn't:** Pre-trends are significant (~2.5% per quarter before inspection), indicating selection. This limits the causal claim. However, the post-treatment acceleration is dramatic (from 2.5% to 28.5%/quarter post-inspection slope).
- **Review feedback adopted:** All three reviewers flagged pre-trends. Paper already discusses this honestly. V2 revision should implement matched-mine design or mine-specific trends to address this.
