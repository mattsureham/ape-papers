## Discovery
- **Idea selected:** idea_1031 — Japan's Furusato Nozei gift cap offers a clean natural experiment with sharp treatment and administrative microdata
- **Data source:** MIC (soumu.go.jp) Excel files — direct download, no API needed, but Japanese headers require careful parsing
- **Key risk:** Pre-trend from the gift race itself violates standard parallel trends

## Execution
- **What worked:** The MIC data is remarkably complete (1,738 municipalities × 17 years). The gift procurement cost ratio from FY2018 perfectly maps treatment intensity. Three Excel files cover the full analysis.
- **What didn't:** Extending the pre-period to satisfy the ≥5 pre-period requirement weakened the binary DiD from -0.605 to -0.373, because early years predate the gift race acceleration. The municipality-trends spec recovers the effect (-1.121) but reviewers questioned the linear assumption.
- **Review feedback adopted:** Clarified FY2019 exclusion rationale, added back-of-envelope fiscal calculation, noted 47 cluster inference adequacy, expanded institutional background and external validity discussion.
