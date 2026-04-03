# Research Plan: The Regulatory Rebound — Seismic Risk, Production Caps, and Housing Price Recovery in Groningen

## Research Question

How did the Dutch government's production cap decisions — triggered by induced seismicity from Europe's largest onshore gas field — affect housing prices across municipalities near Groningen, and does the pattern of price recovery reveal how markets value regulatory commitment to risk reduction?

## Key Contribution

Bosker, Garretsen, Marlet, and van Woerkens (JEEA, 2019) documented the housing price decline in Groningen municipalities following the Huizinge M=3.6 earthquake (August 2012). We extend this by studying what happened *after* the government imposed production caps (2014-2019): did prices recover, and did recovery vary by proximity to the epicenter? The novel object is the **regulatory rebound** — the rate at which markets re-price risk following credible government intervention.

This frames against a mistaken benchmark: the conventional wisdom treats earthquake-zone housing discounts as permanent risk premia. We test whether regulatory action (production caps that mechanically reduced earthquake frequency) reversed the discount, and how quickly.

## Identification Strategy

### Design: Continuous Treatment DiD (Spatial Event Study)

- **Event:** Huizinge M=3.6 earthquake (August 16, 2012) — the seismic event that triggered the political response
- **Treatment intensity:** Inverse distance from each municipality centroid to the Huizinge epicenter (53.348°N, 6.664°E)
- **Outcome:** Annual municipality-level housing prices (CBS 83625NED)
- **Sample:** All ~350 Dutch municipalities, 1997-2023
- **Pre-period:** 1997-2012 (15 years)
- **Post-period:** 2013-2023 (10 years, spanning all 7 cap decisions)

### Specification

Primary: log(house_price_it) = α_i + γ_t + Σ_k β_k × (1/distance_i) × 1(year = k) + ε_it

Where α_i are municipality FE, γ_t are year FE, and β_k traces out the dynamic treatment effect by proximity.

### Expected Pattern

1. Pre-2012: flat β_k (no differential trends by proximity)
2. 2012-2014: negative β_k (price decline near epicenter after Huizinge)
3. 2014-2019: recovering β_k (production caps reduce seismic activity → prices rebound)
4. Post-2019: full or partial recovery (field closure announced March 2018, completed October 2023)

### Key Robustness

1. **Donut test:** Drop municipalities within 10km of epicenter (to rule out direct damage effects vs risk pricing)
2. **Placebo epicenters:** Assign treatment intensity using randomly placed epicenters elsewhere in the Netherlands
3. **Non-Groningen earthquake zones:** Test for differential trends in other Dutch regions with no induced seismicity
4. **Distance bins:** Replace continuous treatment with 0-20km, 20-50km, 50-100km, >100km bins
5. **Earthquake intensity control:** Include cumulative PGA (peak ground acceleration) as time-varying treatment

### Mechanism Tests

1. **Production-earthquake link:** Show that cap decisions causally reduced earthquake frequency (production → earthquakes is physically determined)
2. **Media salience:** Test whether post-Zeerijp (Jan 2018) recovery accelerated relative to post-Huizinge trajectory

## Data Sources

| Data | Source | Access | Unit |
|------|--------|--------|------|
| Housing prices | CBS 83625NED (OData API) | Public, no auth | Municipality × year |
| Earthquakes | KNMI FDSN webservice | Public, no auth | Event-level (lat/lon/mag/date) |
| Gas production | NLOG portal | Public | Monthly field-level |
| Municipality centroids | CBS geographic data | Public | Municipality |

## Falsification

- Pre-2012 trends should be parallel across distance bins
- Municipalities at >200km from Groningen should show zero treatment effect
- Non-residential property prices (if available) should show smaller effects (less risk-salience for non-occupants)

## Exposure Alignment

The treatment (inverse distance to the Huizinge epicenter) is measured at the municipality level, which matches the level at which housing prices are observed (CBS 83625NED reports municipality-year averages). Earthquake shocks are physically experienced at the municipality level — structural damage, ground shaking, and perceived risk all vary continuously with distance from the epicenter. The outcome (housing prices) is determined at the same spatial level through local housing markets. This alignment ensures that the unit of treatment exposure matches the unit of outcome measurement. However, we note that within-municipality variation in earthquake exposure (e.g., between neighborhoods closer vs farther from fault lines) is not captured by our municipality-centroid distance measure.

## What This Design Can and Cannot Identify

**Can identify:** The differential housing price trajectory of municipalities near vs far from the Groningen gas field, before and after the onset of induced seismicity and subsequent regulatory response.

**Cannot identify:** Whether price changes reflect pure risk updating, amenity effects (e.g., construction damage), or composition changes in housing stock. We interpret through the lens of risk capitalization, supported by the production-cap mechanism test (caps → fewer earthquakes → price recovery).
