# Initial Research Plan

## Research Question

Does the elimination of concealed carry permit requirements ("constitutional carry") affect firearm mortality, violent crime, and law enforcement officer safety?

## Identification Strategy

**Staggered Difference-in-Differences** using Callaway-Sant'Anna (2021) estimators.

- **Unit:** US state (50 states + DC)
- **Time:** Year (2000-2023)
- **Treatment:** Adoption of constitutional/permitless carry law
- **Treated states:** 22+ states adopting between 2010-2022 (13 pre-2020 for COVID-robust subsample)
- **Control group:** ~20 never-treated states (as of 2023)
- **Estimand:** Group-time ATTs aggregated to event-study and overall ATT

### Treatment Timing (verified from multiple sources)

| Year | States |
|------|--------|
| 2010 | Arizona |
| 2011 | Wyoming |
| 2015 | Kansas, Maine |
| 2016 | Idaho, Mississippi, West Virginia |
| 2017 | Missouri, New Hampshire, North Dakota |
| 2019 | Kentucky, Oklahoma, South Dakota |
| 2021 | Arkansas, Iowa, Montana, Tennessee, Texas, Utah |
| 2022 | Alabama, Georgia, Indiana, Ohio |
| 2023 | Florida, Nebraska |
| 2024 | Louisiana, South Carolina |

Note: Vermont (always permitless) and Alaska (2003) are excluded from treated group — VT is always-treated, AK adopted before panel starts. They can serve as pre-existing treated controls or be excluded.

## Expected Effects and Mechanisms

### Theoretical Ambiguity (ex ante)

**Deterrence channel (reduces violence):** More armed citizens → higher cost of crime → fewer attacks. Self-defense use rises.

**Escalation channel (increases violence):** More guns in circulation → more gun theft → more impulsive escalation of conflicts → more accidental deaths. Lower barrier to carrying in public → more confrontations become lethal.

**Police safety:** Ambiguous. Officers face more armed encounters → may use more force preemptively, OR more restraint. Citizens may be more or less likely to resist arrest.

### Key ex ante prediction: The sign of the effect is theoretically ambiguous, making this a genuine empirical question. Both outcomes are publishable.

## Primary Specification

```
Y_{st} = ATT(g,t) via Callaway-Sant'Anna
```

Where:
- Y = firearm homicide rate per 100K, firearm suicide rate per 100K, etc.
- g = cohort (year of adoption)
- t = calendar year
- Controls: state FE, year FE (implicit in CS-DiD)
- Covariates: log population, percent urban, median income, poverty rate, unemployment rate (from ACS/Census)
- Clustering: state level

## Planned Outcomes (Multi-Margin)

### Primary (civilian mortality — CDC WONDER)
1. Firearm homicide rate (per 100K)
2. Firearm suicide rate (per 100K)
3. Accidental firearm death rate (per 100K)
4. Total firearm death rate (per 100K)

### Placebo (should show null — CDC WONDER)
5. Non-firearm homicide rate
6. Non-firearm suicide rate

### Police Safety (FBI LEOKA)
7. Officers feloniously killed (per 10K officers)
8. Officers assaulted (per 10K officers)

### Crime (FBI UCR)
9. Violent crime rate
10. Robbery rate
11. Aggravated assault rate

### Mechanism (FBI NICS)
12. Background checks per capita (gun demand response)

## Planned Robustness Checks

1. **Pre-2020 subsample** (2000-2019, 13 treated states): Eliminates COVID crime spike
2. **Bacon decomposition**: Identify problematic 2x2 comparisons
3. **HonestDiD / Rambachan-Roth**: Sensitivity to pre-trend violations
4. **Randomization inference**: Permute treatment timing across states
5. **Placebo outcomes**: Non-firearm deaths (should show null)
6. **Heterogeneity**: Early vs. late adopters; rural vs. urban states; by pre-existing gun culture
7. **Event-study visualization**: Full lead/lag structure for each outcome
8. **Stacked DiD**: As alternative to CS-DiD
9. **Leave-one-out**: Drop each cohort to test sensitivity

## Power Assessment

- **Pre-treatment periods:** 10-22 years (depending on cohort)
- **Treated clusters:** 22 states
- **Never-treated clusters:** ~20 states
- **Post-treatment periods:** 1-13 years (depending on cohort)
- **MDE:** With 42 states × 24 years = ~1,000 state-years, and typical firearm homicide rate ~4/100K (SD ~3), we can detect effects of ~0.5-1.0/100K with 80% power — well within plausible magnitudes.

## Exposure Alignment (DiD Required Section)

- **Who is actually treated?** Residents of states that adopt constitutional carry — all adults who can legally possess a firearm can now carry concealed without a permit.
- **Primary estimand population:** State-level population (mortality rates, crime rates)
- **Placebo/control population:** Non-firearm deaths in the same states (mechanism-specific placebo)
- **Design:** Standard DiD with staggered adoption

## Data Sources

| Source | Granularity | Years | Access |
|--------|-------------|-------|--------|
| CDC WONDER (Underlying Cause of Death) | State × Year | 1999-2023 | API (POST) |
| FBI UCR (Crime Data Explorer) | State × Year | 2000-2022 | API |
| FBI LEOKA | State × Year | 2000-2022 | API/Download |
| FBI NICS | State × Month | 1998-2024 | Download |
| Census ACS | State × Year | 2005-2023 | API |
| BLS LAUS | State × Year | 2000-2023 | API |

## Welfare Framework

Back-of-envelope calculation:
- ΔDeaths × VSL ($11.6M, 2023 DOT) = welfare cost of constitutional carry
- Offset: regulatory compliance cost saved (permit fees ~$50-200 × number of permit holders)
- Net welfare: deaths cost − saved compliance costs
- Present expected value of policy per capita
