## Discovery
- **Idea selected:** idea_2062 — Multi-threshold hospital bed bunching atlas (originally picked idea_2324 on wine ABV, but TTB COLA data lacked ABV in public exports)
- **Data source:** CMS HCRIS Form 2552-10, 14 annual ZIP files from downloads.cms.gov — reliable, large, freely accessible
- **Key risk:** Overlap with two existing single-threshold APEP papers (apep_1150 at 25 beds, apep_1148 at 50 beds). Differentiated by unified framework + heaping decomposition.

## Execution
- **What worked:** The data pipeline was clean — downloading HCRIS ZIPs and extracting bed count rows via grep took minutes. The CAH bunching is visually stunning (9,841 at 25 vs 1 at 26 for CAH hospitals). The heaping decomposition was the key insight — it showed that 50-bed and 100-bed "bunching" is mostly cognitive heaping.
- **What didn't:** First idea attempt (wine ABV bunching) failed because the TTB COLA Public Registry doesn't include ABV in bulk exports. The labeled ABV is only available through a commercial COLA Cloud license. Lost ~25 minutes on data exploration before pivoting.
- **Review feedback adopted:** Clarified that bed counts are licensed beds (capacity decisions). Added welfare back-of-envelope calculation. Acknowledged DSH upward-notch direction. Reframed polynomial sensitivity around excess mass stability.
