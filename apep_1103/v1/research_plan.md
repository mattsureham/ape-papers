# Research Plan: The Rehabilitation Dividend — Cross-System Fiscal Spillovers from Switzerland's Disability Reforms

## Research Question

Do Switzerland's disability insurance (IV) reforms — which shifted from compensating disability to preventing it — reduce mandatory health insurance (OKP) costs? If disability prevention keeps people employed and healthier, the fiscal case for "rehabilitation before pension" is much stronger than DI savings alone suggest. We call this cross-system fiscal externality the **rehabilitation dividend**.

## Background

Switzerland reformed its disability insurance (Invalidenversicherung, IV) in two waves:

1. **5th IV Revision (January 1, 2008):** Introduced early intervention and early detection measures. IV offices could intervene before a person's health deteriorated to the point of requiring a full disability pension.

2. **6a IV Revision (January 1, 2012):** Targeted reintegration of existing pensioners, with a goal of moving 16,800 back toward employment within six years.

Both reforms were federal but implemented through cantonal IV offices with varying intensity. Some cantons embraced integration measures aggressively; others were more passive.

Switzerland also has a mandatory health insurance system (Obligatorische Krankenpflegeversicherung, OKP) funded by individual premiums that vary by canton. If disability prevention keeps people healthier, OKP per-capita costs should grow more slowly in cantons that implemented IV reforms more intensively.

## Identification Strategy

**Design:** Difference-in-differences exploiting cross-canton variation in IV reform implementation intensity around two reform dates (2008, 2012).

**Treatment variable:** Integration measures per capita by canton (from BFS PXWeb), measuring how intensively each canton implemented rehabilitation/early intervention.

**Outcome:** OKP per-capita gross health costs by canton and year (from OBSAN API, 2000–2024).

**Key specification:**
```
OKP_cost_{ct} = α + β · IntegrationIntensity_{ct} + γ_c + δ_t + X_{ct}'θ + ε_{ct}
```

Where:
- `c` indexes cantons, `t` indexes years
- `γ_c` = canton fixed effects (absorb time-invariant canton characteristics)
- `δ_t` = year fixed effects (absorb common health cost trends)
- `IntegrationIntensity_{ct}` = integration measures per 1,000 population
- `X_{ct}` = time-varying controls (population, age structure, unemployment)

**Event study:** Pre-period 2000–2007 (8 years before first reform); post-period 2008–2024.

**Identifying assumption:** Conditional on canton and year FEs, cantons with higher integration intensity would have followed parallel OKP cost trends absent the reforms.

**Threats and robustness:**
- Endogeneity of intensity: instrument with pre-reform canton characteristics (urbanization, industry mix, pre-2008 DI caseloads)
- Conservative inference: wild cluster bootstrap with 26 clusters
- Decompose OKP costs by type (ambulatory, inpatient, pharmaceutical) to test mechanism
- Placebo: test whether integration intensity predicts OKP costs in pre-reform period (should be null)

## Expected Effects and Mechanisms

**Positive channel (rehabilitation dividend):** People who stay employed maintain social connections, income, and physical activity → better health → lower OKP costs.

**Negative channel (cost shifting):** People denied disability who are genuinely sick seek more medical care → higher OKP costs.

**Net effect:** Empirically open — the sign reveals whether "rehabilitation before pension" generates health dividends or health costs.

## Data Sources

1. **OBSAN API:** OKP per-capita gross costs by canton and year (2000–2024, 26 cantons). Smoke test confirmed 2,025 records.
2. **BFS PXWeb (px-x-1305010000_042):** IV integration measures by canton (2006–2024).
3. **BFS PXWeb:** IV pension recipients by canton (for first-stage DI caseload outcomes).
4. **BFS PXWeb:** Cantonal population, age structure, unemployment for controls.

## Exposure Alignment

The treatment dose (2009 DI rate per 1,000) measures which cantons had more individuals potentially affected by the IV reforms. Higher-DI cantons had more people who could be diverted from disability pensions into rehabilitation under the 2008/2012 reforms. The outcome (OKP health costs per insured) captures the health spending of the entire insured population in each canton. Since DI recipients are a subset of OKP-insured individuals, the outcome variable is measured at the same unit level as the treatment exposure. However, the treatment captures disability burden rather than reform implementation intensity — a limitation.

## Primary Specification

1. **First stage:** Show that integration intensity reduced DI caseloads (validates the reform worked)
2. **Reduced form:** Show the relationship between integration intensity and OKP costs (the rehabilitation dividend)
3. **Event study:** Plot pre-trends and dynamic effects around both reform dates
4. **Decomposition:** Break OKP costs into ambulatory/inpatient/pharmaceutical
5. **Heterogeneity:** High vs low pre-reform DI caseload cantons (sample split)
