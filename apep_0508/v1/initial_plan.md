# Initial Research Plan: The Cost of Sponsorship

## Research Question

How much did UAE firms benefit from the kafala system's restriction on worker mobility? When the UAE abolished the employer No Objection Certificate (NOC) requirement in February 2022, reducing monopsony power over migrant workers, did firms with high migrant labor dependence experience abnormal stock price declines?

## Identification Strategy

**Cross-sectional event study / DiD** on Dubai Financial Market (DFM) listed firms.

**Treatment:** The kafala reform (Federal Decree-Law No. 33 of 2021) reduced employers' ability to tie workers. Labor-intensive sectors with high migrant worker shares (construction, real estate, services) lost more monopsony rents than capital-intensive sectors (banking, insurance, telecom).

**Variation:** Sector-level migrant labor intensity. High-exposure sectors (construction, real estate, hospitality, industrial) rely on kafala-bound workers; low-exposure sectors (banking, insurance, telecom, investment) employ workers who were already relatively mobile.

**Event dates (three-event stacked design):**
1. September 20, 2021: Federal Decree-Law No. 33 signed
2. November 15, 2021: Implementing regulations published
3. February 2, 2022: Law enters into effect

## Expected Effects and Mechanisms

**Main hypothesis:** Negative abnormal returns for high-exposure (labor-intensive) firms relative to low-exposure (capital-intensive) firms around event dates. The kafala system granted employers monopsony power; its abolition increases expected wage costs.

**Mechanisms:**
1. **Wage channel:** Workers can now bargain for higher wages or switch to better-paying employers → higher labor costs
2. **Turnover channel:** Increased worker mobility → higher recruitment/training costs
3. **Bargaining power:** Reduced outside-option restriction → rent redistribution from firms to workers

**Magnitude:** Under monopsony, the wage markdown is w/MRP < 1. If kafala maintained a 20% markdown, the reform eliminates this rent. For a firm with labor share of 50%, this implies a ~10% increase in costs → should be reflected in firm value decline.

## Primary Specification

**Abnormal returns model:**
```
CAR_{i,t} = α + β₁ · HighExposure_i + γ · X_i + ε_{i,t}
```

Where:
- CAR = Cumulative Abnormal Return over event window [−1, +3] trading days
- HighExposure = indicator for labor-intensive sector (construction, real estate, services, industrial)
- X = controls (firm size, beta, prior returns, sector fixed effects within exposure groups)

**DiD specification (daily panel):**
```
R_{i,t} = α_i + δ_t + β · (HighExposure_i × Post_t) + ε_{i,t}
```

Where:
- R = daily return for firm i on day t
- α_i = firm fixed effects
- δ_t = trading-day fixed effects
- Post = indicator for post-event window
- Standard errors clustered at firm level

## Exposure Alignment

**Who is treated?** All DFM-listed firms, but with differential treatment intensity:
- **High exposure:** Firms in sectors with >85% migrant worker share (construction, real estate, services, hospitality, industrial)
- **Low exposure (placebo):** Firms in sectors with <75% migrant worker share but with already-mobile workforces (banking, insurance, telecom, investment)
- The reform applied to ALL private sector workers, but its BITE was strongest where the kafala system was most binding

**Primary estimand:** Difference in cumulative abnormal returns between high-exposure and low-exposure firms around reform event dates.

## Power Assessment

- **Pre-treatment periods:** ~500 trading days (Jan 2019 – Aug 2021)
- **Treated units:** ~20-25 high-exposure DFM firms
- **Control units:** ~20-25 low-exposure DFM firms
- **Post-treatment events:** 3 event windows (Sept 2021, Nov 2021, Feb 2022)
- **MDE:** With N=46 firms, σ(CAR) ≈ 5%, α=0.05: MDE ≈ 3% abnormal return difference. This is detectable if monopsony rents represent >3% of firm value — plausible given the extreme nature of kafala.

## Planned Robustness Checks

1. **Placebo dates:** Run identical analysis on 5 non-event dates (e.g., March 2021, June 2021, April 2022)
2. **GCC placebo:** Show Saudi Tadawul labor-intensive firms did NOT react to UAE reform dates
3. **Alternative event windows:** [−2, +5], [−1, +1], [0, +10]
4. **Continuous exposure:** Replace binary HighExposure with sector-level migrant share (continuous treatment)
5. **Market model vs. market-adjusted returns:** Use both Fama-French-style model and simple market-adjusted returns
6. **Excluding confounding dates:** If any major macroeconomic announcement coincides with reform dates, exclude that event
7. **Randomization inference:** Permute event dates 1,000 times to obtain RI p-values
8. **HonestDiD sensitivity:** Rambachan-Roth bounds on pre-trend violations for DiD specification
