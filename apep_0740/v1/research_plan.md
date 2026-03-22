# Research Plan: The Designation Paradox — QPV Priority Neighborhood Boundaries and Property Values in France

## Research Question

Does official designation as a "priority neighborhood" (Quartier Prioritaire de la Politique de la Ville, QPV) increase or decrease property values? France's QPV system bundles fiscal incentives (30% property tax reduction, 5.5% reduced VAT, corporate tax exemptions) and urban renewal investment (12 billion euros ANRU/NPNRU) with a poverty label that may stigmatize designated areas. This paper estimates the net capitalization effect at QPV boundaries using a spatial regression discontinuity design.

## Identification Strategy

**Spatial RDD** (not DiD) exploiting the sharp geographic perimeters of 1,362 QPVs in metropolitan France. This is a cross-sectional spatial regression discontinuity design.

**Exposure alignment:** Treatment (QPV designation) directly affects all residential properties inside QPV boundaries. The policy bundle is geographically determined: a property is treated if it lies inside any QPV polygon. Properties inside QPVs are exposed to the full policy bundle (TFPB reduction, VAT subsidies, ANRU eligibility, official designation label). Properties outside QPVs receive none of these treatments. There is no partial exposure or dosage variation — treatment is binary and perfectly determined by geographic location relative to the QPV boundary.

- **Running variable:** Signed geodesic distance from each DVF property transaction to the nearest QPV boundary perimeter. Positive = inside QPV, negative = outside.
- **Treatment:** Being located inside a QPV boundary (triggering the full policy bundle).
- **Bandwidth:** 500m primary (CCT-optimal bandwidth as robustness).
- **Internal replication:** 1,362 separate QPV boundaries, pooled with QPV fixed effects.

**Key identifying assumption:** Properties cannot sort discontinuously across QPV boundaries. QPV perimeters were drawn by ANCT using 200m gridded income data from INSEE — not based on property transactions or housing characteristics. Validation: covariate balance at the boundary (property type, surface area, number of rooms).

**Threats and mitigation:**
1. *Sorting:* QPV boundaries follow existing geographic features (roads, rails). Include boundary-segment fixed effects.
2. *Anticipation:* QPV boundaries set in 2014 law, effective January 2015. Use pre-2015 transactions as placebo.
3. *Compositional changes:* ANRU demolition/reconstruction may change housing stock inside QPVs. Test with pre-ANRU vs. post-ANRU subsamples.

## Expected Effects and Mechanisms

**Competing channels:**
1. **Stigma effect** (negative): "Priority neighborhood" label signals poverty, crime, social disadvantage → buyers discount properties inside QPV → lower prices.
2. **Fiscal incentive effect** (positive): Reduced VAT (5.5% vs 20%) on new construction, 30% TFPB reduction, CFE exemption → developers build more/cheaper, buyers save on taxes → higher demand.
3. **Urban renewal effect** (positive): ANRU spending on infrastructure, housing renovation → physical improvement → higher prices.

**Net effect is ex ante ambiguous**, which is what makes this question interesting. A null result would mean stigma and subsidies exactly offset. A positive result would mean fiscal incentives dominate stigma. A negative result would mean the poverty label is a powerful market signal.

## Primary Specification

Y_i = α + τ · QPV_i + f(distance_i) + X_i'β + γ_b + δ_t + ε_i

- Y_i: log(price per m²) of transaction i
- QPV_i: indicator for location inside QPV boundary
- f(distance_i): local polynomial in signed distance (linear, primary)
- X_i: property controls (type, rooms, surface area)
- γ_b: boundary-segment fixed effects (group transactions by nearest QPV)
- δ_t: year-quarter fixed effects
- Clustering: at commune level

RDD estimation via rdrobust (Calonico, Cattaneo, Titiunik 2014).

## Data Sources

1. **DVF Geolocalized** (data.gouv.fr): All property transactions in France with lat/lon coordinates at parcel centroid. ~494MB compressed. Years: 2014-2024.
2. **QPV Shapefiles** (data.gouv.fr): Official polygon boundaries of all 1,362 QPVs. Available as SHP/GeoJSON.
3. **INSEE Filosofi 200m** (optional): Income grid data for covariate balance checks.

## Data Processing Strategy (8GB RAM constraint)

1. Download QPV shapefiles (small, ~10MB)
2. Buffer QPV boundaries by 2km
3. Download DVF year-by-year and filter to transactions within 2km of any QPV boundary
4. Compute signed distances using sf::st_distance()
5. Stack filtered transactions into analysis dataset

## Feasibility Assessment

- **Sample size:** ~100,000-500,000 transactions within 500m bandwidth (2014-2024)
- **Treatment variation:** Binary (inside/outside QPV at boundary)
- **Pre-trends:** Pre-2015 transactions serve as placebo
- **Power:** With 100K+ transactions, even small effects (~2-3% price difference) should be detectable
