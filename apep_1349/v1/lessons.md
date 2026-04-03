## Discovery
- **Idea selected:** idea_2360 — Dutch BPM multi-cutoff bunching. First choice (idea_0652, MSHA mine inspections) was already published as apep_0774 (73% overlap).
- **Data source:** EEA CO2 monitoring API — reliable, no auth required. Querying individual CO2 value counts was slow (~1500 queries per country-year) but worked.
- **Key risk:** The idea manifest assumed notches but the BPM is actually kinks (continuous tax). This changed the entire theoretical prediction.

## Execution
- **What worked:** The kink vs notch distinction turned a potential "failed bunching paper" into a clean null with mechanism — rational non-response when engineering costs exceed tax savings. Germany placebo and PHEV decomposition were strong diagnostics.
- **What didn't:** Polynomial bunching estimation was completely unstable on lumpy vehicle CO2 data. Car models cluster at specific CO2 values (87, 92, 102-103 g/km), breaking the smoothness assumption. Future bunching papers on vehicle data should use model-level variation rather than aggregate density.
- **Review feedback adopted:** (1) McCrary is wrong for kinks — added framing that polynomial is primary, McCrary supplements. (2) Added power/MDE calculation. (3) Added engineering cost calibration from Reynaert (2021). (4) Softened claims throughout. (5) Clarified that bunching identifies manufacturer manipulation specifically, not consumer sorting.
