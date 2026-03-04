# Initial Research Plan — apep_0503

## Exposure Alignment

**Who is treated:** Properties with DPE energy score above each cutoff receive the worse label (and at regulatory cutoffs, face the rental ban). Treatment is sharp: the label changes discretely at the threshold. The affected population is energy-bound properties (81.7% of sample) near each cutoff. Owner-occupiers are indirectly affected (loss of rental option value); landlords/investors are directly affected. This is a multi-cutoff RDD, not a DiD design.

## Research Question

Does the capitalization of energy efficiency labels into property prices reflect information salience, regulatory constraints, or forward-looking anticipation of announced future bans? Specifically: how does France's phased rental ban based on DPE (Diagnostic de Performance Énergétique) labels — banning class G from rental in 2023, with announced bans on F (2028) and E (2034) — affect property transaction prices at each label threshold?

## Identification Strategy

**Multi-cutoff sharp Regression Discontinuity Design (RDD)** exploiting the discrete jumps in regulatory status at DPE band boundaries.

**Running variable:** Primary energy consumption per m² per year (kWh/m²/year), as measured in the DPE assessment. This is a continuous variable that determines the discrete DPE label (A through G).

**Cutoffs and treatments:**

| Boundary | Cutoff (kWh/m²/year) | Treatment difference | Channel |
|----------|---------------------|---------------------|---------|
| G/F | 420 | G: banned from rental (2023/2025). F: legal. | **Active regulation** |
| F/E | 330 | F: announced ban (2028). E: announced ban (2034). | **Near-term anticipation** |
| E/D | 250 | E: announced ban (2034). D: no ban. | **Distant anticipation** |
| D/C | 180 | No regulatory difference. | **Information/salience only** |
| C/B | 110 | No regulatory difference. | **Information/salience only** |
| B/A | 70 | No regulatory difference. | **Information/salience only** |

**Key identifying assumption:** Properties just above and just below each cutoff are comparable in all relevant characteristics except the DPE label and its associated regulatory status. The DPE score is determined by physical building characteristics (insulation, heating system, glazing) and cannot be precisely manipulated by property owners.

**Built-in placebo:** Owner-occupied properties face no rental ban regardless of DPE class. If the price discontinuity at G/F is driven by the regulatory prohibition rather than information alone, it should appear for properties in high-rental-share communes but NOT for properties predominantly in owner-occupied use.

## Expected Effects and Mechanisms

### Primary hypothesis
Properties just below the G/F cutoff (banned from rental) should trade at a discount relative to properties just above (F, legal to rent), reflecting the lost rental income stream. This "regulatory capitalization" should exceed any pure information/salience effect observed at non-regulatory cutoffs (D/C, C/B, B/A).

### Anticipation hypothesis
Properties in class F (announced 2028 ban) should show an intermediate price discount relative to class E — smaller than the G discount (ban is further away, discounted) but larger than non-regulatory label effects (some forward-looking pricing).

### Mechanism decomposition
1. **Information channel:** Price differences at all cutoffs, including D/C, C/B, B/A (where no regulation exists) — pure label salience as in Sejas-Portillo et al. (2025).
2. **Regulatory channel:** Excess price difference at G/F beyond the information effect — attributable to the rental ban.
3. **Anticipation channel:** Price difference at F/E and E/D — forward-looking market response to announced future bans.

### Substitution/displacement hypothesis
The rental ban may cause landlords to sell G-rated properties rather than renovate, creating:
- Higher transaction volumes for G-rated properties (testable with DVF volume data)
- Price depression for G-rated properties beyond the regulatory discount (excess supply)
- Possible price increases for E-rated and D-rated properties (demand substitution from banned stock)

## Primary Specification

For each cutoff $c$, estimate:

$$\tau_c = \lim_{x \downarrow c} E[Y_i | X_i = x] - \lim_{x \uparrow c} E[Y_i | X_i = x]$$

where $Y_i$ is log transaction price per m² and $X_i$ is energy consumption per m² (kWh/m²/year).

