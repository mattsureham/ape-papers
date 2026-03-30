# Research Plan: The Solar Footprint — Utility-Scale Photovoltaic Expansion and Farmland Bird Populations

## Research Question

Does the construction of utility-scale solar photovoltaic facilities on greenfield (agricultural/undeveloped) land reduce local farmland bird populations, and does siting on degraded land (brownfield/landfill) avoid this ecological cost?

## Identification Strategy

**Design:** Staggered Difference-in-Differences with continuous dose-response

**Treatment:** Cumulative greenfield solar MW capacity within a fixed radius (10 km primary; 5 km and 20 km robustness) of each USGS Breeding Bird Survey (BBS) route centroid. Treatment timing = operational year of the first nearby greenfield solar facility.

**Data:**
- **Treatment:** USGS USPVDB v3.0 (5,712 facilities, lat/lon, operational year, MW capacity, greenfield/brownfield/landfill classification)
- **Outcome:** USGS Breeding Bird Survey, 1966-2024 (route-level, 50-stop standardized counts, ~3,000 US routes, annual)
- **Species:** Farmland guild (Eastern/Western Meadowlark, Grasshopper Sparrow, Bobolink, Dickcissel, Horned Lark, Killdeer) as treatment group; forest-interior species (Ovenbird, Wood Thrush, Scarlet Tanager) as placebo

**Why BBS over eBird:** BBS uses standardized protocol (same routes, same 50 stops, same timing, same duration) — no observer effort confound. eBird requires complex effort controls that are hard to validate.

**Exogeneity argument:** Solar facility siting is driven by state RPS mandates, federal ITC availability, grid interconnection capacity, and land prices — not by local bird population trends. Pre-trend validation: farmland bird counts on treatment and control routes should trend similarly before solar construction.

**Fixed effects:** Route + year. State-by-year FE in preferred specification.

**Clustering:** State level.

## Expected Effects

- **Farmland birds near greenfield solar:** Negative (habitat conversion removes grassland/agricultural habitat)
- **Farmland birds near brownfield/landfill solar:** Null (already degraded habitat)
- **Forest-interior species near any solar:** Null (wrong habitat type — placebo)
- **Agrivoltaic facilities:** Smaller negative effect (pollinator-friendly management preserves some habitat value)

## Primary Specification

**Continuous dose-response:**
$$Y_{rt} = \alpha_r + \gamma_t + \beta \cdot \text{GreenSolarMW}_{rt} + \varepsilon_{rt}$$

Where $Y_{rt}$ is the count of farmland bird species on route $r$ in year $t$, and GreenSolarMW is the cumulative greenfield solar capacity within 10 km.

**Also:** Callaway-Sant'Anna event study using binary treatment (first greenfield facility within 10 km).

## Placebo Tests

1. **Brownfield/landfill solar**: Same dose-response on degraded-land solar — should be null
2. **Forest-interior species**: Same treatment, wrong species — should be null
3. **Pre-trends**: Event study leads should be zero
4. **Wind turbines**: Different mechanism (collision not habitat) — supplementary comparison

## Robustness

1. HonestDiD sensitivity for parallel trends
2. Radius variation: 5 km (local only) and 20 km (broader area)
3. Population-weighted vs unweighted
4. Exclude routes near urban areas (>500K pop)
5. Restrict to routes with ≥10 years of continuous data

## Kill Conditions

1. BBS routes within 10 km of solar facilities < 50 (insufficient treated units)
2. No farmland guild species detected on treated routes (wrong geography)
3. Significant pre-trends that cannot be resolved

## Data Fetch Strategy

1. USPVDB: Download CSV from energy.usgs.gov/uspvdb/data/
2. BBS: Download route-level species counts from ScienceBase/USGS
3. Compute distances: BBS route centroids ↔ solar facility lat/lon
4. Construct route-year panel with cumulative solar MW exposure
