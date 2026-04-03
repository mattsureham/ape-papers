## Discovery
- **Idea selected:** idea_2072 — Brexit ROO as product-level natural experiment (zero tariffs, variable ROO)
- **Data source:** UN Comtrade API (HS-4, annual, 31 partners, 2015-2024) — ~3.1M rows
- **Key risk:** HS-2 ROO coding too coarse; HMRC preference data unavailable for V1

## Execution
- **What worked:** The compliance asymmetry finding (exports affected, imports not) emerged naturally from the data and has a clean economic explanation. Comtrade API v4 worked well after fixing the endpoint path.
- **What didn't:** Original idea promised HS-8 HMRC data with preference utilization — Comtrade is a significant downgrade. 2018 data was anomalously thin in aggregate queries but fine in partner-disaggregated ones. Needed 2015-2016 data to meet ≥5 pre-period requirement.
- **Review feedback adopted:** Strengthened limitations section, added identification discussion, flagged preference utilization as V2 priority. Could not improve ROO granularity or obtain HMRC data within V1 scope.
