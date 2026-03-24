# Research Plan: apep_0848

## Research Question

Does the Enhanced Nurse Licensure Compact (eNLC) increase healthcare employer hiring and reduce turnover? The eNLC, launched January 2018 with 25 founding states, permits RNs and LPNs to practice across member states without additional licensure. We ask whether this licensing reform altered *employer-side* labor market dynamics — hiring flows, separations, and job-to-job transitions — in the healthcare sector.

## Identification Strategy

**Staggered Difference-in-Differences** using Callaway & Sant'Anna (2021).

- **Treatment:** State adoption of the eNLC. 25 founding states adopted simultaneously on January 19, 2018. Additional states (AL 2019, IN 2020, KS 2020, WI 2021, NJ 2021, LA 2022, OH 2023) adopted later.
- **Control group:** Never-adopted states (CA, NY, IL, MI, OR, WA, CT, HI, AK, MN, MA — 12 states, ~593 counties).
- **Unit of observation:** County × quarter × 3-digit NAICS industry.
- **Pre-treatment period:** 2014Q1–2017Q4 (16 quarters).
- **Post-treatment period:** 2018Q1–2023Q4 (24 quarters).

### Key Design Features

1. **Cross-sector triple-DiD:** Compare healthcare (NAICS 621, 622, 623) to placebo sectors (retail 44-45, accommodation 72) within the same county. If eNLC effects appear only in healthcare, this rules out state-level confounders.
2. **Education decomposition:** QWI `se` files provide sex × education breakdowns. Associate's degree holders (E3) are a proxy for nurses; bachelor's+ (E4) captures physicians/managers less affected by the compact.
3. **Subsector heterogeneity:** NAICS 621 (ambulatory care), 622 (hospitals), 623 (nursing/residential care) may respond differently. If the compact eased the post-COVID long-term care staffing crisis, effects should concentrate in 623.

## Expected Effects and Mechanisms

**Primary prediction:** eNLC adoption increases new hires (HirN) and all hires (HirA) in healthcare subsectors, particularly for associate's-degree workers (nursing proxy). Separations (Sep) may decrease (retention) or increase (increased mobility). Net employment (Emp) rises if hiring exceeds separations.

**Mechanism:** The compact reduces the fixed cost of cross-state practice. Nurses in border regions and travel nurses can accept positions without waiting for state-by-state licensure. Employers in shortage areas gain access to a larger labor pool.

## Primary Specification

$$Y_{c,s,t} = \alpha_c + \gamma_t + \delta \cdot \text{eNLC}_{s,t} + X_{c,t}'\beta + \epsilon_{c,s,t}$$

where $c$ indexes county × industry, $s$ state, $t$ quarter. Using Callaway-Sant'Anna with never-treated as comparison group, state-level clustering.

**Outcomes:** Employment (Emp), new hires (HirN), all hires (HirA), separations (Sep), average earnings (EarnS), firm-to-firm transitions (FrmJbGn, FrmJbLs), turnover (TurnOvrS).

## Data Source and Fetch Strategy

1. **QWI from Azure** (already available):
   - `derived/qwi/sa/n3/*.parquet` — sex × age, 3-digit NAICS (primary)
   - `derived/qwi/se/n3/*.parquet` — sex × education, 3-digit NAICS (education decomposition)
   - Variables: Emp, HirN, HirA, Sep, EarnS, FrmJbGn, FrmJbLs, TurnOvrS

2. **Scope:** All 51 states, counties, quarterly, NAICS 621/622/623 (healthcare) + 44-45/72 (placebo).

3. **Sample restrictions:**
   - Drop county-industry cells with suppressed employment (status flags)
   - Require at least 8 pre-treatment quarters of non-missing data
   - Healthcare subsectors only for main analysis; retail/accommodation for placebo

## Exposure Alignment

The eNLC directly affects registered nurses and licensed practical nurses. QWI data measure total employment in healthcare industries (NAICS 621, 622, 623), which includes physicians, administrative staff, technicians, and other workers not subject to nursing licensure. This creates measurement dilution: the treatment targets a subset of the workforce, but outcomes capture the entire industry. We address this limitation by: (1) using education decomposition (E3 = associate's degree, the typical nursing credential) as a nurse proxy; (2) comparing subsector effects across NAICS 623 (nursing-intensive) vs 622 (physician-heavy); (3) interpreting null results as ruling out large aggregate effects rather than nurse-specific effects.

## Robustness

1. Event study plots (Callaway-Sant'Anna)
2. HonestDiD / Rambachan-Roth sensitivity for parallel trends
3. Placebo sectors (retail, accommodation)
4. Leave-one-out by cohort (drop founding states, keep only later adopters)
5. Border county analysis (counties adjacent to a state border)
6. Wild cluster bootstrap (few-cluster concern with state-level treatment)
