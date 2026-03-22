# Research Plan: The Price of Beauty

## Research Question

Does aesthetic regulatory gatekeeping by France's Architectes des Bâtiments de France (ABF) — exercised through binding opinions on all construction within 500 meters of historic monuments — capitalize into property values? The direction of the effect is theoretically ambiguous: restrictions may raise values (preserved aesthetics, amenity, signaling prestige) or lower them (constrained development, renovation delays, compliance costs).

## Institutional Background

Since 1943 (Heritage Code L.621-32), any construction, modification, or demolition within a 500-meter radius of a classified or registered historic monument in France requires a binding advisory opinion from the ABF. This creates approximately 400,000 annual opinions affecting over 20% of French urban development authorizations. The 500-meter threshold is fixed by law, uniform across all 46,700+ monuments, and has no economic basis — it was chosen as a rough visual co-visibility buffer in the 1943 law.

## Identification Strategy

**Spatial Regression Discontinuity Design (RDD)** following Keele and Titiunik (2015).

- **Running variable:** Euclidean distance from each DVF transaction to the nearest monument (meters)
- **Cutoff:** 500 meters
- **Treatment:** Property lies within the ABF regulatory zone (distance < 500m)
- **Control:** Property lies just outside the ABF zone (distance > 500m)

Properties at 490m vs 510m from a monument face radically different regulatory regimes but are otherwise in the same neighborhood, served by the same schools, transport, and amenities. The boundary is administrative (not economic), and individuals cannot manipulate their distance to a monument.

### Validity Tests
1. **Density test:** McCrary test for manipulation of the running variable at 500m
2. **Covariate balance:** Property size, type, number of rooms should be smooth through the boundary
3. **Donut-hole:** Exclude transactions at 450–550m and check robustness
4. **Placebo cutoffs:** Test at 300m, 400m, 600m, 700m where no regulatory boundary exists
5. **Bandwidth sensitivity:** Optimal bandwidth (Calonico, Cattaneo, Titiunik 2014) plus half/double

### Heterogeneity
- Monument type: classé (highest protection) vs inscrit (registered)
- Urban vs rural communes
- Paris/Île-de-France vs province

## Expected Effects and Mechanisms

**Ex ante ambiguous:**
- **Amenity channel (+):** Proximity to a well-preserved monument raises neighborhood quality, historical character, and aesthetics. ABF enforcement prevents ugly construction that would degrade the setting.
- **Restriction channel (−):** ABF opinions delay or block renovations and construction, raise compliance costs, and constrain development. Owners face uncertainty and additional regulatory burden.
- **Signaling channel (+):** Being within the protected perimeter may signal prestige or quality neighborhood.

The net effect depends on which channel dominates. If the amenity/signaling channels dominate, we expect a positive price premium inside the 500m zone.

## Primary Specification

Local polynomial regression at the 500m cutoff:

```
log(price_per_m2)_i = α + τ · 1(dist_i < 500) + f(dist_i) + X_i'β + γ_commune + δ_year + ε_i
```

Where:
- `dist_i` = distance from transaction i to nearest monument
- `f(dist_i)` = local polynomial in distance (separate on each side of cutoff)
- `X_i` = property characteristics (type, rooms, area)
- `γ_commune` = commune fixed effects
- `δ_year` = year fixed effects

Bandwidth selected by CCT optimal procedure. Triangular kernel weights.

## Data Sources

1. **DVF (Demandes de Valeurs Foncières):** 3-5M geolocated property transactions per year (2019-2024) with exact latitude/longitude, price, property type, floor area, number of rooms. Open data on data.gouv.fr.

2. **Monuments Historiques API:** 46,714 monuments with WGS84 coordinates. Open API from data.culture.gouv.fr.

3. **Commune boundaries:** AdminExpress from IGN (for commune fixed effects).

## Fetch Strategy

1. Download DVF bulk data from data.gouv.fr (CSV format, ~500MB per year)
2. Query Monuments Historiques API for all monument coordinates
3. Compute distance from each transaction to nearest monument using Haversine formula
4. Restrict sample to transactions within a reasonable bandwidth of 500m (e.g., 200m–800m)
