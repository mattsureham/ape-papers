## Discovery
- **Idea selected:** idea_2450 — SDWA coliform monitoring thresholds for multi-cutoff RDD
- **Data source:** EPA SDWIS via Envirofacts API — API works but has 100K row cap per query; CSV format much faster than JSON
- **Key risk:** Cross-sectional "ever violated" outcome spans 35 years, weakening contemporaneous RDD interpretation

## Execution
- **What worked:** Multi-cutoff RDD implementation clean; 9 thresholds with homogeneous +1 sample jumps; density test passes at 8 of 9 cutoffs; result robustly null across all specifications
- **What didn't:** No first-stage data (actual samples collected vs required); 3,300 threshold has AWIA 2018 confound; API row cap limits violation data completeness
- **Review feedback adopted:** Softened "monitoring mirage" claims, acknowledged first-stage limitation, reported result excluding 3,300 in main text, clarified 9-vs-33 threshold restriction rationale, improved data credibility language
