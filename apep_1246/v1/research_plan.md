# Research Plan: apep_1246

## Research Question

Did state healthcare worker vaccine mandates cause a permanent demographic recomposition of the nursing home workforce? Specifically: are the mandates responsible for the fact that NAICS 623 (Nursing & Residential Care) is the only US health subsector that has not recovered pre-pandemic employment, and did the mandates disproportionately push out young and minority workers?

## Vivid Mechanism: "The Mandate Sieve"

Vaccine mandates acted as a demographic sieve — filtering out younger, minority workers who were more likely to resist vaccination, while retaining older workers who had higher vaccination rates. This produced a permanent demographic transformation, not just a temporary staffing shock.

## Identification Strategy

**Triple-Difference-in-Differences (DDD):**

1. **Sector difference:** NAICS 623 (nursing/residential care, subject to facility-specific COVID regulations and CMS vaccine mandate) vs. NAICS 624 (social assistance — shares workforce demographics but was NOT covered by CMS vaccine mandate)
2. **State difference:** Early state mandate states (Aug-Oct 2021, ~15-20 states) vs. late/no state mandate states (where only the federal CMS mandate applied, Jan-March 2022)
3. **Time difference:** Pre-mandate (2015Q1-2021Q2) vs. post-mandate (2021Q3-2024Q4)

**Why this works:**
- The DD between NAICS 623 and 624 removes county-time confounds (general labor market conditions, COVID impacts common to both sectors)
- The DDD adds state-mandate timing variation, distinguishing mandate effects from general nursing home challenges
- Pre-treatment: 26+ quarters (2015Q1-2021Q2) for parallel trends testing
- The within-county comparison controls for local labor market conditions

**Estimator:** Callaway-Sant'Anna (2021) for heterogeneity-robust group-time ATTs with staggered adoption. NAICS 624 within the same county serves as the comparison sector.

**Inference:** Wild cluster bootstrap at the state level (~50 clusters). State is the treatment assignment level for state mandates.

## Expected Effects

1. **Employment (headcount):** Negative for NAICS 623 in mandate states, concentrated among ages 25-34 and Black workers
2. **Earnings (survivors):** Positive — remaining workers receive compensating wage increases (+23% indicated in smoke test)
3. **Heterogeneity:** Mandate sieve should be strongest where pre-mandate vaccination rates were lowest (younger, minority demographics)
4. **Persistence:** Effects should NOT recover — this is permanent recomposition, not temporary attrition

## Primary Specification

```
Y_{c,s,t} = α + β₁(Mandate_s × Post_t × NAICS623_s) + β₂(Mandate_s × Post_t) 
            + β₃(Post_t × NAICS623_s) + β₄(Mandate_s × NAICS623_s) 
            + γ_{c,s} + δ_t + ε_{c,s,t}

where:
  c = county, s = sector (623 vs 624), t = quarter
  Mandate_s = state adopted vaccine mandate before CMS federal mandate
  Post_t = post-mandate period
  γ_{c,s} = county-sector fixed effects
  δ_t = quarter fixed effects
```

For the staggered adoption version: Callaway-Sant'Anna with group = state mandate quarter, time = calendar quarter, comparing NAICS 623 to 624 within county.

## Data Source and Fetch Strategy

**Primary data:** QWI (Quarterly Workforce Indicators) from Azure Blob Storage
- `derived/qwi/sa/n3/*.parquet` — county × quarter × 3-digit NAICS × demographics (beginning-of-quarter employment, hires, separations, earnings)
- Filter to NAICS 623 and 624
- Years: 2015-2024
- Demographics: age group, race/ethnicity, sex, education

**Treatment data:** State vaccine mandate dates
- Compile from KFF (Kaiser Family Foundation), NASHP, and published literature
- Key variables: state FIPS, mandate announcement date, mandate effective date, mandate type (healthcare workers, nursing home specific)

**Validation data:**
- BLS QCEW for aggregate sector employment trends
- CMS nursing home staffing data (Payroll-Based Journal) for facility-level validation

## Robustness Checks

1. **Event study:** Dynamic treatment effects to verify parallel pre-trends
2. **Placebo sector:** NAICS 621 (ambulatory care — partially covered by mandates, should show weaker effects)
3. **Placebo demographics:** Age 55+ workers (higher vaccination rates → should show weaker mandate sieve effect)
4. **HonestDiD sensitivity:** Rambachan-Roth bounds for pre-trend violations
5. **Leave-one-out:** Drop each mandate state one at a time
6. **Alternative estimator:** Sun-Abraham via fixest::sunab() as robustness check

## Key Risks

1. **COVID confound:** COVID itself hit nursing homes hardest — but the DDD with NAICS 624 and pre-mandate periods (2020-2021Q2) should absorb this
2. **Federal mandate overlap:** CMS mandate (Jan 2022) eventually applied to all states — identification comes from the TIMING differential between state and federal mandates
3. **Suppressed cells:** QWI suppresses small cells for privacy — may lose rural counties in demographic breakdowns
