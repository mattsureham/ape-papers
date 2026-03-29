# Research Plan: The Alliance Ratchet — Asymmetric Fare Effects from the Court-Ordered Dissolution of the JetBlue–American Northeast Alliance

## Research Question

Do airline fares fully revert after the court-ordered dissolution of a major airline alliance, or does coordination create sticky pricing that persists — an "alliance ratchet"? If fares rose during the JetBlue–American Northeast Alliance (NEA) but did not fully fall after its dissolution, antitrust remedies are systematically less effective than assumed.

## Identification Strategy

**Event-study DiD with two treatment shocks.** The NEA provides a rare lifecycle natural experiment: formation (Q1 2021, DOT approval Jan 10, 2021) and dissolution (Q3 2023, court ruling May 19, 2023; JetBlue termination July 29, 2023).

**Unit of analysis:** Directional airport-pair market × quarter.

**Treatment group:** Routes at JFK, LGA, BOS, EWR where both JetBlue and American operated or codeshared under the NEA (~175 routes).

**Control group:** Routes at the same four airports served by carriers not party to the NEA (within-airport controls), plus matched routes at non-NEA airports (external controls).

**Specification:**

log(Fare_{rt}) = α_r + δ_t + β₁(NEA_r × Formation_t) + β₂(NEA_r × Dissolution_t) + X_{rt}γ + ε_{rt}

**Key test:** β₂ ≠ −β₁ (asymmetry). If β₁ > 0 (formation raised fares) and |β₂| < |β₁| (dissolution didn't fully reverse), the difference measures the "ratchet" — the permanent fare increase attributable to coordination.

**Clustering:** Two-way clustering by route and quarter.

**Modern estimator:** Callaway–Sant'Anna (2021) for staggered adoption robustness, though the NEA is essentially a single-shock design (all routes treated simultaneously).

## Expected Effects and Mechanisms

- **Formation:** +5–8% fare increase (consistent with Agrawal & Ni 2024 finding of +6.7%)
- **Dissolution:** Partial reversion, −2–5% (less than formation effect if ratchet exists)
- **Mechanism 1 — Capacity withdrawal:** Airlines may have permanently reduced capacity/frequency on NEA routes, limiting competitive pressure even after dissolution
- **Mechanism 2 — Tacit collusion:** Coordination created pricing norms (Ciliberto & Williams 2014, AER) that persist informally
- **Mechanism 3 — Market structure:** Entry/exit patterns during NEA period permanently altered route-level HHI

## Primary Specification

1. **Main result:** log(fare) DiD with route + quarter FE, two treatment indicators
2. **Event study:** Quarter-by-quarter coefficients relative to Q4 2020 (pre-formation baseline)
3. **Asymmetry test:** F-test of β₁ + β₂ = 0

## Exposure Alignment

The treatment (NEA coordination) directly affected route-level pricing and capacity decisions by JetBlue and American Airlines on overlapping routes. The outcome (itinerary-level fares aggregated to route-quarter) captures the same unit of exposure: passengers purchasing tickets on treated routes experienced the coordination-induced pricing changes. The treatment is binary (a route either had both NEA carriers operating pre-alliance or did not), and the timing of exposure is uniform: all treated routes were simultaneously affected by formation (Q1 2021) and dissolution (Q3 2023). There is no partial or staggered rollout concern because the NEA was approved as a single agreement covering all participating routes at once, and the court order dissolved the entire agreement simultaneously.

## Robustness Checks

1. Passenger-weighted regressions
2. Median fares (robust to outlier tickets)
3. Excluding connecting itineraries (nonstop only)
4. Placebo: routes at NEA airports NOT served by JetBlue or American
5. Different control groups (propensity-score matched routes)
6. HonestDiD sensitivity analysis for pre-trend violations

## Data Source and Fetch Strategy

**Primary:** BTS DB1B Market data (10% ticket sample), quarterly, from transtats.bts.gov. Variables: MktFare, MktMilesFlown, Origin, Dest, OpCarrier, TkCarrier, Passengers, MktCoupons, Year, Quarter.

**Period:** Q1 2018 – Q4 2024 (3 years pre-formation, ~1.5 years post-dissolution)

**Fetch method:** Direct CSV download from BTS Transtats. Each quarter is a separate file. Will download Q1 2018 through latest available quarter.

**Secondary:** T-100 Domestic Segment data for capacity/frequency mechanism tests.

## Timeline

- NEA formation: Q1 2021 (DOT approval Jan 10, 2021)
- NEA dissolution: Q3 2023 (Court ruling May 19, 2023; JetBlue termination July 29, 2023)
- Pre-period: Q1 2018 – Q4 2020 (12 quarters)
- Formation period: Q1 2021 – Q2 2023 (10 quarters)
- Post-dissolution: Q3 2023 – Q4 2024 (6 quarters)