Implementation using local polynomial regression:
- **Estimator:** `rdrobust` (Cattaneo, Idrobo & Titiunik 2020) with triangular kernel
- **Bandwidth:** MSE-optimal (Imbens & Kalyanaraman 2012), with CER-optimal as robustness
- **Polynomial order:** Local linear (p=1, following Gelman & Imbens 2019)
- **Inference:** Robust bias-corrected confidence intervals (Cattaneo, Jansson & Ma 2020)
- **Covariates:** Surface area, year of construction, building type, commune fixed effects (as in Cattaneo et al. 2019 covariate-adjusted RDD)

### Multi-cutoff pooled estimation
Normalize running variable as distance-to-cutoff for each boundary. Pool observations across cutoffs with cutoff fixed effects. Test whether the discontinuity at regulatory cutoffs (G/F, F/E) significantly exceeds the discontinuity at non-regulatory cutoffs (D/C, C/B, B/A).

## Planned Robustness Checks

1. **McCrary density test** at each cutoff — manipulation testing
2. **Covariate balance** at cutoffs — pre-determined property characteristics should be smooth
3. **Bandwidth sensitivity** — half/double optimal bandwidth
4. **Donut RDD** — exclude ±5 and ±10 kWh/m² around cutoffs
5. **Polynomial order** — quadratic (p=2) as alternative
6. **Placebo cutoffs** — artificial cutoffs at midpoints between real cutoffs
7. **Owner-occupied placebo** — no regulatory effect expected
8. **Pre-ban vs. post-ban comparison** — pre-2023 DPE assessments at G/F cutoff
9. **Energy-bound vs. GHG-bound** — heterogeneity by binding dimension
10. **Heaping/rounding corrections** — Barreca et al. (2016) if integer clustering detected

## Double-Seuil Strategy

Under the post-2021 DPE, properties are classified by the WORSE of energy consumption (kWh/m²/year) and GHG emissions (kg CO₂eq/m²/year).

**Primary analysis:** Focus on energy-bound properties (where `etiquette_dpe` matches the class implied by `conso_5_usages_par_m2_ep` alone). These properties have a univariate running variable.

**Secondary analysis:** GHG-bound properties analyzed separately with GHG emissions as running variable.

**Heterogeneity:** Binding dimension reveals heating system type (electric → likely energy-bound; gas/oil/coal → may be GHG-bound), enabling mechanism analysis of how fuel type interacts with the rental ban.

## Power Assessment

- **G-rated DPE assessments:** 504K properties
- **F-rated DPE assessments:** 879K properties
- **Properties near G/F cutoff (±20 kWh/m²):** Expected >100K observations
- **DVF transactions linked to DPE:** Expected linkage rate ~20-40% (DPE required for sale transactions since 2006)
- **Effective N near cutoff:** Expected 20K-50K transactions within optimal bandwidth — extremely well-powered
- **MDE:** With this sample size and local polynomial estimation, we can detect effects as small as 0.5-1% of property value

## Data Sources

| Source | Content | Access | Records |
|--------|---------|--------|---------|
| ADEME DPE (post-2021) | Individual DPE assessments | API (data.ademe.fr) | 14.17M |
| DVF (2019-2025) | Property transactions | Bulk CSV (data.gouv.fr) | ~5M/year |
| ADEME DPE (pre-2021) | Historical DPE assessments | API (data.ademe.fr) | 10.73M |
| INSEE commune data | Demographics, rental share | SDMX/BDM | All communes |

## Analysis Scripts

| Script | Purpose |
|--------|---------|
| `00_packages.R` | Load libraries, set themes |
| `01_fetch_data.R` | Download DPE + DVF + commune data |
| `02_clean_data.R` | Link DPE to DVF, construct variables, identify binding dimension |
| `03_main_analysis.R` | Multi-cutoff RDD estimation |
| `04_robustness.R` | McCrary, donut, bandwidth, placebos |
| `05_figures.R` | RDD plots, density plots, mechanism figures |
| `06_tables.R` | Main results, robustness, heterogeneity tables |
