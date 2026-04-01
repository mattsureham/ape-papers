# Research Plan: De-Risking the Risk Haven

## Research Question

Does FATF grey-listing selectively damage internationally-oriented banks while shielding domestically-focused banks? We exploit Panama's June 2019 grey-listing and the pre-determined regulatory distinction between International License banks (restricted to cross-border operations) and General License banks (with domestic deposit bases) to estimate within-country differential effects on bank profitability and balance sheet composition.

## Identification Strategy

**Design:** Within-country difference-in-differences exploiting regulatory heterogeneity across bank license types.

**Treatment:** FATF grey-listing of Panama on June 21, 2019 (removed October 2023).

**Treatment group:** International License banks (~19 banks) — legally restricted to cross-border operations only, maximally exposed to correspondent banking pressure and enhanced due diligence.

**Control group:** General License private banks (~20 banks) — substantial domestic deposit bases provide partial insulation from international compliance pressure.

**Key identification assumptions:**
1. License type is pre-determined by law, not a response to FATF listing
2. Both bank types operate under the same SBP supervision, in the same country, under the same macro conditions
3. Parallel trends in profitability metrics before June 2019
4. No differential shocks to international vs. domestic banking coinciding with grey-listing

**Exposure alignment:** Treatment exposure is tightly aligned with outcomes at the bank-type level. International License banks are legally restricted to cross-border operations — their entire business model depends on correspondent banking relationships that grey-listing directly disrupts. The treatment (FATF grey-listing) affects the compliance cost of these relationships, and the outcomes (ROA, ROE) measure the profitability of the institutions bearing those costs. Who is treated: ~18-20 International License banks whose operations are 100% cross-border.

**Threats and mitigation:**
- COVID-19 (March 2020): Use pre-COVID window (June 2019 – Feb 2020) for short-run effects; de-listing (Oct 2023) provides post-COVID symmetric test
- Concurrent reforms: Panama implemented AML improvements during grey-listing period — these affect all banks equally
- Entry/exit: Monitor bank counts by license type for composition changes
- Prior grey-listing (2014-2016): International banks may have adapted during the first episode, muting the 2019 shock

## Expected Effects and Mechanisms

**Primary mechanism — "Intermediary Tax":** Grey-listing raises the compliance cost of transacting with Panamanian counterparties. International License banks, whose entire business model depends on cross-border flows, face the full burden. General License banks with domestic operations can partially substitute toward domestic business.

**Expected effects:**
- International License banks: decline in ROA, ROE; contraction in total assets and deposits
- General License banks: smaller or null effect on profitability; potential increase in domestic market share
- De-listing (Oct 2023): partial reversal, especially for international banks

## Primary Specification

$$Y_{it} = \alpha_i + \lambda_t + \beta \cdot (\text{International}_i \times \text{GreyList}_t) + \varepsilon_{it}$$

Where:
- $Y_{it}$: ROA, ROE, or log assets for bank type $i$ in month $t$
- $\alpha_i$: bank-type fixed effects
- $\lambda_t$: month fixed effects
- $\text{International}_i$: indicator for International License bank type
- $\text{GreyList}_t$: indicator for June 2019 – September 2023

**Robustness:**
- Event study specification with monthly leads/lags
- Pre-COVID restricted window (through Feb 2020)
- De-listing reversal analysis (post Oct 2023)
- Placebo tests using pre-treatment fake dates
- Leave-one-type-out sensitivity

## Data Source and Fetch Strategy

**Primary:** Superintendencia de Bancos de Panamá (SBP)
1. `Indicadores_Financieros.xlsx` — Monthly ROA, ROAA, ROE, capital adequacy by bank type (Jan 2016 – Aug 2025)
2. `BANCOS.xlsx` — Monthly listing of all operating banks with license type (Nov 2019 – Jul 2025)
3. Quarterly balance sheets by license type (assets, liabilities, deposits, loans)

**Secondary:** 
- World Bank Financial Development indicators for Panama (annual)
- FRED: Panama bank non-performing loans, deposits-to-GDP
- FATF mutual evaluation reports and follow-up reports (for institutional context)

**Fetch strategy:** Direct HTTP download from superbancos.gob.pa. Both files confirmed accessible (HTTP 200) in smoke test.
