# Research Plan: The Apprenticeship Levy and the Crowding Out of Entry-Level Training

## Research Question

Did the UK's 2017 Apprenticeship Levy—a 0.5% payroll tax on employers with wage bills exceeding £3 million—crowd out entry-level (Level 2) apprenticeship starts at non-levy-paying SMEs, even as it fueled an eightfold expansion in degree-level (Level 6+) apprenticeships at levy-paying firms?

## Policy Background

- **Apprenticeship Levy** (Finance Act 2016, effective April 2017): 0.5% of total pay bill for employers with annual wage bills > £3M.
- ~23,000–26,000 levy payers (<1.5% of UK businesses) but employing ~60% of workers.
- Levy funds deposited into Digital Apprenticeship Service (DAS) accounts; 24-month spend-or-lose rule.
- Degree apprenticeships (Level 6–7) cost up to £27,000; Level 2 apprenticeships cost £3,000–£5,000.
- Non-levy SMEs access training via 5% co-investment (reduced from 10% in 2019).

## Identification Strategy

**Bartik shift-share DiD.** The national policy shock (Levy introduction in April 2017) differentially affected Local Authorities based on their pre-existing concentration of large employers.

- **Shift:** National Apprenticeship Levy introduction (April 2017) — common across all LAs.
- **Share (instrument):** Pre-levy (2016) share of employment in enterprises with 250+ employees by LA, from NOMIS UK Business Counts (NM_142_1).
- **Treatment intensity:** LAs with higher large-employer concentration → greater levy exposure → more local training providers shifting to serve levy-funded degree apprenticeships → greater crowding-out of SME Level 2 starts.

### Key specifications

1. **Two-way FE:** `Y_{lt} = α_l + γ_t + β(LevyExposure_l × Post_t) + X'_{lt}δ + ε_{lt}`
   where Y = Level 2 starts per capita, l = LA, t = academic year
2. **Triple-difference:** Add level dimension: `Y_{lkt} = ... + β₃(LevyExposure_l × Post_t × Level2_k)`
   comparing Level 2 vs Level 4+ within the same LA
3. **Pre-trend test:** Event study with year-specific β_t interacted with LevyExposure
4. **Placebo:** Use Level 4+ starts (should not be crowded out — if anything, should increase)

### Controls
- LA population, working-age share, unemployment rate (NOMIS)
- Industry composition (manufacturing share, service share)

## Expected Effects and Mechanisms

- **Main result:** Negative β on Level 2 starts — larger in high-levy-exposure LAs
- **Mechanism:** Training provider capacity reallocation. Providers shift to serve levy-funded degree apprenticeships (higher revenue per learner: £27K vs £3K). SMEs face reduced supply of Level 2 training places.
- **Heterogeneity:** Effect concentrated in (a) non-levy firms, (b) young age groups (under 19), (c) sectors with mixed firm-size distribution (construction, manufacturing)

## Data Sources

1. **DfE Explore Education Statistics** — Apprenticeship starts by LA, level, age group (2019/20–2024/25, 247,449 rows, 321 LAs)
2. **GOV.UK FE Data Library** — Historical starts by LA (2009/10–2019/20, XLSX, 300+ LAs)
3. **DfE Enterprise Characteristics** — Starts by levy status, level, sector (3.2M rows, 2017/18–2021/22)
4. **NOMIS NM_142_1** — UK Business Counts by LA and employee size band (for Bartik instrument)
5. **NOMIS labour market stats** — Controls (unemployment, population)

## Outcome Variables

- Level 2 apprenticeship starts per 1,000 working-age population (primary)
- Level 3 apprenticeship starts per capita (secondary — intermediate level)
- Level 4+ / Level 6+ starts per capita (placebo — should increase, not decrease)
- Share of starts that are Level 2 (compositional measure)

## Robustness

- Randomization inference (permute LevyExposure across LAs)
- Leave-one-out on top-5 largest LAs
- Alternative exposure measures (share of employment in 500+ firms)
- Sensitivity to pre-period window (drop 2009/10–2012/13)
- Borusyak-Hull-Jaravel (2022) shift-share diagnostics
