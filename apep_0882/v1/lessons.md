## Discovery
- **Idea selected:** idea_0289 — Resource busts and mortality using CDC county data. Chose for first-order welfare question (deaths), massive microdata panel, and clean geological identification.
- **Data source:** CDC NCHS Drug Poisoning by County (data.cdc.gov pbkm-d27e) + Census CBP for shale classification + FRED oil prices
- **Key risk:** CDC data uses categorical bins (2-unit ranges) rather than continuous rates — introduces measurement error

## Execution
- **What worked:** Census CBP API for pre-boom oil/gas employment was clean and well-documented. County × year panel construction was straightforward. The triple-diff specification revealed meaningful heterogeneity that the average null hid.
- **What didn't:** BLS QCEW API returns 404 for years before 2014 — had to use Census CBP instead. CDC drug poisoning data ends at 2015, limiting the bust analysis to 1 year. Wild cluster bootstrap failed with a non-numeric error in fwildclusterboot.
- **Review feedback adopted:** Added formal asymmetry test (p>0.75), expanded limitations on binned data/single bust year/establishment-based treatment, added interval regression discussion, added just transition policy framing. Reviewers wanted NVSS microdata, CS-DiD, geological treatment — deferred to future revision.
