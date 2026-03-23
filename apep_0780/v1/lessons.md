## Discovery
- **Idea selected:** idea_1027 — UK alcohol CIAs and violent crime. Pivoted from idea_0761 (India PMFBY crop insurance) which failed because ICRISAT data ends 2017 but treatment starts 2018.
- **Data source:** Home Office Police Recorded Crime Open Data Tables (gov.uk ODS files). Police API only retains 36 months — insufficient for DiD. ONS file URLs had changed (404s). Gov.uk statistics page WebFetch found correct current URLs.
- **Key risk:** Force-level treatment assignment is coarse (CIAs are zone-level within LAs, but crime data is at police force area level). This dilutes the treatment signal.

## Execution
- **What worked:** Home Office PFA ODS files are comprehensive (241K rows, 42 forces, 13 years, detailed offence categories). Direct download from gov.uk worked after finding correct URLs via WebFetch. The paper writes a credible null result.
- **What didn't:** India idea (PMFBY) was a dead end — ICRISAT DLD data stops at 2017. Police API only keeps 36 months. First attempt at gov.uk URLs used outdated paths (404). Force-level analysis is coarser than the ideal LA-level analysis (CSP data was 45MB but harder to process).
- **Review feedback:** TBD at publish time.
