## Discovery
- **Idea selected:** idea_2151 — FCA contingent charging ban and FOS pension complaint outcomes
- **Data source:** Financial Ombudsman Service quarterly product complaints Excel files (38 quarters, 2014-2026)
- **Key risk:** Single treated product category; inference with 4 clusters

## Execution
- **What worked:** FOS data was freely downloadable and remarkably granular at the product level. Product-level DiD design exploited the product-specific nature of the regulation cleanly. The "quality dividend" framing — uphold rate increases while volume stays flat — told a compelling story.
- **What didn't:** First idea (Philippines free tuition) failed due to data access — WDI enrollment data stopped in 2017, CHED behind Cloudflare. Always check API data availability covers the treatment window before claiming an idea. Also: early FOS files (2014-2018) had different column structures and product naming conventions, requiring careful cross-format parsing.
- **Review feedback adopted:** (1) Tempered causal language — reframed from "causal" to "suggestive evidence" given single treated unit. (2) Added back-of-envelope welfare calculation (19 additional upheld cases per quarter). (3) Clarified that the clustered SE p-value of 0.006 is unreliable with 4 clusters; HC1 p<0.10 better reflects effective degrees of freedom. (4) Acknowledged alternative explanations (changed FOS adjudication standards, COVID backlogs, complaint selection).
