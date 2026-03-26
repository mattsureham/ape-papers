# Research Plan: apep_0985

## Research Question

Do catalytic converter anti-theft laws reduce catalytic converter theft, and can we decompose the observed decline into a **price effect** (falling palladium prices reduce criminal incentives) versus a **law effect** (enhanced penalties and scrap dealer regulations deter theft)?

## Motivation

Catalytic converter theft surged ~1,632% between 2019 and 2022 (3,721 to 64,433 insurance claims), driven by soaring precious metal prices — particularly palladium, which peaked at $2,958/oz in April 2021. In response, 32+ US states enacted anti-theft legislation between 2021 and 2023, creating rich staggered adoption variation. Simultaneously, palladium prices collapsed ~66% from peak to trough. This dual variation — in policy and in criminal returns — allows a clean decomposition that directly tests Becker's (1968) rational crime model.

## Identification Strategy

**Primary:** Callaway-Sant'Anna (2021) staggered DiD with state-month panel.
- Treatment: binary indicator for state enacting catalytic converter anti-theft law
- Outcome: log(larceny-theft rate per 100,000) at the state-month level from FBI UCR/NIBRS
- Comparison group: not-yet-treated states
- Clustering: state level

**Commodity price decomposition:** Augment the DiD with state × log(palladium price) interactions to separate:
1. **Price effect** — mechanical decline in theft as metal values fall (captured by palladium coefficient in untreated states)
2. **Law effect** — deterrence from legislation (captured by treatment indicator, conditional on price)
3. **Interaction** — whether laws are more effective when prices are high (law × price interaction)

**Built-in placebo:** Motor vehicle theft (not related to precious metal prices) and burglary serve as mechanism-matched placebos. If our results are driven by catalytic converter-specific deterrence, these should show null effects.

## Expected Effects and Mechanisms

1. Laws reduce theft (negative treatment effect), but the magnitude depends on enforcement and law type
2. Palladium price is positively associated with theft in untreated states (Becker price mechanism)
3. Laws may be more effective when prices are high (interaction), because deterrence matters more when criminal returns are large
4. Heterogeneity by law type: felony penalties > misdemeanor; scrap dealer regulation > marking requirements

## Primary Specification

$$Y_{st} = \alpha_s + \gamma_t + \beta \cdot \text{Law}_{st} + \delta \cdot \log(\text{Palladium}_t) + \phi \cdot \text{Law}_{st} \times \log(\text{Palladium}_t) + X'_{st}\Gamma + \varepsilon_{st}$$

Where $Y_{st}$ is the log larceny-theft rate in state $s$, month $t$. Callaway-Sant'Anna group-time ATTs provide the primary causal estimates; the TWFE specification above decomposes the price channel.

## Data Sources

1. **Crime data:** FBI Uniform Crime Reporting (UCR) — state-level monthly property crime counts. Accessed via FBI Crime Data Explorer API or pre-processed UCR data.
2. **Palladium prices:** Yahoo Finance (ticker PA=F), monthly OHLC, 2016-2025.
3. **Law enactment dates:** Compiled from NCSL, state legislature records, and media reports. Key dates: TX (June 2021), CO (June 2022), AZ (May 2022), NY (Aug 2022), GA (April 2023), NM (April 2023), MN (Aug 2023), CA (Jan 2024).
4. **Controls:** State population (Census), unemployment rate (BLS/FRED), poverty rate.

## Feasibility Assessment

- **Treated units:** 32+ states (far exceeds DiD minimum of 20)
- **Pre-periods:** 5+ years (2016-2020 before first law in June 2021)
- **Price variation:** 188% rise then 66% fall — massive identifying variation
- **Data access:** FBI UCR data publicly available; palladium prices freely available
