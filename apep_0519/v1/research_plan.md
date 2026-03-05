# Initial Research Plan: Mandating the Green Transition

## Research Question

Does mandated building energy code adoption (MuKEn 2014) accelerate the transition from fossil heating to heat pumps in Swiss residential buildings? Or do mandates deter renovation activity, creating a compliance-cost channel that slows the transition?

## Identification Strategy

**Staggered Difference-in-Differences** exploiting differential cantonal adoption timing of MuKEn 2014 across Swiss cantons.

- **Treatment:** Canton adopts MuKEn 2014 (binary: any module; continuous: module count)
- **Unit of observation:** Municipality × year
- **Treated:** ~1,800 municipalities in 22 cantons that adopted MuKEn 2014 (timing varies from ~2017 to 2024)
- **Control:** ~300 municipalities in 4 cantons that have not (yet) adopted
- **Estimator:** Callaway & Sant'Anna (2021) for heterogeneous treatment timing
- **Inference:** Wild cluster bootstrap at the canton level (26 clusters); randomization inference as robustness

### Exposure Alignment

- **Who is treated:** Building owners and developers in adopting cantons who undertake new construction or major renovations
- **Primary estimand population:** All residential buildings (new construction + renovations)
- **Placebo populations:** (1) Existing buildings not undergoing renovation; (2) Cantons that adopted MuKEn 2008 but not 2014; (3) Non-residential buildings subject to different/no standards
- **Design:** DiD with supplementary spatial RDD at cantonal borders and DDD (adopted canton × high fossil stock municipality × post)

### Power Assessment

- **Pre-treatment periods:** 5+ years (2012-2016 before first adopter ~2017)
- **Treated clusters:** 22 cantons (~1,800 municipalities)
- **Control clusters:** 4 cantons (~300 municipalities)
- **Post-treatment periods:** Varies by cohort; earliest cohorts have 6-7 post-treatment years
- **MDE:** With ~2,100 municipalities and ~10 years, the design is well-powered for detecting economically meaningful shifts in heating system shares (e.g., 2-5 percentage point change in heat pump share)

## Expected Effects and Mechanisms

### Main hypothesis
MuKEn 2014 adoption increases heat pump installation rates in new construction and accelerates fossil heating replacement in renovations.

### Mechanism decomposition
1. **New construction channel:** Building code mandates near-zero energy standards → new buildings must install heat pumps or equivalent. Expected: large, immediate effect on new construction heating mix.
2. **Renovation channel:** Heating replacement module requires partial renewable share when replacing boilers. Expected: moderate effect, conditional on renovation timing.
3. **Deterrence channel:** Higher compliance costs may reduce renovation rates. Expected: possible negative effect on renovation count, especially for cost-sensitive building owners.
4. **Technology substitution:** Within heat sources, oil → gas → heat pump progression. Expected: primarily oil displacement.

### Expected signs
- Heat pump share in new buildings: strongly positive
- Heat pump share in renovated buildings: positive
- Fossil heating share: negative
- Total renovation/construction activity: ambiguous (potential negative from compliance cost)

## Primary Specification

$$Y_{m,t} = \alpha_m + \gamma_t + \sum_g \sum_t \text{ATT}(g,t) \cdot \mathbb{1}[G_m = g] \cdot \mathbb{1}[t = t] + \epsilon_{m,t}$$

where $Y_{m,t}$ is the heat pump share among new/renovated buildings in municipality $m$ in year $t$, $\alpha_m$ are municipality fixed effects, $\gamma_t$ are year fixed effects, and ATT(g,t) are group-time average treatment effects from CS-DiD.

### Key variables
- **Outcomes:** (1) Share of new buildings with heat pump heating; (2) Share of renovated buildings with heat pump; (3) Count of renovations per 1,000 buildings; (4) Share with oil/gas heating
- **Treatment:** Binary cantonal adoption; module count; module-specific dummies
- **Controls:** Canton-level energy price index, federal subsidy generosity, population growth, building stock age composition

## Planned Robustness Checks

1. **Pre-trends:** Event-study plot with leads/lags; Rambachan & Roth (2023) HonestDiD sensitivity
2. **Border RDD:** Municipalities within 10-20km of cantonal border (adopter vs. non-adopter)
3. **Placebo outcomes:** Non-residential building heating; cantonal-level outcomes unrelated to buildings
4. **Exclude 2022+:** Remove energy crisis period to ensure results not driven by fossil price shock
5. **Module-level analysis:** Estimate effects separately for heating replacement, solar, and envelope modules
6. **DDD:** Adopted canton × high-fossil-stock municipality × post-adoption
7. **Sun & Abraham (2021):** Alternative estimator robust to anticipation effects
8. **Randomization inference:** Permute treatment assignment across cantons
9. **Bacon decomposition:** Examine weights on timing-pair comparisons
10. **Concurrent subsidies:** Control for cantonal subsidy program generosity

## Data Sources

| Source | Variables | Access |
|--------|-----------|--------|
| GWR (opendata.swiss) | Building-level heating energy source, construction year, building type | Free download (Parquet/CSV) |
| BFS PXWeb | Construction permits, completions by municipality-year | Free API |
| ENDK | MuKEn 2014 module adoption dates by canton | Published status reports |
| BFS PXWeb | Municipal population, demographics | Free API |
| BFE/BFS | Energy price indices by canton | Published statistics |
| energiefranken.ch | Cantonal subsidy program details | Web scraping |
| Swissvotes/swissdd | Referendum results (for cantons that voted on MuKEn) | Free API/R package |

## Welfare Calculation

Map reduced-form estimates into carbon abatement costs:
- Mandated heat pump installation displaces X tons CO2/year per building
- Additional compliance cost per building = Y CHF (from construction cost data)
- Implied abatement cost = Y/X CHF per ton CO2
- Compare with Swiss CO2 levy (120 CHF/ton as of 2022) and EU ETS price
- Compare mandate-driven abatement with subsidy-driven abatement (using Gebäudeprogramm take-up data)
