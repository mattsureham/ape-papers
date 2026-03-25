## Discovery
- **Idea selected:** idea_1790 — Moldova wine embargo as Bartik shift-share; chose for clean shock, confirmed data, and trade weaponization framing
- **Data source:** EOAtlas VIIRS (AWS S3) + UN Comtrade API — EOAtlas URL pattern had changed from idea manifest; required reverse-engineering from GitHub repo
- **Key risk:** Pre-existing trends between wine and non-wine raions; nightlights insensitivity to agricultural shocks

## Execution
- **What worked:** Data fetching was efficient once correct URL found; 37 raions × 149 months gave a clean panel; trade collapse clearly documented in Comtrade data
- **What didn't:** Pre-trends are fatal — placebo at Sept 2012 significant (p = 0.002); event study shows multiple significant pre-embargo coefficients; leave-one-out reveals Bender drives positive estimate
- **Review feedback adopted:** Added MDE/power analysis (can rule out effects > 0.087 SDE); reframed abstract to acknowledge pre-trend limitations upfront; cautioned that null could reflect measurement insensitivity
- **Key lesson:** Nightlights are poor proxies for agricultural sector shocks in small economies — wine production is a daytime activity with minimal nightlight footprint. Future Moldova/trade embargo papers should use firm-level or household survey data.
