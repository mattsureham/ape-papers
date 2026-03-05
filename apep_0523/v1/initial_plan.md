# Initial Research Plan: Does Taxing Vacant Housing Put Homes on the Market?

## Research Question

Does France's Taxe sur les Logements Vacants (TLV) — a tax on properties vacant for over one year — increase housing supply and affect property prices? We exploit the sharp 2023 expansion of TLV coverage from 1,138 to 3,693 communes to estimate causal effects on transaction volumes, prices, and property composition using the universe of French property transactions.

## Policy Background

France's TLV was introduced in 1998 (Article 232, Code Général des Impôts) to combat housing vacancies in tight markets. Key timeline:
- **1998**: TLV introduced for communes in agglomerations of 200,000+ inhabitants
- **2013** (Décret n°2013-392): Expanded to 1,138 communes across 28 urban units (threshold lowered to 50,000+ inhabitants)
- **August 25, 2023** (Décret n°2023-822): Expanded to 3,693 communes, adding ~2,555 communes including "zones touristiques tendues" (tourist areas with housing tension). Tax rates also increased from 12.5%/25% to 17%/34% of rental value.
- **December 22, 2025** (Décret n°2025-1267): Further expansion (not used in this study)

## Identification Strategy

**Staggered Difference-in-Differences** exploiting the August 2023 expansion:

| Group | N communes | Role |
|-------|-----------|------|
| Newly treated (2023) | ~2,555 | Treatment |
| Never treated | ~31,000 | Control |
| Always treated (since 2013) | ~1,100 | Placebo/validation |
| Lost treatment (2023) | ~35 | Reverse treatment |

**Primary estimand:** ATT on transaction volumes and prices in newly-treated communes, relative to never-treated communes.

**Estimator:** Callaway-Sant'Anna (2021), with treatment timing at 2024Q1 (first tax year). Alternative timing: 2023Q3 (decree publication/announcement).

**Key threats and defenses:**
1. *Anticipation*: Loi de finances 2024 debated fall 2022 → event study leads test for pre-trend violations; HonestDiD sensitivity analysis
2. *COVID confounding*: Region × quarter FE; results excluding 2020; matched control groups
3. *Spillovers*: Border commune analysis; distance gradient from treated boundary
4. *Concurrent policies*: Control for concurrent housing policies via always-treated placebo group

### Exposure Alignment (DiD Requirements)

- **Who is treated?** Property owners holding vacant dwellings in newly-covered communes
- **Primary estimand population:** Communes newly subject to TLV as of the 2023 decree
- **Placebo/control population:** (1) Never-treated communes (geographic control); (2) Always-treated communes (temporal placebo); (3) Non-vacant properties within treated communes (within-commune placebo)
- **Design:** Standard two-group DiD with CS estimator for staggered timing

### Power Assessment

- **Pre-treatment periods:** ~14 quarters (2020Q1–2023Q2)
- **Treated clusters:** ~2,555 communes
- **Post-treatment periods per cohort:** ~6 quarters (2024Q1–2025Q2)
- **MDE:** With 2,555 treated communes and hundreds of transactions per commune-year, even modest effects (2-5% price changes) should be detectable. Formal power calculations will be run after data assembly.

## Expected Effects and Mechanisms

1. **Transaction volume increase** (primary first-stage): TLV makes vacancy costly → owners sell/rent → more transactions. Expected: 5-15% increase in transaction volume in treated communes.
2. **Price decline** (main outcome): Increased supply → downward price pressure. Expected: small negative effect (1-5%), potentially attenuated by quality differences.
3. **Composition shift**: Vacant properties tend to be older/smaller → transactions shift toward these types. Testable via property type and surface area distributions.
4. **Heterogeneity by zone type**: "Zone tendue" vs. "zone touristique et tendue" may show different patterns (speculative vacancy vs. second-home vacancy).

## Primary Specification

$$Y_{ct} = \alpha_c + \gamma_t + \beta \cdot \text{TLV}_{ct} + X'_{ct}\delta + \varepsilon_{ct}$$

Where:
- $Y_{ct}$: outcome (log transactions, log median price/m²) in commune $c$, quarter $t$
- $\alpha_c$: commune fixed effects
- $\gamma_t$: quarter fixed effects (or region × quarter FE)
- $\text{TLV}_{ct}$: indicator = 1 if commune $c$ is newly subject to TLV and $t \geq$ 2024Q1
- $X_{ct}$: time-varying controls (population, income if available)
- Clustering: commune level (or département level for robustness)

## Planned Robustness Checks

1. **Event study** with quarterly leads/lags (-8 to +6 quarters around treatment)
2. **Callaway-Sant'Anna estimator** (group-time ATT, heterogeneity by cohort)
3. **Placebo tests**: (a) always-treated communes show no 2023 effect; (b) reverse treatment for 35 communes losing TLV status
4. **Matched controls**: CEM/propensity score matching on pre-treatment price levels, population, and trends
5. **HonestDiD/Rambachan-Roth** sensitivity to potential pre-trend violations
6. **COVID robustness**: exclude 2020; restrict pre-period to 2021-2023
7. **Spillover analysis**: border communes, distance gradient
8. **Heterogeneity**: zone tendue vs. touristique; urban vs. rural; high vs. low pre-treatment vacancy
9. **Randomization inference** for p-value validation
10. **Alternative treatment timing**: decree date (2023Q3) vs. first tax year (2024Q1)

## Data Sources

| Source | Variables | Granularity | Access |
|--------|-----------|-------------|--------|
| DVF (geo-DVF) | Transaction price, date, type, surface, location | Property-level, geocoded | Open bulk download |
| TLV zoning CSV | Commune TLV status (2013, 2023, 2025) | Commune | Open (data.gouv.fr) |
| INSEE BDM | Population, income controls | Commune/département × year | Open SDMX API |
| Sirene | Firm creation/cessation in real estate sector | Establishment-level | Open Parquet bulk |
| IGN AdminExpress | Commune boundaries (for adjacency/spillover) | Commune polygons | Open download |
