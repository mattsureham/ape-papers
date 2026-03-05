# Initial Research Plan: Do Administrative Borders Tax Electricity?

## Research Question

How much of Switzerland's enormous municipal electricity price variation (10–50 Rp/kWh) is driven by cantonal energy policy choices versus geographic and cost fundamentals? Specifically, do cantonal energy law reforms create sharp discontinuities in electricity tariffs at cantonal borders, and which tariff component absorbs the policy effect?

## Identification Strategy

**Multi-border spatial RDD with event-study (spatial DiD).**

We exploit the staggered adoption of comprehensive cantonal energy law reforms across 8 Swiss cantons between 2010 and 2020. The identifying assumption is that municipalities on either side of a cantonal border are similar in observable and unobservable characteristics, but face different cantonal energy policy regimes.

**Treatment:** Cantonal energy law reform adoption (timing varies by canton).

**Running variable:** Distance from municipal centroid to nearest cantonal border (signed: positive = treated canton, negative = control canton).

**Key border pairs (8 reformed cantons × adjacent non-reformed cantons):**
- GR (2010) vs. SG, GL, TI, UR
- BE (2011) vs. FR, SO, AG, LU, JU, NE, VD, VS
- AG (2012) vs. ZH, SO, LU, BL, BE
- BL (2016) vs. SO, JU, AG, BS
- BS (2016) vs. BL, SO, AG
- LU (2017) vs. SZ, OW, NW, AG, ZG, BE
- FR (2019) vs. VD, NE, BE
- AI (2020) vs. AR, SG

**Built-in placebo:** Federal aid fee (Netzzuschlag) is nationally uniform → should show zero discontinuity at every cantonal border. Non-policy tariff components (grid, energy) may show discontinuities driven by cost fundamentals, but should not change at the time of reform adoption.

## Exposure Alignment

- **Who is actually treated?** Municipalities in cantons that adopt comprehensive energy legislation. Treatment is at the canton level but measured at the municipality level.
- **Primary estimand population:** Municipalities near cantonal borders (within 15km), in mixed border pairs (one reform, one non-reform canton).
- **Placebo/control population:** Municipalities on the non-reform side of mixed border pairs.
- **Design:** Border-pair DiD with spatial controls (hybrid spatial RDD/DiD).

## Expected Effects and Mechanisms

1. **Charges component:** Positive discontinuity after reform — cantonal energy laws introduce energy fund levies, renewable promotion charges, and efficiency mandates that increase the "Abgaben" component.
2. **Energy component:** Ambiguous — energy law reforms may incentivize local renewable generation, potentially reducing procurement costs, but could also increase costs if mandates raise production costs.
3. **Grid usage:** Near zero discontinuity — grid costs depend on physical infrastructure, not cantonal policy.
4. **Federal aid fee:** Zero discontinuity (placebo) — nationally set by federal government.
5. **Total tariff:** Positive discontinuity driven primarily by charges component.

**Magnitude:** We expect the charges component discontinuity to be 0.5–3 Rp/kWh, representing 2–10% of the median total tariff (~28 Rp/kWh).

## Primary Specification

$$Y_{m,t} = \alpha + \beta_1 \cdot \text{Treated}_{m} + f(\text{Distance}_{m}) + \gamma_t + \delta_b + \epsilon_{m,t}$$

Where:
- $Y_{m,t}$ = tariff component (total, energy, grid, charges, aid fee) for municipality $m$ in year $t$
- $\text{Treated}_{m}$ = indicator for municipality being in a canton that has adopted energy law reform by year $t$
- $f(\text{Distance}_{m})$ = polynomial or local linear in distance to nearest cantonal border
- $\gamma_t$ = year fixed effects
- $\delta_b$ = border-pair fixed effects (comparing only municipalities near the same border)
- Standard errors clustered at the canton level (conservative) or municipality level

**Event-study specification:**
$$Y_{m,t} = \sum_{k=-5}^{+10} \beta_k \cdot \text{Treated}_{m} \times \mathbf{1}[t - t^*_c = k] + f(\text{Distance}_{m}) + \gamma_t + \delta_b + \epsilon_{m,t}$$

Where $t^*_c$ is the reform year for canton $c$.

## Planned Robustness Checks

1. **Bandwidth sensitivity:** 5km, 10km, 15km, 20km bandwidth windows
2. **Polynomial order:** Local linear, quadratic, cubic in distance
3. **DSO fixed effects:** Control for utility-specific pricing behavior
4. **Donut RDD:** Exclude municipalities directly on the border (within 2km)
5. **Placebo borders:** Randomly assign fake borders within cantons; test for spurious discontinuities
6. **Placebo outcome:** Federal aid fee should show zero discontinuity
7. **Individual border pair estimates:** Show estimates for each of ~50 border pairs
8. **Pre-reform balance tests:** Covariate balance across all borders
9. **Temporal placebo:** Test for discontinuities in years before reform adoption
10. **Cross-border utility analysis:** Estimate within-DSO variation for utilities serving both sides

## Data Sources

| Source | Variable | Granularity | Period |
|--------|----------|-------------|--------|
| ElCom SPARQL | Electricity tariffs (5 components) | Municipal (2,712) | 2011–2026 |
| swissBOUNDARIES3D | Municipal boundaries + centroids | Municipal polygons | 2016–2026 |
| BFS PXWeb | Population, income, employment | Municipal | 2011–2024 |
| Fedlex SPARQL | Cantonal energy law adoption dates | Cantonal | Various |
| rcds/swiss_legislation | Staggered cantonal law details | Cantonal | Various |

## Welfare/Counterfactual

To elevate beyond a measurement exercise, we will compute:
1. **Decomposition of price dispersion:** What share of cross-municipal price variation is attributable to cantonal policy vs. cost fundamentals?
2. **Consumer cost of cantonal autonomy:** Average household excess cost from living in a reform-canton municipality near a border vs. equivalent non-reform municipality.
3. **Policy counterfactual:** What would the national price distribution look like if all cantons adopted the median policy charges?

## Power Assessment

- **Municipalities:** ~2,712 (all of Switzerland)
- **Border municipalities (within 15km of cantonal border):** ~1,500+ (Switzerland is small and dense)
- **Treated canton municipalities near borders:** ~500+
- **Pre-treatment periods:** 1–9 years depending on canton
- **Post-treatment periods:** 6–15 years depending on canton
- **Tariff variation:** SD ~8 Rp/kWh across municipalities
- **Expected MDE:** With ~500 treated municipalities and SD of 8 Rp/kWh, at 80% power and α=0.05, MDE ≈ 0.7 Rp/kWh — well below expected effect sizes of 1–3 Rp/kWh.
