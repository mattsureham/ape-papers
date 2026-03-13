# Research Plan: The Hidden Wage Floor

## Research Question

Do salary history bans compress the gender pay gap among new hires, and if so, through which industries and demographic groups? Does information removal trigger Doleac-Hansen-style statistical discrimination against minority workers, or does it reduce anchoring to discriminatory past wages?

## Policy Setting

State salary history bans prohibit employers from asking job applicants about prior compensation. Sixteen U.S. states adopted private-employer bans between 2017 and 2023 in seven distinct cohorts:

| Cohort | States | Effective Date |
|--------|--------|---------------|
| 1 | Delaware, Oregon | Dec 2017, Oct 2017 |
| 2 | California, Massachusetts, Vermont | Jan 2018, Jul 2018, Jul 2018 |
| 3 | Connecticut, Hawaii, Illinois, Washington, Maine, Alabama | Jan-Sep 2019 |
| 4 | New Jersey | Jan 2020 |
| 5 | Maryland | Oct 2020 |
| 6 | Colorado | Jan 2021 |
| 7 | Nevada, Rhode Island | Oct 2021, Jan 2023 |

Thirty-four states never adopted private-employer bans (as of 2023).

## Identification Strategy

**Primary design:** Callaway-Sant'Anna (2021) staggered DiD. Group-time ATTs estimated at the state-quarter level, using never-treated states as the comparison group.

**Key estimand:** The gender gap in new-hire earnings (female minus male EarnHirNS within the same county-industry-quarter cell), and how this gap changes after salary history ban adoption.

**Triple difference (DDD):** Within treated states, compare female-male new-hire earnings gap before vs after the ban, relative to the same gap in never-treated states. This nets out:
- Industry-specific national trends in gender pay convergence
- State-specific economic shocks that affect both genders equally
- Time-invariant state-level gender gap differences

**Cross-industry mechanism test:** Industries with large pre-ban gender gaps (Finance NAICS 52, Professional Services 54) vs small gaps (Wholesale 42, Manufacturing 31-33). If bans work through removing wage anchoring, effects should concentrate where gaps were largest.

## Expected Effects and Mechanisms

**Theory 1 (Anchoring removal):** Salary history perpetuates past discrimination. Removing it → female new-hire earnings rise → gender gap narrows. Prediction: larger effect in high-gap industries.

**Theory 2 (Statistical discrimination):** Employers use salary history as a productivity signal. Removing it → employers rely on group-level priors → may help or hurt minorities depending on prior beliefs. Prediction: if bans trigger discrimination, hiring rates fall for groups with lower average prior wages.

**Theory 3 (Market adjustment):** Bans constrain employer price discovery → firms adjust through hiring volume rather than price. Prediction: separation rates or hiring rates change even if wage effects are modest.

## Primary Specification

$$\Delta \text{Gap}_{s,j,t} = \alpha_{s} + \gamma_{j,t} + \beta \cdot \text{Post}_{s,t} + \epsilon_{s,j,t}$$

Where $\Delta \text{Gap}_{s,j,t}$ is the female-male new-hire earnings ratio in state $s$, industry $j$, quarter $t$. State FE, industry×quarter FE. Clustered at the state level.

CS-DiD implementation: group = state cohort, time = quarter, unit = state×industry.

## Data Source and Fetch Strategy

**Source:** QWI Parquet files on Azure Blob Storage.

**Files needed:**
1. `derived/qwi/sa/ns/*.parquet` — sex × age × NAICS sector (185M rows)
2. `derived/qwi/se/ns/*.parquet` — sex × education × NAICS sector (123M rows)
3. `derived/qwi/rh/ns/*.parquet` — race × ethnicity × NAICS sector (144M rows)

**Fetch strategy:** Use R `arrow` package to read Parquet directly from Azure. Filter to:
- Geographic level: state (for primary spec) and county (for border-county robustness)
- Time: 2013Q1–2023Q4 (4+ years pre for earliest cohort)
- Industries: all 20 NAICS supersectors
- Demographics: sex = male/female (not combined)

**No API download required** — data is already in Azure.

## Robustness Checks

1. **Event study:** CS-DiD dynamic effects, 12+ quarters pre, 12+ quarters post
2. **HonestDiD/Rambachan-Roth bounds** for pre-trend sensitivity
3. **Bacon decomposition** to verify clean identification
4. **Border county pairs:** Restrict to counties bordering a state with different ban status
5. **Randomization inference:** 1,000 permutations of treatment timing
6. **Placebo tests:**
   - Government sector (NAICS 92) — exempt from private-employer bans
   - Male-only outcomes — bans should have smaller/no effect on male wages if anchoring is the channel
   - Pre-treatment placebo (fake treatment 4 years early)

## Outcome Variables

| Variable | QWI Name | Description |
|----------|----------|-------------|
| New-hire earnings | EarnHirNS | Avg monthly earnings of new hires |
| Employment | Emp | Beginning-of-quarter employment |
| New hires | HirN | New hires (first job at firm) |
| Separations | Sep | Workers who left the firm |
| Firm job creation | FrmJbGn | Jobs at expanding/entering firms |
| Turnover | TurnOvrS | Worker turnover rate |
