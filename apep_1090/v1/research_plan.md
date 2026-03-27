# Research Plan: The Compliance Trap — How Tripling Inventory Requirements Reduced Food Access for SNAP Households

## Research Question

Did the January 2018 USDA depth-of-stock provision — which tripled minimum stocking requirements from 12 to 36 items — cause small-format SNAP retailers to exit the program, and did these exits reduce food access for SNAP-participating households?

## Policy Background

The 2016 USDA final rule (81 FR 90675) contained five provisions to strengthen SNAP retailer stocking requirements. Congress blocked the headline provision (increasing variety from 3 to 7 staple food categories) via Section 765 of the 2017 Appropriations Act. However, the **depth-of-stock provision was NOT blocked**: effective January 17, 2018, every authorized SNAP retailer was required to stock at least 3 units per staple variety per category (up from 1), tripling the minimum from 12 to 36 items.

Only 30.2% of small-format stores met the full requirement at the time of implementation (Andreyeva et al. 2019). SNAP-authorized retailers peaked at 263,105 in FY2017 and declined to ~248,000 by FY2019 — a net loss of ~15,000 retailers coinciding precisely with the provision's implementation.

## Identification Strategy

**Design:** Difference-in-differences with heterogeneous treatment intensity.

**Treatment measure:** Pre-2018 (FY2017) tract-level share of SNAP retailers that are small-format (convenience stores [CS], small grocery [SG], delivery/farmer [DF/DR]). Tracts with higher small-format shares face a more binding constraint.

**Estimating equation:**

Y_{ct} = α + β(SmallShare_c × Post_t) + X_{ct}γ + μ_c + δ_t + ε_{ct}

where c indexes census tracts, t indexes years. β captures the differential change in outcomes for tracts with higher exposure to binding stocking requirements.

**Key identification assumptions:**
1. Absent the provision, tracts with different small-format shares would have followed parallel trends
2. The provision's timing (Jan 2018) is exogenous to tract-level trends
3. No confounding policies changed differentially by small-format share at the same time

**Placebo tests:**
- Supermarket exits should NOT vary by small-format share (they already meet requirements)
- Pre-2018 event study should show flat pre-trends

**Dose-response:** Compare tracts in top quartile vs bottom quartile of small-format share.

## Expected Effects and Mechanisms

**Primary mechanism (compliance trap):** Small-format retailers (convenience stores, small groceries) lack the shelf space and capital to stock 36+ items across staple categories. Rather than invest in compliance, many exit the SNAP program — reducing the network of redemption points available to SNAP households.

**Expected signs:**
- Retailer exits: Positive (more exits in high-small-format tracts) — **large**
- SNAP participation: Negative (fewer nearby retailers → reduced access) — **small to moderate**
- Food insecurity: Positive (reduced access → worse food security) — **small**

## Primary Specification

1. **First stage:** Small-format SNAP retailer exits by tract-year
2. **Reduced form:** SNAP household participation by tract-year
3. **Mechanism:** Food access measures (distance to nearest SNAP retailer)

## Data Sources

| Source | Variables | Unit | Years | Access |
|--------|-----------|------|-------|--------|
| USDA SNAP Retailer Historical Database | Store authorizations, end dates, types, geocodes | Store | 2010-2024 | Public download (24MB ZIP) |
| ACS Table B22003 | SNAP/food stamp receipt by tract | Tract-year | 2015-2022 | Census API |
| USDA Food Access Research Atlas | Low-access flags, distance measures | Tract | 2015, 2019 | Public download |

## Fetch Strategy

1. Download SNAP Historical Database ZIP from USDA
2. Query ACS B22003 at tract level for 2015-2022 via Census API
3. Download Food Access Research Atlas for cross-sectional validation
