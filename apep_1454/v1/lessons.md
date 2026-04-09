## Discovery
- **Idea selected:** idea_2427 — Denmark's 2014 Uddannelseshjælp reform (age-30 benefit cliff)
- **Data source:** Statistics Denmark Statbank API — reliable, well-documented, free
- **Key risk:** Public API only provides 5-year age bins, preventing the RDD promised in the manifest

## Execution
- **What worked:** DST API data fetch was clean; DiD design produced strong, interpretable results; the "absorption gap" narrative resonated
- **What didn't:** Pivoted from RDD to DiD due to data granularity constraints; national-level SE computation with 2 groups initially produced misleading (0.000) SEs — fixed with HC1
- **Review feedback adopted:** Fixed SE reporting (HC1 instead of cluster with 2 groups); added inference caveats section; strengthened limitations discussion about RDD→DiD pivot; added Cameron et al. (2008) reference for clustering guidance
