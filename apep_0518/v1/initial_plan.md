# Initial Research Plan — apep_0518

## Research Question

Does losing place-based priority neighborhood status reduce local economic activity, and does designation of new priority neighborhoods create net new activity or merely relocate it from areas that lost status?

## Policy Background

In 2014, France replaced its Zones Urbaines Sensibles (ZUS, established 1996) with a new geography of Quartiers Prioritaires de la Politique de la Ville (QPV). The redesignation was mandated by the Lamy Law (February 2014) and took effect January 1, 2015.

- **Old system:** 751 ZUS neighborhoods identified using composite socioeconomic indicators
- **New system:** 1,514 QPV neighborhoods identified using 200m grid-based low-income concentration
- **Key variation:** Some former ZUS lost status (not covered by any QPV), others transitioned (ZUS→QPV), and new areas were designated as QPV for the first time

Priority neighborhood status brings: Contrats de Ville operational funding (~€400M/year total), ANRU urban renovation investment (€12B total NPNRU), emplois francs hiring subsidies, and (for the 100 ZFU neighborhoods) tax exemptions.

## Identification Strategy

### Primary Design: Panel DiD

**Treatment group:** Former ZUS neighborhoods that lost priority status (no QPV overlap)
**Control group:** Former ZUS neighborhoods that transitioned to QPV (kept status)

Both groups were treated under the old system, ensuring pre-treatment comparability. The key advantage: comparing within formerly-treated neighborhoods eliminates confounds from never-treated areas being systematically different.

**Pre-treatment period:** 2010-2014 (5 years, using SIRENE firm creation data)
**Post-treatment period:** 2015-2024 (10 years)

Treatment assignment is determined by spatial intersection of ZUS and QPV shapefiles — neighborhoods where ZUS polygons have zero or minimal overlap with QPV polygons are coded as "lost status."

### Classification of Neighborhoods

Using spatial overlay (sf::st_intersection in R):

1. **Lost status (treatment):** ZUS area with <10% overlap with any QPV polygon
2. **Kept status (control):** ZUS area with ≥50% overlap with QPV polygon
3. **Gained status (new QPV):** QPV area with <10% overlap with any ZUS polygon
4. **Never treated:** Areas in neither ZUS nor QPV (for triple-difference if needed)

The 10%/50% thresholds avoid ambiguous partial-overlap cases. Sensitivity analysis varies these thresholds.

### Displacement Test

The paper's central contribution: simultaneously estimate effects for neighborhoods that LOST status and neighborhoods that GAINED status. If total firm creation across all former-ZUS + new-QPV neighborhoods is unchanged, the policy merely relocated activity (pure displacement). If total firm creation increased, the policy created net new activity.

## Expected Effects and Mechanisms

**Hypothesis 1:** Neighborhoods losing priority status experience reduced firm creation
- Mechanism: loss of public investment, hiring subsidies, and symbolic "priority" label that may attract firms
- Direction: negative effect on firm creation rate

**Hypothesis 2:** Newly designated QPV neighborhoods experience increased firm creation
- Mechanism: gain of same benefits
- Direction: positive effect on firm creation rate

**Hypothesis 3:** The net effect across all neighborhoods is zero (pure displacement)
- This is the null that the displacement test targets
- Rejecting it in either direction is informative

## Primary Specification

$$Y_{it} = \alpha_i + \gamma_t + \beta \cdot \text{LostStatus}_i \times \text{Post}_t + X_{it}'\delta + \varepsilon_{it}$$

Where:
- $Y_{it}$ = annual firm creation count (or log+1) in neighborhood $i$, year $t$
- $\alpha_i$ = neighborhood fixed effects
- $\gamma_t$ = year fixed effects
- $\text{LostStatus}_i$ = 1 if ZUS neighborhood lost priority status
- $\text{Post}_t$ = 1 if $t \geq 2015$
- $X_{it}$ = time-varying controls (commune population, regional GDP)

Event-study specification for dynamic effects:
$$Y_{it} = \alpha_i + \gamma_t + \sum_{k=-4}^{9} \beta_k \cdot \text{LostStatus}_i \times \mathbb{1}[t = 2015 + k] + \varepsilon_{it}$$

Normalized to $k = -1$ (2014).

## Planned Robustness Checks

1. **Pre-trend test:** Joint F-test on pre-treatment event-study coefficients ($\beta_{-4}, \beta_{-3}, \beta_{-2}$)
2. **HonestDiD sensitivity:** Rambachan-Roth bounds on treatment effects under plausible pre-trend violations
3. **Placebo timing:** Assign treatment at 2012 or 2013 and verify null effects
4. **Placebo outcome:** Firm creation in sectors unaffected by QPV programs (agriculture, public administration)
5. **ZFU exclusion:** Drop 100 ZFU neighborhoods from main sample; analyze separately
6. **Entropy balancing:** Match lost-status and kept-status neighborhoods on pre-2014 firm counts, population, income, sector composition
7. **Spatial buffers:** Ring analysis at 500m, 1km, 2km, 5km from neighborhood boundaries
8. **Alternative overlap thresholds:** Vary the 10%/50% overlap cutoffs
9. **Poisson regression:** As alternative to OLS for count outcomes
10. **Net displacement test:** Sum effects across lost-status + gained-status neighborhoods

## Exposure Alignment (DiD Requirements)

- **Who is actually treated?** Firms and potential firms in former ZUS neighborhoods that lost priority status
- **Primary estimand population:** Neighborhoods that lost ZUS status (expected N ~200-400)
- **Control population:** Neighborhoods that kept status (ZUS→QPV, expected N ~300-400)
- **Pre-treatment periods:** 5 (2010-2014)
- **Post-treatment periods per cohort:** 10 (2015-2024)
- **Design:** Standard 2-period DiD with event-study dynamics

## Power Assessment

- **Treated clusters:** ~200-400 neighborhoods (to be confirmed after spatial overlay)
- **Control clusters:** ~300-400 neighborhoods
- **Pre-treatment periods:** 5
- **Post-treatment periods:** 10
- **MDE:** With 200 treated units and typical within-neighborhood firm creation variance, we can detect effects of ~15-20% changes in firm creation rate (will compute formal MDE after data assembly)

## Data Sources

| Data | Source | Access | Coverage |
|------|--------|--------|----------|
| QPV boundaries (2015) | data.gouv.fr / sig.ville.gouv.fr | Open, shapefile | National |
| ZUS boundaries | data.gouv.fr | Open, shapefile | National |
| ZFU boundaries | data.gouv.fr | Open, shapefile | National (100 zones) |
| SIRENE establishments | data.gouv.fr (parquet) | Open, bulk download | All firms since 1973 |
| DVF transactions (geocoded) | data.gouv.fr | Open, CSV | 2020-2025 (geocoded) |
| Commune characteristics | INSEE BDM/SDMX | Open, REST API | Annual |

## Code Structure

```
code/
├── 00_packages.R          # Libraries and themes
├── 01_fetch_data.R         # Download shapefiles, SIRENE, DVF, BDM
├── 02_clean_data.R         # Spatial overlay, treatment assignment, panel construction
├── 03_main_analysis.R      # DiD, event study, displacement test
├── 04_robustness.R         # All robustness checks
├── 05_figures.R            # Event-study plots, maps, displacement diagram
├── 06_tables.R             # Regression tables, summary statistics
```
