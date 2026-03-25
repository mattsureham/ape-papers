## Discovery
- **Idea selected:** idea_0133 — Dutch nitrogen ruling and BBB populist backlash. Selected because: vivid cross-domain mechanism (environmental court ruling → political realignment), all data confirmed accessible via open APIs, 342 municipalities with wide variation in BBB vote share (5–59%).
- **Data source:** CBS StatLine (building permits, regional key figures), Kiesraad EML XML (election results), PDOK WFS (Natura 2000 shapefiles). CBS regional keys table (70072NED) was unexpectedly rich — 323 columns including nitrogen excretion, employment by sector, urbanization.
- **Key risk:** Cross-sectional political outcome cannot establish causality.

## Execution
- **What worked:** The decomposition finding is clean and robust — agriculture employment share absorbs all the explanatory power of the nitrogen exposure index for BBB vote share. Province FE doesn't change the result.
- **What didn't:** Building permits DiD is null — the ruling's economic effects were national, not spatially concentrated. Election data was hard to access (Kiesraad has no simple API; had to parse 342 EML XML files from data.overheid.nl ZIP archives).
- **Review feedback adopted:** Added province FE to BBB regression (unchanged result), softened causal language for cross-section, acknowledged that building permits may not capture full economic disruption.
