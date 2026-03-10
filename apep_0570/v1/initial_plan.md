# Initial Research Plan: The Anatomy of Tax Pass-Through

## Research Question

Do consumer prices adjust symmetrically to indirect tax removal and reimposition? Malaysia's 2018 GST-to-SST switch provides a uniquely clean laboratory: on June 1, the 6% GST was zeroed across all standard-rated products (after a surprise election result); on September 1, a narrower SST was reimposed covering only a subset of those products. This sequential shock structure allows within-product comparison of downward vs. upward price adjustment — a direct test of asymmetric pass-through ("rockets and feathers") for indirect taxes.

## Identification Strategy

**Design:** Triple-difference (product tax status × post-June 2018 × post-September 2018).

**Three product groups (predetermined by legislation):**
- **Group A (Full cycle):** Standard-rated under GST AND covered by SST → prices should drop in June, partially recover in September.
- **Group B (Permanent windfall):** Standard-rated under GST but NOT covered by SST → prices should drop in June and stay low.
- **Group C (Control):** Zero-rated or exempt under GST → no price change expected in either period.

**Primary specification:**
$$\log(CPI_{it}) = \alpha_i + \alpha_t + \beta_1(\text{PostJune}_t \times \text{Standard}_i) + \beta_2(\text{PostSept}_t \times \text{Standard}_i \times \text{SST}_i) + \varepsilon_{it}$$

- $\beta_1$: Pass-through from GST removal (expected negative; full pass-through ≈ −5.7% = −log(1.06))
- $\beta_2$: Incremental price recovery from SST reimposition (expected positive for SST-covered products)

**Key identifying assumptions:**
1. Absent the tax change, CPI trends for standard-rated and zero-rated/exempt products would have been parallel. Testable with 96+ months of pre-treatment data (Jan 2010 – May 2018).
2. The June 1 zeroing was sudden (announced May 16, 2018; 16 days notice) following a genuinely surprising election outcome (first government change since 1957).
3. Product tax classifications were predetermined by GST Act 2014, not chosen by firms in response to the 2018 reform.

**Estimand population:** All 101 CPI product classes covering the Malaysian consumer basket.

**Placebo/control population:** Zero-rated and exempt product classes (housing, education, health, basic food).

## Expected Effects and Mechanisms

1. **Incomplete downward pass-through:** Firms may not fully pass tax cuts to consumers due to menu costs, market power, or coordination failures. Expected β₁ > −0.057 (i.e., less than full pass-through of 6% GST).
2. **Faster upward adjustment ("rockets"):** Firms may pass SST reimposition more completely, consistent with Peltzman (2000) asymmetry. Expected β₂/SST_rate > |β₁|/GST_rate.
3. **Market structure channel:** Products with less retail competition should show larger incomplete pass-through (higher margins absorbed during removal, higher margins charged during reimposition).
4. **Welfare:** The 3-month "tax holiday" (June–August 2018) generated consumer surplus gains that varied across products and income groups.

## Primary Specification

Event-study version (preferred for visualization):
$$\log(CPI_{it}) = \alpha_i + \alpha_t + \sum_{k \neq -1} \gamma_k \cdot \mathbf{1}[t = k] \times \text{Standard}_i + \varepsilon_{it}$$

where k indexes months relative to June 2018 (k = −1 is May 2018, the omitted reference period).

TWFE DiD version (for tables):
$$\log(CPI_{it}) = \alpha_i + \alpha_t + \beta_1 \text{Post}_t \times \text{Treated}_i + \varepsilon_{it}$$

Standard errors clustered at the product-class level (101 clusters — sufficient for cluster-robust inference).

## Planned Robustness Checks

1. Event study with 48+ pre-treatment periods to assess parallel trends
2. Placebo timing tests (move treatment to June 2017, June 2016)
3. Leave-one-class-out stability
4. Alternative classification using 2-digit division aggregation
5. Randomization inference (permute treatment assignment across product classes)
6. HonestDiD sensitivity analysis for parallel trends violations
7. Controlling for global commodity prices (oil, food indices)
8. Excluding the 2015 GST introduction window as a separate check

## Power Assessment

- **Product classes:** 101 (≥70 treated, ≥30 control)
- **Pre-treatment periods:** 100 months (Jan 2010 – May 2018)
- **Post-treatment periods:** 93 months (June 2018 – Jan 2026)
- **Observed effect sizes:** 2–4% price drops in June 2018 for treated categories
- **Power:** With 101 product classes and >100 pre-periods, even small effects (1%) should be detectable

## Data Sources

| Source | Variables | Coverage | Access |
|--------|-----------|----------|--------|
| OpenDOSM CPI 4-digit | 101 product class price indices, monthly | Jan 2010 – Jan 2026 | Parquet, no key |
| OpenDOSM CPI 2-digit | 14 division indices, monthly | Jan 2000 – Jan 2026 | Parquet, no key |
| Malaysian GST Act 2014 | Product tax classification (standard/zero/exempt) | 2015–2018 | Legislation |
| SST Acts 2018 | Product SST coverage | Sept 2018+ | Legislation |
