# Initial Research Plan

## Research Question

Does World Bank aid stabilize Nigerian ministry-level government spending during fiscal shocks? When federal revenue collapses, do ministries with active World Bank projects experience smaller spending cuts? Conversely, when revenue surges, does the government redirect windfalls toward sectors without external support?

## Identification Strategy

**Dual-shock difference-in-differences** exploiting two major fiscal events within the Open Treasury data window (2018-2024):

1. **Negative shock (March 2020):** Global oil price crash from $65/barrel to $19/barrel, driven by the Saudi-Russia price war. Nigeria derives ~75% of government revenue from oil. The crash triggered severe federal spending contraction across MDAs.

2. **Positive shock (June 2023):** Fuel subsidy removal on President Tinubu's inauguration freed ~N3.6 trillion ($10B) annually in fiscal space. This represents the largest single fiscal policy change in Nigeria's history.

**Treatment assignment:** MDAs are classified as "WB-aided" if they have at least one active World Bank project at the time of the shock. Treatment is predetermined — WB projects are approved years before either shock. The treatment variable is both binary (has WB project) and continuous (total WB commitment in current USD).

**Estimating equation:**

log(Spending_{i,t}) = alpha_i + gamma_t + beta * (Aided_i x Post_t) + X'_{i,t} delta + epsilon_{i,t}

where i indexes MDAs, t indexes months, alpha_i are MDA fixed effects, gamma_t are month fixed effects, and Aided_i x Post_t is the DiD interaction.

**Built-in placebos:**
- Health MDA during 2020: expected to increase spending for pandemic reasons regardless of oil shock (COVID placebo)
- MDAs where WB projects closed before each shock (treat-then-untreated)
- 2023 shock tests reverse direction: non-aided MDAs should benefit more from windfall

## Expected Effects and Mechanisms

**Hypothesis 1 (Stabilization):** During the 2020 oil crash, WB-aided MDAs experienced smaller spending cuts than non-aided MDAs. Mechanism: WB project disbursements continued in USD, providing a floor for aided-sector spending even as domestic revenue fell.

**Hypothesis 2 (Fungibility):** During the 2023 fiscal expansion, non-aided MDAs received disproportionately more of the windfall. Mechanism: with WB already funding health/education/infrastructure, the government directed new revenue to previously underfunded sectors (security, administration, debt service).

**Hypothesis 3 (Downstream):** Spending cuts in non-aided MDAs during 2020 correlated with increased conflict events (ACLED) in relevant areas. This is a secondary/mechanism test, not the core outcome.

## Primary Specification

**Unit of analysis:** MDA × month (approximately 60-70 MDAs × 72 months = ~4,000-5,000 observations)

**Outcome:** Log of monthly total payments from Open Treasury, by MDA

**Treatment:** Binary indicator for active WB project × post-shock indicator

**Fixed effects:** MDA FE (absorbs permanent MDA differences) + Year-month FE (absorbs common time trends)

**Standard errors:** Clustered at the MDA level. Randomization inference as robustness given moderate cluster count (~60-70).

**Sample restriction (main):** Exclude health-related MDAs from the 2020 specification (COVID confound). Include all MDAs for the 2023 specification.

## Planned Robustness Checks

1. **Pre-trend test:** Event study with monthly leads/lags; F-test for joint significance of pre-treatment coefficients
2. **Continuous treatment:** Replace binary with log WB commitment amount
3. **Leave-one-out:** Drop each MDA one at a time to check for outlier dependence
4. **Wild cluster bootstrap:** Given moderate cluster count
5. **Randomization inference:** Permute treatment assignment across MDAs (1000 draws)
6. **Alternative shock windows:** Vary the start/end dates of each shock
7. **Placebo shocks:** Test non-events (e.g., 2019 election, non-oil months) for false positives
8. **Health MDA placebo:** Show health ministry increases during COVID regardless of oil shock
9. **Stacked design:** Treat 2020 and 2023 as two separate staggered events in a Callaway-Sant'Anna framework
10. **Intensive margin:** Among aided MDAs, test whether larger WB commitments provide more buffering

## Data Sources

| Source | Variables | Access | Frequency |
|--------|-----------|--------|-----------|
| Open Treasury (opentreasury.gov.ng) | MDA payments | Direct URL/CSV | Daily |
| govspend.ng | Processed MDA spending | Web scraping | Monthly |
| WB Projects API | Projects, sectors, dates, commitments | REST API, no key | Project-level |
| FRED | Brent crude oil prices | API with key | Monthly |
| ACLED | Conflict events (state × month) | API with key | Event-level |
| World Bank Indicators | GDP, aid flows, macro | REST API, no key | Annual |

## Exposure Alignment (DiD)

- **Who is actually treated?** Federal MDAs (ministries/departments/agencies) that serve as implementing agencies for active World Bank projects.
- **Primary estimand population:** All federal MDAs in Nigeria's budget (~60-70 entities).
- **Placebo/control population:** MDAs without active WB projects at the time of each shock.
- **Design:** Two-period DiD (pre/post each shock) with continuous extension via event study.

## Power Assessment

- **Pre-treatment periods:** ~18 months before 2020 shock; ~42 months before 2023 shock
- **Treated clusters:** ~15-20 MDAs with active WB projects
- **Control clusters:** ~40-50 MDAs without WB projects
- **Post-treatment periods:** ~10 months for 2020 shock; ~18 months for 2023 shock
- **Total panel observations:** ~4,000-5,000 MDA-months
- **MDE assessment:** With 60-70 clusters and within-MDA variation, minimum detectable effect is approximately 10-15% of a standard deviation in log spending (to be refined with actual data).
