# Research Ideas

## Idea 1: Demonetization by Design: The 2023 Nigerian Naira Redesign and the Cash-Mediation Channel in Food Markets
**Policy:** Nigeria's 2022-2023 naira redesign withdrew 76% of cash from circulation in 3 months. On October 26, 2022, CBN Governor announced redesign of the three highest-denomination banknotes (N200, N500, N1000 -- 93% of currency in circulation). Old notes demonetized January 31, 2023. Currency in circulation collapsed from N3.3 trillion to N982 billion. Supreme Court reversed the policy on March 3, 2023.
**Outcome:** WFP Food Price Monitoring data for Nigeria via HDX (56,163 observations, 68 markets, 14 states, 43 commodities, 2002-2026). Primary outcomes: log prices of cash-mediated local staples (millet, sorghum, maize, local rice) vs. banking-mediated imports (imported rice, wheat flour, sugar).
**Identification:** Within-market, across-commodity triple-difference. Treatment intensity = cash-mediation intensity (CMI) of each commodity. Market-by-time FE absorbs all market-level confounders (exchange rate, local demand, transport costs). The across-commodity variation within each market isolates the cash-mediation channel. Built-in placebo: imported rice (same food product, banking-mediated supply chain) vs local rice (cash-mediated). Supreme Court reversal (March 2023) provides natural experiment within the experiment.
**Why it's novel:** No published paper uses market-level commodity price data with within-market across-commodity variation to study the naira redesign. First micro-empirical test of demonetization effects on food markets in Sub-Saharan Africa. Tests two competing hypotheses: supply disruption (prices fall) vs. transaction cost inflation (prices rise).
**Feasibility check:** Confirmed: WFP HDX data downloaded (56,163 obs, 68 markets, 43 commodities). Clear commodity-level distinction between cash-mediated and banking-mediated goods within same markets. 20+ years of pre-period data for parallel trends.

## Idea 2: Trade Protection by Fiat: The Price Effects of Nigeria's 2019 Land Border Closure
**Policy:** On August 20, 2019, President Buhari ordered sudden closure of all land borders to goods movement. No advance announcement. Borders with Benin, Niger, Cameroon, Chad sealed for 15 months until December 2020.
**Outcome:** WFP Global Food Prices Database via HDX. 34 markets with rice data spanning border to deep interior, monthly 2017-2021. Cross-border Benin and Niger market data available.
**Identification:** Spatial difference-in-differences. Treatment intensity = distance from each market to nearest international land border. Border markets (<150km) treated; interior markets (>300km) controls. 31 months pre-period. Placebo: non-tradeable commodities (firewood, charcoal). Cross-border validation in Benin/Niger.
**Why it's novel:** No published paper uses WFP geo-referenced monthly price data with spatial DiD on the border closure.
**Feasibility check:** Confirmed: 34 markets with rice data, distance ranges 39-515km from border, WFP HDX CSV download, no auth required.

## Idea 3: Pump Price Pass-Through After Nigeria's 2023 Fuel Subsidy Removal
**Policy:** Nigeria's petrol subsidy removed May 29, 2023. Pump prices jumped from N238/litre to N545/litre (129% in one month). Single national shock on a known date.
**Outcome:** NBS Monthly PMS Price Watch (36 states + FCT), Transport Fare Watch, and GHS-Panel Wave 5 (4,715 households).
**Identification:** Continuous geographic treatment intensity using distance from state capital to nearest petroleum import terminal (Lagos, Port Harcourt, Warri). State x month panel. Pre-reform prices were nationally uniform under subsidy; post-reform prices vary by distribution costs.
**Why it's novel:** No published paper uses geographic pass-through heterogeneity for causal identification of fuel subsidy removal effects.
**Feasibility check:** Confirmed: NBS data shows N83/litre cross-state spread in first post-reform month. GHS Panel Wave 5 publicly listed. Risk: NBS data may be in PDF format requiring extraction.
