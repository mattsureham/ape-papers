## Discovery
- **Idea selected:** idea_0576 — Groningen earthquake compensation zone. Sharp PC4 boundary + dense property data = strong RDD potential
- **Data source:** CBS OData (buurt-level WOZ values), KNMI earthquake catalog, PDOK buurt shapefiles
- **Data pivot:** Could not access IMG eligible postcode list (not exposed as structured data). Pivoted from spatial RDD to DiD using earthquake intensity (PGA) as treatment proxy.
- **Key risk:** Using PGA proxy rather than actual eligibility boundary introduces measurement error; WOZ assessments may lag/smooth market response

## Execution
- **What worked:** CBS OData API is excellent — reliable, well-documented, rich buurt-level data. KNMI earthquake catalog is open and complete. PDOK WFS needed pagination but worked well.
- **What didn't:** IMG postcode list not publicly available as structured data. NVM/Kadaster transaction data requires ODISSEI academic access — not available via API. 2022 CBS data had a table format issue.
- **Result:** Clean, well-powered null. Compensation does not capitalize into WOZ values. MDE = 1.82% of mean WOZ; can rule out capitalization above 15% of compensation.
- **Review feedback adopted:** Added "what this can and cannot identify" section, clarified non-transferable legal structure, reframed from "precise zero" to "bounded null," acknowledged limitations re: transaction data and exact boundary more directly.

## Key Takeaway
- Netherlands data infrastructure (CBS + PDOK + KNMI) is excellent for buurt-level policy evaluation
- For future Groningen papers: seek ODISSEI access for Kadaster transaction data to enable the sharper spatial RDD
- Null results with clear mechanism explanations are viable papers — "the missing premium" framing works
