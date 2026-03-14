# Research Plan: Environmental Regulation as Housing Supply Constraint

## Research Question

What is the causal effect of nutrient neutrality regulations on residential development in England? Natural England's staggered nutrient neutrality advice to 74 local planning authorities (32 in 2019, 42 more in March 2022) created an effective moratorium on housing development in affected areas. We estimate the impact on planning approvals and net housing additions.

## Identification Strategy

**Staggered Difference-in-Differences** using Callaway-Sant'Anna (2021).

- **Treatment:** Binary indicator for whether an LPA has received nutrient neutrality advice from Natural England
- **Wave 1 (2019):** 32 LPAs received advice (linked to Solent, Somerset Levels, Stodmarsh catchments)
- **Wave 2 (March 2022):** 42 additional LPAs received advice (Broads, Teesmouth, Humber Estuary, etc.)
- **Controls:** ~230 never-treated LPAs in England
- **Assignment mechanism:** Hydrology and proximity to designated habitat sites — plausibly exogenous to housing demand trends

## Expected Effects and Mechanisms

- **Primary:** Reduction in planning approvals (major residential) in treated LPAs
- **Secondary:** Reduction in net additional dwellings delivered
- **Mechanism:** Nutrient neutrality advice creates a de facto moratorium — developments that would add wastewater cannot demonstrate neutrality, so planning permissions are refused or delayed
- **Expected direction:** Negative (fewer approvals, fewer completions)
- **Magnitude:** Industry estimates suggest 150,000+ homes stalled; we estimate the per-LPA effect

## Primary Specification

$$Y_{it} = \alpha_i + \gamma_t + \tau \cdot \text{ATT}(g,t) + \varepsilon_{it}$$

Using Callaway-Sant'Anna with:
- Unit: Local Planning Authority (LPA)
- Time: Financial quarter (MHCLG PS1 data)
- Outcome: Number of major residential planning decisions granted / total decisions
- Treatment cohorts: g ∈ {2019Q2, 2022Q1}
- Control group: Never-treated LPAs
- Clustering: LPA level

## Data Sources

1. **MHCLG PS1 Planning Application Statistics** — Quarterly planning decisions by LA, 1996-2025 (~462 LAs). CSV download from gov.uk. Key variables: district, quarter, major residential decisions granted/refused/total.

2. **MHCLG Live Table 122** — Annual net additional dwellings by LA, 2001-2025. ODS from gov.uk.

3. **Nutrient neutrality LPA list** — From Natural England guidance documents. Two waves: 2019 (32 LPAs) and March 2022 (42 LPAs).

## Exposure Alignment

The treatment — nutrient neutrality advice from Natural England — directly constrains planning decisions in the affected LPAs. The PS1 outcome (total planning applications decided) captures the primary margin of policy impact: LPAs cannot grant permissions for developments that cannot demonstrate nutrient neutrality. The treatment is binary at the LPA level (advice received or not), and the outcome measures the same units' planning activity. The assignment is determined by hydrology (river catchment boundaries draining into protected habitat sites), which is plausibly exogenous to housing demand trends. A potential concern is that PS1 captures all application types (residential + commercial), not residential-only, making the outcome a conservative measure of the true residential impact.

## Robustness Checks

1. Event study with pre-treatment coefficients (verify parallel trends)
2. HonestDiD sensitivity analysis (Rambachan-Roth bounds)
3. Placebo outcomes (commercial planning decisions)
4. Displacement test (approvals in neighboring unaffected LPAs)
5. Alternative control groups (not-yet-treated for Wave 1 analysis)
