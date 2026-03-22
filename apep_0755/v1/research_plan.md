# Research Plan: Does Your Block Determine Your Score?

## Research Question

Does Colombia's estrato classification system — which assigns every urban city block a socioeconomic ranking from 1 to 6 — causally sort schools and students, creating discontinuous jumps in educational outcomes at estrato boundaries? We decompose the total boundary effect into a **subsidy channel** (utility cost differentials induce residential sorting) and a **label channel** (estrato identity creates stigma/aspiration effects), using the 5|6 boundary as a built-in placebo where both sides pay surcharges.

## Identification Strategy

**Spatial multi-cutoff RDD** at estrato boundaries within cities. The running variable is distance from each school's manzana to the nearest estrato boundary. Treatment is crossing from estrato *k* to estrato *k*+1.

Key design features:
1. **Multi-cutoff structure**: Five boundaries (1|2, 2|3, 3|4, 4|5, 5|6) with heterogeneous subsidy intensity
2. **Built-in placebo**: The 5|6 boundary is a pure-label test — both pay surcharges
3. **Within-municipality comparison**: Municipality fixed effects ensure we compare schools in the same local labor/housing market
4. **Covariate balance**: ICFES microdata provides rich student/household controls (parental education, internet access, computer ownership)

For V1, we simplify the spatial component: instead of exact geographic distances, we aggregate to school-level mean outcomes and use student-reported estrato as the discrete running variable within municipalities, following Lee & Card (2008) on RDD with discrete running variables. We identify boundary schools as those drawing students from adjacent estratos.

## Expected Effects and Mechanisms

- **Subsidy channel**: Estratos 1-3 receive utility subsidies (60%/40%/15%); this reduces living costs in low-estrato areas, attracting lower-income families → lower school inputs → lower test scores. Effect should be largest at the 3|4 boundary (largest subsidy discontinuity: 15% subsidy → 0%).
- **Label channel**: Estrato labels may create stigma (employers, landlords) or aspiration effects. If present, the 5|6 boundary should show a discontinuity despite no subsidy differential.
- **Expected direction**: Positive score jumps at each boundary moving from lower to higher estrato. The magnitude should correlate with subsidy intensity.

## Primary Specification

$$Y_{i,s,m} = \alpha + \sum_{k=1}^{5} \beta_k \cdot \mathbb{1}[\text{estrato}_s > k] + f(d_{s,k}) + \gamma_m + X_i'\delta + \varepsilon_{i,s,m}$$

where $Y_{i,s,m}$ is the test score for student $i$ in school $s$ in municipality $m$, $d_{s,k}$ is the distance to boundary $k$, and $X_i$ are student covariates.

For V1 (discrete running variable approach):
$$Y_{i,s,m} = \alpha + \beta \cdot \mathbb{1}[\text{estrato}_s = k+1] + \gamma_m + X_i'\delta + \varepsilon_{i,s,m}$$

estimated separately for each boundary, restricting to schools drawing from estrato $k$ or $k+1$ within each municipality.

## Data Sources

1. **ICFES Saber 11**: 7.1M student records (2011-2022), SODA API on datos.gov.co (dataset kgxf-xxbe). Fields: test scores, student estrato, school DANE code, municipality, parental education, household assets.

2. **Manzana Estrato**: 407,851 urban blocks with predominant estrato classification from Esri Colombia ArcGIS feature service.

3. **DANE School Directory**: School locations by municipality from datos.gov.co.

## Fetch Strategy

1. Query ICFES API for Bogota (largest city, 43K manzanas) across all years
2. Query ICFES API for 3-5 additional major cities (Medellín, Cali, Barranquilla, Cartagena)
3. Download manzana estrato data for these cities from ArcGIS
4. Match schools to manzanas via municipality codes

## Robustness

- Bandwidth sensitivity (estrato ±1, ±2)
- Donut RDD (exclude boundary manzanas)
- Placebo cutoffs (test for discontinuities where there shouldn't be any)
- Covariate balance at boundaries
- Year-by-year stability
