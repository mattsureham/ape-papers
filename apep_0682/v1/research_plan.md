# Research Plan: Dirty Water, Cheap Houses?

## Research Question

Does the revelation of sewage spill frequency — through mandatory Event Duration Monitoring (EDM) on England's storm overflows — capitalize into nearby residential property values?

## Institutional Background

England's 10 Water and Sewerage Companies (WaSCs) discharge untreated sewage via ~14,000 storm overflows during heavy rainfall. Before EDM, the frequency and duration of these spills was unknown. The Environment Agency mandated staggered installation of Event Duration Monitors between 2016 and 2023, going from ~50% to 100% coverage. Annual Returns data, published each spring, revealed that many overflows spill hundreds of times per year — far more than the public expected. In 2023, 464,000 spills were recorded, lasting 3.6 million hours.

The key insight: **overflows were spilling before EDM, but nobody knew how much.** EDM installation did not change pollution levels — it revealed existing pollution. This cleanly separates the information channel from the pollution channel.

## Identification Strategy

**Staggered Difference-in-Differences.**

- **Unit:** Postcode district × year (postcode districts are the first half of a UK postcode, ~2,900 in England)
- **Treatment:** First year in which overflows within a postcode district have EDM monitoring data published (information shock)
- **Treatment variation:** Staggered 2016–2023 as WaSCs installed monitors at different overflows at different times
- **Control:** Postcode districts where overflows were already monitored (always-treated, used as never-treated relative to late adopters) and postcode districts with no storm overflows (pure controls)
- **Outcome:** Log mean transaction price from HM Land Registry PPD
- **Estimator:** Callaway & Sant'Anna (2021) with not-yet-treated as control group

**Key identification assumption:** The timing of EDM installation across overflows was driven by engineering logistics (accessibility, WaSC investment plans, EA prioritization of largest overflows) — not by local housing market conditions.

## Expected Effects

- **Negative price effect** for properties near high-spill overflows once monitoring data is published
- **Heterogeneity by spill intensity:** Stronger capitalization where revealed spills are more frequent/prolonged
- **Heterogeneity by property type:** Flats (more urban) may respond less than detached houses (more exposed to local water quality)
- **Placebo:** No effect on properties far from overflows in the same postcode district

## Primary Specification

```
log(price_pdt) = α_pd + γ_t + β × EDM_revealed_pdt + X_pdt'δ + ε_pdt
```

Where pd indexes postcode district, t indexes year, and EDM_revealed is an indicator for whether the postcode district's overflows have published monitoring data.

## Data Sources

1. **EDM Storm Overflow Annual Returns** (Environment Agency, data.gov.uk)
   - Overflow-level: grid reference, WaSC, spill count, spill duration, monitoring status
   - Years: 2020–2024 (earlier years have partial coverage)
   - ~14,000+ overflows

2. **HM Land Registry Price Paid Data** (gov.uk)
   - Transaction-level: price, date, postcode, property type, new/existing
   - Years: 2016–2024 for the analysis window
   - ~1M transactions/year in England

3. **ONS National Statistics Postcode Lookup (NSPL)**
   - Postcode → LSOA → LA → lat/lon → postcode district mapping

## Robustness Checks

1. Pre-trend test: event study coefficients for t-4 through t-1 should be zero
2. Dose-response: interact treatment with revealed spill count/duration
3. Distance gradient: effects should attenuate with distance from overflow
4. Placebo: no effect in postcode districts without overflows
5. Property type heterogeneity
6. Callaway & Sant'Anna with different control groups (not-yet-treated vs never-treated)

## Key Risk

Data parsing complexity — EDM Annual Returns are published as spreadsheets with per-WaSC sheets. May need manual column alignment across years. Mitigation: start with 2020–2024 data where format is more standardized.
