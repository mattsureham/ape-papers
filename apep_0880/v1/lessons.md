## Discovery
- **Idea selected:** idea_0711 — EU Critical Raw Materials Act and import diversification
- **Data source:** UN Comtrade public preview API — no auth needed, bilateral trade flows at HS4-HS6 level
- **Key risk:** Pre-trends not parallel; short post-treatment window (1-2 years)
- **Pivot:** Originally selected idea_0466 (OIRA review duration), but reginfo.gov has no public API — entire site is JS-rendered SPA. Resolved as failed after 10 minutes of URL testing.

## Execution
- **What worked:** Comtrade preview API (comtradeapi.un.org/public/v1/preview) is reliable, fast, no auth. Continuous-treatment DiD is clean and easy to implement in fixest.
- **What didn't:** First Comtrade fetch used partnerCode=0 which returns only world aggregates. Cost 15 minutes. Always omit partnerCode to get bilateral flows.
- **Review feedback adopted:** Added Germany-proxy caveat, MDE power discussion, timing nuance about 2030 deadline vs 2024 data. Pre-trend issue honestly acknowledged — cannot be fixed with this design.
- **Null result:** Honest and well-powered. CRMA has not moved import sourcing in its first 1-2 years. Placebo test confirms pre-trends aren't parallel, making the causal interpretation fragile but the policy finding robust.
