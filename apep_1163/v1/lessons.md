## Discovery
- **Idea selected:** idea_1874 — CMS Open Payments bunching at reporting thresholds. Chosen for novel identification (moving CPI threshold), massive public dataset, and policy relevance to pharmaceutical transparency.
- **Data source:** CMS Open Payments DKAN API — functional but API limit of 500 records/page and no server-side filtering made bulk data collection slow (~30 min per year)
- **Key risk:** API pagination yields a non-random sample (~1% of each year). Acknowledged as limitation.

## Execution
- **What worked:** The bunching framework adapted well to the reporting threshold setting. The negative bunching finding (censoring blind spot) was actually more interesting than the expected positive bunching (strategic avoidance).
- **What didn't:** Initially assumed positive bunching; had to completely rewrite the paper when results showed negative bunching. The CMS API was challenging — bulk CSVs are 6GB each, the datastore query API has a 500-record limit, and there's no WHERE-clause filtering.
- **Review feedback adopted:** Expanded limitations section on sampling representativeness, clarified distinction between mechanical censoring and strategic avoidance, flagged Part D linkage as future work. Reviewers all converged on the same concern (sampling), suggesting it's the paper's main weakness.
