## Discovery
- **Idea selected:** idea_0638 — Mexico's Sorteo Militar, one of the world's largest annual randomizations with no prior economic study
- **Data source:** INEGI ENOE quarterly labor force survey (2018-2019) — direct download, no API key needed
- **Key risk:** Male-female DiD could capture lifecycle gender differences rather than lottery effects

## Execution
- **What worked:** The ENOE microdata are rich and cleanly structured. The male-female gap by age tells a compelling descriptive story. 835K observations with 30K+ males at age 18 gives enormous statistical power.
- **What didn't:** INEGI ZIP files have UTF-8 BOM in column headers, causing silent merge failures. The derived labor market variables (ingocup, hrsocup, seg_soc, pos_ocu) are in SDEMT, not COE2 — the initial code tried to merge COE2 for variables that were already in the demographics file. Post-2020 ENOE URLs changed (renamed ENOEN), limiting the data to 2018-2019.
- **Review feedback adopted:** Strengthened the identifying assumption discussion with quantitative pre-trend evidence; added explicit caveats about LATE scaling assumptions; expanded limitations section to acknowledge gender-specific lifecycle confounds; fixed duplicate [ref] rows in event study table.

## Key Finding
- ITT on employment: +13.6 pp (SE=0.81). ITT on formal employment: +11.6 pp (SE=0.71). Null on conditional earnings. Mechanism: credentialing via cartilla militar, not human capital.
