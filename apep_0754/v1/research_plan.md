# Research Plan: From Clicks to Closures

## Research Question
Did the SNAP Online Purchasing Pilot — which shifted EBT redemptions from physical stores to Amazon and Walmart — accelerate the exit of brick-and-mortar convenience stores from the SNAP program?

## The Puzzle
The SNAP Online Purchasing Pilot was designed to improve food access. But 375,000 convenience stores — the dominant SNAP retailer type — depend on EBT transactions for a large share of revenue. When SNAP goes online, the very retailers the program was designed to support lose their competitive advantage. The policy intended to help poor households may instead destroy the physical food infrastructure they depend on.

## Identification Strategy

### Primary: Staggered DiD (Callaway-Sant'Anna 2021)
- **Treatment:** State gains SNAP online purchasing capability
- **Timing:** NY (April 2019), WA (Jan 2020), then rapid expansion to 47 states April-December 2020
- **Unit of analysis:** State × store-type × quarter
- **Outcome:** Quarterly exit rate = (SNAP deauthorizations) / (active authorized stores at start of quarter)
- **Comparison:** Never-treated states (3-4 states without online SNAP through 2020) + not-yet-treated

### Triple-Difference (Store-Type DDD)
Key innovation to address COVID confounding:
- **Convenience stores** (treatment group): lose SNAP share to online competitors (Amazon, Walmart)
- **Supermarkets** (control group): face same COVID shock but benefit from (or are neutral to) online SNAP
- First diff: pre/post online SNAP
- Second diff: treated state / not-yet-treated state
- Third diff: convenience store / supermarket

### Heterogeneity Tests
1. **Urban vs Rural:** Online delivery covers 95% metro but <30% rural → expect null in rural
2. **Broadband penetration:** High-broadband states should show larger effects (ACS B28002)
3. **Pre-COVID vs COVID-era treatment:** NY (April 2019) provides clean pre-COVID evidence

### Placebo Tests
1. Supermarket exit rates should not accelerate (or may decline) post-online SNAP
2. States with low broadband should show smaller effects
3. Rural counties within treated states should show null effects

## Data Sources
1. **SNAP Retailer Historical Database** (USDA): 703K retailers, geocoded, authorization/end dates, store type codes (2005-2025)
2. **FNS State-Monthly SNAP Data:** Households, persons, benefits by state-month
3. **SNAP Online Pilot Dates:** Compiled from USDA FNS press releases
4. **ACS Broadband** (B28002): State-level broadband penetration

## Expected Effects
- Convenience store exit rates increase 10-30% in treated states post-online SNAP
- Effect concentrated in urban, high-broadband areas
- Supermarkets show null or negative effect (fewer exits)
- NY pre-COVID estimate isolates the mechanism from pandemic confounding

## Primary Specification
```
ExitRate_{s,type,t} = α + β₁(OnlineSNAP_{s,t} × ConvStore_{type}) + β₂(OnlineSNAP_{s,t}) + β₃(ConvStore_{type}) + γ_{s,type} + δ_t + ε_{s,type,t}
```
With state×store-type FE and quarter FE. β₁ is the DDD coefficient: excess convenience store exits attributable to online SNAP, net of COVID and secular trends.
