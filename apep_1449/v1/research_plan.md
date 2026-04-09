# Research Plan: Fishing by Moonlight

## Research Question
Do subsidized fishing fleets persist through deterministic low-productivity periods that unsubsidized fleets avoid? The 29.5-day lunar cycle mechanically reduces squid jigging catch rates during full moon periods (vessel lights cannot compete with moonlight). If subsidies insulate effort from productivity signals, subsidized fleets should show muted lunar-cycle response — fishing through the moon while unsubsidized fleets rest.

## Identification Strategy
**Continuous treatment design.** The lunar illumination fraction (0 = new moon, 1 = full moon) is a perfectly predictable, exogenous productivity shifter for squid jigging. Unlike wage variation in the taxi/bike messenger literature, the lunar cycle is known centuries in advance and varies identically across all vessels in a region on a given night.

**Main specification:**
log(fishing_hours_{it}) = β × lunar_illumination_t + X_{it}γ + α_i + δ_m + ε_{it}

where i indexes vessel/grid-cell, t indexes day, α_i are unit fixed effects, δ_m are calendar-month or year-month fixed effects, and X includes SST, distance from port, and day-of-week.

**Key heterogeneity:** β_Chinese vs β_non-Chinese (Korean, Taiwanese, Japanese). If subsidies create effort persistence, |β_Chinese| < |β_non-Chinese|.

**Falsification:**
1. Trawlers and longliners (light-independent gear) should show no lunar response
2. Daytime fishing hours should show no lunar response
3. Effect should be stronger in winter (longer nights → more exposure)

## Expected Effects
- Large negative effect of lunar illumination on squid jigging effort (CPUE near-zero at full moon per Niu et al. 2024)
- Muted response for Chinese (subsidized) fleet vs Korean/Taiwanese (unsubsidized)
- Null effect for non-light-dependent gear types (trawlers, longliners)

## Data Source and Fetch Strategy
**Global Fishing Watch v3.0** on Zenodo (DOI: 10.5281/zenodo.14625646 or similar). 
- Daily 0.01° resolution, 2012-2024
- Fields: date, lat, lon, flag, geartype, fishing_hours
- Squid_jigger gear type pre-classified
- Vessel registry CSV (115 MB) for flag/gear metadata

**Lunar ephemeris:** R package `suncalc` or `lunar` computes illumination fraction for any date.

**Strategy:** Download 2-3 representative annual files first to validate schema, then process all years. Aggregate to vessel-day or flag-day level to keep analysis tractable.
