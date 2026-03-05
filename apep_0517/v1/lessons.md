## Discovery
- **Policy chosen:** UK police austerity cuts (2010-2019) — Enormous cross-force variation (Cleveland -31% vs Surrey -0.4%) creates natural experiment at PFA boundaries
- **Ideas rejected:** Cumulative Impact Zones (endogenous boundary drawing, decentralized GIS data), Ofsted RDD (ordinal running variable), Rainfall-crime (monthly crime data kills high-frequency design)
- **Data source:** Police API bulk download (LSOA-level crime, Dec 2010+), ONS PFA boundaries, Home Office workforce stats — all confirmed working, fully open
- **Key risk:** PFA boundaries may coincide with other geographic discontinuities (rivers, urban edges). Mitigated by segment-level heterogeneity analysis and pre-period balance tests.

## Review
- **Advisor verdict:** 3 of 4 PASS (Grok, Gemini, Codex PASS; GPT FAIL on centroid precision)
- **Top criticism:** LSOA centroids derived from crime reports creates potential running variable endogeneity (GPT). Response: centroids accurate to <50m, well below 2km bandwidth
- **Surprise feedback:** GPT pushed for "border DiD" specification as stronger design than year-by-year event study
- **What changed:** Fixed donut RDD interpretation, added recording practices limitation, corrected abstract percentage (20%→18%), clarified data sampling, added polynomial order specification

## Summary
- **Core insight:** BDD at administrative borders can be confounded by geographic sorting — event study diagnostics essential
- **Methodological lesson:** MSE-optimal bandwidth with mass points produces unrealistically narrow windows — fixed bandwidth following Keele & Titiunik (2015) needed
- **Advisor review iterations:** 9 rounds — GPT and Gemini extremely nitpicky about internal consistency across tables/text
