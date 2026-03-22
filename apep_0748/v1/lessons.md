## Discovery
- **Idea selected:** idea_0984 — GP closures → A&E utilization. Chosen for 1,400+ treated units, vivid first-order question, and no existing causal study.
- **Data source:** NHS ODS API (GP closures) + NHS England A&E monthly SitReps (provider-level). ODS flat file download broken (403); API worked with Accept header + 1-based offset. A&E required downloading/parsing 95 individual monthly XLS files.
- **Key risk:** Geographic mapping of GP closures to A&E trusts via 10km radius is blunt.

## Execution
- **What worked:** Data assembly pipeline (ODS API → geocoding → distance matching → provider panel) was robust. The finding — a meaningful null pre-COVID and significant effect post-COVID — tells a clean, surprising story.
- **What didn't:** Callaway-Sant'Anna failed due to near-universal treatment (119/122 trusts treated). Had to fall back to TWFE. Binary treatment indicator is too coarse (all closures treated equally regardless of practice size).
- **Review feedback adopted:** Added C-S failure explanation, strengthened event study reporting, added frank limitations paragraph about measurement error and identification caveats.
