# Research Plan: apep_0701

## Research Question
Does Brazil's 2007 FUNDEB education equalization reform differentially increase female secondary enrollment and completion? FUNDEB extended per-pupil spending floors from primary-only (FUNDEF) to ALL basic education including secondary. Municipalities below the national floor received large exogenous funding increases. Given Brazil's pre-existing reverse gender gap (girls 77.5% vs boys 69.1% secondary enrollment in 2007), equalization could either widen or narrow this gap depending on the binding constraints.

## Policy Background
- FUNDEF (1996–2006): equalized per-pupil spending for primary education only
- FUNDEB (2007): extended equalization to ALL basic education (pre-school, primary, secondary)
- Federal "complementação" transfers flow to states/municipalities where per-pupil spending < national minimum (R$946.29/year in 2007)
- ~60% of Brazil's 5,570 municipalities in complementação-receiving states
- Treatment intensity = municipality-specific pre-FUNDEB per-pupil spending gap relative to the floor

## Identification Strategy
**Continuous treatment DiD:** Municipalities below the FUNDEB floor received exogenous funding increases proportional to their pre-reform shortfall. Municipalities at or above the floor = comparison group (no complementação shock).

**Specification:**
```
Y_{mt} = alpha_m + delta_t + beta * (Gap_m * Post_t) + X_{mt}' * gamma + epsilon_{mt}
```
Where Gap_m = max(0, FUNDEB_floor - Pre_reform_spending_m) / FUNDEB_floor (normalized)
Post_t = 1 for 2007 onwards

**Event study:** 2003–2011 (4 pre-periods: 2003–2006; 5 post-periods: 2007–2011)

**Staggered timing:** CS-DiD estimator (Callaway & Sant'Anna 2021) to handle heterogeneous treatment timing, since complementação phased in as floor levels changed.

## Expected Effects and Mechanisms
- H1 (primary): Larger per-pupil spending increases → higher secondary completion for both genders
- H2 (gender): If binding constraint for girls is school quality/safety rather than tuition → gap narrows
- H3 (heterogeneity): Poorest municipalities see largest effects (most below floor)
- Mechanism tests: (a) teacher quality (share with higher education degree); (b) infrastructure investment (new classrooms); (c) gender-specific opportunity cost interaction (poverty × female gap)

**Placebo:** Primary enrollment (already equalized under FUNDEF since 1996) — should show no post-2007 discontinuity for primary, only for secondary.

## Data Sources and Fetch Strategy
1. **INEP Censo Escolar:** Annual school census via `educabR` R package (CRAN v0.1.3). Enrollment by municipality, gender, school level. Available 2002–2022.
2. **FNDE FUNDEB transfers:** Publicly available at dados.gov.br. Per-municipality annual complementação values.
3. **IBGE SIDRA API:** Municipal GDP, population (for per-pupil calculation). Endpoint: `https://servicodados.ibge.gov.br/api/v3/agregados/{id}/periodos/{anos}/variaveis/{var}?localidades=N6[all]`
4. **Pre-reform spending:** FINBRA (FNDE) municipal education expenditure 2003–2006.

## Key Risks
- educabR may require local file pre-download (check documentation first)
- Treatment intensity requires pre-reform spending data — must be constructed from FINBRA
- Potential confound: Bolsa Família (2003) + PAC (2007) co-occurring with FUNDEB

## Commit Plan
1. research_plan.md committed before data fetch
2. After data: diagnostics.json with n_treated, n_pre, n_obs
3. After paper: paper.tex + tables/

## Sample Size Targets (from smoke test)
- ~5,570 municipalities × 9 years (2003–2011) = ~50,130 municipality-year observations
- Treated: ~3,300 municipalities in complementação states
- Pre-periods: 4 (2003–2006)

## Exposure Alignment (DiD Design)

**Who is actually affected by complementação?**

The federal complementação transfers flow to the state-level FUNDEB fund when the state's per-student fund value falls below the national floor. The mechanism works as follows:
- All municipalities in an eligible state's fund pool receive a proportional top-up in per-student allocations
- Treatment is at the state level: all municipalities in a complementação-receiving state are exposed
- Within-state variation: municipalities with higher enrollment per fund-contribution dollar receive a larger absolute transfer, but all are treated via the state fund mechanism

**Exposure alignment rationale:**
The design assigns treatment at the state level (T_i = 1 if municipality i's state received complementação). This aligns with the actual mechanism of exposure: municipalities in complementação states experienced an exogenous increase in the per-student fund value starting 2007. Non-complementação states did not receive the federal top-up, but their municipalities still benefit from FUNDEB's expanded revenue base (20% pool vs 15% under FUNDEF). Our DiD isolates the complementação effect net of the general FUNDEB expansion.

**Potential confounder:** All 27 states experienced FUNDEB's general fund expansion. The treatment effect captures only the marginal complementação transfers, not the baseline FUNDEB effect. This is the correct estimand for policy evaluation of the equity-focused complementação mechanism.
