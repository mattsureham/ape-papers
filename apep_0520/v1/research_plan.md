# Initial Research Plan: Does Coverage Create Capacity?

## Research Question

Does lifting the Institutions for Mental Diseases (IMD) exclusion through Section 1115 SUD demonstration waivers increase the supply of behavioral health providers billing Medicaid? Specifically: does the waiver expand treatment capacity at the extensive margin (new provider entry), the intensive margin (more patients per provider), or both — and does expansion reach high-need areas?

## Background

For over 50 years, the IMD exclusion prohibited federal Medicaid payments for inpatient psychiatric or substance use disorder treatment in facilities with more than 16 beds. Beginning in 2017, CMS allowed states to obtain Section 1115 waivers exempting them from this exclusion, enabling Medicaid coverage of residential SUD treatment in IMDs for the first time.

By 2024, approximately 37 states had received CMS approval, with staggered adoption from 2017 to 2024. This creates clean quasi-experimental variation: states adopted at different times, and a group of states never received waivers during the data window.

The existing literature (Maclean et al. 2020; Wen et al. 2022; Saloner et al.) shows that SUD waivers increased Medicaid enrollment in SUD treatment and reduced ED visits. But all prior work uses demand-side data. No study has examined whether the waiver actually expanded the SUPPLY of treatment providers — the binding constraint in the opioid crisis.

## Identification Strategy

**Design:** Staggered difference-in-differences using the Callaway & Sant'Anna (2021) estimator.

**Treatment:** State × month of CMS 1115 SUD waiver approval. Binary: 0 before approval, 1 from approval month onward.

**Unit of observation:** State × month (Jan 2018 – Dec 2024, 84 months).

**Treatment group:** States receiving 1115 SUD waivers from January 2019 onward (ensuring ≥12 months pre-treatment). ~20–25 states.

**Control group:** (a) Never-treated states (~13 states that had not received SUD waivers by Dec 2024); (b) Not-yet-treated states (standard CS-DiD approach).

**Always-treated exclusion:** States approved before January 2019 (Virginia, Indiana, Kentucky, Maryland, West Virginia, California, Utah, etc.) are excluded from ATT estimation due to insufficient pre-treatment data. Included in robustness checks.

## Expected Effects and Mechanisms

**Primary hypothesis:** SUD waivers increase behavioral health provider supply in Medicaid by enabling IMD-based facilities to bill Medicaid for the first time.

**Expected sign:** Positive — more providers, more claims, more beneficiaries served.

**Mechanisms:**
1. **Extensive margin (provider entry):** New organizational NPIs (IMD-based SUD treatment facilities) begin billing H-codes after the waiver.
2. **Intensive margin (caseload expansion):** Existing behavioral health providers increase beneficiary volume as newly-covered patients access treatment.
3. **Geographic reallocation:** New providers disproportionately enter high-opioid-mortality areas where demand was previously unmet by Medicaid.
4. **Cross-code composition:** Share of SUD-specific H-codes (H0010–H0050) increases relative to general behavioral health H-codes.

**Possible null interpretations:**
- Workforce shortage prevents expansion regardless of payment policy.
- Providers were already billing through alternative codes/mechanisms.
- Waiver bite is delayed or too small to detect.

## Primary Specification

$$Y_{st} = \alpha_s + \gamma_t + \beta \cdot \text{Waiver}_{st} + \varepsilon_{st}$$

Where:
- $Y_{st}$: outcome in state $s$, month $t$ (log active behavioral health providers, log total H-code claims, log beneficiaries served)
- $\alpha_s$: state fixed effects
- $\gamma_t$: month fixed effects
- $\text{Waiver}_{st}$: binary indicator (1 from CMS approval month onward)

Estimated via CS-DiD with group-time ATTs aggregated by event time.

**Clustering:** State level (primary). Wild cluster bootstrap and randomization inference as robustness.

## Planned Robustness Checks

1. **Bacon decomposition** — assess 2×2 DiD weight contributions
2. **Stacked cohort design** — alternative to CS-DiD (Sun & Abraham 2021)
3. **HonestDiD/Rambachan-Roth** — sensitivity to pre-trend violations
4. **Include always-treated states** — show results stable when adding early adopters
5. **Exclude COVID period** — drop March 2020–December 2020 and show results hold
6. **State-specific linear trends** — absorb gradual T-MSIS reporting improvements
7. **Restrict to high DQ states** — subset to states with good T-MSIS data quality
8. **Per-capita normalization** — outcomes per 1,000 Medicaid enrollees (using CMS enrollment data)

## Pre-Registered Placebo Battery

1. **Personal care T-codes** (T1019, T2016, S5125): HCBS services unrelated to SUD. Expect null.
2. **Dental providers** (D-code NPIs): Unrelated clinical specialty. Expect null.
3. **Never-treated pseudo-events:** Randomly assign pseudo-treatment dates to control states. Expect null.

## Mechanism Decomposition

1. **Extensive vs. intensive margin:** Decompose total claims growth into (a) new NPI entry and (b) claims per existing NPI.
2. **Provider type:** Organizational (entity type 2, likely IMD facilities) vs. individual (entity type 1, likely counselors/therapists).
3. **Geographic targeting:** Interact waiver with county-level opioid mortality quartiles (CDC WONDER / CDC PLACES).
4. **MAT drugs:** Separately estimate effects on J0571–J0575 (buprenorphine) and J2315 (naltrexone/Vivitrol) prescribing.

## Data Sources

| Source | Purpose | Access |
|--------|---------|--------|
| T-MSIS Medicaid Provider Spending | Main outcome: provider supply, claims, beneficiaries | Local Parquet (2.74 GB) |
| NPPES | State, ZIP, entity type, taxonomy, enumeration date | Bulk CSV (free) |
| CMS/KFF 1115 Waiver Tracker | Treatment timing: waiver approval dates | Web (public) |
| Census ACS | State population denominators, demographics | API (CENSUS_API_KEY) |
| CDC PLACES | County opioid mortality, chronic disease prevalence | Socrata (free) |
| FRED | State unemployment rate, macro controls | API (FRED_API_KEY) |
| BLS QCEW | Healthcare employment by state-quarter | Direct CSV (free) |

## Code Pipeline

- `00_packages.R` — Load libraries
- `01_fetch_data.R` — Load T-MSIS Parquet, NPPES extract, compile waiver dates, fetch ACS/FRED/CDC
- `02_clean_data.R` — Build state × month panel, classify H-codes as SUD vs. non-SUD, construct outcomes
- `03_main_analysis.R` — CS-DiD estimation, event study, first-stage
- `04_robustness.R` — Bacon decomposition, stacked cohort, HonestDiD, placebos, RI
- `05_figures.R` — Event study plots, mechanism decomposition figures, maps
- `06_tables.R` — Summary statistics, main results, robustness, mechanism decomposition
