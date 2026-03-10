## Discovery
- **Policy chosen:** Chile's 2012 voting reform (Law 20.568, compulsory→voluntary) — cleanest modern case of democratic contraction with massive cross-comuna variation in turnout decline (15-58 pp)
- **Ideas rejected:** Used pinned idea (idea_0024) from database — no alternatives considered
- **Data source:** SERVEL electoral data from Harvard Dataverse (Cox & González 2022), DMCS crime data from datos.gob.cl (2010-2012), CEAD crime data from GitHub (2018-2024). DMCS xlsx required custom Python parser (openpyxl) because R's read_excel couldn't handle the complex pivoted monthly structure. Historical crime data (2013-2017) unavailable — SPD/CEAD endpoints returned 404/timeouts, creating a "donut" gap bridged by treating 2010-2011 as pre and 2018-2024 as post.
- **Key risk:** The 6-year gap (2013-2017) between pre and post periods limits the event study to only one pre-treatment year (2010 vs 2011 base). Mitigated by: (1) pre-trend F-test p=0.809, (2) randomization inference, (3) leave-one-out stability, (4) the built-in placebo (non-police-dependent crimes).
- **Surprise finding:** Expected MORE crime in high-decline comunas but found LESS recorded crime (drugs, burglary) with MORE homicide. Reframed as "detection gap" — the paper's core contribution.

## Review
- **Advisor verdict:** 4 of 4 PASS (after 5 attempts; earlier rounds caught real errors in sensitivity analysis, inconsistent definitions, missing SEs)
- **Referee verdict:** 2 R&R (GPT R1, R2) + 1 Minor Revision (Gemini)
- **Top criticism:** Treatment variable conflates voluntary voting with automatic registration (denominator expansion). Both GPT reviewers flagged this independently. Also: 6-year data gap, only 1 pre-period, no direct policing data.
- **Surprise feedback:** GPT R1 questioned whether RI is informative given treatment is non-random — valid point about permutation inference vs identification.
- **What changed:** (1) Added IHS transformation, tipología×year FE, covariate×post interactions as robustness; (2) Softened causal language throughout ("consistent with" not "caused"); (3) Reframed predicted-treatment as descriptive check, removed IV/Bartik language; (4) Expanded Limitations from 1 paragraph to 6; (5) Added treatment-conflation caveat in Section 2.6; (6) Acknowledged 1-pre-period limitation honestly.

## Summary
- **Key lesson:** Detection-gap framework (discretionary vs non-discretionary crime) is theoretically strong but the data environment (6-year gap, 1 pre-period, different crime systems) makes identification fragile. Reviewers are right that the paper is suggestive rather than definitive. The writing and framing quality can compensate somewhat for design limitations.
- **What worked well:** Prose quality rated "top-journal ready" by Gemini prose review. Opening hook and detection-gap branding strong.
- **For future work:** Chile papers need continuous crime data coverage; the DMCS-CEAD gap is a fundamental constraint. Consider victimization survey data (ENUSC) for validation.
