## Discovery
- **Idea selected:** idea_1733 — SNAP retailer loss as supply-side constraint on benefit takeup. Novel angle vs. demand-side participation literature.
- **Data source:** USDA SNAP Historical Retailer Database (703K stores, auth/end dates) + ACS B22003 tract-level. S3 links dead; found correct USDA FNS download at fns-prod.azureedge.us.
- **Key risk:** Exclusion restriction — do corporate shocks and stocking rule affect SNAP participation only through retailer access?

## Execution
- **What worked:** State-by-state spatial join (100% match rate per state), shift-share from 2018 stocking rule clearly visible in data (net exits jump from +0.008 to +0.129). Tract FE IV cleanly identifies negative effect.
- **What didn't:** County-FE IV produces wrong sign (positive) due to severe cross-tract selection — dollar stores locate in high-SNAP neighborhoods. Poverty placebo fails, suggesting instruments capture local economic disruption beyond pure access channel.
- **Review feedback adopted:** (1) Added explicit ACS 5-year rolling-window caveat per GPT-5.4 reviewer (ACS "2018" reflects 2014-2018 data, so effects are conservative/medium-run). (2) Softened causal claims given significant poverty placebo — reframed as "access + local economic disruption" rather than pure access. (3) Emphasized LATE interpretation for large coefficient (complier tracts where marginal retailer was primary access point).
