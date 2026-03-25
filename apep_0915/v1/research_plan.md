# Research Plan: Regulatory Escape Hatches — HAP Emission Bunching After the OIAI Reversal

## Research Question

Did the EPA's January 2018 withdrawal of the "Once In Always In" (OIAI) guidance cause facilities to strategically reduce reported HAP emissions below Clean Air Act major source thresholds? This tests whether environmental regulatory escape hatches create measurable strategic behavior in emissions reporting.

## Policy Background

Under Clean Air Act Section 112, facilities emitting ≥10 tons/year of any single HAP or ≥25 tons/year of combined HAPs are classified as **major sources**, subject to costly Maximum Achievable Control Technology (MACT) standards. In 1995, EPA issued OIAI guidance: once classified as major, always major — regardless of subsequent emission reductions. On **January 25, 2018**, EPA Administrator Pruitt withdrew this guidance, allowing major sources to reclassify as "area sources" by reducing emissions below thresholds. This created a sharp incentive change for ~66,000 facilities.

## Identification Strategy

**Difference-in-bunching design:**
1. Estimate the distribution of facility-level HAP emissions around the 10-ton single-HAP threshold in the **pre-period** (2012–2017, OIAI in effect) and **post-period** (2018–2021, OIAI withdrawn)
2. Compare excess mass below the threshold across regimes using the Chetty et al. (2011) / Kleven (2016) bunching estimator
3. The change in bunching identifies strategic responses to the OIAI withdrawal

**Placebos:**
- **Criteria air pollutant thresholds** (e.g., 100 tons/year VOC for major source under Title V) — NOT affected by OIAI change
- **Below-median HAP emitters** — too far from threshold to respond

**Additional tests:**
- Heterogeneity by industry (NAICS) and state regulatory stringency
- Event-study specification around the 2018 threshold

## Data Sources

1. **EPA National Emissions Inventory (NEI) Facility Summaries** (2012–2021): facility-level annual HAP emissions. ~66,000 facilities/year, ~2M rows per year. Source: gaftp.epa.gov CSV files.
2. **EPA AQS** (if feasible): ambient air quality monitors for mechanism tests.

## Expected Effects

- **Increased bunching below 10-ton threshold post-2018**: facilities that were marginal major sources now have incentive to reduce (or underreport) emissions just below the cutoff
- **Effect magnitude**: literature on regulatory thresholds suggests 5–15% excess mass; the OIAI withdrawal may produce larger bunching since it created a new escape option for existing major sources
- **Mechanism**: real emission reductions vs. strategic reporting (testable via ambient air quality data)

## Primary Specification

Bunching estimator following Kleven (2016):
- Running variable: facility-level single-HAP emissions (tons/year) relative to 10-ton threshold
- Bandwidth: 2–15 tons around threshold
- Counterfactual: polynomial fit excluding bunching window
- Treatment: post-2018 indicator
- Standard errors: bootstrap (facility-level resampling)

DiD regression complement:
- Y_it = 1(emissions < 10 tons) for facilities near threshold
- Treatment: Post_2018 × NearThreshold
- FE: facility, year
- Clustering: state level

## Exposure Alignment

The OIAI withdrawal affected all facilities classified as major sources under CAA Section 112. The "treated" population is facilities with HAP emissions near the major-source thresholds (10 tons single HAP, 25 tons combined), who now have a financial incentive to reduce emissions below the threshold and reclassify as area sources. Facilities far below the thresholds were never major sources and are unaffected. Facilities far above the thresholds face prohibitively high abatement costs and are effectively untreated. The DiD design exploits this heterogeneous exposure: "near-threshold" facilities (pre-period average 7-13 tons for the 10-ton analysis) are the treated group, while "far-from-threshold" facilities serve as controls. The bunching design does not require group assignment — it identifies behavioral responses from the shape of the full emission distribution.

## Risks and Mitigations

| Risk | Mitigation |
|------|-----------|
| NEI data availability | Smoke test confirms 2012–2021 CSVs available |
| Small bunching window sample | 2,000–5,000 facilities near threshold per year |
| Reporting frequency (NEI is triennial for some facilities) | Use facility summaries which are annual compilations |
| Real vs. reported emissions | Frame as "reported emission bunching" — real effects are a separate mechanism test |
