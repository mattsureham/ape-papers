# Research Plan: The First Wage Floor for Women

## Research Question

Did America's first minimum wage laws (1912–1920), which targeted women workers in specific industries, retain women in the labor force or push them out? Using individual-level linked census data, this paper estimates whether these laws caused women in covered industries to remain in the labor force, persist in the same industry, and upgrade occupationally — or whether the "protective" legislation functioned as an exclusionary barrier.

## Policy Background

Between 1912 and 1920, fourteen US states enacted minimum wage laws specifically for women workers:
- **1912:** Massachusetts (advisory only)
- **1913:** California, Oregon, Washington, Minnesota, Wisconsin, Utah, Nebraska, Colorado
- **1913–1915:** Arkansas, Kansas
- **1917:** Arizona
- **1919:** North Dakota, Texas

These laws covered women in manufacturing, laundry, retail, and hospitality but **exempted domestic service and agriculture**. The exemption creates a built-in within-state control group.

## Identification Strategy

**Triple-Difference (DDD):**

Y_ist = α + β₁(MW_s × Covered_i × Post_t) + β₂(MW_s × Post_t) + β₃(Covered_i × Post_t) + β₄(MW_s × Covered_i) + δ_s + λ_i + γ_t + X'_ist θ + ε_ist

Where:
- MW_s = 1 if individual's 1910 state enacted a minimum wage law by 1920
- Covered_i = 1 if individual's 1910 industry was covered (manufacturing, laundry, retail, hospitality)
- Post_t = 1 for 1920 observation
- δ_s, λ_i, γ_t = state, industry, and time fixed effects

**Key identifying assumption:** In the absence of MW laws, the gap between covered and exempt industries in MW states would have evolved parallel to the same gap in non-MW states.

**Built-in placebo:** Men in the same covered industries in MW states (laws targeted women only).

## Expected Effects and Mechanisms

Two competing hypotheses from the historical literature:

1. **Protection hypothesis:** Minimum wages raised the floor, preventing exploitative wages, thereby retaining women in covered industries. Prediction: β₁ > 0 for retention, ≥ 0 for occupational score.

2. **Exclusion hypothesis:** Employers substituted men for women when forced to pay women more. Prediction: β₁ < 0 for retention, possible positive selection on occupation score among remaining women.

The smoke test suggests +1.89pp retention — consistent with the protection hypothesis.

## Primary Specification

Three outcomes:
1. **Labor force retention** (binary): Is the woman in the labor force in 1920?
2. **Industry persistence** (binary): Is the woman in the same 1950-coded industry in 1920?
3. **Occupational upgrading** (continuous): Change in occupation score (occscore) from 1910 to 1920.

Clustering: State level (14 MW + 35 non-MW = 49 clusters). Given <50 clusters, will use wild cluster bootstrap.

## Data Source and Fetch Strategy

**Primary:** MLP (Multi-Linkage Panel) 1910–1920 linked census panel on Azure Blob Storage.
- Path: `az://derived/mlp_panel/linked_1910_1920.parquet`
- Size: 43.9 million individuals linked across 1910 and 1920 censuses
- Variables: occ1950, ind1950, occscore, statefip, sex, race, age, nativity, lit
- Filter to women (sex == 2) for main analysis; men for placebo

**Treatment coding:**
- 14 MW states identified by statefip codes
- Covered industries identified by ind1950 codes for manufacturing, laundry, retail, hospitality
- Exempt industries: domestic service, agriculture

**No external API calls needed** — data is already on Azure.
