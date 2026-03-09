# Research Plan: India Farm Laws Symmetric Natural Experiment

## Research Question
Did India's 2020 farm laws—which deregulated agricultural trade outside APMC mandis—affect retail commodity prices? Does the symmetric policy sequence (enactment → stay → repeal) provide evidence for or against a causal effect?

## Identification Strategy
- **Design:** Continuous-treatment DiD exploiting cross-state variation in pre-existing APMC regulation stringency
- **Treatment:** APMC stringency index (composite: 40% cess rate, 30% commodity coverage, 30% private market restriction)
- **ON phase:** June 2020–January 2021 (farm laws active)
- **OFF phase:** February 2021 onward (post-Supreme Court stay, then repeal)
- **FE:** State×commodity + Commodity×month
- **Clustering:** State level (28 clusters)

## Data
- **Source:** WFP/VAM food price monitoring via Humanitarian Data Exchange (HDX)
- **Coverage:** 169 markets, 28 states, 5 commodities (rice, wheat, onion, potato, tomato)
- **Period:** January 2018 – December 2023 (72 months)
- **Unit:** Retail prices in INR/kg
- **Panel:** 6,866 state×commodity×month cells (aggregated from 20,356 market-level observations)

## Key Finding
**Null result.** The farm laws had no statistically significant effect on retail commodity prices.
- ON coefficient: 0.058 (SE = 0.080, p = 0.48)
- OFF coefficient: 0.210 (SE = 0.200, p = 0.30)
- RI p-values: 0.52 (ON), 0.31 (OFF)
- All robustness checks and placebos confirm the null

## Robustness
1. Binary treatment → null
2. Cess-rate-only treatment → null
3. Price dispersion outcome → null
4. Number of markets outcome → null
5. Drop protest states → null
6. Drop blocked states → null
7. Exclude deregulated states → null
8. Narrow bandwidth → null
9. Leave-one-state-out → stable
10. Randomization inference → RI p = 0.52
11. Three placebos → null (as expected)

## Mechanisms for Null
1. Brief, contested implementation → insufficient time for market adjustment
2. Wholesale-retail disconnect → WFP captures retail, not wholesale margins
3. Mandis as genuine infrastructure → legal deregulation doesn't displace functional markets
