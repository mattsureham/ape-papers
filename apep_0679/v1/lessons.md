## Discovery
- **Idea selected:** idea_0898 — UK Apprenticeship Levy geographic crowding-out. Chosen for vivid paradox (Pigouvian policy backfires), strong Bartik identification (321+ LAs), and confirmed data.
- **Data source:** GOV.UK FE Data Library (historical XLSX) + NOMIS Business Counts API. DfE Explore Education Statistics was available but only covers 2021/22-2023/24 (all post-Levy).
- **Key risk:** Historical data has total starts only (no level breakdown), preventing direct test of Level 2 vs Level 4+ compositional shift at LA level.

## Execution
- **What worked:** NOMIS API with server-side `industry=37748736` filter worked perfectly for business counts. Bartik shift-share DiD ran cleanly with 123 LAs × 10 years.
- **What didn't:**
  - DfE Explore Education Statistics API was hard to find — no obvious download URL. CKAN search on data.gov.uk returned geography lookups, not apprenticeship data. The real URL was found via WebSearch.
  - EES data only covers 2021/22-2023/24, not 2018/19+ as expected. This meant no level-specific pre-Levy data.
  - NOMIS population data (NM_31_1, NM_2002_1) returned empty OBS_VALUE fields for many LA-year cells. Used `resp_body_string()` + `writeLines()` workaround instead of `resp_body_raw()`.
  - Geo code lookup in the historical XLSX had LA names in column 4 and codes in column 5 (not 4-6 as initially assumed).
  - The "Since May 2010" cumulative column was accidentally included as a year, inflating means until filtered.
- **Main finding:** Precise null (β=3.94, SE=13.43, p=0.77). The Levy did not crowd out local training. Randomization inference confirms (p=0.63).
- **Review feedback adopted:** Added explicit discussion of total-starts limitation, acknowledged 123/321 LA coverage gap, addressed pre-trend interpretation following Roth (2022).

## Data Lessons
- **NOMIS API tip:** Always include `industry=37748736` when querying NM_142_1 to get "Total" industry only. Without this, the query returns rows for every SIC subclass and hits the 25K guest limit.
- **UK apprenticeship data landscape:** The FE Data Library (XLSX) has long time series but only totals by LA. The EES has level/age breakdowns but starts only from 2021/22. For a study needing level-specific pre/post data, one would need the DfE's Individualised Learner Record (ILR) — not publicly available.
