# Initial Research Plan: Scale Mismatch in French Climate Policy

## Research Question

Does climate policy that appears consensual at the national level become politically divisive when implemented locally? We test this "scale mismatch" hypothesis using France's Low-Emission Zones (Zones a Faibles Emissions, ZFE-m), a nationally legislated but locally implemented vehicle restriction policy where distributional costs (banning older cars, constraining commuters) become concrete at the local level.

## Identification Strategy

### Treatment Definition
- **Unit of analysis**: Legislative constituency (circonscription legislative) for local electoral outcomes; MP for spillback analysis.
- **Treatment**: ZFE activation in the constituency, measured as (i) binary indicator for any active ZFE and (ii) continuous intensity = share of constituency population residing within ZFE perimeter.
- **Treatment assignment (quasi-exogenous)**: Two sources of externally imposed mandates:
  1. **Air-quality exceedance (LOM 2019)**: 11 agglomerations where pre-2019 NO2 annual averages exceeded 40 microg/m3 for 3+ of 5 years were legally required to establish ZFE by December 2020.
  2. **Population threshold (Climat et Resilience 2021)**: All agglomerations >150,000 inhabitants required to establish ZFE by January 2025.
- **Control group**: Constituencies in agglomerations that are (a) mandated but implemented later, or (b) below the population threshold and not mandated. Pure staggered design.

### Design
- **Callaway-Sant'Anna (2021) staggered DiD**: Cohort-time ATT estimates with never-treated and not-yet-treated as controls.
- **Event study**: Leads/lags around ZFE activation date, with 4 pre-treatment election periods (2002, 2007, 2012, 2017) and 2-3 post-treatment periods (2022, 2024; some cities also 2020 municipales).

### Power Assessment
- **Treated clusters**: ~25 constituencies in Wave 1 ZFE cities (2019-2023 implementation), ~100+ in Wave 2 (2024-2025).
- **Pre-treatment periods**: 4 legislative elections (2002-2017), 3 municipal elections (2001-2014).
- **Post-treatment periods**: 1-3 depending on cohort (2020 municipales, 2022 legislatives, 2024 legislatives).
- **MDE estimate**: With ~500 constituencies, 4 pre-periods, and ~25% treated, standard power calculations suggest MDE of ~0.15 SD for ENP, which is meaningful (mean ENP ~4.5, SD ~1.2 in recent elections).

### Exposure Alignment
- **Who is actually treated?** Residents of communes inside ZFE perimeters, especially those owning older (Crit'Air 3+) vehicles.
- **Primary estimand population**: Voters in constituencies overlapping ZFE areas.
- **Placebo/control population**: Voters in non-ZFE constituencies of similar-sized agglomerations.
- **Design**: DiD with staggered treatment timing. No DDD needed given clean treatment definition.

## Expected Effects and Mechanisms

### Hypotheses
1. **Local divisiveness increases post-ZFE**: Electoral polarization (ENP) and anti-restriction party vote shares (RN) increase in ZFE constituencies relative to controls.
2. **National divisiveness remains flat or increases only mildly**: Roll-call polarization on climate legislation does not show comparable increase. The "gap" between local and national divisiveness widens after ZFE rollout.
3. **Heterogeneity by exposure**: Effects are larger in constituencies with higher share of Crit'Air 3+ vehicles, lower public transit access, higher commuting dependence, and lower income.
4. **Spillback**: MPs from high-ZFE-exposure constituencies are more likely to deviate from party lines on subsequent national climate/transport votes.

### Expected magnitudes
- Anti-restriction party (RN) vote share increase of 2-5 pp in ZFE constituencies (based on analogues from fuel tax protests/Gilets Jaunes literature).
- Spillback deviation rate of 5-15 pp above party mean on ZFE-adjacent votes.

## Primary Specification

### Outcome variables (pre-registered hierarchy)
1. **Primary local**: Effective Number of Parties (ENP) = 1/sum(s_i^2) in legislative elections, by constituency.
2. **Secondary local**: RN + Reconquete vote share in legislative elections, by constituency.
3. **National benchmark (descriptive)**: Rice index of party-line voting on ZFE-tagged roll calls.
4. **Mechanism (spillback)**: Binary deviation from party-group majority position on climate/transport roll calls, by MP.

### Covariates and fixed effects
- Constituency FE + election-year FE (main DiD)
- MP FE + vote FE (spillback analysis)
- Controls: constituency-level income, population density, urbanization rate, public transit access, vehicle fleet composition (Crit'Air share) — all pre-treatment values interacted with time trends.

## Planned Robustness Checks
1. **Pre-trend validation**: Event-study plots with formal Rambachan-Roth sensitivity analysis.
2. **Bacon decomposition**: Verify clean identification weights in staggered setting.
3. **Alternative estimators**: Sun-Abraham, Borusyak-Jaravel-Spiess, stacked DiD.
4. **Placebo outcomes**: Non-climate roll-call votes (e.g., education, defense) as placebo for spillback.
5. **Placebo geographies**: Constituencies in agglomerations just below 150k population threshold.
6. **Donut specifications**: Exclude commuting-belt constituencies.
7. **Continuous treatment intensity**: Population-weighted ZFE exposure instead of binary.
8. **Municipal election outcomes**: Replicate main results using municipal elections (different timing).
9. **Randomization inference**: Permute treatment assignment across constituencies.

## Data Sources
- **Roll-call votes**: data.assemblee-nationale.fr (JSON, no auth)
- **Debate transcripts**: data.assemblee-nationale.fr (XML, no auth) — appendix only
- **Election results**: data.gouv.fr aggregated elections (Parquet, no auth)
- **ZFE boundaries + rules**: transport.data.gouv.fr BNZFE (GeoJSON, no auth)
- **Air quality**: Geodair API or data.gouv.fr annual concentrations (CSV)
- **Vehicle fleet by Crit'Air**: SDES (Excel)
- **Constituency boundaries**: data.gouv.fr (GeoJSON)
- **Controls**: INSEE commune-level census data (income, density, transit)
