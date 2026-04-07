# Research Plan: When the Branch Closes

## Research Question

Do merger-induced bank branch closures widen racial disparities in mortgage lending? Specifically, when acquiring banks close overlapping branches after mergers, do Black and Hispanic applicants experience larger increases in denial rates and interest rate spreads compared to white applicants in the same census tracts?

## Identification Strategy

**Instrumental Variables (following Nguyen 2019 AEJ: Applied).**

The endogeneity problem: branch closures may correlate with neighborhood characteristics that independently affect lending outcomes. Mergers, however, are driven by bank-level strategic considerations (scale economies, geographic expansion, regulatory pressure) largely orthogonal to tract-level mortgage demand conditions.

**Instrument:** For each census tract *i* in year *t*, compute the share of local bank branches belonging to institutions that completed a merger in the prior 1-3 years:

$$MergerExposure_{it} = \frac{\sum_b \mathbf{1}[\text{bank } b \text{ merged in } (t-3, t)]}{N_{it}^{branches}}$$

**First stage:** Merger exposure → branch closures (net change in branches per tract).

**Second stage:** Predicted branch closures → racial mortgage gap outcomes.

**Key identifying assumption:** Conditional on MSA×year fixed effects and tract characteristics, the share of local branches belonging to recently merged banks is uncorrelated with tract-level shocks to racial mortgage disparities except through branch closures.

**Validation:**
1. Event-study plots showing no pre-trends in outcomes relative to merger timing
2. Placebo: merger exposure should not predict outcomes in tracts where merged banks had no branches
3. Balance tests: pre-merger tract characteristics should be similar across exposure quartiles
4. Robustness to excluding tracts in MSAs where mergers were motivated by CRA concerns

## Expected Effects and Mechanisms

1. **Access channel:** Branch closures reduce physical proximity, raising search costs disproportionately for minority borrowers who rely more on in-person banking relationships (Ergungor 2010)
2. **Competition channel:** Fewer lenders in a tract reduces competitive pressure on rates and approval standards
3. **Relationship channel:** Existing banking relationships disrupted; minority borrowers less likely to be retained by acquiring bank

Expected: Branch closures → higher denial rates (especially for Black/Hispanic applicants), wider rate spreads, shift toward non-bank lenders (who charge more).

## Primary Specification

$$Y_{it} = \alpha + \beta \cdot \widehat{ClosureRate}_{it} + \gamma \cdot X_{it} + \delta_{m(i),t} + \epsilon_{it}$$

Where:
- $Y_{it}$: racial gap in denial rate (Black minus White denial rate) in tract $i$, year $t$
- $\widehat{ClosureRate}_{it}$: instrumented net branch change per capita
- $X_{it}$: tract-level controls (income, population, housing stock)
- $\delta_{m(i),t}$: MSA × year fixed effects
- Standard errors clustered at county level

## Data Sources and Fetch Strategy

1. **FDIC Summary of Deposits (SOD):** Annual branch-level panel, 1994-2023. API at `banks.data.fdic.gov`. Fields: CERT, BRNUM, SIMS_LATITUDE, SIMS_LONGITUDE, STCNTYBR (state+county+tract FIPS), DEPDOM. Geocoded to census tracts.

2. **FDIC History/Mergers:** API at `banks.data.fdic.gov`. Event-level merger records with acquiring/target CERT, effective dates. Filter for code 711 (mergers).

3. **HMDA Loan-Level Microdata:** CFPB Data Browser, 2018-2023. 20M+ records/year. Key fields: derived_race, action_taken (denial=3,7), interest_rate, rate_spread, census_tract, loan_amount, debt_to_income_ratio, applicant_income, aus_1 (automated underwriting).

**Fetch order:** FDIC SOD → FDIC mergers → construct instrument → HMDA (tract-year aggregates).

## Key Risks

1. HMDA files are large (2-5GB/year). Will use targeted queries from CFPB Data Browser API with filters.
2. Tract-level aggregation of HMDA may produce small cell sizes for minority applicants in some tracts. Will require minimum observation thresholds.
3. The merger-IV is well-known — novelty depends on the racial disparity angle and the post-2018 HMDA expansion (DTI, LTV, AUS fields enabling decomposition).
