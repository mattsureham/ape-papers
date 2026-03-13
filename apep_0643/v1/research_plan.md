# Research Plan: apep_0643

## Research Question

Does paid family leave (PFL) attract workers or repel employers at state borders? Using contiguous border county pairs straddling PFL adoption boundaries, this paper estimates the causal effects of state PFL programs on female employment dynamics — decomposing the aggregate effect into hiring, separations, job creation, and job destruction channels that standard surveys cannot identify.

## Identification Strategy

**Border-county-pair difference-in-differences** (Dube, Lester, Reich 2010 style).

For each PFL adoption wave, pair treated border counties with adjacent control counties across the state line. Within county-pair × quarter cells, compare outcomes before and after PFL, stacking across waves with wave fixed effects.

**Specification:**
```
Y_{c,t,w} = α_{p(c),w} + γ_{t,w} + β · PFL_{c,t} + ε_{c,t,w}
```
Where p(c) denotes the county pair, w the wave, α are county-pair × wave FEs, γ are time × wave FEs. β captures the ATT of PFL on female labor market outcomes.

**Waves:**
1. New Jersey (Jul 2009) vs. PA, DE — ~15 border counties per side
2. New York (Jan 2018) vs. PA, VT — ~14 counties per side
3. Washington (Jan 2020) vs. ID — ~7 counties per side
4. Colorado (Jan 2024) vs. NE, KS, WY — ~13 counties per side

**Exposure alignment:**
PFL applies to workers based on their state of employment (not residence). QWI measures jobs located in each county. Thus treatment status (county in a PFL state) aligns with exposure: workers employed in PFL-state counties are eligible for PFL benefits, while workers employed in adjacent control-state counties are not. Cross-border commuters create some misalignment — a worker living in NJ but employed in PA would not receive NJ PFL benefits — but QWI captures employment at the workplace, so the treatment-outcome mapping is consistent. The relevant population is all UI-covered private-sector workers employed in border counties.

**Why this design is credible:**
- Adjacent border counties share local labor markets, amenities, and economic shocks
- County-pair FEs absorb all permanent differences
- Stacking across 4 independent waves provides external validity
- QWI is the universe of UI-covered employment (not survey-based)
- Directly addresses the parallel trends failure identified in apep_0041

## Expected Effects and Mechanisms

**Competing hypotheses:**
1. **Worker attraction:** PFL increases female labor force attachment → higher employment, lower separations
2. **Employer displacement:** PFL raises labor costs → firms shift hiring to control counties → lower job creation in treated counties
3. **Null at border:** PFL affects within-state composition but is too small to shift cross-border margins

**Primary outcomes (female):**
- Employment (Emp)
- Average monthly earnings (EarnS)

**Decomposition outcomes (the novel contribution):**
- All hires (HirA), new hires (HirN)
- Separations (Sep)
- Firm job gains (FrmJbGn), firm job losses (FrmJbLs)
- Turnover (TurnOvrS)

**Heterogeneity:**
- By education (QWI sex × education): Low-education women should show largest effects
- By industry: Healthcare (62), Retail (44-45), Accommodation/Food (72)

## Primary Specification

Main: female employment in all industries, border county pairs, 8 quarters pre through 16+ quarters post.

Event study: Estimate dynamic treatment effects at each quarter relative to PFL adoption.

Inference: Cluster at the state level (few clusters → wild cluster bootstrap). Also report county-pair clustered SEs.

## Data Source and Fetch Strategy

**QWI data from Azure Blob Storage:**
```
az://derived/qwi/sa/ns/*.parquet
```
Already confirmed: 133,467 county-quarter-sector observations for 68 border counties.

**Border county adjacency:** Census Bureau county adjacency file or manual identification of contiguous counties across state lines at PFL borders.

**No additional data downloads needed** — QWI in Azure covers all required variables.

## Robustness

1. Placebo: Male employment (minimal PFL effect expected)
2. Placebo: Government sector (exempt from PFL)
3. Bandwidth sensitivity: 50km, 100km, 200km from border
4. Leave-one-wave-out
5. Pre-trend tests and event study visualization (in tables)
6. Wild cluster bootstrap p-values (few state clusters)

## Feasibility Assessment

- Data: CONFIRMED (Azure QWI, 133K observations)
- Sample size: 68 border counties × 141 quarters = adequate
- Identification: Strong (border discontinuity + 4 waves)
- Novel contribution: First border-county-pair study of PFL; first worker-flow decomposition
