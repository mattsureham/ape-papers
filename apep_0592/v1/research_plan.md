# Initial Research Plan: State Prohibition and General Equilibrium Labor Market Restructuring

## Research Question

When America's fifth-largest industry was destroyed by staggered state prohibition laws (1907-1919), how were the occupational trajectories of *non-alcohol* workers reshaped in high-exposure cities? We study the general equilibrium labor market spillovers — not the direct effect on displaced alcohol workers, but the reallocation, crowding, and social infrastructure effects on everyone else.

## Identification Strategy

**Staggered DiD with Continuous Exposure (Callaway-Sant'Anna framework)**

Two sources of variation:
1. **Cross-state timing:** 33 states adopted prohibition at different times (1907-1919). ~15 states remained wet until national prohibition (1920).
2. **Within-state, cross-city intensity:** Cities with higher pre-prohibition alcohol industry employment shares experienced larger labor demand shocks.

**Core estimating equation:**

ΔOCCSCOREᵢ,t→t+10 = α + β(Prohibition_s,t × AlcoholShare_c,1910) + X'ᵢγ + δ_c + θ_s,t + εᵢ

Where:
- ΔOCCSCOREᵢ is the within-person change in occupational income score
- Prohibition_s,t = 1 if state s has enacted prohibition by census year t
- AlcoholShare_c,1910 = share of city c's 1910 workforce in alcohol industries
- Xᵢ = individual 1910 controls (age, race, nativity, marital status, occupation)
- δ_c = city fixed effects, θ_s,t = state×year fixed effects

**Critical design feature:** Sample EXCLUDES alcohol industry workers. β captures spillover effects on the other 95%.

**Built-in placebos:**
1. Workers in zero-exposure cities (AlcoholShare = 0)
2. Workers in already-dry states (ME, KS, ND) — they experienced no new prohibition shock
3. Pre-trend test: 1900-1910 linked panel (pre-prohibition for all but 3 states)

## Exposure Alignment (DiD)

- **Who is treated?** Non-alcohol workers in cities with high alcohol industry concentration, in states that adopted prohibition during 1907-1919.
- **Primary estimand population:** Working-age males (18-65) in non-alcohol occupations, residing in cities with >0% alcohol industry share.
- **Placebo/control populations:** (a) Workers in zero-exposure cities, (b) workers in never-dry states before 1920, (c) workers in already-dry states.
- **Design:** Continuous treatment DiD with staggered timing. Treatment intensity = AlcoholShare_c,1910.

## Power Assessment

- **Pre-treatment periods:** 1 decade (1900-1910 linked panel)
- **Treated clusters:** 33 states with staggered timing; within-state variation across hundreds of cities
- **Post-treatment periods:** 1 decade (1910-1920) for state prohibition; additional 1920-1930 for long-run
- **Sample size:** 8-10M non-alcohol workers in the MLP linked 1910-1920 panel (full-count)
- **MDE:** With millions of observations and continuous treatment, power is not a concern. The question is economic significance.

## Expected Effects and Mechanisms

1. **Demand spillover (upstream/downstream):** Workers in cooperage, glass-making, grain/hops agriculture, and transportation should see occupational downgrading in high-exposure cities. *Expected: negative β for supply-chain workers.*
2. **Labor reallocation (crowding):** Surplus labor floods other sectors, compressing occupational standing for incumbents in manufacturing and services. *Expected: small negative β for manufacturing workers.*
3. **Commercial real estate:** Saloon closures freed prime commercial locations, enabling new retail businesses. *Expected: positive β for self-employment and retail entry.*
4. **Social infrastructure:** Saloons served as working-class social institutions (job referrals, labor organizing, informal insurance). Their destruction may have disrupted labor networks. *Expected: increased geographic mobility, more occupation-switching.*
5. **Women's employment:** Saloons (male-only) replaced by restaurants, soda fountains, tea rooms (open to women). *Expected: positive β for female labor force participation in high-exposure cities.*

**Overall:** The net effect is ambiguous — negative demand/crowding vs. positive reallocation/women's employment. The paper's contribution is decomposing these channels.

## Primary Specification

1. Main result: β for ΔOCCSCORE on Prohibition × AlcoholShare
2. Mechanism tests by pre-prohibition industry (supply chain vs. other manufacturing vs. services)
3. Heterogeneity by race, nativity, gender (pre-committed from theory)
4. Long-run effects (1910-1930)

## Planned Robustness Checks

1. Pre-trend: 1900-1910 linked panel (expect null β)
2. Placebo: zero-exposure cities
3. Exclude already-dry states (ME, KS, ND)
4. Restrict to non-Southern states (14 Third Wave states)
5. Sun and Abraham (2021) interaction-weighted estimator
6. ABE crosswalk as alternative linking methodology
7. County-level analysis (IPUMS provides county codes)
8. Leave-one-out by state (exclude each treated state in turn)
9. Randomization inference (permute state prohibition timing)

## Data Sources

1. **IPUMS Full-Count Census 1910, 1920, 1930:** In Azure (`raw/ipums_fullcount/us{year}.parquet`)
2. **MLP Crosswalks:** In Azure (`raw/ipums_mlp/v2/`) — pre-linked panels for 1910-1920, 1920-1930
3. **ABE Crosswalks:** In Azure (`raw/census_linking_project/crosswalk_{from}_{to}.parquet`)
4. **State Prohibition Dates:** Beienburg (2020), hardcoded from appendix table
5. **City-level alcohol industry shares:** Constructed from 1910 full-count census (IND1950 codes)
