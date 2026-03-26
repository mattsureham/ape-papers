## Discovery
- **Idea selected:** idea_1708 — Zero economics papers on premarital education incentives despite 20 years of adoption across 10 states. The only study (Clyde et al. 2019) uses biased TWFE on 5 states.
- **Data source:** CDC NVSS state divorce/marriage rates (Excel downloads) + ACS 1-year marital status via Census API. CDC URLs had moved to a new subdirectory path; found via web search.
- **Key risk:** Only 6 treated clusters in the balanced panel (10 states minus FL pre-panel, GA missing data, OK borderline). Power concerns with few clusters.

## Execution
- **What worked:** Staggered DiD with Callaway-Sant'Anna produced clean, interpretable results. The null finding is definitive and robust across all specifications. Wild cluster bootstrap confirmed the null. HonestDiD bounds include zero.
- **What didn't:** BLS LAUS API failed to return data for multi-decade queries (likely needs registration key). Hand-coded FIPS crosswalk had a critical bug (DC FIPS 11 placed in position 9 instead of 51, shifting all subsequent state mappings). Always verify FIPS crosswalks against a known source — or better, use R's built-in state FIPS data.
- **Review feedback adopted:** Added a treatment adoption table listing all 10 states with policy details and CS panel status. Added ITT vs. TOT discussion with take-up bounds. Added minimum detectable effect discussion. These were the three main points raised by all reviewers.
