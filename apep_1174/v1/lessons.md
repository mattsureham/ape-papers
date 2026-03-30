## Discovery
- **Idea selected:** idea_2055 — EPA ECHO enforcement lottery, examiner-leniency IV design with massive administrative data
- **Data source:** EPA ECHO (ICIS-Air inspections), TRI (facility-year emissions), FRS (crosswalk), ECHO Exporter (facility metadata)
- **Key risk:** SRF instrument might not generate enough quasi-random variation; TRI is self-reported

## Execution
- **What worked:** Data pipeline — 1.16M inspections linked to 9,907 TRI facilities via FRS crosswalk. Strong first stage (F=397). Clean event study with no pre-trends. ECHO bulk downloads are well-structured and comprehensive.
- **What didn't:** Could not directly exploit SRF review cycle timing (would require coding 50 states × multiple rounds from EPA reports). ECHO Exporter URL changed from .csv.gz to .zip (check URLs before hardcoding). FRS download is 353MB and needs 10+ minute timeout.
- **Review feedback adopted:** Added SRF caveat in empirical strategy, strengthened reporting-channel discussion, added generalizability caveats for TRI sample vs broader universe. Key reviewer suggestion for future work: use violation/penalty/SNC data as intermediate outcomes to separate reporting from deterrence.

## Key Result
A well-identified null: federal enforcement does not measurably reduce TRI emissions compared to state enforcement. The IV point estimate is positive (0.259) but imprecise (SE = 0.268). The OLS estimate is nearly zero (0.031, SE = 0.031). Multiple robustness checks confirm stability.
