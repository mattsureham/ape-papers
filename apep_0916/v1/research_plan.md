# Research Plan: When the Banks Broke — Depression-Era Bank Failures and Individual Economic Scarring

## Research Question
Did county-level bank failure intensity during the Great Depression (1929–1933) cause lasting economic scarring for individuals? Using the first individual-level linked census panel spanning the Depression decade, this paper estimates causal effects of local banking collapse on occupational trajectories, homeownership, and migration.

## Identification Strategy
**Within-individual long-difference** using the MLP 1920–1930–1940 three-decade linked panel (10.2M men). Individuals are observed in 1920 (pre-Depression baseline), 1930 (onset), and 1940 (post-crisis). The primary specification estimates:

ΔY_i(1940–1920) = α + β × BankFailureIntensity_c + X_i(1920)γ + StateRegion_FE + ε_i

where BankFailureIntensity_c is the county-level bank suspension rate (failures per 1,000 population, 1929–1933) and X_i(1920) are individual baseline characteristics.

**Instrument:** State unit banking laws (prohibiting branch banking) interacted with county agricultural dependence. Unit banking states experienced dramatically higher failure rates because single-office banks could not diversify risk across geographies. Agricultural counties were hit hardest due to commodity price collapse.

## Expected Effects
- **Occupational downgrading:** Individuals in high-failure counties experience persistent occupational income score declines (1920→1940) — credit destruction reduces local labor demand and entrepreneurship.
- **Homeownership loss:** Bank failures destroy savings and mortgage access, reducing homeownership.
- **Forced migration:** Workers in collapsed banking markets migrate to less-affected areas.
- **Heterogeneity:** Effects concentrated among younger workers (career disruption), farmers (agricultural exposure), and non-homeowners (fewer assets to buffer shocks).

## Primary Specification
IV-2SLS with first stage:
BankFailureRate_c = δ₀ + δ₁ UnitBankingLaw_s × AgShare_c(1920) + Controls + ε_c

Second stage (individual level):
Δ OccScore_i(1940–1920) = α + β BankFailureRate_c(hat) + X_i(1920)γ + Region_FE + ε_i

Clustering: State level (48 states, treatment varies at state-county level).

## Data Sources
1. **MLP 1920–1930–1940 three-decade linked panel** (Azure: `derived/mlp_panel/linked_1920_1930_1940.parquet`) — 10.2M men linked across three censuses with occupational scores, homeownership, county of residence, demographics.
2. **IPUMS full-count 1940 census** (Azure: `raw/ipums_fullcount/us1940b.parquet`) — for wage income (INCWAGE), available only in 1940.
3. **Bank suspension data** — state-level bank suspension counts from FDIC Historical Statistics on Banking / Federal Reserve Board annual reports. County-level if accessible.
4. **Unit banking laws** — classification from Calomiris & Wheelock (1998), Jayaratne & Strahan (1996). Binary indicator by state.
5. **Agricultural employment share** — from 1920 census aggregation (farm workers / total employed by county).

## Key Risks
- County identifiers may be missing or inconsistent across linked decades
- Bank failure data at county level may be unavailable — fallback to state-level analysis
- Link quality in MLP may introduce selection bias — check against ABE crosswalks for robustness
