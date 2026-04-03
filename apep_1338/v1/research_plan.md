# Research Plan: Brexit Rules of Origin and Trade Disintegration

## Research Question
Do product-specific rules of origin (ROO) in the EU-UK Trade and Cooperation Agreement reduce bilateral trade, and by how much? By exploiting the unique setting where tariffs are uniformly zero but ROO restrictiveness varies across ~5,200 product lines, we isolate the pure compliance cost of rules of origin.

## Identification Strategy
**Product-level DDD (triple-difference):**
1. **Time:** Post-TCA (2021-2024) vs pre-TCA (2018-2019), excluding 2020 (transition/COVID)
2. **Partner:** UK-EU vs UK-non-EU trade at the same HS-6 product
3. **Treatment intensity:** ROO Restrictiveness Index (ROO-RI) following Estevadeordal (2000), computed from TCA ANNEX ORIG-2

The DDD isolates ROO-specific trade effects by differencing out: (a) time-varying aggregate shocks affecting all trade (first difference), (b) product-specific trends common to EU and non-EU partners (second difference), and (c) residual variation attributable to ROO restrictiveness (third difference).

**Key identifying assumption:** Conditional on product and partner fixed effects, ROO-RI variation across products is orthogonal to product-level trade trends. ROO-RI was set during diplomatic negotiations based on political economy considerations (lobbying, sectoral sensitivity), not product-level trade trajectories.

## Expected Effects and Mechanisms
- **Main:** Higher ROO-RI reduces UK-EU trade relative to UK-non-EU trade
- **Mechanism 1 (Compliance cost):** Firms in ROO-intensive products face higher documentation/certification costs → some switch to MFN terms or exit
- **Mechanism 2 (Preference utilization):** Higher ROO-RI reduces preference utilization rates (using HMRC BDSPref data from Feb 2025)
- **Mechanism 3 (Value chain disruption):** Products with cross-border intermediate inputs face ROO differently than final goods

## Primary Specification
```
log(Trade_pct) = β₁(Post_t × EU_c × ROO-RI_p) + β₂(Post_t × EU_c) + 
                  γ_pc + δ_pt + θ_ct + ε_pct
```
Where p = HS-6 product, c = partner (EU aggregate vs non-EU controls), t = year-quarter.
Fixed effects: product×partner, product×time, partner×time.
Clustering: HS-2 chapter level (~97 clusters).

## Data Sources
1. **HMRC uktradeinfo** — Monthly UK bilateral trade at HS-8, aggregated to HS-6 × quarter × partner
2. **HMRC BDSPref** — Preference utilization at HS-6 × month (from Jan 2022)
3. **UN Comtrade** — Mirror data and non-EU partner verification
4. **TCA ANNEX ORIG-2** — Product-specific rules of origin → construct ROO-RI
5. **Control partners:** US, Canada, Japan, South Korea, Australia (no ROO change with UK post-Brexit)

## Key Risks
- HMRC data granularity — some HS-8 codes may be suppressed for confidentiality
- ROO-RI construction — requires careful parsing of TCA Annex text
- 2020 exclusion reduces pre-period length to 2 years (2018-2019)
- COVID confound — the non-EU control group addresses this via DDD structure
