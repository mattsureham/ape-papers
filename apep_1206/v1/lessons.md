## Discovery
- **Idea selected:** idea_0942 — Swiss municipal tax competition, letterbox company mechanism using STATENT decomposition
- **Data source:** BFS STATENT (PXWeb API) + cantonal Steuerfuss (ZH/BL OGD) — both fully open, no API keys
- **Key risk:** Only 2 cantons with digitized Steuerfuss; nationwide ESTV data not accessible via CKAN

## Execution
- **What worked:** The establishment-by-employment decomposition is a genuine data advantage — clean separation of extensive/intensive margins. json-stat2 parser from PXWeb needed debugging (CJ sorts alphabetically, breaking value alignment; use expand.grid instead). Dose-response pattern across cut thresholds was the strongest robustness evidence.
- **What didn't:** Canton-clustered SEs are unreliable with only 2 cantons. ESTV nationwide Steuerfuss lookup via opendata.swiss CKAN returned no results. The tertiary sector proxy for "letterbox" is coarse — NOGA 2-digit breakdown would sharpen the mechanism.
- **Review feedback adopted:** Added explicit event study coefficients in text (all 3 reviewers wanted this), moderated conclusion language, added back-of-envelope fiscal calculation, acknowledged staggered DiD limitations, expanded threats-to-validity discussion.
