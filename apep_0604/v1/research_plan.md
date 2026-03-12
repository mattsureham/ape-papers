# Research Plan: Schooling After the Guns Fall Silent

## Research Question

Does the cessation of armed conflict cause educational recovery? And if so, does the peace dividend in education require active state investment, or does the mere absence of violence suffice?

## Policy Setting

Colombia's FARC guerrillas waged a 50+ year insurgency affecting ~170 municipalities. Two discrete shocks:
1. **FARC unilateral ceasefire** (December 20, 2014) — violence drops, but no new state investment
2. **PDET investment program** (Decree Law 893 of 2017, implementation ~2018) — $25B targeted to 170 PDET municipalities for school construction, roads, institutional capacity

## Identification Strategy

**Continuous-treatment Difference-in-Differences.** Treatment intensity = municipality-level FARC-attributed violent events per capita (2010–2014) from UCDP GED. Post = 2015+.

$$Y_{m,t} = \alpha_m + \gamma_t + \beta \cdot (\text{FARCintensity}_m \times \text{Post}_t) + X'_{m,t}\delta + \varepsilon_{m,t}$$

where $m$ indexes municipalities and $t$ indexes years.

**Two-shock decomposition:**
- Post1 = 2015–2017 (ceasefire only, no PDET yet)
- Post2 = 2018–2024 (ceasefire + PDET investment)

This separates the "safety channel" from the "investment channel."

**Exposure alignment:** The treatment variable (FARC event count 2010–2014) measures municipality-level exposure to FARC violence. The affected population is the school-age population in these municipalities. Educational outcomes (enrollment rates, dropout rates) are measured at the municipality-year level — the same geographic unit as treatment assignment. Municipality fixed effects absorb time-invariant differences in municipality characteristics. The identifying variation is within-municipality, over-time changes in education outcomes, comparing high-FARC municipalities to low-FARC municipalities before vs. after the ceasefire. One limitation: treatment is measured in raw event counts rather than per capita, so larger municipalities with more events may not have higher per-capita exposure. The binary specification (≥3 events) mitigates this by isolating genuine conflict zones regardless of municipality size.

## Expected Effects and Mechanisms

- **Primary prediction:** Secondary school enrollment (net) increases in high-intensity FARC municipalities after ceasefire, with larger effects after PDET
- **Mechanism 1 (safety):** Reduced violence → children can physically attend school → dropout falls
- **Mechanism 2 (investment):** PDET → new school construction, teacher deployment → enrollment rises
- **Mechanism 3 (composition):** Return migration to formerly violent areas → enrollment rises mechanically

## Primary Specification

Continuous-treatment DiD with municipality and year FEs. Cluster SEs at department level (~32 departments). Event-study version for pre-trend validation.

## Data Sources

1. **Education outcomes:** datos.gov.co resource `nudc-7mev` — municipal education panel 2011–2024 (net enrollment by level, dropout, approval rates)
2. **Conflict intensity:** UCDP GED (Uppsala Conflict Data Program Georeferenced Event Dataset) — event-level FARC attacks geocoded to municipalities
3. **PDET status:** Known list of 170 PDET municipalities from government publications
4. **Controls:** Municipal population, poverty rates from DANE

## Robustness Battery

1. Event-study pre-trend plots (2011–2014)
2. Placebo outcome: primary enrollment (less conflict-sensitive than secondary)
3. HonestDiD sensitivity bounds
4. Alternative treatment: binary (PDET yes/no) instead of continuous
5. Excluding department capitals (urban municipalities less affected)
6. Permutation inference on treatment intensity assignment
