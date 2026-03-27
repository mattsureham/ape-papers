## Discovery
- **Idea selected:** idea_1988 — Dam removals + USGS sensor data. Chosen for massive treated sample (1,341 events), gold-standard sensor outcomes, and genuine novelty (no economics paper examines physical water quality post-removal).
- **Data source:** American Rivers (Figshare) + USGS NWIS API — Figshare URL had changed since the idea was written; needed to query the Figshare API for the current download link. USGS API worked flawlessly for 16 states.
- **Key risk:** Gauge coverage was the main concern going in; got 295 treated matches (vs 1,341 removals), which is sufficient but far from the ideal 1:1 coverage.

## Execution
- **What worked:** The "slow dividend" framing emerged naturally from the event study — effects that grow over a decade are rare in policy evaluation. Sun-Abraham handled the unbalanced panel cleanly. The TWFE vs SA comparison (50-90% attenuation) is a strong methodological finding.
- **What didn't:** The `did` package (Callaway-Sant'Anna) failed on this data structure with a cryptic `1:index` error on the unbalanced panel. Switching to `fixest::sunab()` solved it immediately. Summer-only temperature analysis collapsed to 6 gauges after singleton removal — too few. Turbidity data was too sparse for the matched sample.
- **Review feedback adopted:** Added explicit pre-trend discussion with specific coefficient values, acknowledged upstream/downstream matching limitation as a lower-bound interpretation, noted TWFE caveat on dose-response table, flagged turbidity and upstream placebos as future work.
