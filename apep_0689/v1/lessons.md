## Discovery
- **Idea selected:** idea_0572 — FEMA flood zone + mortgage credit access via HMDA
- **Data source:** CFPB HMDA Data Browser API (910K FL records), Census ACS via tidycensus (with geometry for coastal distance), FEMA NRI (attempted, servers down — pivoted to coastal proximity)
- **Key risk:** Coastal proximity as SFHA proxy introduces measurement error; the paper's claims are bounded by this limitation

## Execution
- **What worked:** CFPB data-browser-api endpoint (note: not data-browser, needs -L for redirect). Coastal distance from tract centroids via tidycensus geometry was a clean fallback when FEMA NRI was inaccessible. The denial reason decomposition (DTI vs credit history) provided the paper's most interesting finding.
- **What didn't:** FEMA servers completely down (NRI, OpenFEMA NFIP APIs all returned 503/000). ArcGIS Feature Server for NRI had bizarre query limitations (only worked for <5 records). This forced the coastal proximity pivot.
- **Review feedback adopted:** Softened causal language from "test" to "examine," from "precise null" to "economically null." Added explicit acknowledgment that coastal proximity captures more than flood zone status. Reframed as "informative reduced-form associations" rather than clean causal identification.
