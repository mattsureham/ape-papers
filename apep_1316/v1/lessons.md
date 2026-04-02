## Discovery
- **Idea selected:** idea_2263 — Judge leniency IV at the BVA is an untapped setting with publicly available data and strong institutional documentation of random assignment.
- **Data source:** BVA decision text files from va.gov — public, freely downloadable, standardized format. No API key or FOIA required.
- **Key risk:** Whether parsed text files would yield clean enough VLJ identifiers and outcome classifications. Passed with 98.2% parse rate.

## Execution
- **What worked:** The judge-leniency design delivers spectacularly in this setting (F=225). BVA text files are remarkably well-structured for automated parsing. The subjectivity premium finding — that judge discretion scales with medical evidence ambiguity — emerged naturally from the heterogeneity analysis and provides a portable conceptual contribution.
- **What didn't:** The paper establishes the instrument but cannot estimate downstream outcomes without linked administrative data. All three reviewers flagged this. A V2 would need to either (a) obtain VA admin data linkage or (b) use aggregate county-level outcomes through a regional office-to-county crosswalk.
- **Review feedback adopted:** Fixed VLJ grant rate range discrepancy (text vs. table mismatch), added formal interaction test for the subjectivity premium, expanded discussion of remand placebo interpretation (two margins), added dollar magnitudes to the IQR comparison.
