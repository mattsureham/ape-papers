# Research Plan: The Regulatory Shield — RTF Constitutional Amendments and Animal Production Employment

## Research Question

Do constitutional Right-to-Farm (RTF) amendments — which shield concentrated animal feeding operations (CAFOs) from nuisance lawsuits and local zoning restrictions — causally increase animal production employment? Six states dramatically strengthened RTF protections between 2012 and 2021 through constitutional amendments or major legislative reforms: North Dakota (2012), North Carolina (2013), Missouri (2014), Iowa (2018), Georgia (2019), and Texas (2021). This paper provides the first causal estimate of the employment effects of these legal shields.

## Identification Strategy

**Staggered Difference-in-Differences** using Callaway and Sant'Anna (2021) to handle heterogeneous treatment effects across cohorts.

- **Treatment:** State-quarter of RTF constitutional strengthening. Binary, absorbing (on-only).
- **Treated states (6):** ND (2012Q4), NC (2013Q3), MO (2014Q3), IA (2018Q4), GA (2019Q3), TX (2021Q3)
- **Control states (8):** KS, NE, WI, TN, VA, SD, KY, MT — agricultural states without RTF strengthening during sample period
- **Unit of analysis:** County-quarter
- **Parallel trends assumption:** In the absence of RTF strengthening, animal production employment trends in treated states would have evolved like those in agricultural control states. Justified by: (a) constitutional amendments are typically driven by political rather than economic conditions, (b) pre-trend event studies, (c) placebo on crop production (NAICS 111) which should be unaffected.

## Expected Effects and Mechanisms

**Primary mechanism:** Constitutional RTF amendments eliminate the threat of nuisance litigation and local zoning restrictions on CAFOs. This reduces regulatory risk and operating costs, encouraging:
1. Expansion of existing CAFOs (intensive margin)
2. Entry of new facilities (extensive margin)
3. Consolidation of production into larger, more labor-intensive operations

**Expected signs:**
- Employment (Emp): Positive (main outcome)
- Hires (HirN): Positive (expansion requires new workers)
- Separations (Sep): Ambiguous (could increase if churning rises, or decrease if stability improves)
- Job creation (FrmJbGn): Positive
- Job destruction (FrmJbLs): Negative or null

**Heterogeneity:** Hispanic workers compose ~28% of animal production employment. RTF-driven expansion may disproportionately increase Hispanic employment. Compare NAICS 112 effects by race/ethnicity using QWI race/ethnicity breakdowns.

## Primary Specification

```
ATT(g,t) estimated via Callaway-Sant'Anna (2021)
Y_it = NAICS 112 employment (county-quarter)
Treatment: binary RTF_strengthening indicator
Cohorts: {2012Q4, 2013Q3, 2014Q3, 2018Q4, 2019Q3, 2021Q3}
Control group: not-yet-treated + never-treated
Clustering: state level (14 clusters → wild cluster bootstrap)
```

## Robustness

1. **Placebo: NAICS 111 (Crop Production)** — should show null effect
2. **Wild cluster bootstrap** for inference with 14 clusters
3. **Randomization inference** — permute treatment assignment across states
4. **Leave-one-out:** Drop each treated state; verify no single state drives results
5. **Sun-Abraham (2021)** as alternative estimator
6. **Event study** with pre-trend assessment and HonestDiD sensitivity bounds

## Data Source and Fetch Strategy

**QWI on Azure:**
- `az://derived/qwi/sa/n3/*.parquet` — State-county-NAICS3 quarterly panel (sex/age breakdowns)
- `az://derived/qwi/rh/n3/*.parquet` — Race/ethnicity-Hispanic origin breakdowns
- Variables: Emp, HirN, Sep, FrmJbGn, FrmJbLs, EarnS
- Filter to NAICS 112 (Animal Production) and NAICS 111 (Crop Production, placebo)
- States: ND, NC, MO, IA, GA, TX (treated) + KS, NE, WI, TN, VA, SD, KY, MT (control)
- Time: 2005Q1–2024Q4 (long pre-period for event study)

**Treatment dates:** Hardcoded from state constitutional amendment records.
