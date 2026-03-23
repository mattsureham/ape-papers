# Research Plan: Lights, Camera, Equity

## Research Question
Do state film production tax credits create jobs in the motion picture industry, and do Black workers capture a proportional share of the employment gains? The paper revisits Button (2019, NBER w25963), who found null employment effects through 2016, using extended QWI data through 2024 with demographic breakdowns — the first distributional analysis of film tax credits.

## Identification Strategy
**Callaway-Sant'Anna (2021) staggered DiD.** Treatment: state-quarter of film tax credit adoption or major enhancement (≥15% rate). 37+ treated states with staggered adoption 1997-2019, ~13 never-treated controls. Cluster standard errors at the state level.

Key design strengths:
1. **NC repeal (2014)** provides a removal test — do effects reverse when credits end?
2. **Placebo sectors** (NAICS 71 Arts/Entertainment, 52 Finance, 31-33 Manufacturing) — if credits only affect motion picture, treatment is not spurious
3. **Worker flows** — QWI hires/separations decompose net employment into creation vs reallocation
4. **Demographic decomposition** — race (via `rh` files), sex×age, sex×education

## Expected Effects and Mechanisms
1. **Positive employment effects in NAICS 512** concentrated in states with generous, refundable/transferable credits (GA, NM, LA, CT)
2. **Null effects in states with small or non-refundable credits** (explains Button's average null)
3. **Disproportionate Black employment gains** in states like GA where Atlanta's established Black cultural infrastructure provides a local labor pool
4. **Effects concentrated in hires, not separations** — credits create new positions rather than preventing layoffs
5. **NC repeal should show partial reversal** — some infrastructure sticks, some production leaves

## Primary Specification
```
Y_{s,t} = α_s + γ_t + Σ_g ATT(g,t) + ε_{s,t}
```
where Y is log employment (or employment-to-population ratio) in NAICS 512 at the state-quarter level, estimated via `did::att_gt()` with never-treated comparison group.

## Data Source and Fetch Strategy
1. **QWI Parquet on Azure** — `derived/qwi/rh/n3/{state}.parquet` for race/ethnicity × NAICS 3-digit. Filter to industry codes starting with "512" (Motion Picture and Sound Recording). All 51 states, 2001-2024.
2. **Treatment timing** — constructed from NCSL film incentive surveys, academic sources (Button 2019, Thom 2018). Key dates: NM 2002, LA 2002 (enhanced 2005), GA 2005 (enhanced 2008), CT 2006, NC ~2009 (repealed 2014).
3. **State-level controls** — total employment (all sectors) from QWI for normalization; BEA GDP by state for economic conditions.

## Exposure Alignment
The treatment (state film tax credit adoption) directly affects firms producing films within the state. NAICS 512 employment captures the primary exposed population: workers in motion picture production, post-production, and sound recording. The treatment timing is legislatively determined (state adoption year) and applies to all qualifying productions within the state. Workers in other industries (our placebo sectors) are not directly exposed, providing a valid falsification test.

## Key Methodological Concerns
- **Heterogeneous treatment:** Credits vary wildly in generosity (5-40%), structure (refundable/transferable/non-refundable), and caps. Use continuous treatment intensity as robustness.
- **SUTVA violations:** Production may relocate across states (zero-sum). Border-state analysis can address this.
- **Pre-trends:** Georgia's film industry was already growing before 2008 enhancement — need careful event-study validation.
- **Small NAICS 512 in many states:** Employment noise in small-population cells. Weight by pre-treatment employment or population.
