# Research Plan: The Consolidation Trap

## Research Question
When small community water systems (CWS) are deactivated across the US, their customers must be absorbed by neighboring systems. Does this absorption increase health-based drinking water violations in the receiving system?

## Identification Strategy
**Staggered DiD with spatial matching.**

- **Treatment:** Active CWS that absorbs customers from a deactivated neighboring CWS (identified via same-ZIP or nearest-ZIP matching).
- **Treatment timing:** Staggered across ~40,716 deactivation events spanning decades.
- **Controls:** Active CWS with no nearby deactivation in the relevant window.
- **Key assumption:** Deactivation timing is driven by the failing system's own violations and financial distress, not by conditions at the receiving system. Pre-trend tests verify flat violation rates before neighbor deactivation.
- **Estimator:** Callaway & Sant'Anna (2021) for staggered DiD, avoiding TWFE bias.

## Expected Effects and Mechanisms
1. **Capacity shock:** Receiving system faces sudden demand increase without proportional infrastructure investment → more MCL violations.
2. **Infrastructure contamination:** Connecting to old/failing distribution pipes introduces contamination pathways.
3. **Regulatory dilution:** Staff and monitoring resources spread thinner across larger service area.

**Expected direction:** Positive effect on health-based violations (consolidation increases violations in receivers). Magnitude likely moderate — not all consolidations involve physical pipe connections.

## Primary Specification
```
Y_{it} = α_i + γ_t + β × Absorbed_{it} + ε_{it}
```
Where Y_{it} = health-based violation indicator (or count) for CWS i in quarter t, Absorbed_{it} = indicator for having absorbed a deactivated system's customers by quarter t.

## Exposure Alignment
The treatment (neighbor deactivation) primarily affects the single active CWS that physically inherits the deactivated system's customers. SDWIS does not record this link, so we approximate using ZIP-code co-location. This creates measurement error: many "treated" systems in a ZIP may not actually absorb any customers. The resulting attenuation bias pushes estimates toward zero, making our null conservative. The dose-response analysis (by absorbed population size) partially addresses this by testing whether the signal is stronger where the capacity shock is plausibly larger.

## Robustness
1. CS estimator vs. TWFE (show both)
2. Restrict to California mandatory consolidations (SB 88, cleaner treatment)
3. Placebo: transient non-community water system (TNCWS) deactivations
4. Dose-response: interaction with absorbed system's population size
5. Pre-trend test with 8+ pre-treatment quarters
6. Wild cluster bootstrap (clustering at state level)

## Data Source and Fetch Strategy
- **Primary:** EPA SDWIS via Envirofacts REST API (`data.epa.gov/efservice/`)
  - `WATER_SYSTEM` table: system info, deactivation dates, ZIP codes, population served
  - `VIOLATION` table: violation records with dates, contaminant codes, health-based indicator
- **Fetch strategy:**
  1. Download all CWS (active + inactive) with system characteristics
  2. Download all health-based violations nationally
  3. Construct quarterly panel: system × quarter
  4. Match deactivated systems to nearest active CWS via ZIP code
  5. Define treatment as "active CWS in same ZIP had a deactivation event"
- **Sample:** ~49,349 active CWS, ~40,716 deactivation events, quarterly panels 2000–2024
