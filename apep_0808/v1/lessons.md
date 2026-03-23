## Discovery
- **Idea selected:** idea_0845 — IRS mass revocation is the largest organizational death event in US history, with perfect administrative data
- **Data source:** IRS Auto-Revocation List (45MB zip, pipe-delimited) + Exempt Organizations BMF (4 CSVs from irs.gov/pub/irs-soi/). Both download reliably and parse cleanly with data.table.
- **Key risk:** Cross-sectional identification is inherently weaker than DiD/RDD. Subsection type proxies for many unobservables.
- **Pivot:** Initially claimed idea_0013 (India RTE Act) but DISE/UDISE+ data is not accessible via any API. SHRUG Census VD only has 2011 cross-section. Pivoted to idea_0845 within 10 minutes.

## Execution
- **What worked:** IRS data is spectacularly accessible and rich. 1.2M revocation records + 1.9M BMF records download in minutes. The EIN matching is straightforward. The temporal placebo (2010 surprise vs post-2010 waves) provides a genuine mechanism test.
- **What didn't:** Organizational age analysis failed because BMF RULING field is only available for currently registered orgs (reinstated), not for the full revoked sample. Asset validation via BMF ASSET_AMT is weak because most small orgs file 990-N (no financials reported).
- **Surprise finding:** The asset premium exists ONLY in the 2010 surprise wave (DiD interaction = 3.1pp, t=8.7). In post-2010 waves the premium is <1pp and insignificant. This strongly supports information asymmetry over fixed-cost stories.
- **Review feedback adopted:** Added formal DiD interaction test (Asset × Surprise), strengthened c(3) vs c(4) comparison, fixed dating inconsistency (2010 effective vs 2011 posted), added measurement limitations paragraph.
