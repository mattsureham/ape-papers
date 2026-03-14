# Research Plan: Price Floors and Poison

## Research Question

Does minimum unit pricing (MUP) for alcohol reduce alcoholic liver disease (ALD) mortality? Scotland implemented MUP at 50p/unit in May 2018; Wales followed at 50p/unit in March 2020; England has never implemented MUP. This staggered adoption across UK nations enables the first causal between-nation estimate of MUP's effect on alcohol-attributable mortality.

## Identification Strategy

**Callaway-Sant'Anna staggered DiD:**
- G=2018 cohort: 32 Scottish councils (treated May 2018)
- G=2020 cohort: 22 Welsh LAs (treated March 2020)
- Never-treated: 317 English LAs
- Total: 371 units, 54 treated

**Key assumptions:**
1. Parallel trends in K70 (ALD) death rates across UK nations pre-2018
2. No anticipation — MUP legislation to implementation was brief
3. SUTVA — limited cross-border alcohol purchasing (tested via border LAs)

## Expected Effects and Mechanisms

**Primary hypothesis:** MUP reduces ALD mortality by raising the floor price of cheap, high-strength products consumed by heavy/dependent drinkers.

**Mechanism:** MUP targets the cheapest alcohol disproportionately consumed by the most deprived populations. Elasticity literature (Wagenaar et al. 2009) suggests heavy drinkers reduce consumption when floor prices rise, though less than moderate drinkers.

**Expected direction:** Negative ATT on K70 death rate (MUP reduces ALD mortality), with heterogeneity by deprivation — larger effects in more deprived areas.

**Magnitude:** Descriptive evidence: Scotland K70 grew +22% (2019-2023) vs England +38%. This ~16pp gap is the raw DiD. Controlling for pre-trends and COVID, the ATT may be smaller.

## Primary Specification

```
Y_{it} = K70 death rate per 100,000 in LA/council i, year t
Treatment: first_MUP_year (2018 for Scotland, 2020 for Wales)
Method: Callaway-Sant'Anna (did R package)
Clustering: LA/council level
```

## Robustness Checks

1. **Placebo outcomes:** Non-alcohol-specific causes (e.g., transport accidents, diabetes)
2. **Cross-border spillovers:** English LAs bordering Scotland as partial treatment test
3. **Drug substitution:** F11-F19 (mental/behavioral disorders due to drugs) as substitution test
4. **COVID controls:** Exclude 2020 for Wales cohort sensitivity; include year FE
5. **Population weighting:** Weighted vs unweighted specifications
6. **Alternative control groups:** Never-treated only vs not-yet-treated

## Data Sources

| Source | Variable | Geography | Time |
|--------|----------|-----------|------|
| NOMIS NM_161_1 | K70 deaths by LA | 317 England + 22 Wales LAs | 2013-2023 |
| NRS Alcohol-Specific Deaths | K70 deaths by council | 32 Scottish councils | 2013-2023 |
| NOMIS NM_31_1 | Mid-year population | All LAs/councils | 2013-2023 |
| IMD/SIMD/WIMD | Deprivation rankings | LA-level | 2019/2020 |

## Fetch Strategy

1. NOMIS API for England/Wales K70 deaths and population estimates
2. NRS Excel tables from nrscotland.gov.uk for Scottish K70 deaths
3. Deprivation indices from gov.uk/gov.scot/gov.wales
