## Discovery
- **Idea selected:** idea_0881 — GDPR enforcement as a shock to US labor markets via Brussels Effect. Novel angle (zero existing APEP papers on GDPR/data privacy).
- **Data source:** QWI from Azure (350K rows) + Census Foreign Trade API for EU trade exposure. Azure data access was seamless; Census `statenaics` endpoint returned HTTP 204 (known issue), but `statehs` worked with different parameters.
- **Key risk:** State-level merchandise exports poorly proxy digital data regulation exposure. Both reviewers flagged this.

## Execution
- **What worked:** Triple-diff with 150K observations, 50 states, 4 industries cleanly identified the geographic gradient (or lack thereof). QWI-Azure pipeline is reliable. The null DDD was genuinely informative — rules out large geographic gradients.
- **What didn't:** The DD event study revealed pre-existing trend in Information vs. control sectors, weakening causal attribution of the 7.7% national decline to GDPR specifically. The merchandise-export proxy for digital regulation exposure was too coarse — future GDPR papers should use BEA digital services trade data or firm-level EU revenue exposure.
- **Review feedback adopted:** Added explicit power/MDE discussion, acknowledged proxy limitation in Discussion, softened DD causal language to note pre-trend, noted DD event study timing pattern.
