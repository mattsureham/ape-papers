## Discovery
- **Idea selected:** idea_0697 — Geneva's world-highest minimum wage (CHF 23/hr) vs. Vaud border design
- **Data source:** BFS STATENT (canton × NOGA × year panel, 2011-2023) via PXWeb API. BFS UDEMO for firm dynamics.
- **Key risk:** COVID timing overlap (Nov 2020 min wage introduction during second wave)

## Execution
- **What worked:** Triple-difference design effectively isolates minimum wage from COVID. Event study with 9 pre-treatment years confirms clean parallel trends. Swiss BFS data is high-quality census data with no sampling error.
- **What didn't:** BFS PXWeb API navigation was painful — nested paths, many 400 errors, and the STATENT tables were hard to find (had to search the German catalog). Cross-border commuter data (SEM) failed to fetch. UDEMO only has broad sector classification (secondary/tertiary), preventing a DDD on firm dynamics.
- **Review feedback adopted:** Added randomization inference (500 permutations, RI p=0.23 matching cluster-robust p=0.24). Softened precision claims about "ruling out 3% decline." Qualified UDEMO firm entry result as suggestive. Expanded COVID limitation discussion.

## Key Lessons
- For Swiss data: Always search BFS catalog in German first. English catalog has far fewer results.
- For two-canton designs: Always add randomization inference — reviewers universally flagged this.
- For COVID-era policies: Triple-diff with sector-year FE is the right approach, but late-period results (post-COVID) are the strongest evidence.
- Precisely estimated nulls with clean pre-trends are tournament-competitive when the question is first-order and the setting is novel.
