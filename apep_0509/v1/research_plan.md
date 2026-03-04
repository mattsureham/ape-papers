# Initial Research Plan — apep_0509

## Research Question

Does India's employment guarantee (MGNREGA) improve or reduce agricultural productivity, and do the effects differ systematically across crops with different labor intensities? We estimate the causal effect of MGNREGA on crop-specific yields using the program's three-phase staggered district rollout (2006–2008) and ICRISAT district-level agricultural data spanning 2000–2017, decomposing the mechanism through the input substitution channel.

## Motivation

Employment guarantee programs are a cornerstone of developing-country social protection, with MGNREGA alone covering over 100 million rural households. A large literature documents MGNREGA's effects on private-sector wages (Imbert & Papp 2015), technology adoption (Bhargava 2023), and aggregate economic activity (multiple APEP papers). Yet the program's net effect on agricultural productivity — the backbone of rural livelihoods — remains unresolved.

Theory predicts two opposing channels:
1. **Labor scarcity channel (anti-productivity):** MGNREGA draws workers away from agriculture and pushes up wages, raising production costs and potentially reducing output.
2. **Input substitution channel (pro-productivity):** Higher wages incentivize farmers to substitute labor with capital (mechanization) and purchased inputs (fertilizer, irrigation), potentially raising yields per hectare.

The sign of the net effect is empirically ambiguous, making any well-identified estimate a genuine contribution regardless of direction. Moreover, the effect should be heterogeneous across crops: labor-intensive crops (rice, cotton, sugarcane) face the strongest labor cost shock and thus the greatest incentive to mechanize, while less labor-intensive crops (wheat, pulses) should show smaller effects. This crop-level heterogeneity provides a built-in mechanism test that distinguishes our causal chain from confounding explanations.

## Identification Strategy

**Design:** Callaway & Sant'Anna (2021) staggered DiD exploiting MGNREGA's three-phase rollout:
- Phase I: February 2006 → 200 most backward districts (backwardness index)
- Phase II: April 2007 → +130 additional districts
- Phase III: April 2008 → all remaining ~310 rural districts

**Estimator:** CS-DiD group-time ATT, aggregated to dynamic event-study estimates. This avoids negative weighting and forbidden comparisons in traditional TWFE.

**Agricultural year alignment:** ICRISAT DLD uses agricultural years (July–June). First fully treated agricultural year:
- Phase I: 2006–07 (DLD year = 2007)
- Phase II: 2007–08 (DLD year = 2008)
- Phase III: 2008–09 (DLD year = 2009)

**Unit of analysis:** District × agricultural year (313 apportioned districts × 18 years, 2000–2017)

**Fixed effects:** District FE + year FE (absorbed by CS-DiD). State × year FE in robustness.

**Clustering:** State level (20 states). Robustness with wild cluster bootstrap.

## Exposure Alignment (DiD Requirements)

- **Who is actually treated?** Rural agricultural workers and farmers in MGNREGA districts. MGNREGA provides guaranteed employment at minimum wages, drawing labor from private agriculture and raising the reservation wage.
- **Primary estimand population:** Farming households and agricultural laborers in ~313 ICRISAT districts.
- **Placebo/control population:**
  1. Not-yet-treated districts (Phase II/III before their treatment year)
  2. Less-labor-intensive crops within treated districts (within-district heterogeneity)
  3. Irrigated vs rainfed areas (MGNREGA work concentrated in dry season, competing with rainfed agriculture)
- **Design:** Staggered DiD with CS-DiD estimator.

## Power Assessment

- **Pre-treatment periods:** 7 (2000–2006 for Phase I cohort)
- **Treated clusters:** 200 districts (Phase I), 330 cumulative (Phase II), all by Phase III
- **Post-treatment periods per cohort:** Phase I: 11 years (2007–2017), Phase II: 10, Phase III: 9
- **MDE given sample size:** With 313 districts, 18 years, state-level clustering (20 clusters), and within-R² ~0.85 from district/year FE, the MDE for a 5% significance test at 80% power should be approximately 3–5% of mean yield. This is well below the 10–25pp mechanization shifts found by Bhargava (2023) and the 4.3% wage effects in Berg et al.

## Expected Effects and Mechanisms

**Primary hypothesis:** MGNREGA increases yields for labor-intensive crops (rice, cotton, sugarcane) through wage-induced input substitution, with smaller or null effects for less labor-intensive crops (wheat, pulses).

**Mechanism decomposition:**
1. **Wage channel (first stage):** MGNREGA → higher agricultural wages (testable with ICRISAT wage data)
2. **Input substitution:** Higher wages → more fertilizer per hectare, more irrigated area (testable with ICRISAT fertilizer and irrigation data)
3. **Crop-specific productivity:** Input intensification → higher yields for labor-intensive crops (primary outcome)

**Expected signs:**
- Agricultural wages: positive (confirmed by Imbert & Papp 2015)
- Fertilizer per hectare: positive (income effect + substitution)
- Irrigated area: positive (MGNREGA assets include irrigation works)
- Rice/cotton/sugarcane yields: positive (input substitution dominates)
- Wheat/pulse yields: smaller positive or null (less labor-intensive)

## Primary Specification

$$Y_{cdt} = \alpha_d + \lambda_t + \sum_{g \in \{2007, 2008, 2009\}} \sum_{e} \delta_{g,e} \cdot \mathbb{1}[G_d = g] \cdot \mathbb{1}[t = g + e] + X_{dt}'\beta + \varepsilon_{cdt}$$

Where:
- $Y_{cdt}$: Log yield (kg/ha) for crop $c$ in district $d$, year $t$
- $G_d$: Treatment cohort (first fully treated DLD year: 2007, 2008, or 2009)
- $e$: Event time relative to treatment
- $X_{dt}$: Time-varying controls (rainfall, baseline × year trends)
- Standard errors clustered at state level

**Primary outcomes:**
1. Log yield (kg/ha) for individual crops (rice, wheat, cotton, sugarcane, maize, sorghum, chickpea, groundnut)
2. Aggregate crop yield index (area-weighted average yield)
3. First stage: log agricultural wages

**Secondary outcomes:**
4. Fertilizer consumption per hectare (N, P, K, total)
5. Irrigated area share by crop
6. Total cropped area (extensive margin)
7. Crop area composition (share of labor-intensive crops)

## Planned Robustness Checks

1. **Pre-trend tests:** Joint F-test for pre-treatment event-study coefficients = 0
2. **HonestDiD:** Rambachan & Roth (2023) sensitivity to linear pre-trend extrapolation
3. **Spatial spillovers:** Exclude border districts; neighbor-phase exposure test
4. **Alternative controls:** State × year FE; baseline characteristics × year interactions
5. **Inference:** Wild cluster bootstrap (Webb 2023) for 20-state clustering; district-level clustering
6. **Heterogeneity:** By crop labor intensity, baseline irrigation, rainfall variability, district backwardness
7. **Placebo outcomes:** Non-agricultural outcomes if available; out-of-season crops
8. **Dose-response:** MGNREGA person-days at district level (if scrapeable) as continuous treatment intensity
9. **Backwardness-index RDD:** Exploit the threshold in the backwardness index that determined phase assignment for a complementary regression discontinuity analysis
10. **Balanced panel:** Restrict to districts with complete data across all years
