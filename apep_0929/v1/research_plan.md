# Research Plan: The Gift Race — How a Competition Ceiling Reshaped Japan's Fiscal Redistribution

## Research Question

Does regulating competitive generosity in a fiscal donation system redistribute resources or merely reduce participation? Japan's Furusato Nozei (hometown tax) system let taxpayers redirect residence tax to any municipality in exchange for return gifts. A "gift race" emerged: municipalities competed through escalating gift rates (up to 50%+ of donation value), concentrating donations in aggressive municipalities. In June 2019, the Ministry of Internal Affairs and Communications (MIC) imposed a binding 30% cap on return gift value, ending the race. We estimate the causal effect of this competition ceiling on the geographic redistribution of donation inflows across 1,883 municipalities.

## Identification Strategy

**Staggered DiD with continuous treatment intensity:**

- **Treatment:** June 2019 binding cap at 30% of donation value (previously advisory only)
- **Treatment intensity:** Pre-2019 gift rate minus 30% cap. Municipalities with pre-2019 gift rates >30% are treated; those at or below 30% are controls.
- **Dose-response:** Municipalities further above the cap faced larger forced reductions in competitive advantage.
- **Event study:** FY2015-FY2018 (pre) vs FY2020-FY2024 (post). FY2019 straddles reform (April-March fiscal year, reform in June 2019) — excluded or treated as partial.

**Key identifying assumption:** Absent the binding cap, donation trends would have evolved similarly across high-gift-rate and low-gift-rate municipalities (parallel trends). The event study tests this.

**Built-in placebos:**
1. Four municipalities excluded entirely from the system (Izumisano, Miyaki, Kami, Minoh) — extreme treatment
2. Below-30% municipalities — zero treatment intensity

## Expected Effects and Mechanisms

1. **Reallocation:** Donations should shift from previously-high-gift-rate municipalities to moderate-gift-rate municipalities (redistribution effect)
2. **Level effect:** Total system donations may fall if high gift rates were the main draw, or rise if legitimization effect dominates
3. **Cost structure:** Gift procurement costs should fall as a share of donations for treated municipalities
4. **Net fiscal benefit:** If procurement costs fell faster than donations, net revenue per donation could rise

## Primary Specification

```
log(donations_it) = α_i + δ_t + β × (GiftRate_i,pre × Post_t) + ε_it
```

Where `GiftRate_i,pre` is the average pre-2019 gift rate for municipality i, `Post_t` = 1 for FY2020+, and we include municipality and year fixed effects. β captures the differential change in donations for municipalities with higher pre-2019 gift rates after the cap.

## Data Source and Fetch Strategy

**Source:** MIC (soumu.go.jp) publishes annual municipality-level Furusato Nozei statistics in Excel format.

**Key files:**
1. Historical donation receipts by municipality (受入額の推移) — FY2008-FY2024
2. Detailed cost breakdown (返礼品の調達に要した経費等) — FY2016+
3. Tax credit outflows by municipality (控除適用者数等) — FY2008+

**Fetch:** Direct download of Excel files from soumu.go.jp via curl/wget. Parse with `readxl` in R.

**Sample:** ~1,883 municipalities × 17 fiscal years = ~32,000 municipality-year observations.
~400-600 municipalities with pre-2019 gift rates >30% (treated).

## Exposure Alignment

**Who is actually treated?** Municipalities with FY2018 gift procurement cost ratios exceeding 30% are classified as treated. These are municipalities that were forced to reduce their competitive advantage when the binding cap took effect in June 2019. The treatment operates at the municipality level — the entire municipality's donation inflow is affected because the cap constrains the gift-rate instrument that attracted donors. Control municipalities (gift rate ≤ 30%) faced no binding constraint and could maintain their existing gift strategies.

**Treatment timing:** All treated municipalities are treated simultaneously (June 2019). There is no staggering. FY2019 is excluded as a partial treatment year since the reform fell in the first quarter of the Japanese fiscal year (April-March).

## Robustness Checks

1. Event study (pre-trend test)
2. Callaway-Sant'Anna for staggered adoption concerns
3. Exclude the 4 banned municipalities
4. Exclude FY2019 (partial treatment) and FY2020 (COVID)
5. Leave-one-out by prefecture
6. Placebo treatment date (FY2017)
7. Continuous treatment vs binary (above/below 30%)
