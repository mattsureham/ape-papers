# Research Plan: The Reporting Boomerang — Wage Responses to North Macedonia's Twelve-Month Progressive Tax Experiment

## Research Question

How do reported wages respond to a temporary progressive income tax? North Macedonia's 2019 reform introduced an 18% top bracket (above MKD 90,000/month) for exactly 12 months before reverting to the flat 10% rate. The symmetric on-off structure isolates short-run wage reporting responses from secular trends.

## Identification Strategy

**Continuous-treatment DiD with sector-level exposure variation.**

Treatment intensity = pre-reform sector mean wage / MKD 90,000 threshold (a Kaitz-like exposure ratio). High-exposure sectors (ICT: 0.68, Finance: 0.66, Electricity: 0.66) have more workers near or above the threshold than low-exposure sectors (Accommodation: 0.29, Manufacturing: 0.31).

Core specification:
```
ln(wage_st) = α_s + μ_t + β₁(Reform₁₉_t × Exposure_s) + β₂(Post₂₀_t × Exposure_s) + ε_st
```

- β₁ captures wage suppression during the 12-month progressive tax (2019)
- β₂ captures any persistent effect after repeal (2020+)
- The "boomerang" hypothesis: β₁ < 0, β₂ ≈ 0 (wages suppress then snap back)

**Key identification advantages:**
1. Symmetric shock eliminates trend confounds — if β₁ ≈ -β₂, the effect is causally attributable to the tax
2. 168 pre-treatment months (2005-2018) for robust parallel trends validation
3. Low-exposure sectors serve as within-country controls (no cross-country confounds)
4. Continuous treatment intensity avoids arbitrary binary classification

## Expected Effects and Mechanisms

**Primary hypothesis:** High-exposure sectors show wage suppression during 2019 (β₁ < 0) that reverses upon repeal (β₂ ≈ 0). The rapid reversal suggests reporting responses (shifting to non-wage compensation, timing) rather than real labor supply changes.

**Mechanism tests:**
- Gross-net wage gap: If employers shift to non-taxable compensation, gross wages fall more than net wages
- December-January timing: If firms time bonus payments to avoid the progressive bracket, we should see December bunching in 2018 and 2019

**Effect size prior:** Based on Saez (2010) and Kleven-Schultz (2014), elasticity of taxable income to marginal rate is typically 0.1-0.4. An 8pp rate increase (10→18%) on ~1% of taxpayers should produce small-to-moderate wage suppression in high-exposure sectors.

## Primary Specification

1. **Main DiD:** Continuous exposure × reform period interaction, sector and month FEs, wild cluster bootstrap (19 clusters)
2. **Event study:** Monthly leads and lags around Jan 2019, plotted by exposure quintile
3. **Permutation inference:** Randomize treatment timing across all months, compute p-values
4. **Placebo sectors:** Low-exposure sectors should show no response
5. **Gross-net decomposition:** Mechanism test for reporting vs real responses

## Data Source and Fetch Strategy

**Source:** Statistics North Macedonia PXWeb API (makstat.stat.gov.mk)
- Table 125_PazTrud_Mk_bruto_ml.px: Monthly gross wages by NACE sector (19 sectors × 252 months)
- Table 175_PazTrud_Mk_neto_ml.px: Monthly net wages by NACE sector

**Fetch:** POST request to PXWeb API with JSON query. No authentication required.

**Sample:** 19 NACE sectors × ~240 months (2005M01-2024M12) = ~4,560 observations

## Inference Strategy (addressing 19-cluster concern)

With 19 sector clusters, standard cluster-robust SEs are unreliable. We use:
1. Wild cluster bootstrap (Webb 6-point distribution, Cameron-Gelbach-Miller 2008)
2. Randomization inference (permute treatment timing)
3. Leave-one-out sensitivity (drop each high-exposure sector)
4. Effective F-statistics for continuous treatment
