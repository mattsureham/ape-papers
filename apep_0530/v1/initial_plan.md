# Initial Research Plan: When Zones Disappear

## Research Question

What happens to property values when neighborhoods lose priority investment status? Specifically, does the 2014 replacement of France's 751 Zones Urbaines Sensibles (ZUS) with 1514 Quartiers Prioritaires de la Politique de la Ville (QPV) create asymmetric capitalization effects at zone boundaries --- with different responses for areas that gained, lost, or retained designation?

## Policy Background

France's place-based urban policy underwent a wholesale boundary redraw in 2014 under the Loi de Programmation pour la Ville et la Cohesion Urbaine (Loi Lamy, February 2014):

- **Before 2014:** 751 ZUS (created 1996) received targeted investment, tax incentives, and public services. The PNRU (Programme National de Renovation Urbaine, 2003-2014) invested EUR 12B in housing renovation.
- **2014 transition:** ZUS replaced by 1514 QPV, defined by a new income-poverty criterion (median income on 200m grids < 11,250 EUR). The NPNRU (Nouveau Programme National de Renovation Urbaine, 2014-2030) allocated EUR 10B.
- **Three natural groups:**
  - **Gained:** Not in ZUS, now in QPV (new beneficiaries)
  - **Lost:** Were in ZUS, not in QPV (lost designation)
  - **Retained:** In both ZUS and QPV (continuous treatment)

## Identification Strategy

**Boundary difference-in-differences-in-discontinuities (DDD):**

The primary specification compares property transactions just inside vs. just outside zone boundaries, before vs. after the 2014 redesignation, across the three designation-change groups.

**Primary estimand:**

For "lost status" zones, the estimand is:
```
Delta = [Price_inside_boundary - Price_outside_boundary]_post_2014
      - [Price_inside_boundary - Price_outside_boundary]_pre_2014
```

This differences out:
1. Cross-sectional level differences at the boundary (boundary FE)
2. Common time trends (year FE)
3. Zone-specific trends (boundary x year FE)

**Key comparisons:**
- **Lost vs Outside:** Areas that lost ZUS status should converge with "never designated" areas if investment withdrawal reverses capitalization
- **Gained vs Outside:** Areas that gained QPV status should diverge from "never designated" areas if new investment capitalizes
- **Retained (placebo):** Areas with continuous designation should show NO change at the boundary around 2014

## Expected Effects and Mechanisms

### Hypotheses

1. **Symmetric response:** Lost-status areas see price increases (stigma removal > investment loss) while gained-status areas see price decreases (stigma > investment). This supports a "stigma-dominant" model.

2. **Asymmetric response (hysteresis):** Lost-status areas see price declines (investment withdrawal > stigma removal) while gained-status areas see slow price increases. This supports an "investment-dominant" model with hysteresis.

3. **Null for de-designation:** Lost-status areas show no change, suggesting designation was irrelevant for market valuations. This would be a meaningful null.

### Mechanisms to test:
- **Investment channel:** Measure proximity to ANRU renovation projects as a heterogeneity dimension
- **Stigma channel:** Compare owner-occupied vs rental transactions (stigma affects demand composition more than physical housing stock)
- **Composition channel:** Test whether property types transacted shift after redesignation

## Primary Specification

```r
log(price_sqm) ~ gained_x_post + lost_x_post + retained_x_post
                  + inside_boundary
                  + property_controls
                  | boundary_id + year + commune_id
```

Where:
- `price_sqm`: Transaction price per square meter
- `gained_x_post`, `lost_x_post`, `retained_x_post`: Interaction of designation-change group x post-2014
- `inside_boundary`: Whether property is inside the zone boundary
- `boundary_id`: Fixed effect for each unique zone boundary segment
- Controls: surface area, rooms, property type, construction period

**Bandwidth:** Baseline = 500m from boundary (robustness: 200m, 1000m, 2000m)

## Power Assessment

- DVF covers ~3M transactions/year in France, 2014-2024
- ~1514 QPV zones (plus ~751 former ZUS zones)
- At 500m bandwidth, expect ~100-500 transactions per boundary-year
- Pooling across 1000+ boundaries x 10 years = hundreds of thousands of observations
- MDE likely < 2% of mean price/sqm --- adequate for detecting economically meaningful effects

## Planned Robustness Checks

1. **Bandwidth sensitivity:** 200m, 500m, 1000m, 2000m
2. **Donut RDD:** Exclude transactions within 50m of boundary (address precise sorting)
3. **McCrary density test:** Check for bunching of transactions at boundaries
4. **Covariate smoothness:** Test housing characteristics at boundary
5. **Event study:** Year-by-year boundary discontinuity estimates (2014-2024)
6. **Retained-zone placebo:** Confirm null effect for continuously designated areas
7. **Owner-occupied placebo:** Compare owner-occupied vs rental-sector transactions (stigma test)
8. **Alternative outcomes:** Number of transactions (liquidity effect)
9. **Heterogeneity:** By city size, distance to ANRU projects, income level of surrounding area

## Data Sources

| Source | Content | Access |
|--------|---------|--------|
| DVF (data.gouv.fr) | Universe property transactions 2014-2024 | Bulk CSV download |
| QPV shapefiles (data.gouv.fr) | 1514 QPV boundaries (2015 geography) | Shapefile download |
| ZUS shapefiles (data.gouv.fr) | 751 ZUS boundaries (1996 geography) | Shapefile download |
| ANRU project locations | Renovation project sites and timelines | To be verified |
| INSEE carroyage | 200m grid income data | Bulk download |

## Timeline and Execution Order

1. Fetch DVF bulk data (2014-2024)
2. Download QPV and ZUS shapefiles
3. Construct gained/lost/retained classification via spatial overlay
4. Match DVF transactions to zone proximity (distance to nearest boundary)
5. Run primary specification
6. Robustness checks and mechanism tests
7. Write paper
