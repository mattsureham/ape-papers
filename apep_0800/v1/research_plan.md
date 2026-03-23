# Research Plan: Employer Credit Check Bans and Black Employment in Finance

## Research Question

Do state bans on employer use of credit history checks increase Black employment and hiring in the finance sector — the industry where pre-employment credit screening is most pervasive?

## Motivation

Ten U.S. states enacted restrictions on employer credit checks between 2007 and 2013. These bans prohibit employers from using credit history in most hiring decisions, with exemptions for finance, government, and senior management positions. Black workers are 1.7–2× more likely than White workers to have subprime credit or collections records (Traub 2013), making credit screening a racially disparate hiring barrier. The only NBER paper on this topic (Cortes et al. 2021, w25005) provides a theoretical model predicting employment gains for workers with poor credit at the cost of matching efficiency — but no causal empirical test exists.

## Identification Strategy

**Method:** Staggered Triple-Difference (DDD) with Callaway–Sant'Anna estimator.

Three margins of variation:
1. **Race:** Black (A2) vs. White (A1) workers — within-county racial gap
2. **Policy:** Ban states vs. non-ban states — staggered adoption 2007–2013
3. **Time:** Pre-ban vs. post-ban periods

**Treatment timing:**
- Washington (2007), Hawaii (2009), Oregon & Illinois (2010), California, Maryland, Connecticut & DC (2011), Vermont (2012), Nevada & Colorado (2013)

**Pre-trends:** 2002–2006 provides 5+ years of pre-treatment data for all cohorts (earliest adopter is WA in 2007).

**Placebo tests:**
1. NAICS 11 (Agriculture) — industry where credit checks are never used
2. White workers within ban states — should show no effect if mechanism is credit-screening removal

**Inference:** Cluster at state level (10 treated states). Given few treated clusters, supplement with wild cluster bootstrap (fwildclusterboot) and report both.

## Expected Effects and Mechanisms

**Primary hypothesis:** Banning credit checks reduces a racially disparate screening barrier → Black hiring (HirN) increases in non-exempt sectors.

**Mechanism:** Credit screening disproportionately screens out Black applicants. Removing the screen expands the applicant pool, increasing Black hires. Cortes et al. predict some matching efficiency loss (hiring workers with poor credit who may be less productive), which would show up as lower new-hire earnings (EarnHirNS) conditional on increased hiring.

**Expected signs:**
- Black HirN in finance: positive (main result)
- Black EarnHirNS: ambiguous (could decline if marginal hires have lower productivity, or increase if discrimination was screening out high-ability Black workers)
- White HirN: null or slightly negative (no direct mechanism)
- Agriculture placebo: null

## Primary Specification

$$Y_{c,t}^{r} = \alpha_c + \gamma_t + \delta \cdot (Black_r \times BanState_c \times Post_{c,t}) + \beta_1 (Black_r \times Post_{c,t}) + \beta_2 (BanState_c \times Post_{c,t}) + \beta_3 (Black_r \times BanState_c) + \varepsilon_{c,t}^{r}$$

Where:
- $Y$ = log(HirN) or asinh(HirN) at county $c$, quarter $t$, race $r$
- $\alpha_c$ = county fixed effects
- $\gamma_t$ = quarter fixed effects
- Clustering: state level (with wild cluster bootstrap)

For the staggered implementation, use Callaway–Sant'Anna on the Black–White gap (DDD collapsed to DD on the racial gap).

## Data Source and Fetch Strategy

**Primary data:** QWI race panels from Azure Blob Storage
- Path: `az://apepdata/derived/qwi/rh/ns/*.parquet`
- 143.9M rows, county × quarter × race × ethnicity × industry
- Variables: HirN, EarnHirNS, Emp, EarnS
- Filter: NAICS 52 (Finance) + NAICS 11 (Agriculture placebo), race A1/A2, ethnicity A0
- Years: 2002–2018

**Fetch approach:** Use Arrow/DuckDB to read Parquet from Azure. Filter at read time to keep memory manageable.

## Robustness Checks

1. Event study plots (Callaway–Sant'Anna dynamic ATT)
2. HonestDiD sensitivity bounds for parallel trends violations
3. Wild cluster bootstrap p-values (fwildclusterboot)
4. Bacon decomposition to assess TWFE bias
5. Agriculture (NAICS 11) placebo
6. White-worker placebo within ban states
7. Excluding early adopters (WA 2007) to test sensitivity to treatment timing
8. Alternative outcomes: employment stock (Emp), stayer earnings (EarnS)
