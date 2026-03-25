# Research Plan: Wilderness by Law, Timber by Market

## Research Question
Does federal wilderness designation causally reduce forest harvesting at the boundary? Using the sharp legal discontinuity at 806 wilderness area boundaries—where logging is prohibited on one side and permitted on the other—I estimate the causal effect of wilderness protection on tree cover loss and vegetation health using 30m satellite data.

## Identification Strategy
**Spatial RDD.** The running variable is signed distance from each 30m pixel to the nearest wilderness boundary (negative = inside wilderness, positive = outside). The treatment is wilderness designation, which creates a sharp legal discontinuity: inside wilderness, commercial timber harvest is prohibited under the Wilderness Act of 1964; immediately outside (in National Forest land), harvest is permitted under USFS management plans.

**Key assumption:** Forest characteristics are continuous at the wilderness boundary absent the designation. This is plausible because (a) Congress drew wilderness boundaries through political compromise, not ecological criteria, and (b) both sides are federal land within the same national forests.

**Controls:** Elevation and slope from SRTM 30m DEM (to address the concern that some boundaries follow ridgelines).

**Bandwidth:** Primary 5km; robustness at 2km, 3km, 10km.

**Placebo:** National park boundaries (both sides restrict harvest → no discontinuity expected).

## Expected Effects and Mechanisms
- **Primary:** Tree cover loss should drop sharply crossing into wilderness (legal prohibition binding)
- **Mechanism:** The "legal fortress" effect—formal institutional protection prevents harvesting where economic incentives exist
- **Heterogeneity:** Effect should be larger in high-value timber regions (Pacific Northwest) than non-timber wilderness. Effect may vary by timber market conditions.
- **Possible surprise:** Leakage/displacement—areas just outside wilderness may be harvested MORE intensively if timber demand is redirected.

## Primary Specification
```
TreeCoverLoss_i = α + τ·Wilderness_i + f(Distance_i) + β·Elevation_i + γ·Slope_i + ε_i
```
where `f(Distance_i)` is a local polynomial in signed distance to boundary, estimated within bandwidth h via local linear regression. Standard errors clustered at the wilderness area level.

## Data Sources
1. **Wilderness boundaries:** PAD-US (USGS Protected Areas Database) or WDPA — shapefiles of all 806 designated wilderness areas
2. **Tree cover loss:** Hansen Global Forest Change v1.11 — 30m annual binary loss indicator, 2001–2023
3. **Tree cover:** Hansen GFC treecover2000 — 30m baseline canopy cover
4. **Elevation/slope:** SRTM 30m DEM
5. **National Forest boundaries:** USFS administrative boundary shapefiles (to restrict to forest-adjacent wilderness)
6. **Fire perimeters:** MTBS (Monitoring Trends in Burn Severity) — to separate fire-driven from harvest-driven loss

## Scope (V1 — AER: Insights)
- **Geographic focus:** Pacific Northwest and Northern Rockies (WA, OR, ID, MT, northern CA) — ~200 wilderness areas in prime timber country
- **Pixel sampling:** Random sample of ~500,000 pixels within 5km of wilderness boundaries (sufficient for precise RDD estimates while manageable on 16GB RAM)
- **Temporal:** Cross-sectional RDD using cumulative tree cover loss 2001–2023; robustness with annual panels for selected years
