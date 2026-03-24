# Research Plan: The Partition Trap

## Research Question

Does the Uniform Partition of Heirs Property Act (UPHPA) reduce forced sales of family land and increase Black homeownership? Heirs' property — real estate inherited without a will and held in common by descendants — is one of the largest sources of involuntary land loss for Black families in the United States. Before UPHPA, any co-tenant (including speculators who purchased fractional interests) could petition for a forced partition sale, typically at below-market prices. UPHPA reforms this process by requiring court-ordered appraisals, granting co-tenants a right of first refusal, mandating open-market sales, and requiring courts to consider non-economic value. This paper provides the first causal evaluation of UPHPA.

## Identification Strategy

**Staggered Difference-in-Differences** using Callaway and Sant'Anna (2021) to avoid forbidden comparisons from heterogeneous treatment timing.

- **Treatment:** State-level UPHPA enactment (23+ states, 2011-2024)
- **Primary comparison:** Never-treated states (15+ states)
- **Triple-difference:** Treated × Post × Black (vs. White) homeownership within the same county-year, netting out county-year shocks and race-invariant policy effects

**Built-in placebos:**
1. White homeownership rate (UPHPA targets heirs' property, which disproportionately affects Black families)
2. Pre-period event study dynamics

**Heterogeneity / mechanism tests:**
- Interaction with 2018 Farm Bill Section 12615 (requires UPHPA adoption for USDA heirs' property lending)
- High vs. low intestacy prevalence counties (proxy: share of estates without wills)
- Southern vs. non-Southern states (historical concentration of Black heirs' property)

## Expected Effects and Mechanisms

- **Primary:** UPHPA should increase Black homeownership rates by reducing forced partition sales
- **Mechanism:** Right of first refusal + appraisal requirement → co-tenants retain property instead of losing it at forced auction
- **Farm Bill amplification:** Post-2018, UPHPA states unlock USDA lending for heirs' property resolution, creating an additional channel
- **Magnitude prior:** Small-to-moderate positive effect expected. Heirs' property affects ~30% of Black-owned land in the South (USDA estimates), but UPHPA requires active court proceedings to trigger protections.

## Primary Specification

$$Y_{cst} = \alpha_c + \gamma_t + \beta \cdot \text{UPHPA}_{st} + X_{cst}\Gamma + \varepsilon_{cst}$$

where $Y_{cst}$ is the Black homeownership rate in county $c$, state $s$, year $t$; $\alpha_c$ are county fixed effects; $\gamma_t$ are year fixed effects; $\text{UPHPA}_{st}$ is an indicator for state $s$ having enacted UPHPA by year $t$.

Triple-difference adds race dimension: county-race-year panel with county-race and race-year FE.

Clustering: state level (treatment varies at state level).

## Data Source and Fetch Strategy

1. **ACS 1-Year Estimates** (Census API, 2009-2023):
   - B25003B: Black tenure by occupancy (owner/renter) — county level
   - B25003H: White non-Hispanic tenure — county level (placebo)
   - B01003: Total population (for filtering)
   - B25077: Median home values

2. **Treatment coding:** Manual from Uniform Law Commission records + state legislative databases. 23+ states with exact enactment years.

3. **Sample:** Counties with ≥500 Black households (ensures ACS estimates are non-suppressed and reasonably precise). ~1,200-1,500 counties × 15 years.
