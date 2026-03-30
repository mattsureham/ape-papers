# Research Plan: apep_1144

## Research Question

Do patent grants cause local employment growth? We use quasi-random assignment of patent applications to USPTO examiners of varying leniency to construct a Bartik-style instrument for state-level patent grant shocks, and estimate the effect on employment using the Census Quarterly Workforce Indicators (QWI).

## Identification Strategy

**Design:** Shift-share (Bartik) instrumental variables.

**Endogenous regressor:** State-year patent grant count (log or IHS).

**Instrument construction:**

$$\text{Bartik}_{st} = \sum_a \text{share}_{sa} \times \text{shift}_{at}$$

where:

- $\text{share}_{sa}$ = state $s$'s share of patent applications in art unit $a$, computed over a **fixed early window (2001--2003)** using first-inventor state from BigQuery PatEx `all_inventors` table. These shares are pre-determined and do not vary with later outcomes.

- $\text{shift}_{at}$ = leave-one-out average examiner grant rate within art unit $a$ in year $t$. For each application $i$ assigned to examiner $j$ in art unit $a$ and year $t$, compute examiner $j$'s grant rate from all other applications in the same art-unit-year, excluding application $i$. Then average across all applications in art-unit-year $(a,t)$ to obtain the shock. Random assignment of applications to examiners is within art-unit-year, so the leave-one-out examiner mean at this level captures the exogenous component of leniency (Lemley & Sampat 2012; Sampat & Williams 2019 QJE).

**Exclusion restriction:** Within an art unit and year, application assignment to examiners is quasi-random. Therefore, the art-unit-year average examiner leniency shock is orthogonal to local economic conditions, conditional on the pre-determined technology composition shares.

**Identification argument follows Borusyak, Hull & Jaravel (2022):** With shift-share IV, we rely on exogeneity of shocks (many independent art-unit-year leniency draws with no single dominant art unit driving results). The examiner lottery provides genuinely random shocks at the art-unit-year level, satisfying BHJ conditions.

## Unit of Analysis

**State × year.** 51 states (50 + DC), annual frequency. Estimating sample approximately 2004--2012/13, determined by a censoring rule: we truncate the sample where the unresolved (pending) share of applications in a filing-year cohort exceeds 20%, to avoid right-censoring attenuation in the grant variable. A smoke test on filing-year resolution rates pins down the exact endpoint.

## Expected Effects

- **Main hypothesis:** An exogenous increase in patent grants in a state increases local employment in the following year. The "patent payroll dividend" is positive and economically meaningful.
- **Alternative hypothesis:** Patent grants do not translate to local employment (patents are paper assets, or jobs move to other states). A credible null would be informative.
- **Mechanism:** Employment gains should be larger in patent-intensive ("exposed") sectors (manufacturing, information, professional/scientific services) than in local-service sectors (retail, accommodation, food services). We do not require zero effects in local services, since demand spillovers from innovation income could raise local employment too.

## Primary Specification

**Second stage (2SLS):**

$$\log(\text{Emp}_{s,t+1}) = \alpha_s + \gamma_t + \beta \cdot \log(\text{Grants}_{st}) + \varepsilon_{st}$$

**First stage:**

$$\log(\text{Grants}_{st}) = \alpha_s + \gamma_t + \pi \cdot \text{Bartik}_{st} + u_{st}$$

- State and year fixed effects absorb level differences and common shocks.
- **No additional controls in the baseline specification.** State FE already absorb state size; lagged employment on the RHS of future employment can absorb the persistence margin we care about. Pre-determined characteristics and state-specific trends appear only as robustness checks.
- Outcome is **one year ahead** ($t+1$) because commercialization-to-payroll lags are unlikely same-year.

## Data Sources

1. **USPTO PatEx** (BigQuery: `patents-public-data.uspto_oce_pair.application_data`)
   - 8.3M applications with `examiner_id`, `examiner_art_unit`, `uspc_class`, `disposal_type`, `filing_date`, `patent_issue_date`, `abandon_date`
   - `all_inventors` table for first-inventor state linkage (`inventor_region_code` = US state, 12.1M US inventor records, 4.3M unique applications)

