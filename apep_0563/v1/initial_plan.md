# Initial Research Plan: apep_0563

## Research Question

Does Japan's 2019 dual-rate consumption tax — which taxes the same food at 8% (takeout) versus 10% (eat-in) — cause measurable consumer switching from eat-in to takeout food?

## Policy Setting

On October 1, 2019, Japan raised its consumption tax from 8% to 10%, but introduced a reduced rate of 8% for takeout food and beverages (excluding alcohol). This created a globally unique natural experiment: the same food item faces different tax rates depending solely on consumption location. A convenience store onigiri costs 8% if taken out but 10% if eaten in-store. The within-product price wedge is approximately 1.85% (2/108).

## Identification Strategy

**Triple difference (DDD) around a sharp temporal discontinuity.**

1. **First difference (time):** Pre vs. post October 2019
2. **Second difference (category):** Takeout/prepared food (8% rate) vs. eat-in/restaurant food (10% rate) — both are "prepared food," isolating the tax differential
3. **Third difference (within-food placebo):** Alcoholic beverages went from 8% to 10% regardless of eat-in/takeout — no dual rate. This controls for any general consumption tax increase effects.

The key identification assumption is that absent the differential tax rate, takeout and eat-in food expenditure would have followed parallel trends. The alcohol placebo provides a within-food-expenditure control that faced the uniform rate increase.

## Expected Effects and Mechanisms

- **Primary:** Relative increase in takeout food expenditure share vs. eat-in food expenditure share
- **Magnitude:** With a 1.85% price wedge, standard food demand elasticities (-0.5 to -1.0) predict a 0.9-1.9% shift in the eat-in/takeout expenditure ratio
- **Mechanisms:**
  1. Consumer substitution toward takeout at the margin
  2. Firm pricing responses (absorption vs. pass-through of the differential)
  3. "Eat-in tax evasion" — customers declare takeout but eat in-store (documented social phenomenon)
- **Heterogeneity:** Stronger effects for lower-income households (more price-sensitive) and urban areas (more substitution options)

## Primary Specification

$$\text{TakeoutShare}_{ht} = \alpha + \beta_1 \text{Post}_t + \beta_2 \text{Post}_t \times \text{Takeout}_c + \gamma X_{ht} + \delta_h + \delta_t + \varepsilon_{ht}$$

Where:
- $h$ indexes households, $t$ indexes months, $c$ indexes food category
- $\text{TakeoutShare}_{ht}$ is the ratio of takeout to total prepared-food spending
- $\text{Post}_t$ = 1 for months after October 2019
- Key coefficient: $\beta_2$ captures the differential shift toward takeout food

## Data Sources

1. **Primary:** Japan Family Income and Expenditure Survey (FIES) — monthly household expenditure by commodity class, available on e-Stat (www.e-stat.go.jp). ~8,000 households/month.
2. **Secondary:** Japan CPI by commodity group (Statistics Bureau) — food-at-home vs. food-away-from-home price indices

## Planned Robustness Checks

1. **Pre-trend tests:** Event study with monthly leads/lags around October 2019
2. **Placebo tests:**
   - Alcohol expenditure (uniform rate increase — should show no differential)
   - Earlier time periods (placebo cutoffs at non-reform dates)
3. **COVID sensitivity:** October 2019-February 2020 window (pre-COVID) vs. extended sample
4. **Alternative outcomes:** Levels vs. shares, per-capita vs. household
5. **Seasonal adjustment:** Control for October seasonal spending patterns using prior-year October data
6. **Bandwidth sensitivity:** Varying pre/post windows (6, 12, 18, 24 months)
7. **Confound check:** Japan also introduced a cashless payment reward program (up to 5% rebate) simultaneously — control for payment method mix

## Power Assessment

- Pre-treatment periods: 24 months (October 2017-September 2019)
- Post-treatment periods: 5 months clean (Oct 2019-Feb 2020, pre-COVID) + extended with COVID controls
- Households: ~8,000/month
- Within-household variation: eat-in vs. takeout vs. alcohol spending categories
- Expected effect: ~1-2% shift in expenditure ratio; household-level data should have sufficient power given the large monthly N

## Key Risks

1. **COVID-19 contamination:** COVID hit Japan in early 2020, dramatically shifting eat-in vs. takeout patterns. Must carefully distinguish tax-driven from COVID-driven switching. Use the October 2019-February 2020 window as primary.
2. **Data granularity:** FIES may not separate takeout from eat-in food with enough precision. Need to verify category definitions map cleanly to the tax boundary.
3. **Cashless payment rebate confound:** The simultaneous cashless rebate program may interact with eating-out decisions (since small shops were targeted).
