# Research Plan: No Registration, No Market — The REACH 2018 Deadline and Chemical Industry Restructuring

## Research Question

Did the EU REACH Regulation's 2018 registration deadline — which required all chemical substances manufactured or imported above 1 tonne per year to be registered — cause disproportionate exit and consolidation among small chemical firms in countries with higher pre-treatment micro-firm intensity?

## Identification Strategy

**Triple-difference (DDD) design:**

1. **Time:** Pre vs. post May 31, 2018 (the final REACH registration deadline)
2. **Sector:** NACE C20 (manufacture of chemicals and chemical products) vs. C22-C25 (rubber/plastics, non-metallic minerals, basic metals, fabricated metals) as control sectors
3. **Country intensity:** Pre-treatment (2014-2017 average) micro-firm share in the chemical sector varies from ~40% (Germany) to ~85% (Czechia), creating a continuous treatment intensity measure

**Key identification assumption:** Absent the 2018 deadline, countries with higher micro-firm shares in chemicals would have experienced the same trends in enterprise counts (relative to control sectors) as countries with lower micro-firm shares.

**Built-in falsification:** The May 2013 deadline targeted substances ≥100 tonnes/year — predominantly large firms. If our identification is correct, the 2013 deadline should NOT differentially affect micro-firm-intensive countries. This is a powerful placebo: same regulation, same sector, different tonnage threshold.

## Expected Effects and Mechanisms

**Primary hypothesis:** Higher micro-firm intensity × post-2018 → fewer enterprises, lower employment, reduced turnover in C20 chemicals.

**Mechanism:** Registration costs are largely fixed (dossier preparation, testing, fees), creating disproportionate burden on small producers. ECHA estimates costs at EUR 50,000-300,000 per substance. For a micro-firm producing 2-5 tonnes of a niche substance, this may exceed annual profits.

**Secondary mechanisms to test:**
- Size-class heterogeneity: effects should concentrate in 0-9 employee firms
- Business demography: higher death rates, not lower birth rates (existing firms exit, not fewer entries)
- Turnover per enterprise: surviving firms may see increased turnover (consolidation → market concentration)

## Primary Specification

$$Y_{cst} = \alpha + \beta_1 (\text{Post2018}_t \times \text{C20}_s \times \text{MicroShare}_c) + \beta_2 (\text{Post2018}_t \times \text{C20}_s) + \gamma_{cs} + \delta_{ct} + \theta_{st} + \varepsilon_{cst}$$

Where:
- $Y_{cst}$: log enterprises (or employment, turnover) in country $c$, sector $s$, year $t$
- $\text{MicroShare}_c$: pre-treatment share of firms with 0-9 employees in C20, country $c$
- $\gamma_{cs}$: country × sector fixed effects
- $\delta_{ct}$: country × year fixed effects
- $\theta_{st}$: sector × year fixed effects
- Clustering: country level (18-23 clusters)

## Exposure Alignment

- **Who is actually treated?** Chemical firms producing/importing 1-999 tonnes/year of unregistered substances — predominantly micro and small firms
- **Primary estimand population:** Country-sector-year cells in C20 chemicals
- **Placebo/control population:** C22-C25 (similar manufacturing sectors not subject to REACH registration)
- **Design:** Triple-difference (DDD) with continuous treatment intensity

## Power Assessment

- **Pre-treatment periods:** 10 years (2008-2017)
- **Treated clusters:** 18-23 countries (depending on data availability)
- **Post-treatment periods:** 2-3 years (2018-2020)
- **Outcome variation:** Enterprise counts range from 277 (Denmark) to 4,250 (Italy)
- **MDE:** With 18 clusters, ~40 degrees of freedom in the DDD, and substantial cross-country variation in micro-firm shares (SD ≈ 15pp), we should detect effects of 3-5% of the outcome mean

## Planned Robustness Checks

1. **2013 placebo:** Estimate the same DDD around the May 2013 deadline — should show null
2. **Leave-one-country-out:** Drop each country in turn; check stability
3. **Alternative control sectors:** Use only C22-C23 (closer to chemicals) or broader manufacturing
4. **Wild cluster bootstrap:** Given 18-23 clusters, supplement CRSE with WCB
5. **Randomization inference:** Permute country-level micro-firm shares
6. **Alternative timing:** Use 2017 as treatment year (anticipation), 2019 (delayed effects)
7. **Event study:** Estimate year-by-year DDD coefficients for pre-trend assessment
8. **Continuous vs. binary intensity:** Compare continuous MicroShare with above/below median split

## Data Sources

1. **Eurostat SBS (sbs_na_ind_r2):** Enterprise counts, employment, turnover by NACE 2-digit sector and country. ~2008-2020.
2. **Eurostat Business Demography (bd_9ac_l_form_r2):** Births, deaths, survival rates by NACE sector and country. ~2008-2020.
3. **Eurostat SBS by Size Class (sbs_sc_ind_r2):** Enterprise counts by size class (0-9, 10-19, 20-49, 50-249, 250+) and sector. For constructing MicroShare treatment intensity.
