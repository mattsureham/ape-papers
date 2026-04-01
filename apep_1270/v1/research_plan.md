# Research Plan: The Replacement Channel — Carbon Tax Escalation and Heating Capital Stock Decarbonization in Switzerland

## Research Question

Do carbon taxes drive building decarbonization through technology switching — replacing oil furnaces with heat pumps — rather than through consumption reduction? We exploit Switzerland's six discrete increases in the federal CO2 levy on heating fuels (CHF 12/ton in 2008 → 120/ton in 2022), interacted with cantonal variation in initial oil-heating dependency (7%–65%), to estimate the causal effect of carbon taxation on heating capital stock composition.

## Identification Strategy

**Generalized Difference-in-Differences (Continuous Treatment)**

- **Treatment intensity:** Canton's 2000 oil-heating share × federal levy rate in year t
- **Time variation:** Six discrete levy increases (2008, 2010, 2014, 2016, 2018, 2022)
- **Cross-sectional variation:** 26 cantons with oil-heating shares ranging from 7% (Basel-Stadt) to 65% (Appenzell Innerrhoden)
- **Key assumption:** Absent the levy, cantons with different initial oil dependency would have followed parallel trends in heating system transitions

**Key advantages:**
1. Federal levy is exogenous to any individual canton's energy choices
2. Levy schedule is legislated via ratchet mechanism (triggers if national emissions targets missed), not responsive to canton-level heating trends
3. Six treatment episodes provide internal replication
4. Initial oil share (2000 census) is predetermined — measured 8 years before first levy

**Placebo tests:**
- Electric heating and wood/pellet heating should not respond to the CO2 levy (no CO2 tax on electricity or biomass)
- Cantons with low initial oil share should show minimal response

## Expected Effects and Mechanisms

**Primary mechanism:** Carbon levy increases the operating cost of oil furnaces → when an oil furnace reaches end of life (typical lifespan 20–25 years), replacement decision tips toward heat pump → irreversible capital stock change → permanent emissions reduction.

**Expected signs:**
- Oil heating share: negative (declining faster in high-oil cantons after levy increases)
- Heat pump share: positive (growing faster in high-oil cantons)
- Gas heating share: ambiguous (gas is also taxed but at lower rate per kWh)
- Buildings Programme subsidies: positive (more applications in high-oil cantons after levy increases, since subsidies are funded by levy revenue)

**Heterogeneity:** Effect should be larger in later periods (cumulative levy burden makes oil increasingly uncompetitive), and should interact with building age (older buildings = older furnaces = more replacement decisions).

## Primary Specification

$$Y_{ct} = \alpha + \beta \cdot (\text{OilShare}_{c,2000} \times \text{Levy}_t) + \gamma_c + \delta_t + \epsilon_{ct}$$

Where:
- $Y_{ct}$: heat pump share (or oil share) in canton $c$, year $t$
- $\text{OilShare}_{c,2000}$: canton's oil heating share from 2000 census
- $\text{Levy}_t$: federal CO2 levy rate in CHF/ton CO2
- $\gamma_c$: canton fixed effects
- $\delta_t$: year fixed effects

Standard errors clustered at canton level (26 clusters → supplement with wild cluster bootstrap).

## Data Sources and Fetch Strategy

### Primary: BFS Building and Dwelling Statistics (GWS)
- **Source:** BFS PXWeb API — Gebäude nach Energieträger der Heizung und Kanton
- **Coverage:** Annual, 2010–2024, all 26 cantons
- **Variables:** Number of buildings by heating energy source (oil, gas, heat pump, wood, electric, solar, district heating)
- **Access:** No API key needed, BFS PXWeb REST API

### Secondary: Federal Buildings Programme
- **Source:** opendata.swiss / BFE publications
- **Coverage:** Canton-year, 2017–2024
- **Variables:** Subsidy payouts, number of funded measures, CO2 savings
- **Access:** Direct download from opendata.swiss

### Baseline: 2000 Census Oil Shares
- **Source:** BFS / idea smoke test data (confirmed: oil share by canton from 2000 census)
- **Access:** BFS PXWeb or published tables

### Levy Schedule (known exactly):
| Year | CHF/ton CO2 | Approx CHF/100L heating oil |
|------|-------------|---------------------------|
| 2008 | 12 | 3.2 |
| 2010 | 36 | 9.5 |
| 2014 | 60 | 15.9 |
| 2016 | 84 | 22.2 |
| 2018 | 96 | 25.4 |
| 2022 | 120 | 31.8 |

## Robustness Checks
1. Wild cluster bootstrap (26 clusters)
2. Placebo: electric and wood heating as outcomes
3. Placebo: interact with initial electric-heating share instead of oil share
4. Drop one canton at a time (leave-one-out)
5. Restrict to pre-2022 (exclude COVID-era levy increase)
6. Use gas share as alternative treatment (gas also taxed, but lower CO2 intensity)

## Exposure Alignment
The treatment is defined at the canton × year level. The federal CO2 levy applies to all fossil heating fuel consumed in Switzerland, so all dwellings using oil or gas heating are exposed. The treatment intensity measure (OilShare_c,2000 × Levy_t) captures the differential effective burden: cantons with more oil-heated dwellings face higher aggregate costs from the levy. The outcome (heating energy shares) is measured at the same canton × year level. Treatment and outcome are thus aligned at the canton-year unit. The identifying variation comes from the interaction of predetermined cross-sectional exposure (2000 oil share) with the time-varying levy rate, both measured at the canton level.

## Risk Assessment
- **Main risk:** BFS GWS data may start in 2010, giving only 2 years before first major levy increase (CHF 36 in 2010). Mitigation: 2000 census provides baseline; treat 2010-2013 as partial pre-period for the CHF 60 increase.
- **Cluster count:** 26 cantons is adequate but not large. Wild cluster bootstrap addresses this.
- **Confounders:** Heat pump technology costs declined globally over this period. Year fixed effects absorb this (federal levy is the only canton-varying shock).
