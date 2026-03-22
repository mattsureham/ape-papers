# Research Plan: The Fortress Premium — Exchange Rate Pass-Through and Tourism Demand after Switzerland's Franc Shock

## Research Question
How does a large, unexpected exchange rate appreciation affect international tourism demand, and how does the elasticity vary by visitor origin? The within-market, across-nationality variation reveals whether tourism demand segments by price sensitivity.

## Institutional Background
On January 15, 2015, the Swiss National Bank (SNB) unexpectedly abandoned its EUR/CHF 1.20 minimum exchange rate floor, which had been maintained since September 2011. The franc appreciated 15-20% against the euro instantly. Markets had no warning — the SNB had reaffirmed the floor days earlier. This is a textbook exogenous monetary policy shock.

For a German tourist, a 100 CHF hotel room effectively went from ~€83 to ~€100 overnight. For a Swiss domestic tourist, the price was unchanged. Same room, same hotel, different effective price by nationality — a within-market natural experiment.

## Identification Strategy
**Bartik shift-share DiD:**
- **Unit:** Canton × origin-nationality × month (or canton-month with Bartik exposure weights)
- **Share:** Canton c's pre-shock (2014) composition of overnight stays by nationality n
- **Shift:** Exchange rate change for origin country n's currency vs. CHF
  - Eurozone countries: large (~15-20% appreciation)
  - Non-euro Europeans (UK, Sweden, etc.): moderate (varies)
  - Swiss domestic / non-European: minimal direct effect

**Triple-difference (within-canton placebo):**
- Within each canton, compare Eurozone visitors (treated) vs. Swiss domestic visitors (control)
- Controls for canton-specific demand shocks (weather, events, infrastructure)

**Key advantages:**
- 10 years of monthly pre-treatment data (2005-2014)
- 78 origin countries = granular variation in exchange rate exposure
- Administrative data (hotel registration records) = no measurement error
- Within-market comparison rules out supply-side confounds

## Expected Effects and Mechanisms
- **Main effect:** Negative — franc appreciation reduces overnight stays from exchange-rate-exposed countries
- **Heterogeneity by origin:** Larger effects from neighboring European countries (budget/mix tourists), smaller from long-haul (business/luxury)
- **Heterogeneity by canton:** Alpine luxury cantons (Graubünden) more resilient than proximity-tourism cantons (Ticino)
- **Persistence:** Effects may dissipate over 2-3 years as hotels adjust prices downward

## Primary Specification
$$\ln(Y_{cnt}) = \alpha_{cn} + \gamma_{nt} + \delta_{ct} + \beta \cdot \text{Post}_t \times \text{EuroExposed}_n + \varepsilon_{cnt}$$

Where $Y_{cnt}$ is overnight stays in canton $c$ from nationality $n$ in month $t$. Canton×nationality FE absorb level differences; nationality×time FE absorb origin-specific trends; canton×time FE absorb local demand shocks.

**Bartik reduced form at canton level:**
$$\ln(Y_{ct}) = \alpha_c + \gamma_t + \beta \cdot B_c \times \text{Post}_t + \varepsilon_{ct}$$
Where $B_c = \sum_n s_{cn,2014} \times \Delta \ln(e_{n,t})$ is the Bartik exposure.

## Data Source and Fetch Strategy
1. **HESTA** (Hotel Accommodation Statistics): BFS PXWeb table, monthly overnight stays by canton × origin country, 2005-2025
2. **Exchange rates:** ECB Statistical Data Warehouse — monthly bilateral rates for CHF vs. EUR, GBP, USD, JPY, etc.
3. **Robustness:** Tourism Satellite Accounts (canton-level), employment (STATENT)

## Robustness Checks
- Pre-trend tests (event-study specification)
- Permutation / randomization inference (permute shock timing)
- Donut around shock month (exclude Jan-Feb 2015)
- Rotemberg weight decomposition (AKM-style shift-share diagnostics)
- Alternative exposure definitions (Eurozone vs. non-Eurozone binary)
- Placebo: Swiss domestic visitors (should show no exchange rate effect)
