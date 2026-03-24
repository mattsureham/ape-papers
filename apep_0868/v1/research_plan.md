# Research Plan: Grid Isolation and the Economic Costs of Infrastructure Failure

## Research Question

Does electrical grid isolation impose real economic costs when infrastructure fails? We estimate the medium-run economic impact of Winter Storm Uri (February 2021) on Texas counties, exploiting the ERCOT/SPP grid boundary as a natural experiment. ERCOT's intentional isolation from the national interconnection — chosen decades ago to avoid federal regulation — meant that when cascading generator failures occurred during extreme cold, ERCOT counties could not import power from neighbors. SPP counties in the Texas Panhandle, connected to the national grid, maintained power despite experiencing even colder temperatures.

## Identification Strategy

**Difference-in-Differences with Continuous Treatment Intensity**

- **Treatment group:** ~190 Texas counties served by ERCOT (isolated grid)
- **Control group:** ~40+ Texas counties served by SPP/MISO/WECC (nationally connected grids)
- **Treatment timing:** February 14-19, 2021
- **Key identifying variation:** Grid membership was determined by historical regulatory choices (avoiding FERC jurisdiction), not by anticipated weather vulnerability or economic conditions

**Why this works:**
1. Grid assignment is plausibly exogenous to county economic outcomes — it was a regulatory arbitrage decision made decades before Uri
2. The colder-areas-kept-power fact eliminates weather severity as a confound: Amarillo (SPP) reached -11°F but kept power; Dallas (ERCOT) reached 2°F but lost power
3. Within Texas, we can control for state-level policy responses (all counties subject to same governor's disaster declaration)

**Primary specification:**
```
Y_{it} = α_i + γ_t + β₁(ERCOT_i × Post_t) + X_{it}δ + ε_{it}
```

**Event study:**
```
Y_{it} = α_i + γ_t + Σ_k β_k(ERCOT_i × 1{t=k}) + X_{it}δ + ε_{it}
```
where k ranges from 2019Q1 to 2023Q4, with 2020Q4 as reference period.

## Expected Effects and Mechanisms

1. **Employment:** ERCOT counties should show a negative shock to employment in Q1 2021, with potential persistence through Q2-Q3 2021 as businesses recover
2. **Establishment counts:** Some small businesses may permanently close; construction/repair may increase establishments
3. **House prices:** ERCOT counties may see a capitalization of grid reliability risk into housing values

**Mechanisms:**
- Direct business interruption (closed firms, lost inventory)
- Supply chain disruption (water treatment failures, burst pipes)
- Persistent uncertainty about grid reliability discouraging investment
- Insurance cost increases

## Primary Specification

DiD comparing ERCOT vs non-ERCOT Texas counties, quarterly panel 2019Q1-2023Q4 (8 pre + 12 post quarters). Cluster standard errors at the county level.

**Robustness:**
1. Border county subsample (counties adjacent to the ERCOT boundary)
2. Exclude largest metros (Dallas, Houston, San Antonio) to test sensitivity
3. Wild cluster bootstrap (small cluster concern for ~40 SPP counties)
4. Synthetic control for aggregate ERCOT vs synthetic non-ERCOT

## Exposure Alignment

The treatment (ERCOT grid membership) operates at the county level. All private-sector employers and employees within an ERCOT county were exposed to the blackout—businesses lost power, supply chains froze, and workers could not commute or operate. The QCEW outcome (county-level private-sector employment) captures exactly the population affected. Non-ERCOT counties, connected to the national grid via SPP/MISO/WECC, maintained power and serve as the counterfactual. There is no geographic mismatch between treatment exposure and outcome measurement: the grid boundary cleanly divides Texas counties into treated and control groups at the same unit of observation used in the employment panel.

## Data Sources and Fetch Strategy

| Data | Source | API/Access | Variables |
|------|--------|-----------|-----------|
| County employment | BLS QCEW | BLS API v2 | Total employment, average weekly wages, establishments |
| House prices | FHFA | Public CSV | County-level HPI (quarterly) |
| Weather | NOAA GHCN | NOAA API | Daily min/max temperature by county |
| ERCOT boundary | ERCOT website | Static mapping | County-to-grid-region crosswalk |
| Establishment counts | Census CBP | Census API | Annual establishments by county |

**Fetch order:**
1. Build ERCOT county crosswalk (static — from ERCOT service area maps)
2. BLS QCEW quarterly data for all 254 Texas counties, 2019-2023
3. FHFA county HPI
4. NOAA temperature data for February 2021 (control variable)
