## Discovery
- **Idea selected:** idea_1939 — Railroad quiet zones and crossing safety. Chosen for massive treated sample (4,167 crossings), universe-scale admin data (FRA inventory + accidents), clean policy lever (exact treatment dates), and genuine theoretical ambiguity.
- **Data source:** FRA Socrata API (data.transportation.gov) — Dataset IDs not in manifest; required catalog search. `m2f8-22s6` (Form 71), `icqf-xf4w` (Form 57).
- **Key risk:** Selection into quiet zones is non-random; pre-treatment trend suggests front-loaded safety improvements.

## Execution
- **What worked:** The Socrata API delivered 438K crossings and 250K accidents reliably. TWFE on 8.5M crossing-years ran fast with fixest. The heterogeneity by gate status produced the paper's most interesting finding.
- **What didn't:** Callaway-Sant'Anna struggled with the large panel (needed 10:1 stratified sample); Sun-Abraham sunab() hit 16GB memory limit even with 3:1 sampling. Had to fall back to manual event-time indicators. R's scientific notation (1e+05) broke Socrata pagination URLs.
- **Review feedback adopted:** (1) Explained sample reduction 5,041→4,167 with footnote on Chicago Excused; (2) Acknowledged placebo as both mechanism and identification threat; (3) Strengthened caveat that gate status is current snapshot not historical; (4) Reframed gated-crossing result as "pure Peltzman" effect; (5) Added clustering and pre-trend limitations to Discussion.
