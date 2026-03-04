## Discovery
- **Policy chosen:** NAAQS PM2.5 nonattainment → energy infrastructure — asymmetric cost incidence (fossil vs renewable) creates sharp RDD at regulatory threshold, genuinely novel outcome domain
- **Ideas rejected:** (1) GHGRP 25K tCO2e threshold → emissions behavior — novel angle but reporting threshold may not create real cost discontinuity; (2) CWA 316(b) cooling water → plant retirement — too narrow, data access uncertain
- **Data source:** EPA AQS (PM2.5 monitors, 1999-2023) + EPA eGRID 2022 (plant-level capacity/emissions) + Census ACS — all public, no API key required for core data
- **Key risk:** Cross-sectional energy data (eGRID snapshot) limits ability to detect dynamic effects; power concerns given only 2.9% of RDD sample in nonattainment
- **API issues:** EIA API v2 returned empty responses for generator data 2010+; pivoted to eGRID bulk download. EPA AQS PM2.5 filter required careful handling of "Pollutant Standard" field naming conventions.

## Review
- **Advisor verdict:** 3 of 4 PASS (round 7; GPT, Grok, Codex PASS; Gemini FAIL)
- **Top criticism:** Running variable (decade average) ≠ actual EPA designation process; N_right=6 too small for reliable inference
- **Surprise feedback:** Grok flagged |coefficient| > 100 as "regression sanity" failure — a blanket threshold inappropriate for MW-scale outcomes
- **What changed:** Added running variable clarification paragraph, MDE analysis (5,288 MW = 808% of mean), extensive margin test, toned down null claims throughout, fixed multi-cutoff to cross-sectional, fixed appendix tables from stale panel numbers

## Summary
- **Policy:** NAAQS PM2.5 nonattainment → energy infrastructure (RDD at 12 μg/m³)
- **Key finding:** Null — but severely underpowered (MDE > 800% of mean)
- **Strength:** Clean identification, thorough validity checks, honest about limitations
- **Weakness:** Only 11 nonattainment counties, cross-sectional outcome, cannot test spatial displacement
- **Lesson learned:** RDD with very few treated units near cutoff is fundamentally limited; the 2024 9μg/m³ revision will provide much better data
