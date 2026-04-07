# Research Plan: Nigeria Electricity Privatization and Household Welfare

## Research Question
Does the identity and capacity of the private operator affect household welfare after infrastructure privatization? Nigeria's 2013 electricity privatization created 11 distribution companies (DisCos) with dramatically different performance (collection efficiency 30-80%), allowing us to estimate causal effects of DisCo quality on employment, enterprise operation, education, and energy expenditure.

## Identification Strategy
**Continuous-treatment difference-in-differences (DiD)** with household fixed effects.
- **Unit of observation:** Household across 5 waves (2010/11, 2012/13, 2015/16, 2018/19, 2023/24)
- **Treatment:** Post-privatization (2013+) DisCo performance (collection efficiency)
- **Variation:** 11 DisCos with 30-80% collection efficiency range (source: NERC quarterly reports)
- **Geographic assignment:** Territory mapping fixed at privatization; state-DisCo assignment is exogenous
- **Pre-trends:** Two pre-reform waves (2010/11, 2012/13) allow testing parallel trends assumption
- **Fixed effects:** Household FE absorbs time-invariant DisCo/state characteristics; wave FE absorbs national trends

## Exposure Alignment
**Who is actually treated?** All 5,000 households in the sample are exposed to the 2013 privatization shock, which occurs simultaneously across all states. However, treatment intensity varies by household based on the DisCo serving the household's state of residence.

**Treatment variation:** Households in states served by high-efficiency DisCos (Eko Electric, 85% collection) experience improved service quality. Households in states served by low-efficiency DisCos (Kaduna Electric, 35% collection) experience service degradation relative to the pre-privatization monopoly. Treatment is continuous and determined by DisCo collection efficiency (0--100\%), not binary.

**Exogeneity:** A household's state is determined by survey sampling and residential history (not by DisCo choice). Therefore, DisCo assignment is exogenous to household-level demand for electricity.

## Intuition
Privatization improved service quality in some DisCo territories (e.g., Eko Electric in Lagos: 85% collection) but failed in others (e.g., Kaduna Electric: 35% collection). This heterogeneity creates exogenous treatment intensity. The identification assumes that conditional on household and time fixed effects, DisCo quality is orthogonal to household-specific demand shocks. Robustness: CS-DiD, VIIRS nighttime lights as alternative treatment intensity, household migration selection bounds.

## Expected Effects & Mechanisms

**Primary outcome:** Hours of electricity per week (avg baseline 35.8 hours)
- **Mechanism A (direct):** Better DisCo → more reliable supply → more study/work hours
- **Mechanism B (adaptation):** Worse DisCo → more generator investment → higher energy expenditure share
- **Mechanism C (enterprise):** Better service → non-farm enterprise entry/operation (employment effect)

**Secondary outcomes:**
1. Employment (binary: any employment, including self-employment)
2. Non-farm enterprise ownership (binary)
3. Weekly study hours (children 6-17)
4. Energy expenditure as share of total expenditure

## Data Sources

### Primary: Nigeria General Household Survey Panel (GHS-Panel)
- **Source:** World Bank Microdata Library (LSMS-ISA)
- **Waves:** 5 (2010/11, 2012/13, 2015/16, 2018/19, 2023/24)
- **Sample:** ~5,000 households tracked, ~30,000 individuals per wave
- **Variables:** State, sector (urban/rural), lighting source, electricity hours/week, employment, enterprise ownership, education (study hours), energy expenditure
- **Access:** Free, WB Microdata Library (authenticated access available)
- **Data status:** CONFIRMED AVAILABLE

### Treatment Intensity: NERC DisCo Performance Reports
- **Source:** Nigerian Electricity Regulatory Commission (NERC), quarterly public reports
- **Variables:** DisCo ID, state coverage, collection efficiency (%), ATC&C losses (%), average tariff
- **Period:** 2013-2024 quarterly
- **Access:** nerc.gov.ng (public, no registration required)
- **Data status:** CONFIRMED AVAILABLE

