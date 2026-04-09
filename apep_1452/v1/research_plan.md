# Research Plan: The Indexation Cascade

## Research Question

Did Belgium's automatic wage indexation destroy jobs during the 2022–2023 energy crisis? The system forced 9–12% cumulative wage increases, but sectors received them at different times depending on their pre-committed collective agreement (annual in January vs. quarterly vs. upon each pivot crossing). This cross-sector timing variation identifies the employment effect of mandatory wage cost increases.

## Identification Strategy

**Two-way fixed effects DiD** (sector × quarter), exploiting the fact that Belgium's ~200 joint committees (commissions paritaires) specify different indexation timing rules:
- **Annual-January sectors** (CP 200, ~500K workers): received the full cumulative adjustment in Q1 2023
- **Quarterly sectors** (CP 124, construction): received four separate 2% shocks mid-2022
- **Pivot-triggered sectors** (healthcare): received immediate adjustments within 2 months of each crossing

The treatment variable is a constructed "cumulative indexation intensity" measuring the mandatory wage cost increase applied to each NACE sector through its joint committee regime, by quarter, 2021–2024.

**Identifying assumption:** Conditional on sector and time FE, sectors that received higher/earlier mandatory wage increases through pre-committed indexation regimes have the same counterfactual employment trend as sectors that received smaller/later increases.

**Key threats:**
1. Energy price levels affect sectors heterogeneously → control for sector energy intensity; time FE absorbs aggregate energy shock
2. COVID recovery heterogeneity → exclude accommodation/food services; pre-trend tests from 2018
3. Potential anticipation → indexation dates are mechanically triggered by CPI, no discretion

## Expected Effects and Mechanisms

**Prior:** Vandekerckhove and Cockx (2023) estimate labor demand elasticity of −0.6 using the 2015 suspension. The 2022–2023 episode is the opposite shock (forced increases, not decreases) and may show asymmetric effects.

**Expected:** Moderate negative effect on employment (0.3–0.8% per percentage point of wage increase), concentrated in labor-intensive, price-taking sectors. Possible hours adjustment rather than headcount.

**Mechanism:** Cost-push → margin squeeze → reduced hiring/increased separations, especially in sectors with elastic output demand.

## Primary Specification

```
Employment_{s,t} = α_s + γ_t + β × CumulativeIndexation_{s,t} + X_{s,t}'δ + ε_{s,t}
```

Where `s` indexes NACE sectors, `t` indexes quarters, and `CumulativeIndexation` is the log cumulative mandatory wage increase applied to sector `s` through quarter `t`.

## Data Sources

1. **Eurostat LFS** (`lfsq_egan2`): Quarterly employment by NACE Rev. 2 section for Belgium, 2018–2025. Confirmed accessible via API.
2. **Statbel Quarterly Wage Index**: 67 NACE subsectors, 2000–2023. XLS from statbel.fgov.be. Confirmed downloaded in smoke test.
3. **Joint committee indexation rules**: Published schedules from Pro-Pay/SD Worx mapping each CP to its indexation timing mechanism. Will be hand-coded (annual/quarterly/pivot) for the ~20 NACE sections.
4. **Eurostat hours worked** (`lfsq_ewhais`): Hours worked per person by NACE, quarterly.

## Robustness

- Event study plots around each pivot crossing
- Placebo: pre-2022 period with no indexation cascade
- Exclude COVID-affected sectors (accommodation, food)
- Alternative treatment: binary early-vs-late rather than continuous intensity
- Permutation inference given small number of sector clusters
