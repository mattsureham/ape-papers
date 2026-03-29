# Research Plan: Who Really Pays? Romania's Overnight Payroll Tax Shift and the Irrelevance of Statutory Incidence

## Research Question

Does shifting the statutory burden of social security contributions from employers to employees affect the economic incidence of payroll taxes? Romania's January 2018 reform — which transferred nearly the entire employer SSC to employees overnight (employer rate: 22.75%→2.25%; employee rate: 16.5%→35%) — provides the most extreme test of statutory incidence irrelevance in modern economic history.

## Identification Strategy

**Cross-country × sector Difference-in-Differences.** Romania is the only EU country to implement a near-complete overnight payroll tax shift. Using Eurostat's quarterly Labour Cost Index (LCI) decomposed into wages (D11) and non-wage costs (D12), we compare Romania's wage and non-wage cost trajectories across NACE sectors against 25 EU control countries.

**Primary specification:**
$$Y_{cst} = \alpha + \beta_1 (\text{Romania}_c \times \text{Post}_t) + \gamma_{cs} + \delta_{ct} + \lambda_{st} + \varepsilon_{cst}$$

Where $c$ = country, $s$ = sector, $t$ = quarter. Three-way fixed effects: country×sector, country×quarter, sector×quarter.

**Addressing single-treated-country concerns:**
1. **Synthetic Control Method (SCM):** Construct synthetic Romania from weighted EU donors for wage and non-wage cost indices. Permutation inference: reassign treatment to each donor country.
2. **Placebo tests:** Apply Romania's treatment to each of the 25 EU control countries, estimate 25 pseudo-treatment effects, compare Romania's actual effect to the distribution.
3. **Event study:** Quarter-by-quarter coefficients centered on 2018-Q1, testing parallel pre-trends over 8 quarters (2016-Q1 to 2017-Q4).
4. **Sector heterogeneity:** Competitive vs. regulated sectors should show different pass-through rates (mechanism test).

**Key assumption:** Absent the reform, Romania's wage/non-wage cost trajectories would have continued parallel to CEE peers (BG, HU, PL, CZ, SK). Testable over 8 pre-quarters.

**Exposure alignment:** Treatment affects all formal-sector employers in Romania simultaneously (universal reform, no opt-out). The Eurostat LCI covers the business economy (NACE B-S), which is the full exposure universe — all firms employing workers under Romanian social security law are affected. Control countries (BG, CZ, HU, PL, SK) share similar labor market structures and EU membership but experienced no comparable SSC reform in this period.

## Expected Effects and Mechanisms

**Textbook prediction (Gruber 1997; Saez et al. 2019):** Statutory incidence is irrelevant — in equilibrium, who writes the check doesn't matter. If labor markets clear, the reform should produce:
- Sharp increase in gross wages (to offset employee SSC increase)
- Sharp decrease in non-wage labor costs (employer SSC collapse)
- Near-zero change in total labor costs
- Near-zero change in employment

**Alternative:** If labor markets feature rigidities (minimum wage binding, nominal wage downward rigidity), statutory incidence could matter. Romania's simultaneous 31% minimum wage increase complicates the pure test — we address this by focusing on sectors where the minimum wage is non-binding.

**Predicted magnitudes (from smoke test):**
- Non-wage costs: −77% (Q1 2018 vs Q4 2017) — massive, self-identifying
- Wages: +20% — consistent with near-full employer-to-employee pass-through
- Employment: near zero — standard prediction under full incidence neutrality

## Primary Specification

**Outcome variables:**
1. Labour Cost Index — Wages/Salaries (D11), index 2020=100
2. Labour Cost Index — Non-wage costs (D12+D4-D5), index 2020=100
3. Total Labour Cost Index (sum)
4. Ratio: Non-wage / Total (share of employer SSC in total compensation)

**Sample:**
- Core: 6 CEE countries (RO, BG, HU, PL, CZ, SK) × 8 NACE sectors × 16 quarters (2016Q1–2019Q4)
- Extended: 26 EU countries × up to 26 NACE sectors × 16+ quarters
- Pre-treatment: 2016-Q1 to 2017-Q4 (8 quarters)
- Post-treatment: 2018-Q1 to 2019-Q4 (8 quarters, stopping before COVID)

**Robustness:**
- SCM with permutation inference
- Longer pre-period (2012-Q1 to 2017-Q4)
- Industry-level heterogeneity (tradeable vs. non-tradeable)
- Employment response (Eurostat nama_10_a64_e)
- Placebo on 2017-Q1 (false treatment date)

## Data Source and Fetch Strategy

**Primary:** Eurostat REST API via `eurostat` R package
- Table `lc_lci_r2_q`: Labour Cost Index, quarterly, NACE sector × country
  - Variables: D11 (wages/salaries), D12_D4_MD5 (non-wage costs)
  - Coverage: 2008-Q1 to present, 26+ EU countries, 8-26 NACE sectors
  - Index: 2020 = 100 (rebased)
  - Confirmed accessible: 1,536+ observations in smoke test

**Secondary:**
- `nama_10_a64_e`: Employment by NACE sector × country (annual)
- `sts_trtu_q`: Turnover indices (quarterly)
- `earn_ses_annual`: Wage distribution data

**Fetch plan:**
1. Download lc_lci_r2_q for all EU countries, all NACE sectors, 2012Q1-2019Q4
2. Filter to D11 (wages) and D12_D4_MD5 (non-wage costs) separately
3. Reshape to country × sector × quarter panel
4. Merge employment data for sector size weights

No API keys required — Eurostat is fully open.
