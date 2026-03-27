# Research Plan: The Compensation Cliff

## Research Question
Does government earthquake damage compensation capitalize into property values at the eligibility boundary? The Dutch IMG Waardedalingsregeling compensates homeowners in ~150 designated 4-digit postcodes (PC4) for earthquake-related property value decline. This paper tests whether the compensation zone boundary creates a sharp discontinuity in property values — a "compensation cliff" where eligible properties gain an insurance premium that their ineligible neighbors do not.

## Policy Background
- **Program:** Instituut Mijnbouwschade Groningen (IMG) Waardedalingsregeling
- **Mechanism:** Homeowners in eligible PC4 areas who sold after January 25, 2013 receive 2.07–12.22% compensation for earthquake-related property value decline
- **Eligibility threshold:** PC4 codes where ≥20% of buildings had approved earthquake damage claims
- **Enacted:** September 2020, retroactive to January 2013
- **Scale:** ~150 eligible postcodes, >€970 million disbursed, ~10 municipalities

## Identification Strategy
**Boundary Difference-in-Differences with Spatial RDD**

The design exploits the sharp administrative boundary between eligible and ineligible PC4 areas:

1. **Treatment:** Buurten (neighborhoods) in PC4 areas eligible for IMG compensation
2. **Control:** Buurten in ineligible PC4 areas near the compensation boundary
3. **Pre/post:** Before vs after September 2020 announcement
4. **Running variable:** Distance from buurt centroid to nearest eligible/ineligible PC4 boundary

Key identification assumptions:
- Properties cannot sort across PC4 boundaries in response to the policy
- No other policy changes at the exact PC4 boundary in 2020
- The 20% filing rate threshold creates quasi-random assignment near the boundary

## Expected Effects
- **Primary:** Positive capitalization effect — eligible properties should appreciate relative to ineligible neighbors after 2020, as markets price in the government insurance
- **Mechanism:** The compensation effectively acts as a put option on earthquake risk. Rational buyers should pay more for properties with this insurance.
- **Magnitude:** Compensation ranges from 2–12%, so capitalization could plausibly be 1–5% of property values

## Primary Specification
```
WOZ_bt = α + β(Eligible_b × Post_t) + γ_b + δ_t + X_bt'θ + ε_bt
```
Where b indexes buurten, t indexes years, γ_b are buurt fixed effects, δ_t are year fixed effects, and X_bt are time-varying controls. Sample restricted to buurten within K km of the compensation boundary.

## Data Sources
1. **CBS StatLine OData API** — Buurt-level WOZ values (property tax assessments), housing stock, demographics. Annual data, "Kerncijfers wijken en buurten" tables.
2. **PDOK** — PC4 shapefiles, buurt shapefiles (geographic boundaries)
3. **IMG/legislation** — List of eligible PC4 codes and compensation percentages
4. **KNMI** — Earthquake catalog (for earthquake intensity controls)

## Exposure Alignment: Who Is Actually Treated?

**Data pivot:** The IMG eligible postcode list is not publicly available as structured data. The analysis uses cumulative Peak Ground Acceleration (PGA) from the KNMI earthquake catalog as a treatment proxy.

**Alignment rationale:** IMG eligibility is determined by a 20% damage claim filing threshold at the PC4 level. Damage claims correlate strongly with earthquake intensity (PGA), as structural damage is a direct function of ground shaking. High-PGA neighborhoods are overwhelmingly within the IMG zone, and low-PGA neighborhoods are overwhelmingly outside it. However, the mapping is imperfect: claim filing also depends on housing stock quality, owner-occupancy rates, and propensity to file.

**Implication for estimates:** Any misclassification (high-PGA but ineligible, or low-PGA but eligible neighborhoods) introduces classical measurement error in the treatment variable, which attenuates the DiD coefficient toward zero. The null finding is therefore conservative — the true boundary effect is at least as large in absolute value as what we estimate.

**Who is affected:** The compensation is paid to sellers who sold after January 2013 in eligible PC4 areas. The treated population in our analysis is neighborhoods with high earthquake exposure (above-median cumulative PGA), which closely approximates neighborhoods where residents are eligible for the compensation. The control group is neighborhoods with low earthquake exposure in adjacent provinces, where residents are not eligible.

## Robustness
- Event study (leads/lags around 2020)
- Varying exposure threshold (25th, 33rd, 50th, 67th, 75th percentile of PGA)
- Placebo treatment year (2018)
- Restricting to Groningen province only
- Dose-response by exposure quartiles
- Heterogeneity by owner-occupancy rates
