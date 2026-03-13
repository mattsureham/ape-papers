# Research Plan: apep_0618

## Research Question

Did the abolition of the UK's Stamp Duty Land Tax (SDLT) slab system in December 2014 generate heterogeneous housing market recoveries across Local Authorities, with areas that had greater pre-reform price distortion experiencing larger gains in transaction volume and price distribution normalization?

## Policy Background

Under the Finance Act 2003, SDLT used a slab structure where a single rate applied to the entire purchase price, creating sharp notches at rate boundaries. At £250,000, the rate jumped from 1% to 3%, imposing a £5,000 tax notch on transactions £1 above the threshold. This created extreme bunching just below £250,000 and a "dead zone" (£250,001–£260,000) where transactions were essentially absent.

On 4 December 2014, Chancellor Osborne announced an immediate structural reform (Finance Act 2014, s. 107): SDLT became a marginal-rate "slice" system, abolishing the notch. The reform was announced and took effect the same day, preventing anticipatory behavioral responses.

## Identification Strategy

**Difference-in-differences with continuous treatment intensity.**

Treatment intensity for Local Authority *i* is defined as the pre-reform (2010–2014) bunching mass at the £250,000 notch: the excess share of transactions priced in [£240k, £250k] relative to a counterfactual polynomial density estimated from the broader distribution (£200k–£350k, excluding the notch window).

Specification:
```
log(Volume_it) = α_i + γ_t + β × (Post_t × BunchIntensity_i) + X_it'δ + ε_it
```

Where α_i are LA fixed effects, γ_t are month fixed effects, and Post_t = 1 after December 2014.

**Key identifying assumption:** Absent the reform, transaction volume trends would have been parallel across LAs with different pre-reform bunching intensities. Testable via pre-trend examination (2010–November 2014).

**Exposure alignment:** Treatment intensity (pre-reform bunching at £250k) directly measures distortion from the slab notch — the very mechanism the reform eliminated. LAs with high excess mass below the notch are more exposed because more of their transactions were being distorted by the tax discontinuity. The reform abolishes the notch uniformly across all LAs; cross-LA variation in exposure comes from pre-existing market conditions (local price distributions near £250k) that determine how binding the notch was. The concern is that bunching intensity also proxies for local price levels and regional demand trajectories (Southeast vs. North), which is why LA-specific linear trends and the dead zone share outcome (a distributional measure immune to volume trends) serve as the primary robustness strategies.

## Expected Effects and Mechanisms

1. **Volume recovery:** LAs with high pre-reform bunching should see larger transaction volume increases post-reform, as the dead zone fills in.
2. **Price distribution normalization:** The gap in the price distribution at £250k–£260k should close most sharply in high-intensity LAs.
3. **Spatial heterogeneity:** Effects should be larger in LAs where the median house price is near £250k (London fringe, Southeast) vs. LAs where few transactions occur near this threshold.

## Primary Specification

- **Unit:** Local Authority × month
- **Outcome:** log(transaction count), share of transactions in dead zone (£250k–£260k)
- **Treatment:** Continuous — pre-reform bunching intensity
- **Sample:** 326 English LAs, January 2010 – December 2019 (~120 months)
- **Inference:** Cluster at LA level (326 clusters)

## Robustness and Placebos

1. **Placebo price band:** Bunching at £125k (1%→3% old threshold) — separate notch, separate treatment intensity
2. **Property type placebo:** New builds (often developer-priced, less responsive to notch) vs. existing homes
3. **Temporal placebo:** Test "reform" at January 2013 (no policy change)
4. **Dose-response:** Interact treatment intensity with post-reform time dummies for dynamic effects
5. **Wild cluster bootstrap:** Supplement standard clustered SEs

## Data Sources

1. **HM Land Registry Price Paid Data (PPD):** Complete universe of residential property transactions in England and Wales, 1995–present. Fields: price, date, postcode, property type, new build flag, estate type, district (LA). Bulk CSV download, no authentication required.

2. **postcodes.io:** Postcode-to-LA/LSOA linkage for geographic matching.

## Fetch Strategy

1. Download Land Registry PPD bulk CSV for 2010–2019
2. Parse transactions with price, date, district (LA identifier), property type
3. Construct LA × month panel: transaction counts, price distributions
4. Compute pre-reform bunching intensity at £250k for each LA
5. Merge with LA-level controls if available (population, median income)
