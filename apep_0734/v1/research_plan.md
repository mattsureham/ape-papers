# Research Plan: apep_0734

## Research Question
Did Wales's September 2023 nationwide default 20mph speed limit on restricted roads causally reduce road casualties? Using England (which retained the 30mph default) as a counterfactual, this paper estimates the causal effect of the most radical default urban speed reduction in European history.

## Identification Strategy
**Difference-in-Differences (DiD)** exploiting the country-border natural experiment:
- **Treated:** 22 Welsh Local Authorities, all simultaneously treated on 17 September 2023
- **Control:** ~300 English Local Authorities that retained 30mph default
- All treatment is simultaneous (no staggering) → standard TWFE DiD is appropriate
- Scotland excluded (introduced 20mph in selected areas, creating contamination)

**Key assumptions:**
1. Parallel trends in road casualties between Welsh and English LAs pre-September 2023
2. No concurrent Welsh-specific shock affecting casualties at the same time
3. SUTVA: no spillovers from Welsh speed limit changes to English border LAs (testable by excluding border LAs)

## Expected Effects and Mechanisms
- **Primary:** Reduction in total casualties on restricted roads (20+30mph combined)
- **Mechanism 1 (Speed reduction):** Lower speeds → fewer and less severe collisions
- **Mechanism 2 (Reclassification):** Roads reclassified from 30→20 get specific treatment; already-20 roads serve as placebo
- **Mechanism 3 (Severity shift):** Even with similar collision rates, lower speeds → less severe injuries (fatal/serious → slight)
- **Heterogeneity:** Urban vs rural LAs, severity categories, time-of-day, pedestrian vs vehicle

## Primary Specification
$$Y_{lt} = \alpha_l + \gamma_t + \beta \cdot (Wales_l \times Post_t) + \varepsilon_{lt}$$

Where:
- $Y_{lt}$ = casualties per 100,000 population in LA $l$, quarter $t$
- $\alpha_l$ = LA fixed effects
- $\gamma_t$ = quarter fixed effects
- $Wales_l$ = 1 if Welsh LA
- $Post_t$ = 1 if quarter ≥ 2023-Q4
- Clustered SEs at LA level; wild cluster bootstrap for inference with 22 treated clusters

## Data Source and Fetch Strategy
1. **STATS19 collision data** from data.gov.uk (DfT Road Safety Data): collision-level CSV with speed limit, LA, severity, date, vehicle/casualty types. Years 2019-2024.
2. **ONS mid-year population estimates** by LA for per-capita normalization
3. **LA boundary lookup** to classify Welsh vs English LAs

All sources are publicly available with no API keys required.

## Exposure Alignment
The treatment is the nationwide default speed limit change from 30→20 mph on restricted roads (roads with street lighting). All road users in Wales are exposed: drivers, pedestrians, cyclists. The outcome (casualties on restricted roads) directly measures the population affected by the policy. The combined 20+30mph measure captures all restricted-road casualties regardless of whether STATS19 records the road as 20 or 30 mph post-reclassification. There is no alignment concern: the policy operates at the road-network level in all 22 Welsh LAs, and the outcome measures casualties on precisely the roads where the default changed.

## Robustness
- Wild cluster bootstrap p-values (few treated clusters)
- Synthetic control (22 Welsh LAs as single treated unit)
- Placebo: effect on non-restricted roads (60mph motorways/A-roads)
- Border-pair design: Welsh vs English border LAs only
- Excluding COVID-affected 2020-2021 from pre-period
- Event-study coefficients for pre-trend validation
