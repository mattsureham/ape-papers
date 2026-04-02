## Discovery
- **Idea selected:** idea_1159 — Lithuania's +39% MW hike, cross-Baltic sector-level DiD with Kaitz binding intensity
- **Data source:** ILO STAT (employment, wages) + Eurostat (minimum wages) — all API-accessible, no credentials needed
- **Key risk:** Few clusters (3 countries), pre-trends in binding-intensity gradient

## Execution
- **What worked:** The ILO API is reliable and the cross-Baltic comparison is a clean natural experiment. 13 sectors with 3x Kaitz spread provides good continuous-treatment variation. Permutation inference (p=0.006) is the most credible inferential tool with 3 countries.
- **What didn't:** The pre-trend concern is real — high-binding Lithuanian sectors were growing faster than Baltic peers in 2013-2014, creating a convergence pattern that contaminates the baseline DiD. The immediate 2018-2019 effect is null, suggesting slow adjustment.
- **Review feedback adopted:** (1) Added sector-specific trend specification (β attenuates from -1.67 to -0.73 but stays significant). (2) Excluded COVID-vulnerable sectors (accommodation, agriculture) — result strengthens. (3) Narrow window 2016-2020 confirms effect. (4) Added Lithuania's 2019 tax reform "gross-up" discussion. (5) Substantially moderated causal claims — "suggestive evidence" not "demonstrates."
- **Key lesson:** When using aggregate sector data across few countries, pre-trends are almost inevitable in convergence settings. Sector-specific trends should be the preferred specification, not a robustness check. The ILO average wage data is too coarse to serve as a "first stage" — it captures compositional changes, not the wage floor's direct impact.
