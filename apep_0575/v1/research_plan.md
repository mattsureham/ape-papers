# Initial Research Plan: Bail-In Risk and Household Deposit Structure

## Research Question

Did the introduction of bail-in risk through the Bank Recovery and Resolution Directive (2014/59/EU) cause European households to restructure their bank deposits toward more liquid configurations?

## Background

The BRRD fundamentally changed the implicit government guarantee on bank deposits. Before BRRD, European governments routinely bailed out banks with taxpayer money — depositors bore no losses. After BRRD, uninsured deposits (above €100,000) sit in the loss-absorption cascade: equity → subordinated debt → senior unsecured debt → uninsured deposits. This creates a clear incentive for households with large deposits to restructure: shift from agreed-maturity deposits (locked in, harder to withdraw before bail-in) to overnight/redeemable deposits (liquid, can be withdrawn at first sign of trouble).

The existing literature on BRRD focuses on wholesale/capital market responses: bail-in bond premia (Giuliana 2022 JFE), CDS spreads (Schäfer et al. 2016), bank funding costs. No paper studies whether bail-in risk caused systematic deposit restructuring by the household sector — the largest depositor base in Europe.

## Identification Strategy

**Design:** Staggered difference-in-differences exploiting variation in national BRRD transposition dates across 25 EU countries (December 2014 to February 2016, 411 days of variation).

**Treatment variable:** Date of national BRRD transposition, from the IWH Banking Union Directives Database, cross-validated via CELLAR SPARQL (255 national implementation measures).

**Estimator:** Callaway and Sant'Anna (2021) heterogeneity-robust DiD with never-treated or not-yet-treated as comparison groups.

**Triple-difference:** Interact transposition timing with pre-BRRD uninsured deposit share (from EBA Deposit Guarantee Scheme data) as continuous treatment intensity. Countries where a larger share of deposits was uninsured should show stronger restructuring.

**Placebo groups:**
1. Corporate deposits (firms already disciplined via wholesale funding markets; should show weaker/no response)
2. Non-financial outcomes (employment, GDP) should be unaffected by deposit regulation timing

## Expected Effects and Mechanisms

**Primary prediction:** After BRRD transposition, households shift from agreed-maturity deposits to overnight/redeemable deposits — increasing the liquidity share of household deposits.

**Mechanism:** Bail-in risk makes illiquid deposits (agreed maturity, locked for months/years) riskier because they cannot be withdrawn if a bank enters resolution. Rational depositors should prefer liquid deposits that can be moved quickly.

**Heterogeneity predictions:**
- Stronger in countries with higher pre-BRRD uninsured deposit shares (more at-risk deposits)
- Stronger in countries with recent banking crises (Cyprus 2013 made bail-in salient)
- Weaker in countries with strong implicit government guarantees (e.g., Germany's bank-group guarantee systems)

## Primary Specification

$$Y_{ct} = \alpha_c + \gamma_t + \beta \cdot \text{Post-Transposition}_{ct} + X_{ct}'\delta + \varepsilon_{ct}$$

Where:
- $Y_{ct}$ = overnight deposit share (L21/L20) for households in country $c$, month $t$
- $\text{Post-Transposition}_{ct}$ = 1 after country $c$ transposes BRRD
- $X_{ct}$ = time-varying controls (ECB policy rate, country NPL ratio, GDP growth)
- Clustered at country level

**Triple-diff specification:**

$$Y_{ct} = \alpha_c + \gamma_t + \beta_1 \cdot \text{Post}_{ct} + \beta_2 \cdot \text{Post}_{ct} \times \text{UninsuredShare}_c + X_{ct}'\delta + \varepsilon_{ct}$$

Where $\text{UninsuredShare}_c$ = pre-BRRD (2013) share of uninsured deposits from EBA DGS data.

## Exposure Alignment (DiD)

- **Who is actually treated?** Households with uninsured deposits (>€100K) in countries that have transposed BRRD
- **Primary estimand population:** All households — we observe aggregate deposit composition, so the effect is an intent-to-treat on the full household deposit base
- **Placebo/control population:** Corporate deposits (sector 2240 in ECB BSI), non-financial outcomes
- **Design:** Staggered DiD with continuous intensity (triple-diff)

## Power Assessment

- Pre-treatment periods: 24 months (Jan 2013-Dec 2014) for early transposers; up to 26 months for late transposers
- Treated clusters: 25 EU countries (all eventually treated)
- Post-treatment periods: 24-38 months per cohort (depending on transposition date through Dec 2016+)
- Observations: ~25 countries × 60 months × 4 deposit types = ~6,000 country-month-type cells
- MDE: With 25 clusters, wild cluster bootstrap is essential; randomization inference over transposition dates

## Data Sources

1. **ECB BSI (Balance Sheet Items):** Monthly deposit data by maturity type (L20-L23) for household sector (S.2250). Available via ECB SDW API, no auth required.
2. **IWH Banking Union Directives Database:** BRRD transposition dates by country. Free download from bankinglibrary.com.
3. **CELLAR SPARQL / eurlex R package:** 255 BRRD national implementation measures with notification dates for cross-validation.
4. **EBA DGS data:** Covered/eligible deposit amounts by country (2015-2024). Excel download.
5. **ECB Statistical Data Warehouse:** ECB policy rates, country-level bank balance sheet aggregates.

## Planned Robustness Checks

1. **Event study:** Dynamic effects around transposition date (Callaway-Sant'Anna group-time ATTs)
2. **Rambachan-Roth sensitivity:** Bound effects under pre-trend violations
3. **Leave-one-out:** Remove each country to check no single country drives results
4. **Randomization inference:** Permute transposition dates across countries
5. **Wild cluster bootstrap:** Address small number of clusters (25)
6. **Placebo timing:** Test for effects at publication date (May 2014) vs transposition date
7. **Alternative outcomes:** Total deposit growth, cross-border deposit flows
8. **Corporate deposit placebo:** Same specification on non-financial corporation deposits
9. **Controlling for ECB QE:** Include ECB asset purchase program indicators
10. **Bail-in tool activation placebo:** Second event at Jan 1, 2016 (mandatory bail-in tool)
