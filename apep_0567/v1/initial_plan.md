# Initial Research Plan: Protecting Landscapes, Punishing Renters

## Research Question

Did Switzerland's 2012 Second Homes Initiative (Lex Weber), which banned new vacation home construction in municipalities where second homes exceed 20% of housing stock, unintentionally tighten rental markets and displace local residents?

## Institutional Background

On March 11, 2012, Swiss voters narrowly approved (50.6%) the Zweitwohnungsinitiative, amending Constitution Art. 75b. The initiative was sponsored by environmental group Helvetia Nostra. Polls predicted defeat; the narrow margin makes anticipatory effects unlikely.

**Treatment:** ~400 municipalities in Alpine tourism regions (Graubünden, Valais, Bern Oberland, Ticino, Vaud Alps) where second-home share exceeds 20% were banned from issuing new vacation home permits.

**Timeline:**
- March 11, 2012: Referendum passes
- January 1, 2013: Emergency ordinance takes effect
- January 1, 2016: ZWG federal act enters force

**Mechanism (hypothesized):** Restricting vacation-home construction reduces total housing supply → tighter rental market → higher vacancy costs → population displacement of lower-income renters → employment decline in service sectors.

## Identification Strategy

### Exposure Alignment

- **Who is treated:** Municipalities with second-home share >20%, where new vacation home permits are banned
- **Affected population:** Local renters and residents in treated municipalities who face tighter housing markets due to reduced construction
- **Placebo/control population:** Municipalities below 20% threshold, unaffected by the ban
- **Design:** DiD (not DDD)

### Primary Design: Sharp DiD

- **Treatment group:** Municipalities with second-home share >20% (banned from new vacation construction)
- **Control group:** Municipalities with second-home share ≤20% (unaffected)
- **Treatment timing:** 2013 (emergency ordinance)
- **Pre-period:** 1990–2012 (22 years for vacancy data)
- **Post-period:** 2013–2023 (11 years)
- **Estimator:** Callaway & Sant'Anna (2021) for robustness to heterogeneity; TWFE as baseline

### Complementary Design: RDD at 20% Threshold

- **Running variable:** Second-home share as measured by ARE Wohnungsinventar
- **Cutoff:** 20%
- **Estimand:** LATE for municipalities just above vs. just below threshold
- **Bandwidth:** Data-driven (Calonico, Cattaneo, Titiunik 2014)

### Built-in Placebos

1. **Non-tourism municipalities above 20%:** Some municipalities have high second-home shares for non-tourism reasons (military, seasonal workers). These should show weaker effects if the mechanism is tourism-construction restriction.
2. **Commercial construction:** Lex Weber restricts residential vacation homes only. Commercial construction permits should be unaffected → placebo outcome.
3. **Pre-2012 placebo timing:** Run the same DiD specification pretending treatment occurred in 2005 → should yield null.

## Expected Effects and Mechanisms

| Outcome | Expected Sign | Mechanism |
|---------|--------------|-----------|
| Vacant dwellings (vacancy rate) | Negative (fewer vacancies) | Reduced total construction tightens market |
| Population growth | Negative | Fewer housing units → displacement |
| Employment (total) | Negative | Population decline → reduced local demand |
| Employment (hospitality NOGA 55/56) | Ambiguous | Tourism may be unaffected; construction and real estate decline |
| Building permits | Negative | Direct treatment effect (verified by Deville 2022) |

## Primary Specification

$$Y_{mt} = \alpha_m + \gamma_t + \beta \cdot \text{Treated}_m \times \text{Post}_t + X_{mt}\delta + \varepsilon_{mt}$$

Where:
- $Y_{mt}$: vacancy rate, log population, log employment in municipality $m$, year $t$
- $\text{Treated}_m = 1$ if second-home share >20%
- $\text{Post}_t = 1$ if $t \geq 2013$
- $\alpha_m, \gamma_t$: municipality and year fixed effects
- $X_{mt}$: time-varying controls (optional; main spec without)

Cluster standard errors at canton level (26 clusters) + wild bootstrap.

## Planned Robustness Checks

1. **Parallel trends:** Event-study with 22 pre-treatment leads
2. **RDD at 20% cutoff:** Local polynomial estimation
3. **Donut DiD:** Exclude municipalities within 2pp of cutoff (18%–22%)
4. **Leave-one-canton-out:** Drop each treated canton iteratively
5. **Randomization inference:** Permute treatment across municipalities
6. **Alternative treatment timing:** Use 2016 (ZWG) instead of 2013
7. **Placebo outcomes:** Commercial construction permits
8. **Placebo timing:** Pre-2012 fake treatment
9. **Continuous treatment intensity:** Second-home share as continuous treatment
10. **Wild cluster bootstrap** (26 canton clusters)

## Data Sources

| Source | Variables | Coverage | Access |
|--------|-----------|----------|--------|
| BFS Leerwohnungszählung | Vacant dwellings by municipality | 1990–2023 | Cantonal portals (CSV) |
| BFS PxWeb (demographics) | Population by municipality | 1971–2024 | REST API |
| BFS STATENT | Employment by municipality × NOGA sector | 2011–2023 | PxWeb API |
| ARE Wohnungsinventar | Second-home share by municipality | Current | geo.admin.ch REST API |
| opendata.swiss | Building permits by canton/municipality | Varies | CKAN API |
| SMMT | Municipal merger mapping | Complete | Download |

## Analysis File Structure

```
code/
├── 00_packages.R
├── 01_fetch_data.R        # Download all BFS/ARE data
├── 02_clean_data.R        # Harmonize municipalities (SMMT), construct panels
├── 03_main_analysis.R     # DiD + RDD + event studies
├── 04_robustness.R        # All robustness checks
├── 05_figures.R           # All figures
└── 06_tables.R            # All tables
```
