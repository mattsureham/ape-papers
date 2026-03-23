## Discovery
- **Idea selected:** idea_1047 — India internet shutdowns + nightlights. Vivid question, large sample, exam-shutdown exogenous subsample.
- **Data source:** Koning (2023) GADM-matched shutdown dataset (GitHub) + NASA VIIRS VNP46A4 via earthaccess
- **Key risk:** Annual nightlights too coarse to detect short shutdowns

## Execution
- **What worked:** Data pipeline eventually succeeded — earthaccess handles NASA auth cleanly. Shutdown data from GitHub was excellent (1,978 events, geocoded, with trigger types). The dose-response analysis provides the most compelling evidence.
- **What didn't:** Multiple nightlights access methods failed (GEE no auth, LAADS API changed, EOG requires login, blackmarbler GDAL no HDF5 support). HDF5 internal structure was VNP_Grid_DNB_2d not VNP_Grid_DNB (V2 vs V1). Annual data mechanically can't detect 1-2 day shutdowns — the exam-shutdown identification strategy, while theoretically clean, fails at annual frequency.
- **Review feedback adopted:** Added explicit measurement limitation section acknowledging annual data constraint. Reviewers correctly identified that the exam subsample is underpowered at annual frequency. Neighbor-district placebo and mechanism tests (mobile-only vs full, digital penetration interaction) are natural V2 extensions.

## Key Takeaway
The fundamental lesson: **match your outcome frequency to your treatment duration.** Annual nightlights can't detect daily shutdowns any more than a thermometer measuring monthly averages can detect a one-day fever. The dose-response (1-3 days → 50+ days) is the right way to frame this — it shows the measurement threshold, not the absence of an effect. A V2 with monthly VIIRS data would transform this paper.