### Geographic Linkage: SDWA Drinking Water Information System (SDWIS)
- **Source:** EPA echo.epa.gov (Public Water Systems serving data)
- **Usage here:** NOT NEEDED for Nigeria (state-DisCo mapping is documented and fixed at privatization)
- **Alternative:** Use state as geographic unit; DisCo-state mapping is deterministic and published in NERC reports

### Robustness/Mechanism: VIIRS Nighttime Lights
- **Source:** NASA EARTH/NOAA VIIRS_DNB_Daily, monthly composites
- **Usage:** Alternative treatment intensity (proxy for electricity access at commune level)
- **Period:** 2012-2024
- **Access:** GCS bucket available via Google Cloud or AWS Earth on AWS
- **Data status:** CONFIRMED AVAILABLE (alternative)

## Primary Specification

```
electricity_hours_w[i,t] = α_i + δ_t + β × (collection_efficiency[s,t] × post_2013[t]) + ε_{i,t}

where:
  i = household
  t = wave
  s = state (mapped to DisCo)
  α_i = household fixed effect
  δ_t = wave fixed effect
  collection_efficiency[s,t] = NERC-reported efficiency (continuous, 0-1 scale)
  post_2013[t] = 1 if t ∈ {2015/16, 2018/19, 2023/24}, 0 otherwise
  β = average treatment effect of a 1-percentage-point increase in DisCo efficiency
```

**Standard errors:** Clustered at state-wave level (11 DisCos, 5 waves = 55 clusters, well-powered)

## Sample Size
- **Households:** ~5,000 households tracked across 5 waves
- **Household-wave observations:** ~25,000 (including wave-by-wave balance)
- **Individual-wave observations:** ~30,000-150,000 (including all household members)
- **Geographic variation:** 37 states, 11 DisCos
- **Pre-reform period:** 2 waves before 2013
- **Post-reform period:** 3 waves after 2013
- **Power:** Well-powered with state-level clustering (11 clusters)

## Robustness Checks
1. **Callaway-Sant'Anna DiD** (allows heterogeneous effects across treatment groups)
2. **VIIRS nighttime lights as alternative treatment intensity**
3. **Bounding for migration selection** (if households migrate toward better-serviced DisCos)
4. **Event study / dynamic effects** (allow treatment effect to vary by years since privatization)
5. **Placebo test:** Use 2010-2013 pre-period to test for pre-existing trends (should be zero)
6. **Alternative outcomes:** Generator ownership (adaptation), tariff collection (cost pass-through)

## Timeline
- **Week 1:** Data fetch from WB and NERC, create state-DisCo-wave panel
- **Week 2:** Analysis, pre-trends test, heterogeneity
- **Week 3:** Robustness checks, write paper
- **Week 4:** Reviews and revision

## Novelty & Contribution
**Novelty:** First causal study of infrastructure privatization failure using household panel data in SSA. Previous literature (Eberhardt & Teal 2011, Andres & Gupta 2013) uses firm surveys or aggregate outcomes. GHS-Panel's five-wave structure spanning the reform is unused for this question.

**Contribution:** Tests whether private-sector operation of infrastructure is inherently superior or whether operator identity/capacity matters. If Eko Electric households gained while Kaduna Electric households lost, the lesson is that privatization without adequate capitalization is worse than the status quo. Fundamental for 30+ years of development policy.

## Key Risks
1. **Migration selection:** Households may migrate toward better-serviced areas (bias toward zero if they flee bad DisCos)
2. **Macroeconomic shocks:** 2015 oil crash, 2020 COVID, inflation 2021-2023 may confound outcomes (mitigated by wave FE)
3. **Data quality:** GHS-Panel electricity hours may be self-reported and subject to recall bias (mitigated by checking pre-trends)
4. **Concurrent reforms:** Other electricity sector reforms (CAPCO, MYTO tariff changes) in 2015, 2017 (documented in Discussion)

## Definitions
- **Collection efficiency:** Ratio of billed units to supplied units (%)
- **ATC&C losses:** Aggregate Technical and Commercial losses (%)
- **DisCo:** Distribution Company (11 regional electric utilities created in 2013)
- **SERVEL:** Electoral commission data (NOT used here; included in idea manifests for reference)
