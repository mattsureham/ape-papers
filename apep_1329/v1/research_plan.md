# Research Plan: Triple-Threshold Bunching in the UK Feed-in Tariff Solar Fleet

## Research Question

Do solar PV installers strategically downsize system capacity to stay below tariff thresholds in the UK Feed-in Tariff (2010–2019)? How large are the implied elasticities of capacity with respect to the net-of-tariff rate, and does bunching disappear when the threshold is removed?

## Identification Strategy

**Multi-cutoff bunching design** (Kleven and Waseem 2013) at three capacity thresholds simultaneously:

1. **4 kW threshold** — highest tariff tier (41.3p/kWh in 2010, declining over time). Installations ≤4 kW receive the top tariff; those above receive a lower rate.
2. **10 kW threshold** — second tier boundary. Installations ≤10 kW receive a higher tariff than those above.
3. **50 kW threshold** — third tier boundary. Installations ≤50 kW receive a higher tariff than those above.

**Threshold-removal experiment:** On January 15, 2016, the FCA merged the 0–4 kW and 4–10 kW bands into a single 0–10 kW band at identical rates. The 4 kW threshold was eliminated. Bunching at 4 kW should disappear post-merger while bunching at 10 and 50 kW (unchanged) persists. This provides a within-system placebo and a direct test of the causal link between tariff structure and capacity choice.

## Expected Effects and Mechanisms

- **Pre-merger (2010–2015):** Strong bunching at all three thresholds, especially 4 kW (largest tariff differential, most residential installations).
- **Post-merger (2016–2019):** Bunching at 4 kW disappears; bunching at 10 kW and 50 kW persists.
- **Mechanism:** Installers (not homeowners) are the optimizing agents — they design systems to maximize tariff revenue per panel. The "capacity trap" means social welfare is reduced because systems are smaller than the roof could accommodate.
- **Heterogeneity:** Bunching intensity may vary by installation type (domestic vs. commercial), geographic region, and tariff degression schedule.

## Primary Specification

For each threshold $k \in \{4, 10, 50\}$:

1. Estimate counterfactual capacity distribution using a polynomial fit to the observed distribution excluding the bunching region $[k - \delta_L, k + \delta_R]$.
2. Compute excess mass $\hat{b}_k$ = (observed - counterfactual) in the bunching region, normalized by the counterfactual height.
3. Estimate the implied elasticity of capacity with respect to the net-of-tariff rate using the Kleven-Waseem formula for kinks.
4. For the 4 kW threshold: estimate separately for pre-merger (2010–2015) and post-merger (2016–2019) periods.

## Data Source and Fetch Strategy

**Primary data:** Ofgem Feed-in Tariff Installation Report
- 860,470 solar PV installations (2010–2019)
- Variables: installed capacity (kW), commissioning date, tariff code, postcode, local authority, LSOA, installation type, export status
- Format: Excel files downloadable from Ofgem website
- Already confirmed in smoke test: bunching ratios of 585:1 at 4 kW, 38:1 at 10 kW, 285:1 at 50 kW

**Tariff schedule:** Ofgem published quarterly FIT tariff tables (2010–2019). Needed to compute the tariff differential (kink size) at each threshold over time.

**Fetch approach:**
1. Download Ofgem FIT Installation Report (3 Excel files)
2. Compile tariff schedule from Ofgem historical tariff tables
3. Clean and merge: parse capacity, dates, installation types
4. Construct analysis variables: distance from each threshold, time period indicators
