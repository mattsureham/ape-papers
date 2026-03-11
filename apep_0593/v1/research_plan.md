# Initial Research Plan: Roaming Abolition and Cross-Border Tourism

## Research Question

Did the EU's 2017 "Roam Like at Home" regulation — which eliminated retail mobile roaming surcharges across the EEA — increase cross-border tourism in border regions relative to interior regions?

## Identification Strategy

**Spatial Difference-in-Differences.** The regulation took effect on June 15, 2017 simultaneously across all EU member states. I exploit spatial variation in exposure: NUTS2 regions sharing internal EU land borders should benefit more from roaming abolition (because cross-border travel — day trips, short stays — is more common there) than interior NUTS2 regions where international travel requires flights and longer-distance planning, making roaming costs a smaller fraction of total trip cost.

- **Treatment group:** ~80-100 NUTS2 regions adjacent to internal EU land borders
- **Control group:** ~170+ interior NUTS2 regions without land borders to other EU countries
- **Treatment timing:** June 2017 (single sharp date, no staggering)
- **Pre-treatment window:** 2012-2016 (5 years)
- **Post-treatment window:** 2017-2019 (avoiding COVID contamination)

**Treatment intensity (continuous):** Pre-treatment share of foreign tourist nights from neighboring EU countries. Regions with higher pre-treatment cross-border tourism share should respond more.

## Expected Effects and Mechanisms

**Primary channel:** Roaming costs acted as a transaction cost for cross-border travel. At typical 2016 rates, a weekend trip could incur €20-50 in roaming charges — meaningful for short stays where total trip cost is €100-300. Removing this cost reduces the price of cross-border travel, particularly for:
- Day trips and weekends (where roaming costs are proportionally highest)
- Young and budget-conscious travelers (who were most likely to switch phones off or avoid data)
- Border regions where the alternative is a domestic trip with no roaming concern

**Expected sign:** Positive effect of RLAH on foreign tourist nights in border regions.

**Magnitude calibration:** BEREC reports show EU roaming data traffic increased 490% between June 2016 and June 2018. If even 5-10% of this reflects new trips (vs. existing travelers using more data), border regions should see a 2-5% increase in foreign tourist nights.

## Primary Specification

$$\text{ForeignNights}_{r,t} = \beta \cdot (\text{Border}_r \times \text{Post}_t) + \alpha_r + \gamma_t + \varepsilon_{r,t}$$

Where:
- $r$ indexes NUTS2 regions, $t$ indexes years
- $\text{Border}_r = 1$ if region shares an internal EU land border
- $\text{Post}_t = 1$ for $t \geq 2017$
- $\alpha_r$ = region fixed effects, $\gamma_t$ = year fixed effects
- Clustering: two-way (region and year) or country-level

**Continuous treatment variant:**

$$\text{ForeignNights}_{r,t} = \beta \cdot (\text{CrossBorderShare}_{r,\text{pre}} \times \text{Post}_t) + \alpha_r + \gamma_t + \varepsilon_{r,t}$$

## Planned Robustness Checks

1. **Pre-trend test:** Event-study with annual leads 2012-2016 (joint F-test)
2. **Rambachan-Roth sensitivity:** Bound parallel-trend violations
3. **Placebo outcomes:**
   - Domestic tourist nights (should show null)
   - Extra-EEA tourist nights (should show null — RLAH doesn't apply)
4. **Placebo geography:** External EU border regions (EU-non-EU borders)
5. **Within-country variation:** Country fixed effects interacted with year
6. **Leave-one-country-out:** Sensitivity to individual country exclusion
7. **Matching:** CEM on pre-treatment levels to improve balance
8. **Alternative treatment definitions:**
   - Binary border indicator
   - Distance to nearest EU internal border (continuous)
   - Pre-treatment cross-border tourism share (continuous)
9. **COVID robustness:** Extend to 2022 with COVID controls vs. truncate at 2019

## Data Sources

1. **Eurostat tour_occ_nin2:** Foreign tourist nights by NUTS2 region, 2012-2022
2. **Eurostat tour_occ_nin2d:** Tourist nights by country of residence (for intra-EEA vs extra-EEA decomposition)
3. **Eurostat nama_10r_3gdp:** NUTS3 GDP for secondary outcome
4. **Eurostat demo_r_pjanaggr3:** Population for controls
5. **GISCO shapefiles:** NUTS2 boundaries for border classification
6. **BEREC reports:** Aggregate roaming traffic data (mechanism)

## Paper Structure

1. Introduction (salience hook: a German tourist in Strasbourg unable to check her hotel app)
2. Background and Institutional Setting (RLAH regulation, roaming market)
3. Data and Border Classification
4. Empirical Strategy
5. Results
6. Mechanisms (intra-EEA vs extra-EEA DDD, short stays, dose-response)
7. Robustness
8. Discussion and Conclusion
