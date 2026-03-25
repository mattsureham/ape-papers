# Research Plan: Open Skies over the Pampas

## Research Question

Did Argentina's aviation deregulation (Decree 599/2024) increase air service on previously monopoly routes? Does the competition dividend vary with route characteristics, and does deregulation reduce geographic inequality in air access?

## Policy Background

Decree 599/2024 (July 8, 2024) reformed Argentina's Aeronautical Code with three changes:
1. Full airfare deregulation (carriers set prices freely)
2. Open route access subject only to safety requirements
3. Foreign cabotage authorization

Pre-decree market: 198 domestic routes, 93 (47%) served by a single carrier (overwhelmingly Aerolíneas Argentinas), 105 (53%) already competed (Aerolíneas + Flybondi/JetSMART).

## Identification Strategy

**Route-level difference-in-differences with continuous treatment intensity.**

- **Treatment intensity:** Pre-decree HHI (Herfindahl-Hirschman Index) computed from 2023 passenger shares. Monopoly routes (HHI ≈ 10,000) have maximum treatment intensity; already-competed routes serve as low-intensity controls.
- **Event study:** Monthly coefficients centered on July 2024, with 90 months pre-treatment (Jan 2017 – Jun 2024) and ~18 months post.
- **Key assumption:** Absent the decree, passenger/seat trends on monopoly routes would have continued to evolve similarly to competed routes (parallel trends). The 90-month pre-period provides extensive evidence on this.
- **Estimator:** TWFE is appropriate here because treatment timing is uniform (single decree date). All routes are treated simultaneously but with varying intensity. No staggered adoption → no forbidden comparisons.

## Expected Effects and Mechanisms

1. **Competition entry:** LCCs (Flybondi, JetSMART) should enter previously monopoly routes → new flights, more seats
2. **Passenger growth:** More competition → lower fares → higher demand on monopoly routes
3. **Load factor:** Ambiguous — new capacity may outpace demand initially (lower load factors) or latent demand may fill seats
4. **Geographic equity:** If new entry concentrates on profitable trunk routes, peripheral monopoly routes may see no change → deregulation increases access inequality. If LCCs cherry-pick underserved routes, inequality falls.

## Primary Specification

$$Y_{rt} = \alpha_r + \gamma_t + \beta \cdot (HHI_r^{pre} \times Post_t) + \varepsilon_{rt}$$

Where:
- $Y_{rt}$: passengers, seats, flights, or load factor on route $r$ in month $t$
- $\alpha_r$: route fixed effects
- $\gamma_t$: month fixed effects
- $HHI_r^{pre}$: pre-decree (2023) HHI for route $r$ (continuous, 0–10,000)
- $Post_t$: indicator for $t \geq$ July 2024
- Clustering: route level (198 clusters)

## Robustness

1. Binary treatment: monopoly (HHI = 10,000) vs. competed (HHI < 10,000)
2. Event study with monthly leads/lags
3. Callaway-Sant'Anna with binary treatment (single timing, but useful for ATT estimation)
4. Leave-one-out (drop Buenos Aires routes, drop largest LCC)
5. Permutation/randomization inference (reassign HHI across routes)
6. Placebo: pre-decree pseudo-treatment at July 2022

## Data Source and Fetch Strategy

**Primary:** ANAC commercial aviation microdata via datos.yvera.gob.ar
- 1,013,003 daily observations (Jan 2017 – Jan 2026)
- Variables: date, airline, origin/destination ICAO codes, city, province, passengers, seats, flights
- Aggregate to route × month panel: ~198 routes × 108 months ≈ 21,384 cells

**Supplementary:** INDEC IPC Transport by region (monthly CPI for transport, 2016–2026) — for mechanism test on consumer prices.

## Idea Source

idea_1852 — "Open Skies over the Pampas: Aviation Deregulation, LCC Entry, and Air Access Inequality in Argentina"
