# Research Plan: The Metro Before the Metro

## Research Question

When do property markets capitalize long-gestation transit infrastructure — at announcement, during construction, or only at service opening? We decompose the total capitalization of Europe's largest metro expansion (Grand Paris Express) into three phases using the universe of property transactions in Ile-de-France from 2014 to 2025.

## Identification Strategy

**Design:** Spatial difference-in-differences with staggered treatment timing.

**Treatment definition:** A property is "treated" if it lies within distance ring d of a GPE station, where d = {0.5, 1.0, 1.5} km. Treatment onset is defined at three milestones per station:
- (a) DUP / route confirmation (2015-2017)
- (b) Construction start — TBM launch or civil works commencement at nearest station (2018-2023)
- (c) Opening to passengers (2024-2031)

**Control units:** Properties in IDF departments >2km from any GPE station. Secondary controls: properties near existing metro stations (already capitalized, no additional premium expected).

**Estimator:** Callaway & Sant'Anna (2021) for group-time ATTs, aggregated to event-time. Given the continuous treatment (distance), we also estimate distance-gradient hedonic models.

**Key identification assumptions:**
1. Parallel trends in transaction prices between near-station and far-from-station properties within IDF, conditional on hedonic controls. Testable with 4+ pre-construction years (2014-2018).
2. No anticipation: DUP dates are observable; we define treatment at construction start as the main specification. Announcement effects tested as a separate specification.
3. SUTVA: 2km buffer between treatment and control rings provides spatial separation.

**Exposure Alignment:**
- Treated: Property buyers/sellers near GPE stations
- Primary estimand: ATT on log transaction price per m2
- Placebo population: Properties near delayed lines (opening 2028+) during 2014-2025 window
- Design: Staggered spatial DiD

**Power Assessment:**
- Pre-treatment periods: 4-5 years (2014-2018) before construction milestones
- Treated clusters: ~45-50 communes near GPE stations
- Post-treatment periods: 2-7 years per cohort (depending on milestone timing)
- MDE: With ~50K treated transactions and ~500K control transactions, power is excellent

## Expected Effects and Mechanisms

**Hypotheses:**
- H1: Announcement/DUP phase: Modest positive capitalization (5-10% within 500m), reflecting expected future access improvement discounted by uncertainty and long time horizon
- H2: Construction phase: Ambiguous — construction disamenities (noise, traffic disruption) may partially offset continued capitalization from uncertainty resolution
- H3: Opening phase: Sharp positive jump as service becomes real — the "last mile" of capitalization

**Mechanisms:**
1. Information/uncertainty resolution: As construction milestones are reached, uncertainty about project completion diminishes, shifting capitalization forward
2. Construction externalities: Noise, dust, traffic disruption create temporary negative shocks near active construction sites
3. Commercial development: Businesses anticipate foot traffic — SIRENE establishment creation may lead residential capitalization
4. Demographic sorting: Higher-income buyers may enter the market near stations before opening, shifting the composition of transactions

## Primary Specification

```
log(price_m2)_{it} = alpha_i + gamma_t + beta * Treatment_{it} + X_{it}' delta + epsilon_{it}
```

Where:
- i indexes commune (or IRIS), t indexes year-quarter
- Treatment_{it} = 1 if property within d km of a station that has reached milestone m by quarter t
- X_{it} = hedonic controls (surface area, rooms, property type, floor)
- Clustering at commune level

**CS-DiD specification:** Group = commune × milestone quarter, with group-time ATTs aggregated to event-time.

## Planned Robustness Checks

1. **Distance rings:** 0.5km, 1.0km, 1.5km treatment definitions
2. **Sun & Abraham (2021):** Interaction-weighted estimator as alternative to CS
3. **Repeat-sales subsample:** Same property sold twice in the panel — eliminates hedonic composition concerns
4. **Rambachan-Roth/HonestDiD:** Sensitivity to pre-trend violations
5. **Placebo lines:** Properties near lines opening 2028+ should show no opening premium during sample
6. **Leave-one-line-out:** Drop each GPE line to test sensitivity to individual lines
7. **Existing metro placebo:** Properties near existing metro stations should show no change during GPE construction
8. **Wild cluster bootstrap:** For inference with ~45 commune clusters

## Data Sources

| Source | Coverage | Access | Key Fields |
|--------|----------|--------|------------|
| CEREMA DVF+ | 2014-2025, universe transactions | Open (datafoncier.cerema.fr) | Price, coordinates, surface, type, date |
| SmartIDF | 69 GPE stations | Open API | Station name, line, GPS coordinates |
| SGP/Herrenknecht | Construction milestones | Public reports | TBM launch dates, breakthrough dates |
| INSEE SIRENE | Establishment registry | API (key configured) | Creation/closure dates, sector, commune |
| Airparif | Air quality 2014-2025 | Open API | PM2.5, NO2 by monitoring station |

## Paper Architecture

1. Introduction: When does infrastructure shape markets? The timing puzzle.
2. Institutional Background: The Grand Paris Express — timeline, scale, political economy
3. Data: DVF+, station coordinates, construction milestones
4. Empirical Strategy: Spatial DiD with multi-milestone treatment
5. Results: Phase decomposition — announcement, construction, opening effects
6. Mechanisms: Firm entry, composition shifts, air quality
7. Robustness: Alternative rings, estimators, placebos
8. Welfare Implications: Value capture, project financing, distributional effects
9. Conclusion
