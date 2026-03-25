## Discovery
- **Idea selected:** idea_1881 — Depression-era bank failures and individual economic scarring using MLP linked panel
- **Data source:** IPUMS MLP 1920-1930-1940 three-decade panel (Azure), 1940 full-count census for wage income
- **Key risk:** County-level bank failure data unavailable; fell back to reduced-form interaction design

## Execution
- **What worked:** Azure DuckDB queries for 8.45M-row panel were efficient; within-individual long-difference design is clean and transparent; wage analysis from 1940 census join confirmed the null
- **What didn't:** Memory constraints (16GB) required careful script design; couldn't implement the promised IV strategy without county-level bank suspension data from ICPSR
- **Review feedback adopted:** Added 1940 INCWAGE cross-sectional analysis (all 3 reviewers requested); softened causal language from "credit destruction" to "exposure to fragile banking regime"; expanded limitations section to address identification, linking bias, and outcome measurement concerns
