# Research Plan: When Your Biggest Customer Disappears

## Research Question

How does the near-total loss of a major export market reshape industrial structure and labor markets? Venezuela's progressive economic collapse destroyed Colombia's second-largest export destination, with bilateral exports falling 97% from $6.1B (2008) to $196M (2020). This paper uses the dramatic cross-sector variation in Venezuelan trade dependence — from $760M in meat to near-zero in many sectors — to estimate the causal effect of losing a dominant trading partner on Colombian manufacturing employment, output, and export diversification.

## Identification Strategy

**Bartik/shift-share design** following Borusyak, Hull & Jaravel (2022). Treatment intensity varies at the department-sector level:

Exposure_{ds} = Σ_k (L_{dsk,pre} / L_{ds,pre}) × ΔExport_{k,VEN}

Where k indexes HS2 product categories, L is employment shares, and ΔExport measures the sector-level export loss to Venezuela. 95 HS2 sectors provide many independent shocks. Pre-period (2005-2008) shares ensure exogeneity.

**Key identifying assumption:** Venezuelan demand destruction (driven by PDVSA nationalization, CADIVI controls, hyperinflation) is exogenous to individual Colombian department economic conditions.

## Expected Effects and Mechanisms

**Primary hypothesis:** Departments with greater pre-period Venezuelan export dependence experienced:
- Larger manufacturing employment declines
- Greater export diversification to alternative markets (US, EU, China)
- Structural shift from manufacturing to services

**Mechanism tests:**
1. Import substitution: Did Venezuela's decline create opportunities for alternative suppliers?
2. Export rerouting: Did firms shift to other markets or exit entirely?
3. Migration interaction: Venezuelan immigration to Colombia (post-2015) may offset labor demand effects

## Data Sources

1. **UN Comtrade**: HS2 bilateral trade flows, Colombia-Venezuela, 2000-2022. API-accessible.
2. **World Bank WDI**: Department-level GDP, employment, manufacturing value added. API-accessible.
3. **DANE GEIH**: Colombian labor force survey — national and city-level employment by sector.
4. **FRED**: Colombia-relevant macro controls (exchange rates, GDP growth).

## Primary Specification

Y_{dt} = α_d + δ_t + β × (Exposure_d × Post_t) + X_{dt}γ + ε_{dt}

Where Y is the outcome (manufacturing employment, export value), d indexes departments, t indexes years, and Exposure_d is the continuous Bartik-style treatment intensity. Standard errors clustered at the department level.

## Analysis Plan

1. Construct HS2-level Colombia→Venezuela export panel from Comtrade (2000-2022)
2. Compute department-level exposure shares from pre-period employment
3. Merge with department-year outcomes (WDI, DANE)
4. Estimate Bartik DiD with continuous treatment
5. Event study showing pre-trends and dynamic effects
6. Robustness: alternative pre-periods, leave-one-sector-out, commodity price controls
