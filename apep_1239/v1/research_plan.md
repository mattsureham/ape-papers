# Research Plan: apep_1239

## Research Question

Did Switzerland's 2008 NFA reform — which replaced earmarked conditional federal transfers with unconditional block grants — change how cantons allocate public spending? And did the resulting fiscal redistribution alter inter-cantonal population sorting?

The core mechanism to test is the **earmark illusion**: if conditional transfers merely relabeled spending that cantons would have done anyway, removing the earmarks should produce no change in expenditure composition. Conversely, if earmarks genuinely constrained cantonal budgets, the shift to unconditional grants should reveal cantons' true spending preferences — redirecting funds toward locally preferred categories.

## Identification Strategy

**Continuous-treatment difference-in-differences** with a common sharp cutoff (January 1, 2008).

- **Treatment intensity:** Annual NFA transfer amount per capita (CHF), published by EFV. Net-recipient cantons receive CHF 300–1,200/capita; net-payer cantons transfer CHF 100–800/capita. Near-zero cantons serve as de facto controls.
- **Unit of observation:** Canton × year, 2001–2022
- **Pre-period:** 7 years (2001–2007)
- **Post-period:** 14 years (2008–2022, or latest available)

**Main specification:**
$$Y_{ct} = \alpha_c + \gamma_t + \beta \cdot (NFA\_Transfer_{ct} \times Post_t) + \varepsilon_{ct}$$

Where $NFA\_Transfer_{ct}$ is per-capita net transfer (positive for recipients, negative for payers), and $Post_t = \mathbf{1}[t \geq 2008]$.

**Event study version:** Replace $\beta$ with year-specific coefficients $\beta_k$ for $k \in \{-6, ..., -1, 0, 1, ..., 14\}$, normalizing $\beta_{-1} = 0$.

## Expected Effects and Mechanisms

1. **Expenditure composition (earmark illusion test):** If earmarks were binding, switching to unconditional grants should shift spending toward locally preferred categories (e.g., infrastructure, culture) and away from federally mandated categories. If earmarks were non-binding, expenditure shares should be stable across the reform.

2. **Tax multipliers:** Net-recipient cantons receiving unconditional windfall transfers may lower Steuerfuss (tax multipliers) to attract residents/firms — a fiscal competition channel. Alternatively, they may keep rates stable and increase services.

3. **Inter-cantonal migration (Tiebout sorting):** If NFA improves public services in recipient cantons without raising taxes, we should observe net in-migration to recipient cantons. This tests whether fiscal equalization durably alters the Tiebout sorting equilibrium.

## Primary Specification

- **Outcome 1:** Cantonal expenditure per capita (total and by function: education, health, social welfare, infrastructure)
- **Outcome 2:** Cantonal tax multiplier (Steuerfuss)
- **Outcome 3:** Net inter-cantonal migration rate per 1,000 residents

Treatment: NFA per-capita net transfer (CHF), interacted with Post-2008 indicator.

Controls: Canton FE, year FE. Canton-specific linear trends to absorb differential pre-trends (including the 2008 accounting standard break).

Inference: Wild cluster bootstrap (26 clusters) using `fwildclusterboot` in R.

## Robustness

1. **Placebo cutoffs:** 2004 and 2006 as false reform dates
2. **Leave-one-out:** Drop each canton and re-estimate
3. **Alternative intensity measure:** Binary recipient/payer classification
4. **GFC control:** Interact year FE with cantonal GDP per capita to absorb differential crisis exposure
5. **Randomization inference:** Permute treatment intensity across cantons (1000 permutations)

## Data Sources and Fetch Strategy

1. **Inter-cantonal migration:** BFS PXWeb API (`px-x-0102020000_101`), 26 cantons × 1971–2024. Confirmed live in smoke test.

2. **NFA transfer amounts:** EFV (Federal Finance Administration) publishes annual equalization payments by canton. Downloadable from EFV website or constructed from published tables. Alternative: opendata.swiss CKAN search for NFA data.

3. **Cantonal public expenditure:** EFV financial statistics (FS model), cantonal breakdowns by function, 2001–2022.

4. **Cantonal tax multipliers (Steuerfuss):** BFS/cantonal tax offices, annual by canton.

5. **Cantonal population:** BFS for per-capita normalization.

## Key Risks

- **N=26 cantons:** Small cluster count. Mitigated by wild cluster bootstrap and RI.
- **GFC confound:** The 2008 reform coincides with the Global Financial Crisis. Mitigated by continuous treatment intensity (GFC hit all cantons, but NFA transfers vary cross-sectionally) and canton-specific trends.
- **Accounting standard break in 2008:** EFV changed cantonal finance reporting simultaneously with NFA. Mitigated by canton-specific linear trends and by focusing on within-canton changes.
