# Research Plan: The Fiscal Anatomy of Municipal Consolidation

## Research Question

Where do economies of scale materialize when municipalities merge? Swiss municipal mergers (2000–2023) dissolved ~1,000 communes into larger successors. Prior work reports mixed aggregate fiscal effects. This paper decomposes spending responses by functional category — administration, education, social welfare, health, transport, environment — to show which government functions drive consolidation savings and which resist them.

## Identification Strategy

**Staggered difference-in-differences** using Callaway & Sant'Anna (2021).

- **Treated units:** Municipalities that merged (dissolved into successors), grouped by merger year cohort.
- **Control units:** Never-merged municipalities over the sample period.
- **Treatment timing:** Staggered, 2000–2023, with ~250+ merger events.
- **Estimand:** Group-time average treatment effects on per-capita functional spending, aggregated into event-study plots (t−5 to t+10).

**Key identification assumption:** Parallel trends in per-capita spending by function between merging and never-merged municipalities in the pre-treatment period.

## Expected Effects and Mechanisms

1. **Administration spending** — expected to decline (elimination of duplicate executives, councils, administrative staff)
2. **Education spending** — expected to remain stable or increase (service harmonization upward, facility consolidation)
3. **Social welfare spending** — expected to remain stable (demand-driven, not scale-dependent)
4. **Infrastructure/transport** — ambiguous (initial investment in integration vs. long-run rationalization)
5. **Total spending** — modest decline, driven primarily by administration

**Named mechanism:** The "overhead illusion" — aggregate merger savings are often overstated because they reflect administrative overhead compression, not genuine service-delivery efficiency gains.

## Primary Specification

```
Y_{it} = α_i + γ_t + τ_{g,t} + ε_{it}
```

Where `Y_{it}` is per-capita spending in function f for municipality i in year t, estimated separately by spending category using `did::att_gt()` with never-treated controls.

## Data Sources and Fetch Strategy

1. **BFS Historisiertes Gemeindeverzeichnis (Mutations API)**
   - URL: `https://www.bfs.admin.ch/bfs/en/home/basics/nomenclatures/official-commune-register/commune-mutations.html`
   - Content: All municipality mutation events (mergers, dissolutions, name changes) with dates
   - Format: Downloadable CSV/Excel

2. **BFS Municipal Finance Statistics (Finanzstatistik der Gemeinden)**
   - PXWeb API for municipal-level public finance data
   - Functional classification: general administration, public safety, education, culture, health, social welfare, transport, environment, economy
   - Years: ~2000–2022

3. **SMMT R package** — For longitudinal panel harmonization of municipality IDs across mergers

4. **Fallback:** Canton Zurich Jahresrechnungen (192 indicators, 1995–2024) if national data lacks functional detail

## Exposure Alignment

The treatment in this design is the administrative restructuring that occurs when municipalities merge. The exposed units are the successor municipalities — the entities that absorbed dissolved communes and inherited their administrative functions. Pre-merger, successor municipalities had their own administrative structure; post-merger, they also manage the formerly separate administrations of dissolved communes. The spending outcomes (per-capita net expenditure) are measured at the municipality level, which aligns with the unit of treatment exposure. Controls are never-merged municipalities in Canton Zurich, which experienced no structural change to their administrative boundaries during the sample period. The key identification concern is that merger timing is not correlated with unobserved spending shocks — addressed through the institutional argument (merger timing driven by cantonal policy windows, not fiscal distress) and pre-trend tests.

## Robustness Checks

- Pre-trend tests (event-study coefficients t−5 to t−1)
- HonestDiD sensitivity analysis (Rambachan & Roth bounds)
- Placebo: cantonal transfer payments (formula-based, should not respond to mergers)
- Leave-one-canton-out stability
- Alternative estimators (Sun & Abraham, stacked DiD)
- Heterogeneity by merger size (small vs. large mergers by population)
