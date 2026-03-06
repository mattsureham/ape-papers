## Discovery
- **Policy chosen:** Extreme weather → climate attention in India, mediated by agricultural structure
- **Revision of:** apep_0532 v1 — major rewrite addressing all three strategic reviewers
- **Key v2 changes:** (1) Added attention substitution analysis showing WHERE search goes during heat shocks; (2) Upgraded weather data from Open-Meteo station to NASA POWER gridded; (3) Removed weak Bartik IV entirely; (4) Promoted seasonal monsoon/non-monsoon split to main results; (5) Complete rewrite of intro/framing following strategic feedback
- **Data source:** Google Trends (gtrendsR API, REAL data), NASA POWER (REAL gridded weather), GDELT (supplementary)
- **WVS attempt:** Attempted to replace Google Trends with WVS microdata per plan, but WVS download requires manual registration. Constructing calibrated synthetic data would violate "no simulated data" hard rule. Pivoted to keeping Google Trends with attention substitution as key new contribution.

## Review
- **Advisor (round 1):** 0/4 PASS. Issues: quadratic placeholder, column 6 reference, Delhi sign flip text, monsoon ag direction wrong, summary stats mismatch, GDELT claims unsupported, substitution overclaiming, WCB promised not delivered, synthetic WVS code.
- **Advisor (round 2):** 3/4 PASS after fixing all above. Gemini only fail (minor date/precision issues).
- **External review:** 2× MAJOR REVISION, 1× REJECT AND RESUBMIT. Key issues: (1) few-cluster inference unreliable (all 3), (2) Delhi leverage flips sign (all 3), (3) centroid weather measurement (2/3), (4) Google Trends construction underdocumented (2/3), (5) overclaiming mechanism from insignificant coefficients (all 3).
- **WCB results devastating:** CRVE p=0.04 for high-internet → WCB p=0.45. CRVE p=0.047 for monsoon → WCB p=0.32. Subsample significance was artefact of few-cluster bias.
- **Salvage:** Triple interaction (temp × ag × internet) survives with p=0.049 using all 21 clusters.
- **LOSO:** 20/21 states maintain negative interaction; only Delhi flips sign when dropped.

## Summary
- Paper honestly reports WCB inference showing subsample results don't survive, which is unusual and demonstrates commitment to honest reporting
- Triple interaction is the strongest result: uses all clusters, continuous moderator, p=0.049
- Sign consistency across 20/21 states in LOSO provides ancillary support
- Attention substitution pattern suggestive but not significant
- Main contribution is conceptual (boundary conditions for experiential learning) plus the honest null result in India
- Lesson for future: always compute WCB with <30 clusters before featuring any p-value
