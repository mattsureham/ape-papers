# Research Plan: Upzoning and Dwelling Type Composition

## Research Question
Does New Zealand's Medium Density Residential Standards (MDRS), which mandated as-of-right construction of up to three dwellings per residential lot in Tier 1 cities from August 2022, shift the composition of new housing construction toward multi-unit dwelling types?

## Identification Strategy
**Staggered Difference-in-Differences (Callaway-Sant'Anna)**

- **Treatment group:** Hamilton and Tauranga (MDRS operative August 2022, no prior comparable upzoning)
- **Control group:** Tier 2 cities (subject to NPS-UD but NOT MDRS): Napier, Hastings, Palmerston North, Nelson, Invercargill, Gisborne, Whangarei, New Plymouth, Rotorua, Timaru, Dunedin
- **Unit of analysis:** Territorial authority × month
- **Pre-treatment period:** January 2015 – July 2022 (90 months)
- **Post-treatment period:** August 2022 – latest available (~42 months)

Auckland is excluded (treated earlier via AUP 2016). Wellington region TAs have staggered later treatment dates (2022-2024) — used as additional treatment cohort.

## Expected Effects and Mechanisms
The MDRS removes resource consent requirements for up to 3 units per lot. This should:
1. **Increase multi-unit share** of new consents (townhouses, flats, apartments vs standalone houses)
2. **Effect may be modest initially** — pipeline lags, construction downturn, council implementation variation
3. **Mechanism:** Reduced regulatory friction (40-70 day consent process + fees eliminated for medium-density)

## Primary Specification
$$Y_{it} = \alpha_i + \lambda_t + \sum_g \sum_e \delta_{g,e} \cdot \mathbf{1}[G_i = g] \cdot \mathbf{1}[t = e] + X_{it}'\beta + \varepsilon_{it}$$

where $Y_{it}$ is the multi-unit share of new dwelling consents in TA $i$ at month $t$, estimated via Callaway-Sant'Anna (2021) with never-treated Tier 2 cities as comparison group.

## Data Source and Fetch Strategy
1. **Stats NZ Building Consents** — Monthly Excel releases. Table 6: consents by TA, dwelling type. URL confirmed HTTP 200.
2. **Secondary:** MBIE Rental Bond Data (rental market response), Stats NZ population estimates (controls).

## Key Risks
- Construction industry downturn may dominate composition effects
- Small number of treated TAs (2 primary, ~4 with Wellington staggering)
- Monthly data may be noisy at TA level — consider quarterly aggregation as robustness
