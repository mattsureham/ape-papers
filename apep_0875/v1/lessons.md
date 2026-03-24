## Discovery
- **Idea selected:** idea_0387 — Gainful Employment Rule and for-profit program survival using IPEDS on Azure
- **Data source:** IPEDS DuckDB (1.2 GB on Azure) — had to download locally since DuckDB can't be queried remotely via Azure blob storage. GE disclosure files (pass/fail/zone) are now 404 at all DOE URLs, forcing a coarser sector-level design
- **Key risk:** Pre-existing for-profit decline (post-2010 bubble burst) complicates causal identification

## Execution
- **What worked:** IPEDS program-level panel (181K programs) is rich and clean. The "disclosure chill" framing — asymmetry between onset and repeal — is a genuinely interesting economic object. Heterogeneity finding (low-risk CIPs decline MORE than high-risk) was surprising and strengthened the stigma interpretation
- **What didn't:** The for-profit vs. public DiD has severe pre-trend problems. All three reviewers flagged this as the #1 issue. Without GE disclosure data, the within-sector design wasn't possible. The enrollment substitution analysis was underpowered and was cut after review
- **Review feedback adopted:** Moderated all causal rhetoric to "acceleration" language; dropped enrollment substitution section; added explicit discussion of Corinthian/ITT confounders, COVID overlap with repeal window, and limitations of zero-completions as death measure; acknowledged the missed GE disclosure data opportunity
