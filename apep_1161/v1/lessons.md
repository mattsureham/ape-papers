## Discovery
- **Idea selected:** idea_1953 — ULEZ/MOT compliance upgrade. Chose for the "new measurement object" angle (257M MOT records, never used in economics) and the built-in diesel/petrol placebo.
- **Data source:** DVSA Anonymised MOT Test Results via data.dft.gov.uk — S3 URLs from manifest were stale; found working URLs on the DfT data page. 2017 used pipe delimiters; later years used commas. ZIPs used compression Python couldn't handle; system `unzip` worked.
- **Key risk:** Short pre-period for Phase 1 (only 2 years before 2019). Mitigated by later cohorts having 4-6 pre-years.

## Execution
- **What worked:** Streaming aggregation pipeline handled 257M records on 8GB RAM by processing one year at a time and deleting each ZIP/CSV immediately. The diesel/petrol split produced the cleanest result — 3:1 effect ratio is very persuasive. Naming the mechanism ("compliance upgrade") gave the paper a clear identity.
- **What didn't:** Euro 4 petrol vehicles also showed a significant decline (-0.97pp), weakening the "pure placebo" interpretation. Reviewers all flagged this. Addressed by reframing the test as a ratio (2.2:1 diesel:petrol) rather than a zero-effect test.
- **Review feedback adopted:** (1) Strengthened threats-to-validity section with four explicit sub-sections. (2) Added discussion of testing-station vs. residence measurement error. (3) Better explained the petrol positive result with two compositional mechanisms. (4) Acknowledged defect disaggregation as a limitation.
