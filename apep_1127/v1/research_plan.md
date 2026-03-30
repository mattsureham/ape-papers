# Research Plan: apep_1127

## Research Question
Did Oklahoma Corporation Commission (OCC) injection well volume directives causally reduce induced seismicity, or was the 97% decline from 2015–2023 driven by market forces (oil price collapse reducing wastewater injection)?

## Mechanism: "The Regulatory Ratchet"
Once regulators imposed well-specific volume caps, injection volumes dropped and stayed low even as oil prices recovered — a ratchet effect. The key insight is that regulatory mandates created a permanent structural break in the injection-seismicity relationship, distinct from the temporary demand-side reduction caused by falling oil prices.

## Identification Strategy
**Staggered Difference-in-Differences** (Callaway & Sant'Anna 2021) at the county-month level.

- **Treatment:** County-level exposure to OCC volume reduction directives (binary: any directive affecting wells in county; continuous: share of county injection wells under directive)
- **Treatment timing:** Staggered across 2015–2017 (primary wave):
  - March 2015: 347 wells in "Area of Interest" required 50% volume reduction
  - Feb–May 2016: 40% aggregate reduction for 600+ wells
  - September 2016 (post-Pawnee M5.8): 32 wells shut in, 35 reduced
  - March 2017: daily caps of 10,000–15,000 BPD
- **Pre-treatment period:** 2010–2014 (5 years)
- **Post-treatment period:** 2015–2023
- **Control counties:** Oklahoma counties without Arbuckle formation injection wells

## Expected Effects
- Large negative effect on earthquake counts (M2.5+) in treated counties
- Dose-response: counties with more directive-affected wells show larger reductions
- Effect should persist even as oil prices recover (2017+), distinguishing regulatory from market

## Primary Specification
$$Y_{ct} = \alpha_c + \gamma_t + \sum_g \beta_g \cdot \mathbb{1}[G_c = g] \cdot \mathbb{1}[t \geq g] + \varepsilon_{ct}$$

Where $Y_{ct}$ is earthquake count (M2.5+) in county $c$, month $t$; $G_c$ is the first treatment month for county $c$.

## Robustness & Placebo Tests
1. **Kansas replication:** KCC independently imposed similar regulations (March 2015, August 2016) — run parallel analysis
2. **Tectonic placebo:** California/Nevada tectonic earthquakes should show no response to Oklahoma regulations
3. **Oil price control:** Include WTI crude × county oil production interaction to separate market from regulatory
4. **Dose-response:** Continuous treatment using directive-affected well share
5. **Magnitude thresholds:** Repeat at M3.0+, M4.0+ to check robustness across earthquake sizes

## Data Sources
1. **USGS ComCat API** (earthquake.usgs.gov/fdsnws/event/1/) — M2.5+ earthquakes, 2009–2024
2. **OCC well data** — Well locations, API numbers, injection volumes (CSV from OCC website)
3. **County shapefiles** — US Census TIGER/Line for spatial joins
4. **Oil prices** — FRED WTI crude monthly
5. **Kansas earthquakes** — Same USGS API, Kansas bounding box

## Data Fetch Strategy
1. Query USGS API for Oklahoma earthquakes (latitude/longitude bounding box, M2.5+, 2009–2024)
2. Query USGS API for Kansas earthquakes (same parameters)
3. Query USGS API for California tectonic earthquakes (placebo)
4. Fetch county FIPS codes and assign earthquakes to counties via spatial join
5. Fetch WTI crude prices from FRED API
6. Construct treatment timing from OCC directive dates (hard-coded from regulatory documents)
