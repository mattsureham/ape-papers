# Initial Research Plan: Municipal Mergers and Direct Democracy

## Research Question

Does municipal consolidation reduce citizen engagement in direct democracy? When Swiss communes merge, do residents of the newly enlarged municipality participate less in federal referendums? If so, does the decline reflect rational disengagement (free-riding in larger groups) or identity loss (severed community attachment)?

## Policy Setting

Switzerland reduced from ~2,900 municipalities in 2000 to ~2,200 by 2020 through approximately 700 voluntary bottom-up mergers. Mergers typically combine one or more small communes (< 1,000 inhabitants) into a neighboring larger commune. The process requires local referendum approval in each constituent commune. Major merger waves occurred in Fribourg (FR), Ticino (TI), Glarus (GL), Graubünden (GR), and Thurgau (TG), with some cantons providing financial incentives.

## Identification Strategy

**Staggered Difference-in-Differences (DiD).**

- **Treatment:** A commune undergoes merger (absorbed into a larger entity or absorbs smaller communes).
- **Timing:** Mergers occurred at different dates between ~1960 and 2025, with the bulk in 2000-2020.
- **Units:** Communes observed across federal referendum dates. For absorbed communes, we track the successor entity pre/post-merger.
- **Controls:** (1) Never-merged communes; (2) Not-yet-merged communes (clean control under staggered assumption).
- **Estimators:** Callaway & Sant'Anna (2021) for heterogeneity-robust group-time ATTs; Sun & Abraham (2021) as robustness. Stacked DiD with cohort-specific clean windows as additional check.

### Exposure Alignment

- **Who is treated?** Residents of communes that undergo merger. Both partners are treated — the absorbed commune loses its identity, the absorbing commune gains new residents.
- **Primary estimand:** ATT on federal referendum turnout for the merged successor entity, relative to its pre-merger constituents' population-weighted turnout.
- **Placebo population:** (1) Geographically adjacent communes not involved in any merger; (2) Communes in non-merging cantons; (3) Referendums on topics unrelated to local governance.

### Power Assessment

- **Pre-treatment periods:** 40+ years (referendums since 1960 for mergers in 2000s)
- **Treated clusters:** ~700 merger events since 2000 (hundreds of commune-level observations)
- **Post-treatment:** 5-25 years depending on merger cohort
- **Referendum frequency:** ~10 federal referendum dates per year × 503 votes = dense panel
- **Inference:** Cluster-robust SE at commune level. Wild cluster bootstrap. Randomization inference for sensitivity.
- **MDE:** With ~700 treated communes, ~1,500 controls, and ~40 referendum dates, the MDE for a 2pp turnout change is well below conventional power thresholds.

## Expected Effects and Mechanisms

**Main hypothesis:** Merger reduces referendum turnout in the successor entity relative to the population-weighted average of pre-merger constituent turnout. Expected magnitude: 1-4 percentage points.

**Mechanisms (decomposition strategy):**

1. **Free-riding/scale effect (rational):** Larger jurisdiction → individual vote matters less → rational abstention. Test: Effect should scale with the population INCREASE from merger (treatment intensity).

2. **Identity loss (behavioral):** Absorbed commune's residents lose community attachment → disengagement. Test: (a) Larger effects when absorbed commune's name disappears; (b) Larger effects on locally salient referendums (governance, fiscal) vs. nationally salient ones (immigration, defense).

3. **Cultural distance:** Merging with politically dissimilar partners → greater disruption. Test: Interact treatment with pre-merger vote divergence (measured as Jensen-Shannon divergence of voting patterns across prior referendums).

4. **Logistics/information:** Changed polling locations, reduced local political information. Test: Effects should be larger immediately post-merger and fade as new routines form.

## Primary Specification

```
Turnout_{ct} = α_c + γ_t + β × Post_Merger_{ct} + ε_{ct}
```

Where:
- c = commune (successor entity for merged communes, original for controls)
- t = referendum date
- α_c = commune fixed effects
- γ_t = referendum-date fixed effects
- Post_Merger_{ct} = 1 if commune c has merged by referendum date t

Implemented via `did::att_gt()` for staggered treatment.

## Planned Robustness Checks

1. **Pre-trend test:** Event-study with ±10 referendum windows; joint F-test on pre-treatment coefficients
2. **HonestDiD:** Rambachan & Roth (2023) sensitivity under M ∈ {0, 0.5Δ, Δ, 2Δ}
3. **Sun & Abraham (2021):** Interaction-weighted estimator
4. **Stacked DiD:** Clean cohort-specific 2×2 windows (Baker et al. 2022)
5. **Matched DiD:** Propensity score matching on pre-merger turnout trajectory, population, political composition
6. **Placebo outcomes:** Blank/invalid vote rates (should not be affected by merger per se)
7. **Placebo timing:** Randomly permute merger dates and compare effect distribution
8. **Excluding Glarus:** The 2011 Glarus mega-merger (25→3) is extreme; verify results hold without it
9. **Dose-response:** Interact treatment with merger size ratio (absorbed/surviving population)
10. **Geographic spillovers:** Test whether adjacent non-merged communes also show turnout changes

## Data Sources

| Data | Source | Granularity | Period | Access |
|------|--------|-------------|--------|--------|
| Referendum results | BFS PXWeb `px-x-1703030000_101` | Commune × vote | 1960-2025 | API (confirmed) |
| Population | BFS PXWeb `px-x-0102010000_101` | Commune × year | 2010-2024 | API (confirmed) |
| Merger timeline | SwissCommunes R package + BFS SMMT | Commune mutation | 1960-2025 | R package |
| Referendum metadata | Swissvotes (swissdd R package) | Vote-level | 1848-2026 | R package |
| Canton merger policies | Cantonal reports | Canton × year | 1990-2020 | Web search |

## Timeline

1. Data collection: Fetch voting data, merger timeline, population data
2. Panel construction: Build commune-referendum panel with harmonized boundaries
3. Descriptive analysis: Merger timeline, turnout trends, balance tables
4. Main estimation: CS-DiD, event studies
5. Mechanisms: Size, identity, cultural distance decomposition
6. Robustness: Full battery
7. Paper writing: 25+ pages following Shleifer clarity standard
