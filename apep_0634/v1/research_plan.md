# Research Plan: Disaster Salience and the Costs of Safety Regulation

## Research Question
Did the MINER Act (2006), triggered by the Sago Mine disaster, accelerate employment decline in coal-dependent counties while raising remaining workers' earnings — and did the Upper Big Branch disaster (2010) compound these effects?

## Identification Strategy
**Continuous-treatment DiD** exploiting the MINER Act as a nationally uniform shock that is differentially binding based on pre-existing county-level coal employment share.

- **Treatment intensity:** Pre-2006 coal mining employment share (NAICS 212 / total employment) at the county level
- **Treatment timing:** MINER Act signed June 15, 2006 (sharp); Upper Big Branch enforcement crackdown April 2010 (second shock)
- **Control group:** Counties in coal-producing states with low/zero coal employment share
- **Fixed effects:** County FE + quarter FE
- **Clustering:** State level (conservative)

Key equation:
Y_{c,t} = α_c + γ_t + β(CoalShare_c × Post2006_t) + ε_{c,t}

Event study version:
Y_{c,t} = α_c + γ_t + Σ_k β_k(CoalShare_c × 1{t=k}) + ε_{c,t}

## Parallel Trends
Testable with 24 pre-treatment quarters (2000Q1–2005Q4). The smoke test confirms coal/non-coal earnings are parallel in this period.

## Data
- **Source:** Census QWI county × 3-digit NAICS panel (Azure: derived/qwi/rh/n3/{state}.parquet)
- **Outcomes:** EmpTotal (employment), EarnS (earnings), Sep/HirA (separations/hires), FrmJbGn/FrmJbLs (firm job gains/losses)
- **States:** All states with coal mining (NAICS 212) employment
- **Period:** 2000Q1–2015Q4 (captures both shocks with adequate pre/post)

## Expected Effects and Mechanisms
1. **Employment decline** in high-coal counties post-MINER Act (compliance costs → mine closures)
2. **Earnings increase** for remaining workers (surviving mines invest in safety → higher skilled workforce; or reduced labor supply → wage pressure)
3. **Turnover increase** (separations rise as marginal mines close; hires may fall)
4. **Firm job destruction** outpaces creation (mine closures > new entry)
5. **Sector spillovers:** Non-coal sectors may also decline (local multiplier) or partially absorb displaced miners

## Primary Specification
Continuous-treatment DiD on county-quarter panel of total employment and earnings, with coal_share measured in 2005 (pre-MINER Act).

## Robustness
- Binary treatment (above/below median coal_share)
- Different pre-period coal_share (2003 vs 2005)
- Exclude WV (most affected by UBB)
- Placebo: non-coal mining sectors in same counties
- HonestDiD sensitivity bounds
