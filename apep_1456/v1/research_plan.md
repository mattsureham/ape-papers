# Research Plan: DPA Enforcement Intensity and ICT Startup Survival

## Research Question

Does the intensity of GDPR enforcement by national Data Protection Authorities affect ICT startup survival rates? Conditional on all EU firms facing the same legal mandate, does stricter enforcement select for more durable entrants (selection effect) or suppress entry and survival (chilling effect)?

## Identification Strategy

**Staggered difference-in-differences** exploiting within-EU variation in DPA enforcement timing and intensity. GDPR is identical across all 27 member states — the identifying variation comes from when and how aggressively each DPA began issuing fines.

- **Treatment:** First significant fine year by country (staggered: Austria/Germany 2018, France/Spain/Bulgaria 2019, Ireland/Finland 2020+), plus continuous measure (cumulative fines per billion EUR GDP).
- **Control:** EU countries that had not yet begun significant enforcement in a given year. Countries serve as their own controls in the pre-enforcement period.
- **Estimator:** Callaway-Sant'Anna (2021) for heterogeneous treatment effects across cohorts.
- **Parallel trends:** Testable using 4+ pre-GDPR years (2014-2017) before any enforcement began.

## Expected Effects and Mechanisms

**Hypothesis 1 (Selection):** Enforcement raises the compliance bar → marginal low-quality entrants don't enter → birth rate falls, but 1-year survival rate rises among entrants. Net effect on ICT employment ambiguous.

**Hypothesis 2 (Chilling):** Enforcement raises regulatory uncertainty → good and bad startups deterred → both birth rate and survival rate fall. Net negative for ICT dynamism.

**Mechanism tests:**
- If selection: birth rate ↓, survival ↑, average firm size at birth ↑
- If chilling: birth rate ↓, survival ↓, average firm size at birth unchanged or ↓

## Primary Specification

```
y_{c,t} = α_c + α_t + β × Enforced_{c,t} + X_{c,t}γ + ε_{c,t}
```

where `Enforced_{c,t}` is binary (first significant fine issued), `y` is ICT startup 1-year survival rate, and `X_{c,t}` includes log GDP per capita, unemployment rate, and BoP interest rate.

CS-DiD version: group-time ATT estimates with never-treated and not-yet-treated as controls.

## Robustness

1. **Placebo sector:** Construction (NACE F) — no data processing, GDPR should not affect
2. **Continuous treatment:** Cumulative fines per GDP instead of binary
3. **Pre-2018 placebo:** Assign fake enforcement stagger to 2014-2015
4. **Excluding COVID year:** Drop 2020 to address overdraft/COVID confound concern
5. **DPA budget IV:** DPA staff FTE (from EDPB reports) as instrument for enforcement intensity

## Data Sources

1. **Enforcement Tracker** (`enforcementtracker.com/data4sfk3j4hwe324kjhfdwe.json`): 3,071 GDPR fine records with country, date, amount, sector. Construct country-year enforcement intensity measures.
2. **Eurostat Business Demography** (`bd_9bd_sz_cl_r2`): ICT (NACE J) startup birth rates (V97020), 1-year survival (V97041), 3-year survival (V97043), average size of new enterprises (V97121). Annual, country-level.
3. **Eurostat GDP** (`nama_10_gdp`): For normalization of enforcement intensity.
4. **Eurostat unemployment** (`une_rt_a`): Control variable.
5. **EDPB Annual Reports** (2019-2022): DPA budget and FTE data for IV specification.

## Exposure Alignment

**Who is actually treated?** ICT startups (NACE J) in EU member states where the national DPA has begun active GDPR enforcement (issued at least one fine). The treatment operates through the signal of regulatory activity: when a DPA issues its first fine, it demonstrates that enforcement is real, raising the perceived compliance bar for prospective entrants. The outcome (startup birth and survival rates) measures firm-level entry and exit decisions at the country-sector-year level. Treatment is assigned to the country, not individual firms — all ICT startups in a given country face the same DPA enforcement environment. Non-ICT sectors (e.g., Construction) serve as within-country placebos since they process minimal personal data and are minimally exposed to GDPR enforcement.

## Data Fetch Strategy

1. Fetch enforcement tracker JSON → parse to country-year panel of cumulative fines
2. Fetch Eurostat business demography via `eurostat` R package → ICT birth/survival rates
3. Fetch Eurostat GDP and unemployment → merge as controls
4. Manually code DPA enforcement cohort years from enforcement tracker data
5. Construct balanced panel: 27 EU countries × 2014-2022 (or latest available)
