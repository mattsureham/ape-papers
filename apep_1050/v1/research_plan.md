# Research Plan: Tax Breaks at the Charging Station

## Research Question

Do recurring annual motor vehicle tax incentives for electric vehicles increase EV adoption? Swiss cantons independently set EV-specific tax exemptions (0–100%), creating a rare natural experiment in which identical vehicles face annual tax bills ranging from CHF 0 to CHF 900+ depending on cantonal policy. This paper exploits this variation to estimate the causal effect of recurring ownership tax incentives on EV adoption — a channel theoretically distinct from the one-time purchase subsidies that dominate the literature.

## Identification Strategy

**Primary: Staggered Difference-in-Differences with Continuous Treatment**

- Treatment: Cantonal EV tax discount rate (0–100%), varying across cantons and over time
- Unit of observation: Municipality × year
- Outcome: Share of new passenger car registrations that are battery-electric (BEV)
- Estimator: Callaway & Sant'Anna (2021) for binary treatment timing; continuous treatment intensity as robustness
- Treated: ~18+ cantons with some form of EV tax relief
- Control: 8 cantons with no EV-specific incentive (AG, AR, AI, LU, SH, SZ, TI, VS)

**Built-in placebo (Triple-Difference):** Within-municipality, within-year comparison of EV vs. gasoline registrations. Cantonal tax exemptions affect EVs but not gasoline vehicles — so gasoline registrations in treated cantons serve as a within-unit counterfactual.

**Border municipality test:** Municipalities at cantonal borders face identical labor markets, geography, and charging infrastructure but different tax regimes. Compare EV adoption in adjacent border municipalities across cantonal lines.

## Expected Effects and Mechanisms

- **Primary:** Higher tax exemptions → higher EV registration share (positive, moderate SDE)
- **Mechanism 1 — Salience:** Annual tax bill is more salient than NPV of lifetime tax savings. Expect larger effects where tax bills are higher (high-Steuerfuss municipalities)
- **Mechanism 2 — Complementarity:** Tax exemptions may interact with federal purchase subsidies and charging infrastructure density
- **Mechanism 3 — Registration gaming:** Border municipalities may see inflated registrations if buyers register in low-tax cantons

## Primary Specification

$$\text{EV\_share}_{mt} = \alpha + \beta \cdot \text{TaxDiscount}_{c(m),t} + \gamma_{m} + \delta_t + \epsilon_{mt}$$

Where $m$ indexes municipalities, $t$ years, $c(m)$ is the canton of municipality $m$. Municipality and year fixed effects. Standard errors clustered at canton level (26 clusters — will supplement with wild cluster bootstrap).

## Data Sources

1. **BFS PXWeb table px-x-1103020200_121**: New passenger car registrations by fuel type, municipality level, 2010–2024. Confirmed accessible.
2. **Cantonal EV tax exemption rates**: Compiled from cantonal motor vehicle tax laws. Key sources: TCS (Touring Club Schweiz) annual comparisons, cantonal tax office publications.
3. **BFS municipal statistics**: Population, income, urbanity for controls.
4. **SMMT municipal merger mapping**: For harmonizing municipality IDs across years.

## Fetch Strategy

1. Query BFS PXWeb API for municipality × fuel-type × year registration data
2. Hand-code cantonal EV tax exemption panel from TCS and cantonal legislation (26 cantons × 15 years = 390 observations)
3. Merge at canton-year level; add municipality controls from BFS
4. Harmonize municipality IDs using SMMT for any mergers during 2010–2024
