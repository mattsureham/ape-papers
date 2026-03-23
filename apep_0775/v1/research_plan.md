# Research Plan: Feeding Reentry — SNAP Drug Felon Ban Rollbacks and Low-Education Employment

## Research Question

Does restoring SNAP eligibility for drug felons increase formal employment among low-education workers? The 1996 PRWORA imposed a lifetime SNAP ban on drug felons. Between 2015 and 2019, 18 states rolled back or modified this ban, restoring food assistance to formerly incarcerated individuals. Using a triple-difference design (modified-ban state × low-education workers × post-rollback), I estimate whether safety net restoration increases formal employment, hires, and earnings — or whether the income effect dominates.

## Identification Strategy

**Triple-Difference (DDD):**
- **First difference (time):** Pre vs. post ban modification
- **Second difference (state):** Modified-ban states vs. always-treated controls (25 states that opted out pre-2010)
- **Third difference (education):** Low-education (E1: <HS, E2: HS/GED) vs. high-education (E3: some college, E4: BA+)

The triple-diff eliminates: (1) state-level shocks common to all education groups, (2) national trends in low-education employment, (3) time-invariant state-education differences.

**Treated states (18):** AL, AK, AZ, AR, DE, GA, IL, IN, KY, LA, MI, MS, NV, ND, SD, TX, VA, WV — staggered 2015-2019.

**Control states (~25):** Pre-2010 opt-out states that already allowed drug felons on SNAP.

**Key placebo:** Effects should be null for E3/E4 workers (some college, BA+) since drug felons are overwhelmingly low-education.

## Expected Effects and Mechanisms

- **Job search channel (+):** SNAP restoration reduces food insecurity, freeing mental bandwidth and resources for job search. Expected: increased hires, employment.
- **Income effect (−):** SNAP provides income substitute, potentially reducing labor supply.
- **Theoretical ambiguity:** The net effect is ex ante unclear. Tuttle (2019) found the original ban *reduced* employment, suggesting the job search channel dominates.
- **Focus industries:** NAICS 56 (Admin/Support — includes temp agencies), 72 (Accommodation/Food), 23 (Construction), 44-45 (Retail), 62 (Healthcare) — sectors with high formerly-incarcerated worker shares.

## Primary Specification

$$Y_{c,e,t} = \alpha + \beta_1 (\text{Treated}_s \times \text{LowEd}_e \times \text{Post}_t) + \beta_2 (\text{Treated}_s \times \text{Post}_t) + \beta_3 (\text{LowEd}_e \times \text{Post}_t) + \gamma_{c} + \delta_{e,t} + \varepsilon_{c,e,t}$$

where $Y$ is employment/hires/earnings for county $c$, education group $e$, quarter $t$. County FE ($\gamma_c$) absorb time-invariant county characteristics. Education-by-quarter FE ($\delta_{e,t}$) absorb national education-specific trends. Callaway-Sant'Anna for the state-time dimension.

Standard errors clustered at the state level (18 treated + 25 control = 43 states).

## Data Sources

1. **QWI se/ns** (sex × education, NAICS sector): On Azure at `derived/qwi/se/ns/*.parquet`. County × quarter × education × industry employment, hires, separations, earnings. ~150M rows, 2001-present.

2. **SNAP drug felon ban status:** Hand-coded from NCSL and state legislative records. 18 states modified 2015-2019.

3. **State FIPS crosswalk:** For merging treatment assignment.

## Fetch Strategy

1. Query Azure QWI Parquet for the 18 treated states + 25 control states
2. Filter to NAICS sectors 56, 72, 23, 44-45, 62 (high reentry industries)
3. Filter to quarters 2010Q1-2022Q4 (5+ years pre, 3+ years post)
4. Aggregate to county × quarter × education level

## Robustness

- Event study (dynamic treatment effects by quarters since rollback)
- Placebo: E3/E4 workers (should show null)
- Dose-response: states that fully vs. partially modified the ban
- Industry heterogeneity: effects concentrated in temp/construction
- Permutation inference for state-level treatment
