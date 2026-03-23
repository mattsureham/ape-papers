## Discovery
- **Idea selected:** idea_0566 — OSHA Heat NEP (2022). Chosen for clean institutional design (NAICS targeting, precise date, geographic heat variation), massive ITA data, and policy relevance to pending heat standard.
- **Data source:** OSHA ITA (Form 300A) — bulk ZIP downloads from OSHA website. URL naming inconsistent across years; required web-scraping to find correct paths. All 8 years (2016-2023) available.
- **Key risk:** Pre-trends from secular convergence in industry injury rates; COVID disruption in 2020-2021.

## Execution
- **What worked:** Triple-DiD exploiting industry × geography × time variation. The geographic null was the cleanest finding — precisely estimated zero where the NEP should bind most. The state-plan placebo and restricted-window robustness strongly confirmed the null.
- **What didn't:** Simple DiD looked significant but was confounded by pre-trends. The event study clearly showed convergence starting years before the NEP. Also, static state-level heat normals are a weaker proxy than county-level time-varying heat-index days — reviewers correctly flagged this.
- **Review feedback adopted:** Elevated illness rate to primary narrative alongside TRC; added measurement limitation discussion (static heat, annual aggregation); nuanced state-plan placebo (some state plans adopted NEP or had stricter standards).
- **Lesson for future:** When evaluating a policy triggered by contemporaneous environmental conditions (weather, pollution), the "dose" measure must match the policy's operational trigger. 30-year climate normals are pre-determined and exogenous but may poorly capture the actual enforcement intensity in any given year.
