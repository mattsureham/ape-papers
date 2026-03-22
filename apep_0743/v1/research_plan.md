# Research Plan: Licensing the Last Rites

## Research Question

Do mandatory funeral director requirements raise prices and reduce competition in death care markets? Nine US states require families to hire a licensed funeral director for all body disposition (filing death certificates, obtaining burial/transit permits, transporting remains). The remaining 41 states allow families to handle these tasks independently. This paper estimates the causal effect of these requirements on market structure (establishments, employment, firm size) and prices using a border discontinuity design.

## Identification Strategy

**Geographic border discontinuity design** (Blair & Chung 2019). Compare death care market outcomes in border counties across 22 unique state-border segments where one state requires funeral director involvement and the other does not. Border-pair fixed effects absorb all local economic conditions that are shared across adjacent counties.

- **Treatment**: County is in one of 9 FD-required states (CT, IL, IN, IA, LA, MI, NE, NJ, NY)
- **Control**: Adjacent county in a non-FD-required state
- **Key assumption**: Death care market conditions vary smoothly at state borders, conditional on observable controls

## Expected Effects and Mechanisms

1. **Higher concentration**: FD requirements create barriers to entry → fewer establishments per capita
2. **Higher prices**: Reduced competition + mandatory professional fees → higher payroll per employee (proxy for prices)
3. **Larger firms**: Entry barriers shift market toward larger, established firms → higher employment per establishment
4. **Substitution away from cremation**: If FD requirements raise cremation costs, cremation rates should be lower in FD states

## Primary Specification

$$Y_{c,b} = \alpha_b + \beta \cdot \text{FD\_Required}_c + X_c'\gamma + \varepsilon_{c,b}$$

Where:
- $Y_{c,b}$: outcome (establishments/capita, employment/capita, payroll/employee, employment/establishment) for county $c$ in border pair $b$
- $\alpha_b$: border-pair fixed effects
- $\text{FD\_Required}_c$: indicator for county in FD-required state
- $X_c$: county controls (population, income, elderly share, death rate, urbanization)

Cluster standard errors by state. Robustness: wild cluster bootstrap (few treated clusters), interior-county placebo, varying bandwidth from border.

## Data Sources

1. **Census County Business Patterns (CBP)**: County-year establishment counts, employment, payroll for NAICS 812210 (Funeral Homes) and 812220 (Cemeteries/Crematories). Available 1998-2022 via Census API.

2. **County adjacency**: Census Bureau county adjacency file (identifies all bordering county pairs).

3. **County demographics**: Census ACS 5-year estimates — population, median household income, percent 65+, urbanization.

4. **State death rates**: CDC WONDER — crude death rates by county.

5. **Cremation rates**: Cremation Association of North America (CANA) — state-level cremation rates as supplementary outcome.

## Data Fetch Strategy

1. Query Census CBP API for NAICS 812210 and 812220, all counties, all available years
2. Download county adjacency file from Census Bureau
3. Query ACS API for county demographics
4. Merge and construct border-pair panel
5. Classify border pairs by FD-required vs non-required status
