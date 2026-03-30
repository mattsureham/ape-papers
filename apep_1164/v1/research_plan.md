# Research Plan: The Formalization Dividend

## Research Question

Does mass regularization of immigrants generate formalization spillovers on native workers? When Colombia's 2021 ETPV (Estatuto Temporal de Protección para Migrantes Venezolanos) granted 10-year work permits to ~1.8 million Venezuelan migrants — most working informally — did native informality rates decline in departments with higher Venezuelan concentration?

## Policy Background

Colombia's Decreto 216 (March 1, 2021) created the ETPV, granting Temporary Protection Status to Venezuelan nationals present before January 31, 2021. The Permiso por Protección Temporal (PPT) provides full labor market access, social security enrollment, and financial inclusion. By September 2022, over 1.4 million PPTs had been delivered. Prior to ETPV, ~90% of Venezuelan migrants worked informally. The regularization shifted these workers from informal to legal-eligible status, creating pressure on firms to formalize employment relationships.

## Identification Strategy

**Continuous-treatment difference-in-differences.** Cross-department variation in Venezuelan share of working-age population (ranging from <1% in Nariño/Cauca to >8% in Norte de Santander/La Guajira) interacted with the ETPV launch (March 2021).

**Treatment intensity:** Pre-ETPV (2019) Venezuelan share of working-age population by department, measured from GEIH Migration Module.

**Estimating equation:**
Y_idt = α_d + γ_t + β(VenShare_d × Post_t) + X_idt'δ + ε_idt

where Y_idt is a formality indicator for native worker i in department d at time t, VenShare_d is the pre-treatment Venezuelan share, Post_t indicates March 2021 onward, and X includes age, education, gender, sector.

**Primary specification:** Callaway-Sant'Anna with continuous treatment intensity, clustered at department level (24 clusters → wild cluster bootstrap).

## Expected Effects and Mechanisms

1. **Formalization spillover (positive):** Firms formalizing Venezuelan workers face fixed costs of compliance (registration, social security). Once these costs are sunk, marginal cost of formalizing additional (native) workers falls. Departments with more Venezuelans should see larger native formality gains.

2. **Competition channel (negative):** Newly formalized Venezuelans compete with natives for formal-sector jobs, potentially displacing natives into informality.

3. **Net prediction:** Ambiguous ex ante — this is what makes the question interesting. The formalization spillover is the novel mechanism; the competition channel is well-studied.

## Primary Specification

- **Outcome:** Native formality rate (pension contribution P6920 or health enrollment P6090)
- **Treatment:** Department-level Venezuelan share × Post-ETPV
- **Unit:** Individual native workers, monthly
- **Sample:** Colombian-born workers aged 18-65, 2019-2023
- **Clustering:** Department level (24 clusters, wild bootstrap)
- **Robustness:** Event study, placebo with low-Venezuelan departments, sector heterogeneity, triple-DiD by baseline informality

## Data Source and Fetch Strategy

**DANE GEIH (Gran Encuesta Integrada de Hogares):**
- Monthly household labor force survey, ~240K individual-month observations/year
- Catalog 701 on microdatos.dane.gov.co
- Variables: employment status, formality (P6920 pension, P6090 health), wages, hours, occupation, sector, department
- Download: Monthly CSV files, 2019-2023 (60 months)

**DANE Migration Module (Catalog 700):**
- Country of birth, nationality, years in Colombia
- Used to identify Venezuelan workers and construct treatment intensity

**Fetch approach:** Download GEIH microdata CSVs directly from DANE's microdata portal. Construct department-level Venezuelan shares from the Migration Module. Merge on department-month.
