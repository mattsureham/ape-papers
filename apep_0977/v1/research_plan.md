# Research Plan: Selective Revenge — Product-Heterogeneous Trade Hysteresis from South Korea's 2019 Anti-Japan Consumer Boycott

## Research Question

Do consumer boycotts create permanent trade diversion, and if so, for which products? We exploit the massive grassroots Korean boycott of Japanese goods following Japan's July 2019 export controls to test whether boycott-induced trade losses are temporary or persistent, and whether recovery depends on domestic substitutability.

## Policy Context

On July 1, 2019, Japan announced export controls on three semiconductor materials critical to Korean chip production, escalating to removing Korea from its "white list" of preferred trade partners on August 28. By early August, surveys showed 61.2% of Korean consumers participating in a boycott of Japanese goods. Korean Air reported a 40% decline in Japan bookings. Crucially, this was a grassroots consumer movement — not a government-mandated trade restriction.

## Identification Strategy

**Triple-Difference (DDD):**
- **Product dimension:** Consumer-facing HS2 products (beverages, vehicles, cosmetics, apparel) vs. industrial/intermediate goods (electrical machinery, chemicals, metals)
- **Destination dimension:** Japan→Korea (treated by boycott) vs. Japan→China (control — no boycott, similar geography)
- **Time dimension:** Pre-boycott (Jan 2018 – Jun 2019) vs. post-boycott (Jul 2019 – Dec 2023)

**Main specification:**
```
log(Trade_{p,d,t}) = β₁(Consumer_p × Korea_d × Post_t) + α_{pd} + α_{dt} + α_{pt} + ε_{p,d,t}
```
With product×destination, destination×month, and product×month fixed effects.

**Event study:**
```
log(Trade_{p,d,t}) = Σ_k β_k(Consumer_p × Korea_d × 1{t=k}) + FEs + ε
```
Relative to June 2019 (last pre-treatment month).

## Expected Effects and Mechanisms

1. **Consumer goods to Korea collapse** post-July 2019 (β₁ < 0, large)
2. **Industrial goods unaffected** (built-in placebo)
3. **Recovery diverges by substitutability:**
   - High domestic substitutability → temporary loss, full recovery (beverages: Korean beer industry already strong)
   - Low substitutability → persistent loss, trade hysteresis (vehicles: limited Korean substitution for Japanese models in Korean market)
4. **Cosmetics anomaly:** Zero boycott effect despite universal participation — potentially driven by private consumption (low social visibility) vs. public signaling

## Mechanism Tests

- **Rauch (1999) classification:** Differentiated vs. homogeneous products predict recovery speed
- **Visibility:** Publicly consumed goods (beer, cars, dining) vs. privately consumed (cosmetics, personal care)
- **Domestic industry strength:** Pre-boycott Korean production share as predictor of recovery

## Primary Specification

- Unit: HS 2-digit product × destination × month
- Outcome: log(trade value USD)
- Treatment: Consumer_p × Korea_d × Post_t
- Fixed effects: product×destination, destination×month, product×month
- Clustering: product×destination level
- Sample: Jan 2018 – Dec 2023, ~13,680 obs (95 products × 72 months × 2 destinations)

## Data Source and Fetch Strategy

**UN Comtrade API** (subscription key available in .env)
- Reporter: Japan (reporter code 392)
- Partners: Korea (410), China (156)
- Flow: Exports (from Japan)
- Classification: HS revision 2017, 2-digit level
- Frequency: Monthly
- Period: January 2018 – December 2023

**Product classification:**
- Consumer vs. industrial: manual classification of 97 HS2 chapters based on BEC (Broad Economic Categories) correspondence
- Rauch (1999): differentiated vs. homogeneous vs. reference-priced
- Visibility: constructed from consumption context (public vs. private)

## Robustness Checks

1. Japan→Taiwan as alternative control destination
2. Excluding COVID period (Jan 2020 – Jun 2021)
3. Continuous treatment intensity (boycott sentiment index from Google Trends Korea)
4. Wild cluster bootstrap for inference with ~95 product clusters
5. Permutation test: randomly reassigning consumer/industrial labels
