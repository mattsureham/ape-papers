# Initial Research Plan: Can Shorter Workweeks Save Fertility?

## Research Question

Does reducing the maximum workweek from 68 to 52 hours increase marriage and fertility rates? We exploit South Korea's 2018 Labor Standards Act amendment, which imposed a 52-hour cap staggered by firm size (300+ employees in July 2018, 50-299 in January 2020, 5-49 in July 2021), to estimate the causal effect of work-time regulation on family formation in the country with the world's lowest fertility rate (TFR = 0.72 in 2023).

## Identification Strategy

**Multi-cutoff staggered DiD with built-in placebo groups.**

The staggered rollout by firm-size thresholds provides three treatment cohorts:
- **Cohort 1 (July 2018):** Workers at firms with 300+ employees
- **Cohort 2 (January 2020):** Workers at firms with 50-299 employees
- **Cohort 3 (July 2021):** Workers at firms with 5-49 employees

**Key design features:**
1. Cohort 2/3 workers serve as not-yet-treated controls during the Cohort 1 treatment period
2. Built-in placebo: Cohort 2/3 should show zero effect during 2018-2019 (the pre-COVID, Cohort 1 treatment window)
3. Individual fixed effects absorb time-invariant worker heterogeneity
4. Callaway-Sant'Anna (2021) estimator handles staggered treatment timing

**Primary estimand:** Effect of the 52-hour cap on annual marriage hazard and birth hazard among working-age individuals, identified from Cohort 1 (pre-COVID window: July 2018 - December 2019).

## Expected Effects and Mechanisms

The sign is **theoretically ambiguous**, which is precisely what makes this interesting:

**Time channel (positive):** Reduced work hours free up time for dating, socializing, and family life. Korea's extreme work culture (2,069 annual hours in 2017, highest in OECD) is widely cited as a barrier to marriage and childbearing.

**Income channel (negative):** Overtime pay was a significant income source. Reduced hours mean lower monthly earnings, potentially making marriage and children less affordable.

**Net effect:** If the time channel dominates, we expect increased marriage rates. If the income channel dominates, we expect no change or decreased rates. A precisely estimated null is also valuable—it would indicate that work hours are not the binding constraint on Korean fertility, despite widespread policy belief.

## Primary Specification

**Individual-level (KLIPS micro-panel):**

$$Y_{it} = \alpha_i + \delta_t + \beta \cdot \text{Post}_t \times \text{Treated}_i + X_{it}'\gamma + \varepsilon_{it}$$

Where:
- $Y_{it}$ = marriage transition (0/1) or birth event (0/1)
- $\alpha_i$ = individual fixed effects
- $\delta_t$ = year fixed effects
- $\text{Treated}_i$ = worker at firm with 300+ employees at baseline (2017)
- $\text{Post}_t$ = 1 if $t \geq 2018$
- $X_{it}$ = time-varying controls (age, education, industry)

**First stage (hours reduction):**

$$\text{Hours}_{it} = \alpha_i + \delta_t + \pi \cdot \text{Post}_t \times \text{Treated}_i + X_{it}'\gamma + \nu_{it}$$

**Province-level (KOSIS vital statistics):**

$$Y_{pt} = \alpha_p + \delta_t + \beta \cdot \text{Exposure}_p \times \text{Post}_t + \varepsilon_{pt}$$

Where $\text{Exposure}_p$ = province-level share of employment in firms with 300+ employees (from baseline Economic Census/KLIPS).

## Exposure Alignment (DiD-specific)

- **Who is treated:** Workers at firms above the firm-size threshold (300 employees in Wave 1)
- **Primary estimand population:** Working-age adults (20-45) employed at large firms, observed in KLIPS
- **Placebo/control population:** Workers at firms with 5-299 employees (not yet treated during Wave 1 window)
- **Design:** Staggered DiD with multiple cohorts; primary analysis focuses on Cohort 1 only (cleanest window)

## Power Assessment

- **Pre-treatment periods:** 3 years (2015-2017) in KLIPS
- **Treated clusters:** ~7,000 workers in firms 300+ (KLIPS)
- **Post-treatment periods:** 2 years clean (2018-2019), 5 years total (2018-2023)
- **MDE:** For marriage (base rate ~5%), with N=7,000 treated and N=13,000 controls, MDE ≈ 0.5-1.0 percentage points. For births (base rate ~2%), MDE ≈ 0.3-0.5pp — borderline, hence births are secondary.

## Planned Robustness Checks

1. **Event study:** Dynamic treatment effects showing no pre-trends and timing of response
2. **Built-in placebo:** Cohort 2/3 workers during 2018-2019 (should show zero effect)
3. **Near-threshold:** Restrict to workers at firms 200-400 to reduce compositional differences
4. **Callaway-Sant'Anna estimator:** Heterogeneity-robust group-time ATTs
5. **COVID sensitivity:** Show main result robust to excluding 2020+ entirely
6. **Randomization inference:** With firm-size assignment as quasi-random, permutation-based p-values
7. **Mechanism decomposition:** Separate hours reduction (first stage) from marriage/birth response
8. **Income vs. time:** Use wage data to test whether hours fell more than earnings (overtime premium)
9. **Gender heterogeneity:** Test whether effects differ for men vs. women
10. **Leave-one-industry-out:** Check results not driven by single sector

## Data Sources

| Source | Level | Variables | Access |
|--------|-------|-----------|--------|
| KLIPS (waves 18-26) | Individual panel | Hours, firm size, marriage, births, wages | Harvard Dataverse |
| World Bank API | Country | TFR, crude marriage/birth rates | Public API |
| KOSIS | Province-month | Registered births, marriages | kosis.kr |
| OECD | Country | Annual hours worked | OECD.Stat API |
