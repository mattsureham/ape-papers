# Initial Research Plan: Tax Borders and the Rich

## Research Question

Does state income tax competition drive geographic sorting of high-income households? Specifically: (1) Do high-income filers cluster disproportionately on the low-tax side of state borders? (2) Did the 2017 TCJA SALT deduction cap amplify this sorting by removing federal tax offset?

## Identification Strategy

**Multi-border boundary discontinuity design (RDD)** using IRS SOI ZIP-code-level income data.

- **Running variable:** Distance from ZIP code centroid to the nearest high-tax/low-tax state border (signed: negative on high-tax side, positive on low-tax side)
- **Treatment:** Residing on the high-tax side of the border
- **Primary outcome:** Share of tax returns with AGI >= $200K (agi_stub=6)
- **Secondary outcomes:** Average AGI per $200K+ return, total AGI from $200K+ filers, growth rates
- **Event study:** TCJA SALT cap (effective January 2018) as a within-border shock. Compare pre-SALT (2012-2017), post-SALT/pre-COVID (2018-2019), and COVID era (2020-2021)

## Expected Effects and Mechanisms

1. **Level effect:** High-income filers should be disproportionately concentrated on the low-tax side of state borders (positive discontinuity)
2. **SALT amplification:** The gap should widen after 2018 when the SALT cap removed federal deductibility
3. **Extensive margin:** More high-income households relocating to the low-tax side post-SALT
4. **Intensive margin:** Remaining high-income filers on the high-tax side may show lower reported AGI (income shifting, not real mobility)
5. **Heterogeneity:** Effects should be larger at borders with bigger tax differentials and in states with higher pre-TCJA SALT deductions

## Exposure Alignment (RDD-Specific)

- **Who is treated?** High-income filers ($200K+ AGI) residing in high-tax states near a low-tax border
- **Primary estimand:** Local average treatment effect at the border — the discontinuity in high-income filer density/growth at the state line
- **Placebo population:** Low-income filers ($<50K AGI), who face minimal cross-border tax differentials
- **Design:** Multi-cutoff boundary discontinuity, with each border pair as a separate "cutoff" (at distance=0)

## Primary Specification

Y_{z,b,t} = alpha + tau * HighTaxSide_z + f(distance_z) + beta * HighTaxSide_z * f(distance_z) + gamma_{b,t} + epsilon_{z,b,t}

Where:
- z = ZIP code, b = border segment, t = year
- Y = share of $200K+ returns among all returns
- HighTaxSide = 1 if ZIP is in the high-tax state
- f(distance) = local polynomial in distance to border
- gamma_{b,t} = border-segment × year fixed effects

Event study variant interacts HighTaxSide with year indicators (base: 2017).

## Border Pairs (8 Primary Segments)

1. New Jersey (10.75%) vs. Pennsylvania (3.07%) — Philadelphia MSA
2. New York (10.9%) vs. Connecticut (6.99%)
3. California (13.3%) vs. Nevada (0%) — Reno/Lake Tahoe, Las Vegas
4. Minnesota (9.85%) vs. South Dakota (0%)
5. Oregon (9.9%) vs. Washington (0%) — Portland/Vancouver MSA
6. Minnesota (9.85%) vs. Wisconsin (7.65%)
7. California (13.3%) vs. Arizona (4.5%)
8. New York (10.9%) vs. Pennsylvania (3.07%)

## Planned Robustness Checks

1. **McCrary density test** on ZIP centroids at each border
2. **Bandwidth sensitivity** (5km, 10km, 15km, 20km, 30km, 50km)
3. **Polynomial order** (linear, quadratic, cubic)
4. **Donut design** (exclude ZIPs within 1km, 2km of border)
5. **Placebo outcomes** (low-income filer share, $<50K AGI)
6. **Covariate balance** at the border (population, land area, urban/rural)
7. **Period subsample** (pre-SALT, post-SALT/pre-COVID, COVID era)
8. **Individual border pair estimates** (heterogeneity across segments)
9. **MSA-only subsample** (within-metro sorting, most credible)
10. **IRS suppression sensitivity** (drop ZIPs with suppressed cells)

## Power Assessment

- 8 border pairs × ~500 ZIPs per pair within 30km = ~4,000 ZIPs
- 10 years of data (2012-2021) = ~40,000 ZIP-year observations
- Share of $200K+ filers nationally: ~5-8% of returns
- Expected effect size: 1-3 percentage point increase on low-tax side
- With N~40,000 and reasonable residual variance, MDE should be well below 1pp

## Data Sources

1. **IRS SOI ZIP-code income data** (2012-2021): `https://www.irs.gov/pub/irs-soi/[YY]zpallagi.csv`
2. **Census ZCTA shapefiles:** TIGER/Line for ZIP code centroid coordinates
3. **State border geometries:** TIGER/Line state boundaries
4. **State income tax rates:** Tax Foundation annual reports
5. **Pre-TCJA SALT deductions:** IRS SOI state-level data

## Welfare Framework

Use the sufficient statistics approach (Kleven, Landais, Saez 2014) to compute:
- Revenue elasticity of migration with respect to the net-of-tax rate
- Implied deadweight loss from tax competition
- Counterfactual revenue under SALT cap repeal
