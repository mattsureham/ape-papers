# Research Plan: Kitchen Table Capitalism

## Research Question
Do food freedom laws — which remove permits, inspections, and sales limits for home food production — grow or shrink formal food-sector labor markets? When states allow anyone to sell food from their kitchen, does the formal food industry gain workers (complementarity via a "formalization ladder") or lose them (crowding out via informal competition)?

## Policy Background
Between 2015 and 2022, seven U.S. states enacted "food freedom acts" that went far beyond traditional cottage food laws. Unlike cottage food laws (which restrict sales to non-perishable foods, cap revenue, and sometimes require permits), food freedom acts allow the sale of nearly any homemade food — including perishable items — directly to consumers with no licensing, no inspections, and no revenue cap.

### Treatment States and Timing
| State | Law | Effective Date | Treatment Quarter |
|-------|-----|---------------|-------------------|
| Wyoming | Food Freedom Act | July 2015 | 2015 Q3 |
| North Dakota | Food Freedom Law | Aug 2017 | 2017 Q3 |
| Maine | Local Control Regarding Food Systems Act | Nov 2017 | 2017 Q4 |
| Utah | Home Consumption and Homemade Food Act | May 2018 | 2018 Q2 |
| Oklahoma | Homemade Food Freedom Act (HB 1032) | Nov 2021 | 2021 Q4 |
| Tennessee | Food Freedom Act (HB 813) | July 2022 | 2022 Q3 |
| Iowa | Cottage Food Overhaul | ~2022 | 2022 Q3 |

Control group: 43 states + DC that did not enact food freedom acts. Many have cottage food laws with restrictions (caps, limited foods, permits), providing the relevant counterfactual: what happens when these restrictions are removed entirely?

## Identification Strategy
**Callaway and Sant'Anna (2021) staggered DiD.** Treatment is the quarter a state's food freedom act takes effect. Cohorts: 2015 Q3, 2017 Q3/Q4, 2018 Q2, 2021 Q4, 2022 Q3. Control group: not-yet-treated and never-treated states.

### Key Threats and Mitigations
1. **Parallel trends**: Test with pre-treatment event study. Food freedom states are predominantly rural/agricultural — I control for this by including state and quarter FEs, and testing sensitivity with state-specific linear trends.
2. **Confounds (COVID, other policies)**: The 2021-2022 cohorts overlap with COVID recovery. I run specifications excluding the 2021+ cohorts. I also use non-food manufacturing as a within-state placebo.
3. **Small treatment count (7 states)**: Use wild cluster bootstrap for inference (Roodman et al. 2019). Report both CS standard errors and WCB p-values.
4. **Staggered adoption bias**: CS DiD handles heterogeneous treatment effects across cohorts by estimating group-time ATTs.

### Built-in Placebo
**Triple-difference:** Food industries (NAICS 311, 722) vs. non-food manufacturing (NAICS 31-33 ex 311) within the same state. If food freedom laws affect only food-sector labor markets, we should see effects in food industries but not in non-food manufacturing.

## Data
**Quarterly Workforce Indicators (QWI)** from the LEHD program, accessed via Azure Blob (Parquet format).
- **Unit:** State × Quarter × Industry
- **Period:** 2005 Q1 – 2024 Q4 (20 years, ~80 quarters)
- **Industries:** NAICS 311 (Food Manufacturing), NAICS 722 (Food Services and Drinking Places), NAICS 31-33 (Manufacturing, placebo)
- **Variables:** Emp (employment), EarnS (average earnings), FrmJbGn (firm job gains = new establishments), FrmJbLs (firm job losses = closures), HirA (all hires), Sep (separations)
- **Demographics:** Sex × Age breakdowns for heterogeneity

## Expected Effects and Mechanisms
- **Formalization ladder (complement):** Food freedom → more people start selling food → some graduate to formal businesses → FrmJbGn ↑, Emp ↑ in 311/722. Expected sign: positive.
- **Crowding out (substitute):** Food freedom → consumers buy from home producers → formal food businesses lose revenue → FrmJbLs ↑, Emp ↓. Expected sign: negative.
- **Null:** Home food markets are too small to affect formal sector. Expected sign: ~zero.

## Primary Specification
```
Y_{s,t} = α_s + γ_t + Σ_g β_g × 1[G_s = g] × 1[t ≥ g] + ε_{s,t}
```
Estimated via `did::att_gt()` with:
- `yname`: log(Emp) or FrmJbGn/Emp
- `tname`: quarter (numeric, e.g., 2015.75 for Q3)
- `idname`: state FIPS
- `gname`: treatment quarter (0 for never-treated)
- `control_group`: "nevertreated"
- Clustered at state level

## Heterogeneity
1. Pre-COVID vs. post-COVID cohorts (2015-2018 vs. 2021-2022)
2. Female vs. male employment (food entrepreneurship may be gendered)
3. Young workers (25-34) vs. older workers (55-64)

## Robustness
1. Exclude COVID-era cohorts (OK, TN, IA)
2. State-specific linear trends
3. Wild cluster bootstrap p-values
4. Placebo: non-food manufacturing outcomes
5. Leave-one-state-out sensitivity
