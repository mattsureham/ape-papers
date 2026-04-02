# Research Plan: apep_1322

## Research Question

Does state-level preemption of single-family-only zoning increase missing middle housing construction? Five US states legalized duplexes-to-fourplexes on single-family lots between 2019 and 2023. Using the Census Building Permits Survey, I estimate whether these reforms shifted the composition of residential construction toward multi-unit missing middle housing.

## Background

Between 2019 and 2023, five states enacted laws preempting local single-family-only zoning:
- **Oregon** HB 2001 (Aug 2019, compliance June 2022): cities 10K+ allow duplexes, 25K+ allow fourplexes
- **California** SB 9 (Sep 2021, effective Jan 2022): up to 4 units on any single-family lot
- **Maine** LD 2003 (Apr 2022): duplexes everywhere single-family is allowed
- **Montana** SB 382/HB 337 (May 2023, effective Oct 2023): cities 5K+ allow duplexes
- **Washington** HB 1110 (May 2023, compliance Jun 2025): duplexes/triplexes/quadplexes

Missing middle housing (2-4 unit buildings) has declined to near-zero as a share of new construction in most US cities since the 1980s. These reforms aim to reverse this by removing the primary legal barrier.

## Identification Strategy

**Staggered DiD with Callaway-Sant'Anna (2021).** Treatment = county is in a state that enacted zoning preemption. Treatment timing varies across the 5 state cohorts (2022 for OR/CA/ME, 2023 for MT/WA). Control group = counties in ~45 never-treated states.

**Treatment assignment:** State-level policy imposed on local governments — plausibly exogenous for individual counties (counties don't choose their state's zoning law).

**Primary specification:**
MissingMiddleShare_{c,t} = α_c + λ_t + β(Treated_c × Post_t) + ε_{c,t}

with county and year-month fixed effects, clustered at state level.

## Expected Effects

1. **Missing middle share (2-4 unit / total):** Positive — reforms legalize these building types
2. **Total permits:** Ambiguous — expansion (more total) or substitution (multi-unit replaces SF)
3. **5+ unit permits:** Near-zero effect (not targeted by these reforms) — serves as placebo

## Data Sources

### Census Building Permits Survey (BPS)
- County-level monthly permits by structure type (1-unit, 2-unit, 3-4 unit, 5+ unit)
- Units: buildings, housing units, construction value
- Coverage: ~3,000 permit-issuing counties, 2000-2025
- Source: census.gov annual and monthly CSV files
- Key outcome: missing_middle_share = (2-unit + 3-4 unit permits) / total permits

### FHFA House Price Index (mechanism)
- County-level quarterly HPI
- Tests whether effects are larger in high-price counties (more binding zoning)

## Sample

- ~3,000 counties × ~300 months (2000-2025) = ~900,000 county-month observations
- Annual aggregation for main spec: ~3,000 counties × 25 years = ~75,000 county-year obs
- Treated: ~175 counties across 5 states
- Control: ~2,825 counties in never-treated states

## Robustness

1. Event study with 5+ pre-period leads (pre-trend test)
2. Sun-Abraham (2021) interaction-weighted estimator
3. Urban vs rural heterogeneity
4. Donut-hole around border counties
5. Permutation inference (state-level clustering with few treated states)

## Exposure Alignment

Treatment is assigned at the state level. The preemption laws apply to municipalities above population thresholds (e.g., Oregon HB 2001: cities above 10,000). County-level BPS data aggregates over affected and unaffected jurisdictions within a county, creating classical measurement error that attenuates estimates toward zero. County-level estimates are conservative lower bounds on city-level effects. Oregon's positive finding survives this attenuation; null results for CA/ME/MT may partly reflect measurement mismatch.

## Key Risk

Only 4 treated states → few clusters. Randomization inference with 1,000 state-level permutations addresses this. Short post-treatment window (2-3 years for 2022 cohort, 1 year for Montana) may be insufficient for construction-based outcomes. A well-powered null with clean pre-trends is still publishable.
