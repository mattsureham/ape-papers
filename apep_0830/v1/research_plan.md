# Research Plan: The Lottery Lever — Do Receipt Lotteries Close the VAT Gap?

## Research Question
Do consumer-as-auditor incentive mechanisms (receipt lotteries) reduce VAT compliance gaps? This paper exploits the staggered adoption and cancellation of VAT receipt lottery programs across 10 EU member states between 2013 and 2021 to estimate their causal effect on tax compliance.

## Identification Strategy
**Staggered difference-in-differences** using Callaway & Sant'Anna (2021). Treatment: binary indicator for active receipt lottery in country-year. 10 treated countries adopt at different times; 17 EU member states never adopt (controls). Three cancellations (Slovakia Feb 2021, Czech Republic Apr 2020, Poland Mar 2017) provide falsification: the compliance gap should widen after lottery cancellation.

**Key methodological notes:**
- Treatment can turn on AND off. Main specification uses de Chaisemartin & D'Haultfoeuille (2024) `DIDmultiplegtDYN` which handles treatment switching.
- Robustness with CS-DiD restricted to the adoption window (before any cancellation).
- Wild cluster bootstrap for inference (27 countries = borderline cluster count).
- HonestDiD sensitivity analysis for pre-trend violations.

## Expected Effects and Mechanisms
Receipt lotteries incentivize consumers to request receipts, making it harder for vendors to underreport sales. Theory (Gordon 1990): third-party reporting creates a "paper trail" that reduces evasion.

- **Primary:** Reduction in VAT-revenue-to-GDP gap after lottery adoption (negative effect on compliance gap / positive effect on VAT/GDP ratio).
- **Magnitude:** Naritomi (2019, AER) finds 22% increase in reported receipts in São Paulo. Cross-country effect likely smaller due to weaker enforcement, heterogeneous compliance cultures.
- **Cancellation:** Gap should widen (or VAT/GDP should decline) after cancellation — a reversal test.
- **Heterogeneity:** Stronger effects in countries with higher baseline compliance gaps (more room for improvement).

## Primary Specification
$$Y_{it} = \alpha_i + \lambda_t + \beta \cdot Lottery_{it} + \epsilon_{it}$$

Where $Y_{it}$ is VAT revenue as % of GDP for country $i$ in year $t$, $Lottery_{it}$ is binary treatment (active lottery), with country and year fixed effects. Implemented via `DIDmultiplegtDYN` for heterogeneity-robust estimation with treatment switching.

## Data Sources
1. **VAT revenue:** Eurostat `gov_10a_taxag` (tax code D211, sector S13) — annual, all EU members, 2005-2023
2. **GDP:** Eurostat `nama_10_gdp` — annual, current prices
3. **VAT gap estimates:** European Commission / CASE consortium annual reports — country-level estimates, backcasted 2000-2022 (manually coded from published reports)
4. **Controls:** GDP growth, trade openness, government effectiveness, shadow economy size

## Treatment Coding
| Country | Start | End | Notes |
|---------|-------|-----|-------|
| Malta | 1997 | present | Pre-dates Eurostat panel; may exclude from main spec |
| Slovakia | 2013-09 | 2021-02 | Cancelled |
| Portugal | 2014 | present | "e-Fatura" system |
| Romania | 2015-01 | present | "Loteria bonurilor fiscale" |
| Poland | 2015-10 | 2017-03 | Ended (National Lottery of Tax Receipts) |
| Czech Republic | 2017-10 | 2020-04 | Cancelled ("Účtenkovka") |
| Greece | 2017-06 | present | Linked to card payment incentives |
| Latvia | 2019-07 | 2023-02 | Discontinued |
| Lithuania | 2019-11 | present | |
| Italy | 2021-02 | present | "Lotteria degli scontrini" |

## Exposure Alignment
The treatment (receipt lottery) operates at the national level—all retail transactions in a country are covered. The unit of treatment, observation, and outcome are all country-year. VAT/GDP captures the aggregate compliance margin: if the lottery induces more receipt requests, vendors report more sales, and VAT collections increase relative to GDP. The outcome is measured at the same level as treatment assignment (country-year), so there is no measurement-treatment mismatch. The key concern is not exposure misalignment but rather the coarseness of the outcome: VAT/GDP is influenced by rate changes, exemption reforms, and structural economic shifts in addition to compliance. Year fixed effects absorb EU-wide shocks, and the income tax placebo controls for country-specific macroeconomic confounders.

## Analysis Plan
1. Fetch VAT revenue and GDP from Eurostat API
2. Construct VAT/GDP ratio panel (27 countries × 19 years)
3. Code treatment variable from lottery adoption/cancellation dates
4. Callaway-Sant'Anna event study (adoption cohorts only, excluding cancellation periods)
5. De Chaisemartin-D'Haultfoeuille with treatment switching for main spec
6. Cancellation analysis: separate event study around cancellation dates
7. Robustness: wild cluster bootstrap, HonestDiD bounds, placebo outcomes (income tax revenue/GDP)
8. Heterogeneity: by baseline compliance gap level
