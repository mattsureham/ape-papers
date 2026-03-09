# Initial Research Plan — apep_0500

## Research Question

Do anti-open grazing laws reduce farmer-herder violence in Nigeria? Or do they exacerbate conflict through enforcement backlash and displacement of pastoral populations?

## Policy Background

Between 2016 and 2021, at least 14 Nigerian states adopted legislation banning open cattle grazing. Benue state (November 2017) was the most prominent early adopter; a wave of southern states followed the May 2021 Southern Governors' Forum resolution. The policy is a direct response to farmer-herder conflict, which has killed thousands and displaced millions across Nigeria's Middle Belt and southern regions. In November 2025, the federal government banned open grazing nationally, making state-level evidence urgently policy-relevant.

## Identification Strategy

**Triple-Difference (DDD) Design:**

1. **First difference (state × time):** States that adopted anti-grazing legislation vs. states that did not, exploiting staggered adoption timing (2016-2021).

2. **Second difference (pastoral exposure):** Within each state, pastoral-zone LGAs (identified by historical livestock density, transhumance corridor proximity, and pre-treatment farmer-herder conflict) vs. non-pastoral LGAs. The law should bind more in pastoral areas.

3. **Third difference (violence type):** Non-state violence (UCDP type 2, which includes farmer-herder clashes) vs. state-based violence (type 1, e.g., Boko Haram) and one-sided violence (type 3). Anti-grazing laws should affect pastoral violence specifically, not other violence types.

**Estimating equation:**

Y_{ist} = β(Law_st × Pastoral_i × Post_t) + state FE + year FE + state×year FE + LGA FE + ε_{ist}

where Y is conflict events/fatalities in LGA i, state s, year t.

## Exposure Alignment

- **Who is treated:** Pastoral communities and pastoralists in states with anti-grazing legislation
- **Primary estimand:** Effect of state-level anti-grazing law on LGA-level farmer-herder violence
- **Placebo populations:** (1) Non-pastoral LGAs in treated states; (2) All violence types unrelated to pastoralism (Boko Haram, banditry, political violence)
- **Design:** Triple-difference (DDD), not simple DiD

## Power Assessment

- **Pre-treatment periods:** 5+ years for 2017 adopters (UCDP data from 2010); 10+ for 2021 adopters
- **Treated clusters (state-level):** 14 confirmed, potentially 17-20 with additional southern states
- **LGA-level observations:** ~774 LGAs × 15 years = ~11,600 obs
- **Inference:** Wild cluster bootstrap (14+ state clusters), randomization inference, HonestDiD sensitivity

## Expected Effects and Mechanisms

**Hypothesis 1 (Deterrence):** Laws reduce farmer-herder violence by creating legal penalties for open grazing, shifting pastoralists to ranching or alternative routes. Expected: negative β.

**Hypothesis 2 (Backlash):** Laws provoke enforcement clashes, displacement of herders into new conflict zones, and retaliatory violence. Expected: positive β, at least in the short run.

**Hypothesis 3 (Null with weak enforcement):** Laws are not enforced and have no effect on actual grazing patterns or violence. Expected: β ≈ 0.

## Primary Specification

Callaway-Sant'Anna (2021) staggered DiD at the state-year level for the main result, then DDD at the LGA-year level for mechanism isolation.

## Planned Robustness Checks

1. **HonestDiD sensitivity:** Rambachan-Roth bounds for pre-trend violations
2. **Wild cluster bootstrap:** Cameron, Gelbach, Miller (2008) with 10,000 iterations
3. **Randomization inference:** Fisher exact test permuting treatment across states
4. **Leave-one-state-out:** Jackknife excluding each treated state
5. **Event study:** Dynamic treatment effects with leads and lags
6. **Placebo tests:** Effect on non-pastoral violence types (type 1, type 3)
7. **Southern Governors' Forum sub-sample:** States that adopted due to collective resolution vs. violence-driven adopters
8. **Dose-response:** Enforcement intensity (where measurable) vs. law-on-the-books
9. **Spatial displacement:** Does violence shift to neighboring untreated LGAs?

## Data Sources

| Data | Source | Access | Unit |
|------|--------|--------|------|
| Conflict events | UCDP GED v25.1 | Free download | Event (geocoded) |
| State boundaries | GADM v4.1 | Free download | State polygon |
| LGA boundaries | GADM v4.1 / HDX | Free download | LGA polygon |
| Law adoption dates | Web research + legislation | Free | State-year |
| Pastoral zones | FAO Gridded Livestock of the World | Free download | Grid (1km) |
| Nighttime lights (secondary) | VIIRS Black Marble | NASA LAADS | Monthly grid |
