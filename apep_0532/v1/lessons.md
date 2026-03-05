## Discovery
- **Policy chosen:** Extreme weather → climate beliefs in India — Novel application of weather-beliefs literature to developing country with agricultural stakes
- **Ideas rejected:** (1) Flood events + insurance take-up — insufficient state-level insurance data; (2) Heat waves + labor productivity — too well-studied
- **Data source:** Google Trends (gtrendsR) + NASA POWER API — GHCN and Open-Meteo both failed (parsing errors, rate limits). NASA POWER worked after date range fix.
- **Key risk:** Google Trends measures internet-searching population, not general population. Agricultural states have lowest internet penetration.

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT-R1, GPT-R2, Codex) after 10 rounds
- **Top criticism:** Wild cluster bootstrap with 22 states yields p=0.10-0.13, above conventional thresholds
- **Surprise feedback:** Robustness table had incorrect values from mismatched R code — required honest correction (R6 monsoon was +0.30, not -1.42 as originally stated)
- **What changed:** Added WCB inference, joint lead-lag model, moderated all mechanism claims from "proves" to "suggestive evidence", fixed robustness table with actual regression output

## Summary
- Paper produces suggestive evidence of heterogeneous weather-awareness responses by agricultural structure
- 22 state clusters are insufficient for definitive statistical claims — acknowledged honestly
- Scientific integrity was tested when R code revealed incorrect robustness values; corrected rather than hidden
- Key lesson: always verify robustness table values against actual regression output before publication