2. **Census QWI** (Azure: `derived/qwi/se/ns/*.parquet`)
   - 150M+ rows: county × quarter × industry × demographics
   - Aggregate to state × year for main panel
   - Key variables: `Emp` (employment), `HirN` (new hires), `EarnS` (monthly earnings)
   - Sex × education breakdown for heterogeneity

## Outcome Variables

| Priority | Variable | Aggregation | Description |
|----------|----------|-------------|-------------|
| Primary | log(Emp_{s,t+1}) | Mean of Q1-Q4 | Total private employment, all sectors |
| Secondary | HirN_{s,t+1} | Sum of Q1-Q4 | Annual new hires |
| Secondary | EarnS_{s,t+1} | Mean of Q1-Q4 | Average monthly earnings |
| Mechanism | log(Emp) by sector group | Mean of Q1-Q4 | Exposed vs local-service sectors |

## Sector Definitions (for mechanism contrasts only)

- **Exposed sectors:** Manufacturing (31-33), Information (51), Professional/Scientific/Technical Services (54)
- **Local-service sectors:** Retail Trade (44-45), Accommodation and Food Services (72), Other Services (81)
- Framing: effects should be *larger* in exposed than local services (mechanism contrast), not necessarily zero in local services.

## Diagnostics and Robustness

1. **First-stage F-statistic** — must exceed 10 (Staiger-Stock) and ideally pass effective F (Olea & Pflueger 2013)
2. **Leave-one-out art unit:** Drop each art unit one at a time; verify no single unit drives the result
3. **Leave-one-out state:** Drop each state; verify no single state drives the result
4. **Exposure-robust inference:** Implement Adao-Kolesár-Morales (2019) or Borusyak-Hull-Jaravel (2022) standard errors, not just state-clustered SEs
5. **Mechanism contrast:** Estimate on exposed vs local-service sectors; effects should be larger in exposed
6. **Pre-trend placebo:** Effect at $t-1$ (pre-grant) should be zero
7. **Reduced-form:** Direct effect of Bartik instrument on employment (bypass endogenous regressor)
8. **Robustness controls:** State-specific linear trends; lagged employment; census region × year FE

## Censoring Rule

Before fixing the estimating sample, compute by filing year: (i) share of applications still pending (unresolved), (ii) median decision lag. Truncate the sample at the last filing year where the unresolved share < 20%. This prevents right-censoring attenuation of the grant variable in late cohorts.

## Kill-Shot Concern

The examiner lottery is credibly random within art-unit-year. The threat is in the aggregation step: do the pre-determined technology composition shares correlate with state-level labor market trends? If states that specialize in fast-growing art units also have faster employment growth for unrelated reasons, the instrument is confounded through the shares, not the shocks. We test this with:
- Pre-trend placebo (effect at $t-1$ should be zero)
- Mechanism contrast (exposed > local services, rather than uniform)
- State-specific trends as robustness
- Balance on pre-period employment growth

## Fetch Strategy

1. **BigQuery (Python):** Query `application_data` joined to `all_inventors` (first inventor, US only) for all applications 2001-2015 with `examiner_id`, `examiner_art_unit`, `uspc_class`, `disposal_type`, `filing_date`, `patent_issue_date`, `abandon_date`, `inventor_region_code`. Export to CSV.
2. **Azure (R):** Query QWI Parquet files via DuckDB for state-level employment aggregates (all sectors, plus NAICS 2-digit breakdown for mechanism splits).
3. **Merge:** State × year panel with patent grants, Bartik instrument, and QWI outcomes.

## Timeline

- Phase 2: Research plan (this document) → commit and push
- Phase 3: Data fetch + R analysis
- Phase 4: Smoke test (go/pivot/kill)
- Phase 5: Write paper
- Phase 6: Consistency check
- Phase 7: Review + publish
