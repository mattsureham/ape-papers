## Discovery
- **Idea selected:** idea_1941 — France DPE rental ban bunching, inspired by apep_0492 (#1 APEP) using multi-cutoff bunching
- **Data source:** ADEME DPE open API — field names differ from documentation (`surface_habitable_immeuble` not `surface_habitable`), pagination requires following `next` URL directly (URL-encoded commas in `after` parameter)
- **Key risk:** Baseline bunching at ALL DPE label boundaries complicates attribution to the rental ban specifically

## Execution
- **What worked:** The geographic heterogeneity test (IDF vs non-IDF) is the sharpest identification — tight markets show renovation, loose markets show retreat. The "renovate or retreat" framing turns an aggregate null into a contribution.
- **What didn't:** Temporal difference-in-bunching shows no significant trend (p=0.63) with wild swings. Small-property reform test has insufficient power (~14K records). Polynomial sensitivity at 420 is wide (-0.23 to +0.54).
- **Review feedback adopted:** Acknowledged polynomial fragility explicitly, noted small-property power limitation, defended geographic difference as main test. All three reviewers independently identified the same concerns.

## Lessons for future papers
- When bunching analysis shows an aggregate null, decompose by mechanism-relevant subgroups before abandoning the threshold
- ADEME API works well but has quirky pagination — always follow the `next` URL rather than constructing `after` parameters
- Bunching at label boundaries exists at ALL thresholds in DPE data, making geographic or temporal variation more informative than level comparisons
