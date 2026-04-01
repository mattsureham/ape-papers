## Discovery
- **Idea selected:** idea_1780 — India's railway gauge conversion as a natural experiment to isolate the transport cost reduction channel from the market access channel
- **Data source:** SHRUG nightlights (on disk) + datameet railway stations (GitHub CC0) — stations had 50%+ missing zone data which was unexpected
- **Key risk:** Gauge conversion timing only available at zone level, not individual station/segment level

## Execution
- **What worked:** The zone-based treatment assignment produced a credible staggered DiD with 6 cohorts and 283 treated districts. The null result is economically meaningful and distinguishes friction reduction from network expansion. The placebo test and LOO analysis both behave as expected.
- **What didn't:** Pre-trends fail badly at longer horizons (5-8 years pre-treatment) in the C-S-A framework. The zone-level treatment introduces measurement error that likely attenuates toward zero — can't distinguish true null from attenuation bias without station-level conversion dates.
- **Review feedback adopted:** Added explicit attenuation bias discussion, clustering caveats (28 clusters / 6 cohorts), coefficient translation to percentage terms, disruption mechanism analysis, and sharper distinction between network efficiency and local development as the appropriate evaluation metric.

## Key Takeaway
India's gauge conversion is a fantastic natural experiment — 25,000+ km converted over 30 years — but exploiting it requires station-level conversion timing from Railway Board archives. The zone-level approximation used here is adequate for a V1 null finding but would need finer granularity for a publishable paper. A future revision should digitize segment-level conversion dates and extend outcomes to VIIRS (2012-2021).
