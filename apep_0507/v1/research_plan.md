# Initial Research Plan: Does Government Consolidation Cost Democracy?

## Research Question

Do municipal mergers reduce democratic participation in direct democracy? When Swiss municipalities consolidate, the average voter's community grows larger and their individual influence shrinks. Does this institutional change — the most common form of government restructuring worldwide — systematically reduce voter turnout?

## Identification Strategy

**Design:** Staggered difference-in-differences exploiting 352 voluntary merger events that dissolved 931 Swiss municipalities between 2000 and 2024.

**Treatment:** Municipality-year indicator equal to 1 in all periods after a merger event. The merger date is recorded precisely in the BFS Historisiertes Gemeindeverzeichnis (SMMT/AGVCH).

**Unit of observation:** Municipality × referendum. Municipalities that eventually merge are harmonized to their post-merger entity: pre-merger turnout is computed as the population-weighted average of constituent municipalities; post-merger turnout is observed directly.

**Control group:** ~1,170 municipalities that never merged during the sample period (2000–2024), plus not-yet-treated municipalities in the CS-DiD framework.

**Fixed effects:** Municipality FE (absorbs time-invariant characteristics) and canton × year FE (absorbs cantonal political shocks, institutional differences).

**Estimator:** Callaway & Sant'Anna (2021) for heterogeneous treatment timing, aggregated to event-time and overall ATT. Robust to negative weighting and treatment effect heterogeneity.

**Clustering:** Standard errors clustered at the municipality level. Robustness with canton-level clustering and wild cluster bootstrap (26 cantons).

## Expected Effects and Mechanisms

**Primary hypothesis:** Mergers reduce voter turnout by 1–5 percentage points.

**Theoretical channels:**
1. **Community size channel:** Larger communities reduce individual sense of influence (pivotal voter theory) and social pressure to participate.
2. **Identity/belonging channel:** Residents of "absorbed" municipalities may feel alienated from the new administrative unit, reducing engagement.
3. **Information channel:** After merger, local political information becomes more diffuse; voters in formerly small municipalities face higher information costs.
4. **Offsetting channel:** Mergers may professionalize local government and improve civic infrastructure (e.g., better information dissemination), partially offsetting turnout declines.

**Direction:** Theoretically ambiguous, but the weight of evidence from Denmark (Lassen & Serritzlew 2011) and theoretical predictions (Dahl & Tufte 1973) suggest negative effects. A well-powered null result would also be a significant contribution.

## Primary Specification

Y_{it} = α_i + δ_{c(i),t} + β × Merged_{it} + ε_{it}

Where:
- Y_{it} = voter turnout (%) in municipality i at referendum t
- α_i = municipality FE
- δ_{c(i),t} = canton × year FE
- Merged_{it} = 1 if municipality i has merged by referendum date t
- Clustering: municipality level

## Planned Robustness Checks

1. **Event study:** Dynamic treatment effects with 5+ pre-treatment and 10+ post-treatment periods
2. **Pre-trend tests:** Formal F-test for joint significance of pre-treatment coefficients
3. **HonestDiD sensitivity:** Rambachan-Roth bounds under linear pre-trend violations
4. **Matching:** Propensity score matching on pre-merger characteristics (population, turnout level, language region, canton)
5. **Placebo outcomes:** Federal election turnout (less frequent, different participation incentives)
6. **Heterogeneity analyses:**
   - By merger size (number of constituent municipalities)
   - By pre-merger population (small vs. medium municipalities)
   - By language region (German vs. French vs. Italian)
   - By Gemeindeversammlung vs. ballot-box cantons
   - By vote closeness (competitive vs. lopsided referenda)
7. **Intensive margin:** Effect on blank/invalid ballot share (protest voting)
8. **Dynamic effects:** Does turnout decline immediately or gradually?
9. **Cantonal merger incentive programs as instruments** (supplementary)

## Exposure Alignment (DiD Requirements)

- **Who is treated?** Municipalities that undergo a merger event (dissolved or restructured)
- **Primary estimand population:** All Swiss municipalities in the panel, with 931 treated (dissolved) + surviving merger partners
- **Control population:** ~1,170 never-merged municipalities
- **Design:** Staggered DiD with Callaway & Sant'Anna estimator

## Power Assessment

- **Pre-treatment periods:** 10–20 years (referendum data from 1981, most mergers 2000–2020)
- **Treated clusters:** 352 merger events involving 931 municipalities
- **Post-treatment periods per cohort:** 5–24 years depending on merger timing
- **Baseline turnout:** ~45% (Swiss federal referenda average)
- **MDE:** With ~2,100 municipalities, 4+ referenda/year, and ~45% baseline turnout, we can detect effects of ~1–2 percentage points. Well-powered for economically meaningful effects.

## Data Sources

1. **Treatment (mergers):** BFS AGVCH Mutations API — precise merger dates, municipality crosswalk
2. **Outcome (turnout):** swissdd R package — municipal referendum results since 1981
3. **Controls (population):** BFS PXWeb — municipal population 2010–2024; pre-2010 from census/intercensal estimates
4. **Covariates:** Language region, canton, urban/rural typology from BFS
