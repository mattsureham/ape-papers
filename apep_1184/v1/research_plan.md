# Research Plan: The Incumbency Shield — EU Slot Waivers and Airport Competition

## Research Question

Did the EU's COVID-era suspension and graduated restoration of the 80/20 airport slot use-it-or-lose-it rule entrench incumbent airlines, reducing passenger throughput at capacity-constrained airports?

## Policy Background

EU Regulation 95/93 requires airlines at "Level 3" (fully coordinated) airports to use at least 80% of allocated slots or forfeit them. In March 2020, the Commission granted a full waiver (0% threshold). Restoration was staggered:
- Summer 2020 – Winter 2020/21: 0% (full waiver)
- Summer 2021: 50%
- Summer 2022: 64%
- Winter 2022/23: 75% (transitional)
- Summer 2023: 80% (full restoration)

~100 EU airports are classified Level 3 (coordinated: Frankfurt, CDG, Schiphol, etc.). ~400+ airports are Level 1/2 and never subject to slot rules.

## Named Mechanism: "The Incumbency Shield"

When the use-it-or-lose-it rule is relaxed, incumbents can hoard slots without operating flights. This creates a **regulatory shield** that freezes market structure: new entrants cannot access capacity even when demand recovers. Airlines reportedly operated "ghost flights" (empty planes) to retain slots at minimal thresholds. The graduated restoration creates dose-response variation in the shield's strength.

## Identification Strategy

**Continuous-treatment DiD:**

Y_{a,t} = α_a + γ_t + β(Level3_a × SlotThreshold_t) + X'_{a,t}δ + ε_{a,t}

- **Treatment group:** ~100 Level 3 airports (slot regulation is binding)
- **Control group:** ~400 Level 1/2 airports (slot regulation never applies)
- **Treatment intensity:** SlotThreshold ∈ {0, 50, 64, 75, 80} — the binding usage requirement
- **Pre-period:** 2016Q1–2019Q4 (16 quarters of constant 80% rule)
- **Post-period:** 2020Q1–2023Q4 (16 quarters of varying thresholds)
- **Fixed effects:** Airport (α_a) + Quarter (γ_t)

**Key identification assumption:** Absent the slot threshold changes, Level 3 and Level 1/2 airports would have followed parallel trends in passenger recovery. The 16-quarter pre-period with constant 80% rule provides a strong basis for testing this.

**Threats and responses:**
1. COVID differentially hit hub airports → within-country pairs (Frankfurt vs. Dortmund), charter placebo
2. Level 3 status is endogenous → Level 3 classification was set before COVID, based on historical congestion
3. Demand recovery differs by airport size → airport fixed effects absorb level differences; event study tests parallel trends

## Placebo Design

**Charter flights (avia_paoc scheduled vs. non-scheduled):** Charter operations are not subject to slot regulation. If we find effects only for scheduled flights at Level 3 airports and not for charter flights, this supports the slot mechanism over general COVID recovery differences.

## Data Sources

1. **Eurostat avia_par_** — Airport-level passenger data (monthly/quarterly/annual)
   - Millions of observations, all EU airports
   - `eurostat` R package, no API key needed
2. **Eurostat avia_tf_apal** — Air traffic movements at airports (flights/movements)
   - Distinguishes commercial, cargo, non-scheduled
3. **Eurostat avia_paoc** — Country-level passengers by schedule type (charter vs. scheduled)
   - For placebo test
4. **Airport coordination status** — EU Slot Regulation coordination lists
   - Level 3 airports identified from official EUACA coordination lists

## Expected Effects

- **β > 0:** Higher slot thresholds → more passengers at Level 3 airports (forcing airlines to use-or-lose drives capacity utilization)
- **Magnitude:** The 80% rule covers airports handling ~70% of EU passenger traffic. Even modest effects have large welfare implications.
- **Heterogeneity:** Larger effects at more concentrated hub airports (where slot hoarding is most valuable)

## Primary Specification

Log passengers ~ Airport FE + Quarter FE + Level3 × SlotThreshold + controls

Cluster standard errors at the airport level. Event study specification around each threshold change for pre-trend validation.

## R Packages

`eurostat`, `fixest`, `data.table`, `modelsummary`, `xtable`
