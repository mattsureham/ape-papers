# Initial Research Plan: Do Low-Emission Zones Price Out the Poor?

## Research Question
Do France's Zones a Faibles Emissions (ZFEs) capitalize into housing prices, and is this effect regressive — disproportionately raising prices of smaller, more affordable properties?

## Identification Strategy
**Boundary Difference-in-Differences** with staggered city-level adoption timing.

### Design
- **Unit:** Property transaction within 2km of any ZFE boundary
- **Treatment:** Inside ZFE boundary x Post-ZFE adoption
- **Control:** Properties just outside ZFE boundary in same city, pre-adoption transactions
- **Staggered timing:** 11 cities adopted ZFEs between 2016 and 2024
- **Estimator:** Callaway & Sant'Anna (2021) with city-level treatment cohorts

### Exposure Alignment
- **Who is treated:** Property transactions within ZFE perimeters, after city-level ZFE adoption
- **Primary estimand:** ATT on log(price/m2) for treated properties
- **Placebo population:** Commercial properties within ZFE (should not respond to residential amenity)
- **Design:** Boundary DiD (spatial discontinuity x temporal adoption)

## ZFE Cities and Adoption Timeline
| City | Department | ZFE Start | Crit'Air Tiers Excluded |
|------|-----------|-----------|------------------------|
| Paris (Grand Paris) | 75/92/93/94 | 2017-01 | 5, then progressive |
| Grenoble | 38 | 2019-05 | 4-5 |
| Lyon | 69 | 2020-01 | 4-5, then progressive |
| Rouen | 76 | 2021-09 | 4-5 |
| Toulouse | 31 | 2022-03 | 5, then progressive |
| Nice | 06 | 2022-01 | 5 |
| Marseille | 13 | 2022-09 | 5 |
| Montpellier | 34 | 2022-07 | 5 |
| Saint-Etienne | 42 | 2022-01 | 5 |
| Clermont-Ferrand | 63 | 2023-01 | 5 |
| Reims | 51 | 2023-01 | 5 |

Note: Strasbourg excluded — DVF does not cover Bas-Rhin (Alsace-Moselle legal exception).

## Expected Effects and Mechanisms
1. **Air quality improvement** (first stage): ZFE adoption → reduced NO2/PM2.5 within zone
2. **Price capitalization** (main): Improved amenity → higher WTP → positive price effect inside vs. outside
3. **Regressive incidence** (distributional): Small/affordable properties may see larger % price increase if demand shifts inward
4. **Spillovers**: Traffic displacement may worsen air quality just outside → negative externality on boundary properties

**Expected signs:**
- Inside x Post on log(price/m2): positive (3-8% based on LEZ literature)
- Stronger for residential than commercial (placebo)
- Potentially larger % effect for small apartments
- Negative or zero just outside boundary (spillover test)

## Primary Specification
```
log(price_m2)_{i,c,t} = alpha + beta * Inside_ZFE_{i} x Post_{c,t}
                       + X_{i} * gamma + delta_c + theta_t + epsilon_{i,c,t}
```
Where:
- i = transaction, c = city, t = year-quarter
- Inside_ZFE = property within ZFE boundary
- Post = after city c's ZFE adoption date
- X = hedonic controls (area, rooms, property type, building age)
- delta_c = city FE
- theta_t = year-quarter FE

CS-DiD version: treatment cohorts defined by city adoption year-quarter.

## Planned Robustness Checks
1. **Bandwidth robustness:** 500m, 1km, 2km, 5km from ZFE boundary
2. **Repeat-sales:** Parcel FE restricting to parcels with 2+ transactions
3. **Donut specification:** Exclude properties within 200m of boundary
4. **Placebo outcomes:** Commercial/mixed-use properties
5. **Placebo boundaries:** Administrative borders within ZFE cities
6. **Event-study:** Dynamic effects showing pre-trend coefficients
7. **Randomization inference:** Permute treatment timing across cities
8. **Distance gradient:** Concentric ring analysis (spillover test)
9. **Hedonic decomposition:** Interact treatment with property size quintiles

## Power Assessment
- **Pre-treatment periods:** 3-8 years (DVF starts 2014, earliest ZFE is 2017)
- **Treated clusters:** 11 cities (with hundreds of communes inside ZFE boundaries)
- **Post-treatment periods:** 1-7 years depending on city
- **Estimated N:** ~500,000+ transactions within 2km of ZFE boundaries across all cities and years
- **MDE:** With N~500K and within-boundary variation, should detect effects of 1-2% on log prices

## Data Sources
1. **DVF** (bulk CSV from cadastre.data.gouv.fr): Universe property transactions 2014-2024, geocoded
2. **BNZFE** (transport.data.gouv.fr): National ZFE boundary GeoJSON
3. **Open-Meteo / CAMS**: Hourly NO2, PM2.5 at city coordinates (first stage)
4. **Optional:** INSEE FILOSOFI commune-level income data (distributional context)

## Hardware Constraints
8GB RAM, 8 cores. Strategy:
- Download DVF by department (not national)
- Filter to transactions within 5km of ZFE boundaries immediately
- Use data.table for memory-efficient processing
- Process cities sequentially if needed
