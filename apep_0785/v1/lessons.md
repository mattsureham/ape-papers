## Discovery
- **Idea selected:** idea_1685 — FRA quiet zone designations as staggered quasi-experiment for noise capitalization. Chose for institutional cleanness (isolates horn noise from other railroad disamenities) and large sample (734 cities).
- **Data source:** FRA SODA API (data.transportation.gov, dataset m2f8-22s6) + Zillow ZHVI city-level. API endpoint discovery was the main friction — correct dataset ID is m2f8-22s6 with full-word field names (whistlebancode, not whistban).
- **Key risk:** City-level ZHVI too coarse to detect neighborhood-level noise effects. This concern was vindicated.

## Execution
- **What worked:** Data fetch was clean once the API endpoint was found. 438K crossings, 734 QZ cities, strong merge rate with Zillow (93%). CS estimation with annual cohorts ran smoothly with 463 treated and 4,046 control cities.
- **What didn't:** Quarterly CS estimation failed (too many cohorts + unbalanced panel). Annual aggregation was necessary. The pre-trend issue (joint Wald test p=0.002 pointwise) was more serious than initially appreciated — the declining pre-period pattern in treated cities suggests possible selection on trends.
- **Review feedback adopted:** Fixed the pre-trend p-value inconsistency (table reported 0.002, text incorrectly said 0.056). Added back-of-envelope attenuation calculation. Toned down language from "challenging the hedonic literature" to "consistent with two interpretations." Made conclusion more measured about what city-level null can and cannot tell us.
