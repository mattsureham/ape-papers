# Initial Research Plan — apep_0590

## Research Question

Does Mexico's Sembrando Vida agroforestry subsidy — which conditions payments on planting trees on "available" (non-forested) land — perversely increase deforestation? The design flaw is a textbook Peltzman effect: by requiring bare land for eligibility, the program may incentivize forest clearing to qualify.

## Identification Strategy

**Callaway-Sant'Anna DiD** exploiting staggered municipality-level rollout across three cohorts:
- **Cohort 1 (2019):** Original municipalities in 20 states (southern/southeastern Mexico)
- **Cohort 2 (2020):** Golden Triangle expansion (Chihuahua, Sinaloa, Durango)
- **Cohort 3 (2021):** Further expansion to remaining eligible municipalities

**Treatment assignment:** Municipalities with medium-to-very-high social marginalization (CONEVAL rezago social index) were eligible. Within eligible municipalities, rollout was staggered by administrative capacity and federal budget allocation — not by pre-existing deforestation trends.

**Control group:** Never-treated municipalities (those with low marginalization or not yet reached by the program).

**Key assumption:** Absent Sembrando Vida, treated and control municipalities would have followed parallel tree-cover-loss trajectories. Supported by 18 years of pre-treatment data (2001-2018).

## Expected Effects and Mechanisms

**Primary hypothesis:** Sembrando Vida increases annual tree cover loss in treated municipalities. The mechanism is the "available land" eligibility requirement — farmers clear existing forest to create bare plots eligible for the MXN 5,000/month subsidy.

**Expected magnitude:** WRI documented 73,000 hectares of anomalous forest loss in Sembrando Vida areas in 2019. Relative to baseline municipality-level annual loss of ~50-200 hectares, we expect a 20-50% increase.

**Heterogeneity predictions (theory-driven):**
1. Effects should be larger in municipalities with more remaining forest cover (more to clear)
2. Effects should be larger where subsidy represents a larger income share (poorer municipalities)
3. Effects should concentrate in tropical moist broadleaf forest (higher baseline tree density, easier to clear)
4. Effects should be smaller in dry/arid ecosystems (less forest to clear, less incentive)

## Primary Specification

$$Y_{it} = \text{ATT}(g,t) \text{ via Callaway-Sant'Anna}$$

Where:
- $Y_{it}$: Annual tree cover loss (hectares) in municipality $i$, year $t$
- $g$: Treatment cohort (2019, 2020, 2021)
- Control group: Never-treated municipalities
- Clustering: State level (23 treated states + controls)

## Exposure Alignment (DiD Required)

- **Who is actually treated?** Farmers in eligible municipalities who receive Sembrando Vida payments
- **Primary estimand population:** All municipalities receiving Sembrando Vida beneficiaries
- **Placebo/control population:** Municipalities never receiving Sembrando Vida (low marginalization)
- **Design:** Standard staggered DiD (not triple-diff)

## Power Assessment

- **Pre-treatment periods:** 18 (2001-2018)
- **Treated clusters:** ~995 municipalities across 23 states
- **Post-treatment periods:** 3-5 per cohort (2019-2024)
- **Total observations:** ~2,400 municipalities × 24 years ≈ 57,600

This is a well-powered design: large number of treated and control units, long pre-period.

## Planned Robustness Checks

1. **Placebo treatment at 2015:** Fake treatment 4 years early should show no effect
2. **Rambachan-Roth HonestDiD sensitivity:** Bound estimates under violations of parallel trends
3. **Dose-response:** Within treated municipalities, effects should scale with beneficiary density
4. **Leave-one-state-out:** Verify no single state drives results
5. **Alternative outcome:** Tree cover loss as % of baseline tree cover (accounts for scale differences)
6. **TWFE comparison:** Show Goodman-Bacon decomposition to illustrate why CS-DiD is necessary
7. **Ecosystem heterogeneity:** Tropical vs. dry vs. temperate forest responses

## Data Sources

| Source | Variables | Coverage |
|--------|-----------|----------|
| Hansen/UMD GFW v1.12 | Annual tree cover loss (30m) | 2001-2024, all Mexico |
| CONEVAL | Marginalization index, poverty | Municipality-level, periodic |
| Sembrando Vida/Bienestar | Beneficiary counts by municipality | 2019-2023 |
| INEGI | Municipality boundaries (shapefiles) | Current |

## Workflow

1. `00_packages.R` — Load libraries, set themes
2. `01_fetch_data.R` — Download GFW tiles, CONEVAL, beneficiary data
3. `02_clean_data.R` — Zonal statistics, panel construction, treatment assignment
4. `03_main_analysis.R` — CS-DiD, event study, aggregate ATT
5. `04_robustness.R` — Placebo, HonestDiD, dose-response, leave-one-out, Bacon decomposition
6. `05_figures.R` — Event study plot, treatment map, heterogeneity figures
7. `06_tables.R` — Summary stats, main results, robustness, heterogeneity
