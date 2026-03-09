# Initial Research Plan: apep_0555

## Research Question

Does demonetization disrupt or inflate food prices in informal markets? Specifically, does the sudden withdrawal of physical cash from a highly cash-dependent economy (Nigeria's 2022-2023 naira redesign) differentially affect the prices of cash-mediated local staples versus banking-mediated imported goods?

## Identification Strategy

**Within-market, across-commodity triple-difference.**

The core insight is that different food commodities in the same physical marketplace rely on different payment infrastructure. Locally produced staples (millet, sorghum, maize, yam, local rice) are grown by smallholders, transported by informal traders, and sold at open-air markets -- with near-100% cash transactions from farmgate to consumer. Imported goods (imported rice, wheat flour, sugar) flow through formal channels: letters of credit, customs clearing, banking-mediated wholesale distribution.

When the CBN withdrew 76% of physical cash from circulation in Q1 2023, these two commodity groups experienced the same macroeconomic environment but different payment infrastructure shocks.

**Primary specification:**

log(P_cmt) = alpha_cm + alpha_mt + beta * (HighCMI_c x CashCrisis_t) + epsilon_cmt

Where:
- c = commodity, m = market, t = month-year
- alpha_cm = commodity-by-market FE (absorb time-invariant market-commodity differences)
- alpha_mt = market-by-time FE (absorb ALL market-level time-varying shocks: exchange rate, local demand, transport costs, inflation)
- HighCMI_c = indicator for high cash-mediation intensity commodity
- CashCrisis_t = indicator for acute crisis period (Feb-May 2023)
- beta = the causal effect of cash scarcity on cash-mediated vs. banking-mediated food prices

**Built-in placebo:** Local rice vs. imported rice within the same market. Same product, different supply chain. This is the sharpest test of the cash-mediation channel.

## Expected Effects and Mechanisms

**Two competing hypotheses:**

1. **Supply disruption (beta < 0):** Cash-strapped farmers cannot transport goods to markets; intermediaries cannot purchase at farmgate. Local supply chains seize up, volumes drop. Desperate farmers accept lower prices. High-CMI commodity prices fall relative to low-CMI commodities.

2. **Transaction cost inflation (beta > 0):** Cash scarcity creates a cash premium; mobile money agents charge 10-30% fees. The effective transaction cost of buying/selling cash-mediated goods rises, pushing prices up for high-CMI commodities.

**The sign of beta discriminates between these hypotheses.** Either result is publishable -- the question is which channel dominates.

**Mechanism test:** If supply disruption dominates, market volumes should fall for high-CMI commodities (testable via WFP's priceflag field). If transaction-cost channel dominates, the spread between wholesale and retail prices should widen.

**Supreme Court reversal (March 3, 2023):** If the cash-mediation channel is real, price effects should attenuate as cash availability recovers through Q2-Q4 2023. We model this as gradual recovery using CBN monthly currency-in-circulation data.

## Primary Specification

1. **Main DiD:** HighCMI x CashCrisis with market-by-time and commodity-by-market FE
2. **Event study:** Monthly leads and lags on HighCMI x month dummies (Oct 2020 - Dec 2023)
3. **Local vs. imported rice:** Standalone DiD using only rice observations within same markets
4. **Continuous CMI:** Replace binary HighCMI with continuous cash-mediation index
5. **Recovery analysis:** Interact HighCMI with CBN cash-availability measure (continuous treatment)

## Planned Robustness Checks

1. **Alternative crisis windows:** Feb-May 2023 (acute), Feb-Aug 2023 (extended), full 2023
2. **Exclude conflict-affected markets:** Drop Borno, Yobe, Adamawa (northeast insurgency)
3. **Alternative CMI classifications:** Binary, ternary (high/medium/low), continuous
4. **Placebo test:** Run same specification on pre-period data (e.g., pretend crisis = 2020)
5. **Leave-one-market-out:** Check no single market drives results
6. **Leave-one-commodity-out:** Check no single commodity drives results
7. **Wild cluster bootstrap:** Cluster at state level (14 states)
8. **Randomization inference:** Permute crisis timing across months

## Power Assessment

- Markets: 68 (across 14 states)
- Commodities per market: ~10-20 (mix of high and low CMI)
- Pre-periods: 240+ months (2002-2022), though we focus on 24-month window
- Crisis period: 4 months (Feb-May 2023) or 11 months (Feb-Dec 2023)
- Total observations: ~56,000 over full sample; ~2,200 during crisis window
- Clusters: 14 states (modest -- will use wild bootstrap and RI)
- Key risk: 14 clusters is below the standard threshold. Wild cluster bootstrap and RI are essential.

## Data Sources

1. **WFP Food Price Monitoring (HDX):** 56,163 observations, 68 markets, 43 commodities, 2002-2026. Free CSV download.
2. **CBN Statistical Bulletin:** Monthly currency in circulation, monetary aggregates. Public.
3. **World Bank Findex 2021:** State-level financial inclusion measures. Public API.
4. **ACLED:** Conflict events for conflict-market exclusion robustness. Requires credentials (configured).
