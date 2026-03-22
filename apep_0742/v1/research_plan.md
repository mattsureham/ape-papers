# Research Plan: When the Music Stops — The UK FOBT Stake Reduction and Neighborhood Crime

## Research Question

Did the April 2019 reduction of Fixed Odds Betting Terminal (FOBT) maximum stakes from £100 to £2 affect neighborhood crime? Two competing channels generate opposite predictions: the financial strain channel (less gambling → less desperation → less acquisitive crime) vs. the foot traffic channel (betting shop closures → fewer eyes on streets → more disorder). Decomposing across crime types identifies which channel dominates.

## Identification Strategy

**Continuous-treatment difference-in-differences.** Treatment intensity is pre-reform (2018) betting shop density per 10,000 population at the local authority level. The specification:

$$Crime_{it} = \alpha_i + \gamma_t + \beta \cdot (BettingDensity_i \times Post_t) + \epsilon_{it}$$

- Unit: ~275 local authorities in England and Wales
- Time: Quarterly, April 2016 – September 2025 (38 quarters)
- $Post_t$ = 1 for quarters after April 2019
- Clustered standard errors at LA level

**Key identification assumption:** Absent the FOBT reform, crime trends would have evolved similarly across high- and low-betting-density areas. Testable via pre-treatment event study.

## Expected Effects and Mechanisms

1. **Financial strain channel:** FOBT revenue fell ~50%. If problem gamblers drove acquisitive crime (burglary, shoplifting, robbery) to fund gambling, these crimes should fall more in high-density areas.

2. **Foot traffic / guardianship channel:** 700+ betting shops closed. If shops provided informal surveillance (Jane Jacobs "eyes on the street"), their closure increases opportunity crime and disorder (ASB, theft from person).

**Predictions by crime type:**
- Burglary, robbery, shoplifting: fall (financial strain dominates) or ambiguous
- ASB, criminal damage: rise (foot traffic loss dominates) or no change
- Violence: ambiguous (both channels operate)

## Primary Specification

Run the continuous-treatment DiD separately for each major crime category:
1. Total recorded crime
2. Burglary (residential + commercial)
3. Robbery
4. Shoplifting
5. Theft (other)
6. Violence against the person
7. Anti-social behaviour (if available)

## Robustness

1. **Pre-COVID window:** Restrict to April 2016 – February 2020 (15 quarters pre, 3 quarters post)
2. **Placebo treatment:** Use restaurant/pub density instead of betting shop density
3. **Dose-response:** Actual betting shop closures (NOMIS SIC 92 exit) as treatment
4. **Event study:** Leads and lags with betting density interaction to verify parallel pre-trends
5. **Wild cluster bootstrap:** For inference robustness

## Exposure Alignment

The FOBT stake reduction applied uniformly across all licensed premises on April 1, 2019, so every PFA was "treated" simultaneously. The relevant variation is in treatment intensity: areas with more pre-reform gambling businesses experienced a larger revenue shock and more subsequent closures. The continuous-treatment design (betting density × post) captures this intensity variation. The exposed population is the full resident population of each PFA, as crime data is recorded at the PFA level. The treatment operates through two channels: (1) direct financial strain on problem gamblers (who are concentrated in high-density areas) and (2) indirect guardianship effects from betting shop closures. The food service density control ensures that we isolate gambling-specific exposure from general urban commercial density.

## Data Sources

1. **Crime:** ONS recorded crime at CSP/LA level, quarterly (data.gov.uk or ONS direct download)
2. **Betting shop density:** NOMIS UK Business Counts, SIC 92 (Gambling and betting activities), by LA, 2016–2023
3. **Population:** ONS mid-year population estimates by LA (NOMIS)
4. **Placebo controls:** NOMIS business counts for SIC 56 (food service/restaurants)
