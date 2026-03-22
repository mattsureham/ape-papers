## Discovery
- **Idea selected:** idea_1744 — Racial anatomy of food desert formation, chosen because apep_0753 showed SNAP retailer data is excellent but state-level analysis too coarse. This paper goes county-level with QWI race-disaggregated employment.
- **Data source:** QWI NAICS 445 from Azure (5.4M rows, fast query), SNAP retailer historical database (reused from apep_0753)
- **Key risk:** County name → FIPS matching between SNAP and QWI datasets

## Execution
- **What worked:** Azure QWI data is outstanding — 3,135 counties, race-disaggregated, 20+ years. FIPS crosswalk achieved 96.1% match. The race DDD design is very clean — county, quarter, and race FEs absorb everything, and the treated × Black interaction is sharply identified.
- **What didn't:** Could not run placebo on non-food retail because QWI query was limited to NAICS 445. Would need separate Azure query for NAICS 44-45 excluding 445.
- **Key finding:** Supermarket exit disproportionately displaces Black workers: +2.45 pp separation rate differential (p<0.001), -17.3 log points employment differential (p=0.002). Effect operates through both higher separations AND lower re-hiring. Positive Black earnings effect reflects negative compositional selection (worst-paid leave first).
- **Review feedback adopted:** [pending review completion]
