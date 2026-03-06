# Initial Research Plan: When the Train Doesn't Come

## Research Question

Does the surprise cancellation of HS2 Phase 2 (Birmingham to Manchester/Leeds) on 4 October 2023 reduce residential property values near cancelled station sites, and does the cancellation simultaneously relieve construction-corridor blight for route-adjacent properties?

## Identification Strategy

**Design:** Event-study difference-in-differences around the 4 October 2023 announcement.

**Treatment:** Properties within distance rings (1, 2, 5, 10 km) of the 6 cancelled Phase 2 station sites:
- Manchester Piccadilly HS2
- Manchester Airport HS2
- Crewe HS2 Hub
- East Midlands Hub (Toton/Broxtowe)
- Meadowhall (Sheffield)
- Leeds HS2

**Controls (nested):**
1. **Within-project control (primary):** Properties near Phase 1 stations (London-Birmingham corridor), which continue under construction. Same project, same macro environment, different cancellation shock.
2. **Adjacent-area control:** Properties in the same regions (Greater Manchester, West Yorkshire, East Midlands) but >20km from any HS2 route, matched on pre-treatment price trends.
3. **Distance gradient:** Properties 20+ km from any cancelled station should show no effect (built-in falsification).

**Estimator:** Two-period DiD (pre: Q1 2021 – Q3 2023; post: Q4 2023 – Q4 2024) with event-study extension using quarterly dummies.

## Exposure Alignment

- **Who is treated?** Residential property sellers/buyers near cancelled Phase 2 stations. The treatment is an information shock — loss of anticipated future accessibility improvements.
- **Primary estimand:** ATT on log transaction prices for properties within 5km of cancelled stations.
- **Placebo population:** Properties near Phase 1 stations (still proceeding) and properties >20km from any HS2 route.
- **Design:** Standard two-group DiD with distance-based treatment intensity.

## Expected Effects and Mechanisms

**Near stations (negative):** Properties within 5km of cancelled stations should decline in value. Mechanism: loss of anticipated travel-time reductions (Manchester-London: 1h08 → 2h07; Leeds-London: 1h21 → 2h15). Expected magnitude: 2-5% based on transit capitalization literature (Gibbons & Machin 2005 find ~4.5% premium per station within 2km).

**Along corridor, far from stations (ambiguous/positive):** Properties along the safeguarded route but >5km from stations may rise in value. Mechanism: cancellation removes construction blight (noise, uncertainty, compulsory purchase threat). Expected magnitude: 1-3%.

**Dose-response:** Effects should decay with distance from cancelled stations and be zero for properties >20km away.

## Primary Specification

```
log(price_ijt) = α + β₁(Post_t × NearStation_i) + β₂(Post_t × AlongRoute_i)
                 + γ × X_it + δ_j + θ_t + ε_ijt

where:
  i = property, j = postcode, t = year-quarter
  NearStation = within 5km of cancelled Phase 2 station
  AlongRoute = on safeguarded route corridor but >5km from station
  X_it = property type, new/old, freehold/leasehold
  δ_j = postcode fixed effects
  θ_t = year-quarter fixed effects
  Clustered SEs at local authority level
```

## Power Assessment

- **Pre-treatment periods:** 11 quarters (Q1 2021 – Q3 2023)
- **Post-treatment periods:** 5 quarters (Q4 2023 – Q4 2024)
- **Treated units:** ~50,000 transactions/year within 10km of cancelled stations; ~20,000 within 5km
- **Cluster count:** ~25 local authorities along Phase 2 corridor
- **MDE:** With ~80,000 treated transactions (2021-2024), ~600,000 control transactions, and 25 clusters, we can detect effects as small as 1.5-2% at 5% significance (conservative with wild cluster bootstrap).

## Planned Robustness Checks

1. **Pre-trend validation:** Quarterly event-study coefficients for 2021-Q3 2023 should be jointly insignificant
2. **Alternative distance rings:** 1km, 2km, 5km, 10km — effects should attenuate with distance
3. **Phase 1 placebo:** Same specification applied to Phase 1 stations (no cancellation) should yield null
4. **Eastern leg sub-analysis:** Leeds branch was curtailed Nov 2021; test for earlier partial anticipation
5. **Wild cluster bootstrap:** Address few-cluster concern (~25 treated LAs)
6. **Conley spatial HAC:** Standard errors robust to spatial correlation (10, 25, 50km cutoffs)
7. **Property-type heterogeneity:** Separate effects for detached, semi-detached, terraced, flat
8. **Repeat-sales subsample:** Restrict to postcodes × property-type cells with transactions in both pre and post periods
9. **Randomization inference:** Permute cancellation across comparable cities
10. **Exclude London:** Phase 1 corridor includes London area — test sensitivity to this high-price control

## Data Sources

| Source | Purpose | Access |
|--------|---------|--------|
| HM Land Registry PPD | Outcome: transaction prices | Bulk CSV download, no auth |
| ONS NSPL | Postcode → LSOA/LA geocoding | Bulk download |
| postcodes.io | Postcode → lat/lng coordinates | Free API |
| HS2 Ltd route maps | Treatment definition | GOV.UK public |
| NOMIS | Control variables (earnings, unemployment by LA) | API, guest access |
| Companies House | Mechanism: firm formation near stations | Bulk CSV |

## Timeline

1. Data acquisition: Fetch Land Registry PPD 2021-2024, NSPL lookup, station coordinates
2. Treatment assignment: Geocode all transactions, compute distance to cancelled/Phase 1 stations
3. Main analysis: DiD with postcode FE, event study
4. Robustness: Distance rings, wild bootstrap, Conley SEs, RI
5. Mechanisms: Corridor blight decomposition, firm formation, property type heterogeneity
6. Paper writing: 25-30 pages, submission-ready
