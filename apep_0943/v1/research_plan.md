# Research Plan: apep_0943

## Research Question

Does the failure of a national climate policy trigger compensatory subnational climate action? Specifically, did the unexpected rejection of Switzerland's CO2 Act referendum (June 13, 2021) accelerate heat pump adoption in pro-climate municipalities relative to anti-climate ones?

## Identification Strategy

**Continuous difference-in-differences.** Treatment intensity = municipal-level CO2 Act yes vote share (range: 34.5%–66.6%). Post = after June 2021 referendum. The identifying assumption: absent the referendum shock, municipalities with different vote shares would have followed parallel trends in heat pump adoption.

**Triple-difference:** The June 2023 Climate and Innovation Act (KlG) passage (59.1% yes) partially restored federal policy. If the 2021 rejection drove compensatory cantonal action, the 2023 passage should *attenuate* the divergence — providing a natural reversal test.

**Placebos:**
- Pre-trends: 2010–2021H1 (12 years of pre-period data)
- Placebo treatment: unrelated referendum vote shares (e.g., immigration initiatives)
- Placebo outcomes: outcomes unrelated to building energy (e.g., population growth)

## Expected Effects and Mechanisms

- **Primary hypothesis:** Municipalities with higher CO2 Act yes vote share accelerated heat pump adoption more after June 2021 (positive interaction coefficient).
- **Mechanism:** Pro-climate cantons adopted own climate laws filling the federal vacuum (Bern Sept 2021, Zurich Nov 2021, etc.), which directly incentivized fossil heating replacement.
- **Heterogeneity:** Effect should be stronger in cantons that actually adopted climate legislation post-rejection.

## Primary Specification

$$Y_{mt} = \alpha_m + \delta_t + \beta \cdot (\text{VoteShare}_m \times \text{Post}_t) + \varepsilon_{mt}$$

Where:
- $Y_{mt}$ = heat pump share of buildings in municipality $m$, year $t$
- $\text{VoteShare}_m$ = CO2 Act yes vote share (continuous, 0–1)
- $\text{Post}_t$ = indicator for $t \geq 2022$ (first full year after June 2021)
- $\alpha_m$, $\delta_t$ = municipality and year fixed effects
- SEs clustered at the canton level (26 clusters)

## Data Sources

1. **Referendum data:** BFS PXWeb / swissdd R package — municipal-level results for CO2 Act (June 2021), Climate Act (June 2023), and placebo referendums
2. **Building heating data:** BFS Gebäude- und Wohnungsregister (GWR) via PXWeb — buildings by energy source of heating, by municipality, annually 2010–2023
3. **Cantonal legislation:** Fedlex SPARQL / manual coding of post-2021 cantonal climate laws

## Outcome Variables

- **Primary:** Heat pump share of total buildings (fraction with heat pump as primary heating source)
- **Secondary:** Fossil heating share (oil + gas), new construction heat pump share
