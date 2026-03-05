# Initial Research Plan: Does Insurance Make Markets Resilient?

## Research Question

How much of the flood-risk property discount reflects insurance market failure vs. actuarial risk pricing? Does guaranteed access to affordable flood insurance (via Flood Re) capitalize into property values?

## Policy Background

Flood Re is a UK government-backed reinsurance scheme that launched on April 4, 2016 (announced in the Water Act 2014, Royal Assent May 14, 2014). It ensures all eligible residential properties can access affordable flood insurance with premiums capped by Council Tax band (£46-£540/year). Eligibility: residential properties built before January 1, 2009, with Council Tax bands A-H. Approximately 350,000 properties benefit. Before Flood Re, insurers could refuse coverage or charge prohibitive premiums for flood-risk properties, creating uninsurability that depressed property values.

## Identification Strategy

### Main DiD (Specification 1)
Compare property prices in flood-risk postcodes (High/Medium risk per EA) vs. non-flood-risk postcodes, before vs. after April 2016.

$$\ln(P_{ipt}) = \alpha + \beta \cdot \text{FloodRisk}_p \times \text{Post2016}_t + \gamma X_{ipt} + \delta_p + \mu_t + \epsilon_{ipt}$$

Where $i$ = transaction, $p$ = postcode, $t$ = year-quarter. $\delta_p$ = postcode sector FE, $\mu_t$ = year-quarter FE. $X_{ipt}$ = property type, freehold/leasehold, new/old.

### Triple-Diff (Specification 2, preferred)
Within flood-risk postcodes, compare Flood-Re-eligible (pre-2009 build) vs. ineligible (post-2009 build) properties, before vs. after 2016.

$$\ln(P_{ipt}) = \alpha + \beta_1 \cdot \text{FloodRisk}_p \times \text{Post2016}_t + \beta_2 \cdot \text{FloodRisk}_p \times \text{Post2016}_t \times \text{Eligible}_i + \gamma X_{ipt} + \text{FEs} + \epsilon_{ipt}$$

$\beta_2$ is the insurance-access effect, purged of any flood-zone-specific trends.

### Dose-Response (Specification 3)
Flood Re premiums vary by Council Tax band. The implicit subsidy (market premium - Flood Re cap) is larger for higher-band properties in absolute terms but larger for lower-band properties as a percentage of value. Use CT band as a dose variable.

### Event Study (Specification 4)
Year-by-year relative time indicators for the flood-risk × year interaction, with base year 2013 (pre-announcement).

## Expected Effects and Mechanisms

1. **Price level (intensive margin):** Property prices in flood-risk areas should increase relative to non-flood-risk areas after 2016, as the insurance-access barrier is removed. Expected: +2-8% for high-risk areas.

2. **Transaction volume (extensive margin):** More transactions in flood-risk areas post-2016, as previously unsellable properties (due to lack of mortgageable insurance) become sellable. This is the "volume first stage."

3. **Price dispersion:** The flood-risk discount should become more uniform post-2016 (less variation driven by idiosyncratic insurance quotes).

4. **Repeat sales convergence:** Properties in flood-risk areas that transact both pre and post 2016 should show faster appreciation than similar properties in non-flood areas.

## Primary Specification

Triple-diff with:
- Treatment: EA flood-risk postcode (High or Medium risk)
- Time: Post April 2016 (quarterly)
- Eligibility: First observed in Land Registry before 2009 (eligible) vs. first observed as new build after 2009 (ineligible)
- FEs: Postcode sector + year-quarter + property type
- Clustering: Local Authority District

## Exposure Alignment (DiD Checks)

- **Who is actually treated?** Residential property owners/buyers in EA-designated flood-risk postcodes who are eligible for Flood Re.
- **Primary estimand population:** All residential transactions in England 2010-2025.
- **Placebo/control population:** (1) Non-flood-risk postcode properties; (2) Post-2009 build properties in flood-risk postcodes (ineligible for Flood Re).
- **Design:** Triple-difference (DiD × eligibility).

## Power Assessment

- **Pre-treatment periods:** 6+ years (2010-2016), 24+ quarterly periods
- **Treated clusters:** ~300 Local Authority Districts containing flood-risk postcodes
- **Post-treatment periods:** 9+ years (2016-2025), 36+ quarterly periods
- **Estimated observations:** 50,000-150,000 transactions in flood-risk postcodes over the full panel; millions in control postcodes
- **MDE:** With this sample size and variation, likely powered to detect effects of 1-2% or smaller

## Planned Robustness Checks

1. **Pre-trends:** Event study with Rambachan-Roth sensitivity
2. **Placebo outcomes:** Commercial property prices (not covered by Flood Re)
3. **Placebo timing:** Assign fake treatment at 2012 or 2014
4. **Alternative flood-risk definitions:** Use "Low" risk as treated (weaker treatment), "Very Low" as control
5. **Exclude London:** London housing market may have different dynamics
6. **Donut specification:** Exclude postcodes at flood-zone boundaries
7. **Heterogeneity by:** property type (detached/semi/terrace/flat), region, Council Tax band, actual flood history
8. **Bacon decomposition:** Check for negative weights in staggered setting (though treatment timing is uniform)
9. **Repeat-sales subsample:** Property FE for within-property estimation
10. **EPC-based eligibility:** Use EPC construction age bands as alternative measure of Flood Re eligibility

## Data Sources

1. **HM Land Registry Price Paid Data:** Yearly CSVs, 1995-2025, ~150MB/year. Columns: transaction ID, price, date, postcode, property type, old/new, tenure, address, district, county, PPD category.
2. **EA Risk of Flooding from Rivers and Sea — Postcodes in Areas at Risk:** CSV, ~4.7MB. Columns: postcode, flood risk band (High/Medium/Low/Very Low), easting, northing, lat/lng.
3. **postcodes.io:** Postcode → LSOA, Local Authority, region mapping for geographic FEs.
4. **EPC Open Data (robustness):** Energy Performance Certificate registers with construction age bands.
