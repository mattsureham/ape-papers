## Discovery
- **Idea selected:** idea_2222 — Weather IV for protest→donations, extending Madestam et al. (2013 QJE)
- **Data source:** GDELT Events database (pivoted from CCC due to auth issues, ACLED DNS failure)
- **Key risk:** Weather IV requires crowd-size data, not media-coded event counts

## Execution
- **What worked:** GDELT daily file download (264K events), Open-Meteo weather API, FEC contribution API
- **What didn't:** CCC behind auth, ACLED DNS unreachable, BigQuery ADC not configured, FEC API extremely slow in R (switched to Python). Weather IV has F-stat ~2 — instrument is weak because GDELT measures media coverage, not physical attendance.
- **Review feedback adopted:** Fixed text claiming "strong" first stage (was contradicted by results), removed economic interpretation of uninformative 2SLS estimates, clarified donor extensity margin as uninformative given weak IV
