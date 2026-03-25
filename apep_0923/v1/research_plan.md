# Research Plan: The End of Banking Secrecy

## Research Question

Does the automatic exchange of tax information (AEOI/CRS) reduce cross-border deposits in Switzerland, and what are the downstream consequences for Swiss financial sector employment and bank survival? We exploit the staggered bilateral activation of Switzerland's AEOI agreements with 100+ partner countries between 2017 and 2020.

## Identification Strategy

**Staggered Difference-in-Differences** on a country-quarter panel of bilateral Swiss bank liabilities.

- **Treatment:** AEOI activation date for each bilateral pair (Switzerland ↔ partner country j). First wave (38 countries, mostly EU) activated January 1, 2017; second wave (Argentina, Brazil, India, etc.) January 1, 2018; third wave brought total to ~97 by 2020.
- **Identifying assumption:** Parallel trends in bilateral deposits from early- vs. late-activating countries, conditional on country and quarter fixed effects.
- **Estimator:** Callaway-Sant'Anna (2021) for heterogeneous treatment timing. Event study for pre-trend validation.

## Expected Effects and Mechanisms

1. **Primary (deposit outflow):** AEOI activation should reduce deposits from affected countries as undeclared wealth holders withdraw or relocate funds. Expected sign: negative, moderate magnitude.
2. **Mechanism — relocation vs. repatriation:** If deposits shift to non-AEOI jurisdictions (Singapore, Hong Kong pre-2024), total Swiss deposits fall but global offshore wealth is merely reshuffled. If deposits are repatriated, this represents genuine formalization.
3. **Downstream — Swiss financial sector:** Aggregate foreign deposit decline should reduce fee income, leading to bank exits (especially small private banks serving foreign clients) and financial sector employment losses.

## Primary Specification

$$\text{Deposits}_{jt} = \alpha_j + \gamma_t + \tau \cdot \text{AEOI}_{jt} + \epsilon_{jt}$$

Where $j$ indexes partner countries, $t$ indexes quarters, $\alpha_j$ are country FE, $\gamma_t$ are quarter FE, and $\text{AEOI}_{jt}$ is an indicator for whether Switzerland's AEOI agreement with country $j$ is active in quarter $t$.

## Data Sources

1. **BIS Locational Banking Statistics** (primary): Quarterly bilateral data on Swiss bank liabilities to counterparty country $j$. CSV bulk download from BIS website. ~200+ countries, 2005-2023.
2. **SNB Banking Statistics**: Number of banks by category (foreign-controlled banks declined 82→60, 2015-2024). Bank balance sheet data.
3. **BFS Employment Statistics**: Financial sector employment (NOGA 64) — declined 131K→117K (-11%, 2014-2018).
4. **AEOI activation dates**: From Swiss Federal Tax Administration (ESTV) and OECD CRS implementation tracker.

## Fetch Strategy

1. Download BIS LBS CSV bulk files (confirmed HTTP 200).
2. Filter to Switzerland as reporting country, extract bilateral liabilities by counterparty country and quarter.
3. Construct AEOI activation dates from ESTV published list.
4. Merge activation dates with BIS panel.
5. Download SNB aggregate statistics for downstream analysis.
6. Download BFS employment data via PXWeb API.

## Robustness Checks

- Event study with ±8 quarter leads/lags
- Placebo: fake activation dates (2 years early)
- Leave-one-out: drop each cohort
- Alternative outcomes: log deposits, deposit growth rate, deposit share
- Heterogeneity: EU vs non-EU, tax haven vs non-haven counterparties, pre-AEOI deposit level
- Wild cluster bootstrap (few cohorts concern)
