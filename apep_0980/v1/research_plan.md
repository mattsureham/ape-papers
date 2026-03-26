# Research Plan: IRA Energy Community Bonus Credit and County-Level Labor Market Restructuring

## Research Question

Does the Inflation Reduction Act's energy community bonus tax credit — a 10 percentage point adder for clean energy projects in fossil-fuel-dependent counties — accelerate labor market restructuring in designated communities?

## Why It Matters

The IRA's energy community provision is the most ambitious place-based clean energy incentive in U.S. history, channeling billions in bonus credits to coal- and oil-dependent counties. Whether place-based industrial policy can achieve a "just transition" — creating clean energy jobs where fossil fuel jobs are disappearing — is a first-order welfare question. No quasi-experimental estimate exists.

## Identification Strategy

**Primary: Staggered DiD with time-varying MSA designation.**

The IRS publishes annual lists of qualifying Metropolitan Statistical Areas (MSAs) based on two criteria:
1. **Fossil fuel employment share ≥ 0.17%** (from BLS QCEW, relatively stable across years)
2. **Local unemployment rate ≥ national average** (from BLS LAUS, varies annually)

The fossil fuel employment criterion is predetermined (based on multi-year historical data). The unemployment rate criterion creates **annual switchers**: MSAs that qualify in 2023 but not 2024 (or vice versa) based on small changes in local unemployment rates relative to the national average.

**Treatment cohorts:**
- Never treated: Counties in MSAs that never meet both criteria
- Treated 2023+: Counties in MSAs qualifying in both 2023 and 2024
- Treated 2023 only: Counties losing eligibility in 2024 (unemployment fell below threshold)
- Treated 2024 only: Counties gaining eligibility in 2024

**Estimator:** Callaway-Sant'Anna (2021) for heterogeneity-robust staggered DiD. Event study with leads/lags. Standard errors clustered at the MSA level (treatment assignment level).

**Built-in control sector:** Mining (NAICS 21) employment within the same treated counties. The energy community bonus incentivizes clean energy, not fossil fuel extraction. If mining employment responds, it suggests a general labor market effect rather than a clean energy channeling effect.

## Expected Effects and Mechanisms

1. **Construction (NAICS 23)**: Positive — clean energy facility construction is the direct mechanism
2. **Utilities (NAICS 22)**: Positive but lagged — operational employment follows construction
3. **Mining (NAICS 21)**: Null or slightly negative — fossil fuel employment not directly incentivized
4. **Manufacturing (NAICS 31-33)**: Ambiguous — equipment manufacturing could concentrate near sites or not

The key test: if Construction responds positively but Mining does not, the bonus credit is channeling clean energy investment specifically, not just stimulating general economic activity.

## Data Sources

### Treatment Assignment
- **BLS QCEW**: Annual county-level employment by 4-digit NAICS. Used to calculate fossil fuel employment shares for NAICS codes 211, 2121, 213111-213113, 32411, 4861-4862. Available via BLS bulk data API.
- **BLS LAUS**: Annual county-level and MSA-level unemployment rates. Available via BLS API (series IDs).
- **MSA-to-county crosswalk**: Census Bureau delineation files mapping MSA codes to county FIPS.
- **Validation**: Cross-check constructed treatment against official IRS Notice 2023-29 / Notice 2024-30 lists.

### Outcome Variables
- **QWI (Quarterly Workforce Indicators)**: On Azure at `derived/qwi/sa/ns/*.parquet`. County × quarter × NAICS sector × sex × age. Key variables: Emp (employment), EmpEnd (end-of-quarter), HirA (all hires), HirN (new hires), Sep (separations), EarnS (average earnings). Coverage: 2001–present, all 51 states.

### Hardware Constraint
- **RAM: 8GB** — use DuckDB for out-of-core queries against Azure Parquet. Never load full QWI into memory. Filter by sector and geography before pulling to R.

## Primary Specification

```
Y_{c,t} = α_c + δ_t + β × EnergyCommunity_{c,t} + ε_{c,t}
```

Where:
- Y = log(Employment) in sector s for county c in quarter t
- EnergyCommunity = 1 if county's MSA qualifies in year containing quarter t
- α_c = county fixed effects
- δ_t = quarter fixed effects
- Clustering: MSA level

## Robustness and Placebo Tests

1. **Unemployment RDD**: Among counties meeting the fossil fuel employment criterion, regression discontinuity at the national average unemployment rate cutoff
2. **Sector placebo**: Retail (44-45), Accommodation/Food (72) — should show null effects
3. **Pre-trend validation**: Event study leads showing no differential pre-trends in construction employment
4. **Coal closure overlap**: Check whether effects are concentrated in coal closure communities (separate IRA category)
5. **Border county comparison**: Treated MSA border counties vs. adjacent untreated counties
6. **HonestDiD sensitivity**: Rambachan-Roth bounds for parallel trend violations

## Paper Structure (AER: Insights)

1. Introduction — "just transition" puzzle, IRA provision, contribution
2. Institutional Background — IRA energy community designation mechanics
3. Data and Empirical Strategy — treatment construction, QWI, staggered DiD
4. Results — main effects by sector, event study, mechanism test
5. Robustness — placebo sectors, RDD, border counties
6. Conclusion — implications for place-based industrial policy
