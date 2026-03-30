# Research Plan: apep_1134

## Research Question

Do renewable energy generators in Germany strategically curtail output to avoid losing subsidy payments under the EEG clawback rule, and did successive tightenings of the threshold amplify this behavior?

## Policy Background

Germany's Renewable Energy Sources Act (EEG) provides market premium payments to renewable generators above 400 kW. However, when day-ahead electricity prices go negative for N or more consecutive hours, generators lose their market premium for the entire episode. This threshold has been progressively tightened:

- **Pre-2021:** 6 consecutive hours
- **2021–2023:** 4 consecutive hours
- **2024–2025:** 3 consecutive hours
- **2026:** 2 consecutive hours (future)

The clawback creates a sharp incentive: as a negative-price episode approaches the threshold duration, generators face a discrete jump in the cost of continued production. Rational generators should curtail output just before the threshold is reached, creating bunching in episode durations just below the cutoff.

## Mechanism: "The Curtailment Cliff"

When negative prices persist, each additional hour brings the episode closer to the clawback threshold. At hour N-1, the marginal cost of one more hour of negative prices is not just the spot-market loss — it's the entire episode's market premium. This creates a cliff: generators who can curtail (primarily wind, to a lesser extent solar via inverter control) have strong incentives to do so just before the threshold, even if conditions would otherwise support generation.

## Identification Strategy

### Primary: Bunching Analysis

Estimate excess mass of negative-price episode durations just below each clawback threshold (6h, 4h, 3h). Following Kleven (2016), estimate the counterfactual distribution of episode durations absent the threshold using polynomial fitting, excluding the bunching region.

- **Bunching estimand:** b = (observed mass in bunching region) / (counterfactual mass)
- **Mechanical channel test:** Compare renewable generation in the final hours of episodes that end just below vs. just above the threshold

### Secondary: Cross-Threshold DiD

Compare generator behavior before and after each threshold change:
- **Treatment 1:** Jan 2021 — threshold tightened from 6h to 4h
- **Treatment 2:** Jan 2024 — threshold tightened from 4h to 3h

Outcome: renewable generation (GW) in hours 3–4 of negative-price episodes. Under the 6h regime, hours 3–4 are "safe" (far from threshold). Under the 4h regime, they trigger clawback risk.

### Placebo: Cross-Country Comparison

Use France, Austria, Netherlands, and Spain from the same Energy-Charts API as placebos — these countries experience negative prices but have no equivalent clawback rule. Episode duration distributions in placebo countries should show no bunching at Germany's thresholds.

## Expected Effects

1. **Bunching:** Excess mass of episodes ending at hours 3, 4, or 6 (depending on regime), with missing mass above
2. **Generation dip:** Renewable output drops sharply in the hour(s) immediately before the threshold
3. **Threshold tightening:** Stronger bunching response after tightening (generators learn/adapt)
4. **Heterogeneity:** Wind responds more than solar (curtailment is easier for wind turbines)

## Primary Specification

For bunching: polynomial counterfactual (order 7) fitted to episode duration distribution, excluding [threshold-1, threshold+2] window.

For DiD:
$$Y_{et} = \alpha + \beta \cdot \mathbb{1}[\text{PostReform}]_t \times \mathbb{1}[\text{NearThreshold}]_e + \gamma_e + \delta_t + \epsilon_{et}$$

where e indexes episodes and t indexes hours within episodes.

## Data Source and Fetch Strategy

**Fraunhofer ISE Energy-Charts API** (https://energy-charts.info/)
- **Endpoint:** Public JSON API for electricity generation and prices
- **Resolution:** 15-minute generation, hourly prices
- **Coverage:** 2019–2024 (6 years, spanning both threshold changes)
- **Fuel types:** 21 types including wind onshore, wind offshore, solar, biomass
- **Countries:** Germany + 42 European countries (for placebos)
- **Access:** Open, no API key, CC BY 4.0

**Fetch plan:**
1. Download hourly day-ahead prices for DE, FR, AT, NL, ES (2019–2024)
2. Download 15-minute generation by fuel type for same countries/years
3. Identify negative-price episodes (consecutive hours with price < 0)
4. Construct episode-level panel with duration, generation profiles, threshold regime

## Sample Size Expectations

- ~1,475 negative-price hours across ~289 episodes in Germany (2019–2024)
- ~457 negative-price hours in 2024 alone
- Cross-country: several hundred additional episodes across 4 placebo countries
- Within-episode: 15-minute resolution gives ~4 observations per hour per fuel type
