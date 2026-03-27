# Research Plan: The Vanishing State

## Research Question

Does the closure of local tax offices (DRFIP/DDFIP/trésoreries) under France's 2019 Nouveau Réseau de Proximité reform causally increase Rassemblement National (RN) vote share?

## Policy Background

In June 2019, the DGFiP announced the NRP reform, consolidating its network of local tax offices from 1,952 commune-level locations to 929 by 2024 — a 52% reduction affecting over 1,000 communes. Closed offices were partly replaced by France Services counters (multi-service points). The reform was nationally coordinated with staggered local implementation across 2019–2024.

## Identification Strategy

**Staggered DiD with Callaway-Sant'Anna (2021).** Treatment: commune's DRFIP/DDFIP count drops from ≥1 to 0 between consecutive BPE vintages. ~1,023 treated communes vs. ~34,000 controls (communes that never had a tax office or retained theirs).

**Pre-trends:** 2002–2017 presidential elections (4 cycles) provide extensive pre-treatment baseline for treated communes.

**Key assumption:** RN vote trends would have evolved similarly in treated and control communes absent the closure, conditional on fixed effects and controls.

## Expected Effects and Mechanisms

1. **State withdrawal hypothesis:** Closure signals state abandonment, increasing alienation and protest voting → RN vote ↑
2. **Service degradation:** Loss of in-person tax services forces digital migration, disproportionately hurting elderly/low-income → populist grievance ↑
3. **Mitigation:** France Services replacement may attenuate backlash

**Expected sign:** Positive effect on RN vote share (1–3 pp based on analogous literature on public service withdrawal).

## Primary Specification

```
RN_share_{ct} = α_c + γ_t + β × Closure_{ct} + X_{ct}′δ + ε_{ct}
```

Where α_c = commune FE, γ_t = election FE, Closure_{ct} = 1 if commune c lost its last tax office by election t. CS-DiD groups by closure year. Clustering at département level (~100 clusters).

## Data Sources

1. **BPE (Base Permanente des Équipements)** — INSEE, annual vintages 2017–2024. Equipment type DRFIP/DDFIP identifies tax office presence per commune. Compare across vintages to date closures.

2. **Election results** — data.gouv.fr. Commune-level results for:
   - Presidential elections: 2002, 2007, 2012, 2017, 2022
   - European elections: 2014, 2019, 2024

3. **Commune characteristics** — INSEE: population, median income, age structure, urbanity classification.

## Exposure Alignment

The treatment—tax office closure—directly affects all residents of the commune who previously had access to in-person fiscal services. The commune is both the administrative unit of treatment assignment (where the office was located) and the unit of electoral observation (where votes are counted). Exposure is geographically aligned: residents of a commune that loses its tax office are the same population casting ballots in that commune's elections. Spillovers to neighboring communes are possible (citizens may use adjacent communes' offices) but would bias toward zero.

## Robustness

- Placebo: effect on left-wing (PS/LFI) vote share
- Dose-response: distance to nearest surviving tax office
- Heterogeneity: rural vs. urban communes; high vs. low elderly share
- Leave-one-département-out
- France Services mitigation test (communes that received a France Services counter vs. not)
