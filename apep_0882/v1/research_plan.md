# Research Plan: Deaths of Despair Through the Resource Cycle

## Research Question
Do resource booms and busts have asymmetric effects on county-level drug overdose mortality? Specifically, does the mortality increase during busts exceed any mortality reduction during booms in shale-exposed US counties?

## Identification Strategy
**Continuous treatment DiD** with pre-boom (2001–2004) county-level oil/gas employment share as treatment intensity and national oil price shocks defining boom/bust periods.

- **Treatment intensity:** Pre-boom (2001–2004 average) NAICS 211 (Oil and Gas Extraction) employment share from BLS QCEW. Uses pre-boom values to avoid endogeneity with boom-period outcomes.
- **Time variation:** WTI crude oil prices define periods: Pre-boom (1999–2004), Boom (2005–2014, WTI avg ~$72), Bust (2015–2016, WTI ~$43), Recovery/Bust II (2017–2019, WTI ~$57).
- **Estimating equation:** Y_{ct} = α_c + γ_t + Σ_k β_k(OilShare_c × 1{t=k}) + X_{ct}δ + ε_{ct}
- **Asymmetry test:** H0: |β_bust| = |β_boom| via F-test on period-interacted specification.

**Key identification assumption:** Pre-boom oil/gas employment share (driven by geological endowment) is uncorrelated with county mortality trends conditional on county + year FE. Testable via pre-trends (1999–2004).

## Expected Effects and Mechanisms
1. **Boom reduces drug OD:** Employment/income gains reduce economic distress → substance abuse
2. **Bust increases drug OD:** Job loss, income collapse → despair, substance abuse relapse
3. **Asymmetry:** Bust mortality increase exceeds boom reduction (hysteresis in addiction, opioid supply persistence, social capital destruction)
4. **Contrast:** Non-drug external causes (traffic) should show OPPOSITE asymmetry (boom increases traffic deaths via congestion)

## Primary Specification
```
feols(drug_od_rate ~ i(year, oil_share, ref=2004) | county + year,
      data = panel, cluster = ~state)
```

## Data Sources
1. **Drug overdose mortality:** CDC NCHS Drug Poisoning by County (data.cdc.gov, pbkm-d27e), 1999–2019, model-based rates per 100K, all 3,100+ counties
2. **Oil/gas employment:** BLS QCEW, NAICS 211, county-level annual employment, 2001–2004
3. **Oil prices:** FRED API, WTI crude oil monthly prices (DCOILWTICO)
4. **County population & covariates:** tidycensus, ACS 5-year estimates
5. **All-cause mortality (robustness):** CDC WONDER or NCHS vital statistics

## Exposure Alignment
The treatment unit is the county, which is also the unit of observation for drug overdose mortality. Oil/gas establishments serve the county population directly through employment and income multipliers. Treatment timing is the national oil price cycle: boom (2005–2014) and bust (2015). All shale counties are exposed simultaneously through global commodity prices, so there is no staggered adoption — this is a standard continuous treatment DiD, not a staggered design. The pre-boom classification (2001–2004) ensures treatment assignment predates the exposure period.

## Robustness
- Binary treatment (above-median oil/gas share)
- Alternative treatment: NAICS 213 (mining support) or combined 211+213
- Wild cluster bootstrap (state-level clustering)
- HonestDiD sensitivity for parallel trends
- Leave-one-state-out
- Controlling for state-level opioid prescription trends
