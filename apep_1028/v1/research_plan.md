# Research Plan: Does a Lawyer Keep You Housed?

## Research Question

Does providing free legal counsel to tenants facing eviction (right-to-counsel, RTC) reduce community-level homelessness? RTC is the most significant expansion of civil legal rights in a generation — NYC alone spends $166M/year — yet the policy's stated justification (preventing homelessness) has never been tested causally. The existing literature studies individual court outcomes (Cassidy & Currie 2022; Collinson & Reed 2023; Caspi & Rafkin 2025), but nobody has connected RTC adoption to population-level homelessness counts.

## Identification Strategy

**Callaway-Sant'Anna staggered DiD** across Continuums of Care (CoCs).

- **Treatment:** 17+ cities enacted RTC between 2017-2023, mapping to ~20 CoCs
- **Control:** ~360 never-treated CoCs
- **Cohorts:** NYC (2017), SF/Newark (2018), Cleveland/Philadelphia (2019), Boulder/Baltimore/Seattle etc. (2020-2021), New Orleans/Detroit (2022), Jersey City/St. Louis (2023)
- **Pre-period:** 2007-2016 for NYC cohort (10 years); 2007-2018 for 2019 cohort

**Key identification advantages:**
1. Pre-COVID cohorts (NYC 2017, SF/Newark 2018, Cleveland/Philadelphia 2019) provide clean identification uncontaminated by moratorium confounds
2. Staggered adoption across diverse cities → not driven by any single local shock
3. Built-in placebo: unsheltered homelessness (less connected to eviction) vs sheltered (directly connected)

**COVID mitigation:**
- Restrict primary specification to pre-COVID cohorts (2017-2019 adopters only)
- Control for eviction moratorium dates in robustness
- COVID sensitivity: show results with and without 2020-2021 adopter cohorts

## Expected Effects and Mechanisms

**Primary hypothesis:** RTC reduces total PIT homeless counts in adopting CoCs by preventing evictions that would otherwise lead to shelter entry or unsheltered homelessness.

**Causal chain:** RTC → tenant gets lawyer → more cases dismissed/settled favorably → fewer evictions → fewer newly homeless

**Expected magnitudes:**
- Eviction filing reductions: 10-30% based on individual-level studies (Cassidy & Currie)
- Homelessness reduction: likely smaller because (a) not all evictions lead to homelessness and (b) homelessness has many non-eviction causes
- SDE expectation: small-to-moderate negative effect on homelessness

**Mechanism test:** Eviction Lab ETS filing rates in RTC cities should decline after adoption. If evictions decline but homelessness doesn't, the chain breaks at "eviction → homelessness."

**Heterogeneity predictions:**
- Sheltered > Unsheltered (direct eviction-to-shelter pipeline)
- Family > Individual (families more likely to become homeless from eviction)
- Tight rental markets > Slack markets (fewer outside options when evicted)

## Primary Specification

$$Y_{ct} = \alpha_c + \gamma_t + \sum_g \sum_{\ell} \text{ATT}(g,\ell) \cdot \mathbf{1}\{G_c = g\} \cdot \mathbf{1}\{t - g = \ell\} + \epsilon_{ct}$$

where $c$ indexes CoCs, $t$ indexes years, $G_c$ is the adoption year, and $\ell$ is event time. Callaway-Sant'Anna with not-yet-treated as comparison group. Clustered at CoC level.

**Outcome variables:**
1. Total PIT homeless count (log)
2. Sheltered homeless count (log)
3. Unsheltered homeless count (log)
4. Homeless families (log)

## Exposure Alignment

The treatment (RTC adoption) is assigned at the city or state level but measured at the CoC level. Key alignment considerations:

- **Who is treated?** Low-income tenants (typically <200% FPL) facing eviction proceedings in jurisdictions that adopted RTC. The directly treated population is tenants who receive free legal representation.
- **Who is measured?** The outcome (PIT count) captures all individuals experiencing homelessness on a single night within the CoC, regardless of their connection to eviction proceedings.
- **Alignment gap:** The treatment affects a narrow inflow channel (eviction-driven homelessness) while the outcome measures the entire stock of homelessness (driven by multiple channels including job loss, substance abuse, mental health, domestic violence, migration). This mismatch is inherent to the research question and is explicitly addressed in the paper's discussion.
- **Geographic alignment:** City-level RTC programs may not cover the entire CoC. For example, NYC's RTC covers all five boroughs, which aligns well with the NY-600 CoC. For state-level programs, all CoCs within the state are coded as treated. Some CoCs may span jurisdictions with and without RTC, diluting the treatment.

## Data Sources and Fetch Strategy

| Dataset | Source | Years | Unit | Access |
|---------|--------|-------|------|--------|
| PIT Homeless Counts | HUD Exchange | 2007-2024 | CoC × year | Public CSV download |
| Housing Inventory Count | HUD Exchange | 2007-2024 | CoC × year | Public CSV download |
| Eviction Lab ETS | Eviction Lab | 2017-2024 | City × week | Public download |
| ACS Housing | Census API | 2009-2023 | County × year | Census API |
| RTC Adoption Dates | Manual coding | 2017-2023 | City/CoC | From manifest + legislative sources |

**Fetch order:**
1. HUD PIT and HIC data (bulk CSV downloads)
2. Code RTC treatment status by CoC
3. Eviction Lab ETS for mechanism
4. ACS covariates (median rent, vacancy rate, poverty rate) for balance tests
