# Initial Research Plan: When the Canal Runs Dry

## Research Question
How does a major waterway disruption reallocate trade across US ports? Specifically, what is the port-level trade diversion elasticity with respect to Panama Canal transit capacity?

## Identification Strategy
**Continuous Treatment DiD with common timing.**

The 2023-24 El Nino drought forced the Panama Canal Authority to reduce daily ship transits from 36-38 to 18 (a 50% reduction). This is exogenous to US port conditions — a pure weather-driven supply shock to transit capacity.

**Treatment intensity:** Each port's pre-drought (2019-2022) share of total imports originating from Canal-dependent countries (East Asia, Southeast Asia — China, Japan, South Korea, Vietnam, Taiwan, etc.). East Coast and Gulf ports receive 30-50% of Asian imports via the Canal; West Coast ports receive Asian imports via direct trans-Pacific routes and have zero Canal dependence.

**Key equation:**
$$\log(Imports_{pt}) = \alpha_p + \gamma_t + \beta \cdot (CanalShare_p \times Drought_t) + X'_{pt}\delta + \varepsilon_{pt}$$

Where:
- $p$ indexes ports, $t$ indexes months
- $CanalShare_p$ is the pre-drought (2019-2022 average) share of imports from Canal-dependent Asian origins
- $Drought_t$ is a continuous measure of Canal restriction intensity (normalized daily transit slots, 0-1)
- $\alpha_p$ are port fixed effects, $\gamma_t$ are month fixed effects

**Exposure Alignment:**
- Who is treated? Ports with high dependence on Canal routes for Asian imports
- Primary estimand: ATT for Canal-dependent ports (East Coast, Gulf)
- Placebo/control: West Coast ports (zero Canal dependence for Asian trade)
- Design: Standard DiD with continuous treatment intensity (not staggered — single shock)

## Expected Effects and Mechanisms
1. **Primary:** High-Canal-share ports see import declines during drought (negative β)
2. **Diversion:** West Coast ports see import increases (positive effect when running reverse specification)
3. **Recovery:** Effects should dissipate as Canal restrictions ease (mid-2024)
4. **Heterogeneity by commodity:** Containerized goods (most Canal traffic) vs. bulk commodities

## Primary Specification
- Unit: Port × month
- Time: January 2019 – December 2024 (72 months)
- Treatment period: July 2023 – August 2024
- Outcome: Log total imports (general import value in USD)
- Fixed effects: Port FE + year-month FE
- Clustering: Port level (with wild bootstrap given ~35 ports)

## Built-in Placebos
1. **European-origin imports:** Imports from Europe (Germany, UK, France, Italy) do not transit the Canal for US-bound trade. Should show no differential effect by Canal share.
2. **Canadian/Mexican imports:** Land-border trade is Canal-independent. Should show no effect.
3. **Pre-drought placebo:** Run same specification with fake treatment July 2021 – August 2022.

## Planned Robustness Checks
1. Wild cluster bootstrap p-values (few clusters)
2. Randomization inference (permute Canal share across ports)
3. Leave-one-out (drop each port, check stability)
4. Alternative treatment definitions (binary East/Gulf vs West Coast; alternative Canal share measures)
5. Alternative outcomes (number of HS codes with positive imports as extensive margin)
6. Houthi Red Sea crisis control (Nov 2023 onset — affects Europe-Asia, not US-Asia routes, but verify)
7. Continuous drought intensity (monthly Canal transit data instead of binary)
8. Alternative functional forms (levels, asinh)

## Power Assessment
- Pre-treatment periods: 54 months (Jan 2019 – June 2023)
- Treated clusters: ~15-20 ports with meaningful Canal dependence
- Post-treatment periods: ~14 months (July 2023 – August 2024)
- Total port-months: ~35 ports × 72 months ≈ 2,520
- MDE: With 35 clusters and continuous treatment, the design should detect effects of ~5-10% with standard power

## Data Sources
1. **Primary:** US Census Bureau International Trade API — monthly port-level imports by country of origin
2. **Canal transits:** Panama Canal Authority monthly transit statistics
3. **FRED:** Henry Hub gas prices (DHHNGSP) for LNG/energy subsector analysis
4. **BTS:** Port Performance Freight Statistics (TEU counts for container ports)
