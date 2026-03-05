# Initial Research Plan: Pills and Diplomas

## Research Question

Do state mandatory Prescription Drug Monitoring Program (PDMP) consultation laws affect college retention and completion? Do PDMPs reduce human capital accumulation by pushing substance use from regulated prescriptions to unregulated illicit opioids (fentanyl)?

## Identification Strategy

**Design:** Callaway & Sant'Anna (2021) staggered difference-in-differences.

**Treatment:** State enactment of a mandatory PDMP consultation law requiring prescribers to check the PDMP before prescribing controlled substances. Treatment dates from Gunadi (2023, BMC Public Health) Supplementary Table S1 (44 states through 2020), cross-referenced with Buchmueller & Carey (2018, AEJ:EP) Table 1.

**Unit of analysis:** Institution × year (mapped to state via IPEDS `hd` table).

**Control group:** Never-treated states (~8-10 states without mandates) and not-yet-treated institutions.

**Clustering:** State level (50 clusters). Wild cluster bootstrap as robustness.

## Expected Effects and Mechanisms

**Channel A — Supply Reduction (positive for education):** PDMPs reduce opioid prescribing → fewer students misusing prescription opioids → better retention and graduation.

**Channel B — Substitution (negative for education):** PDMPs restrict prescription access → affected users substitute to illicit heroin/fentanyl → more overdose deaths and impairment → worse retention and graduation.

**Net effect is ambiguous ex ante.** If Channel B dominates (as emerging evidence suggests), PDMPs may *reduce* college completion — a dark, counterintuitive finding with major policy implications.

**Expected heterogeneity:**
- Larger effects at open-access institutions (community colleges, non-selective 4-year) where student populations overlap more with opioid-affected demographics
- Null effects at graduate-heavy institutions (placebo)
- Stronger effects in high-prescribing states (dose-response)
- Racial heterogeneity: opioid crisis disproportionately affected white communities initially

## Primary Specification

```
Y_{i,s,t} = α_i + γ_t + δ · PDMP_{s,t} + X'_{s,t}β + ε_{i,s,t}
```

Where:
- `Y_{i,s,t}` = retention rate (or graduation rate, enrollment) at institution i in state s, year t
- `α_i` = institution fixed effects
- `γ_t` = year fixed effects
- `PDMP_{s,t}` = 1 if state s has enacted a PDMP mandate by year t
- `X_{s,t}` = state-level time-varying controls (unemployment rate, log(population), Medicaid expansion, naloxone laws, pill mill laws, Good Samaritan laws, cannabis legalization)
- SEs clustered at state level

**CS-DiD implementation:** Use `did` R package. Report group-time ATTs, dynamic ATT event study, and simple weighted ATT.

## Primary Outcome Variables

| Variable | IPEDS Table | Description |
|----------|-------------|-------------|
| `ret_pcf` | ef_d | Full-time student retention rate (%) |
| Graduation rate (150%) | gr | 6-year graduation rate for 4-year institutions |
| Total enrollment | ef_a | Fall headcount enrollment |
| Completions | c_a | Total degrees/certificates awarded |

## Mechanism Variables (Joker Data)

| Variable | Source | Description |
|----------|--------|-------------|
| Drug poisoning deaths (15-24) | CDC jx6g-fdh6 | State × age group, 1999-2015 |
| Prescription opioid deaths (T40.2) | VSRR xkb8-kh2a | State × month, 2015-2025 |
| Synthetic opioid deaths (T40.4) | VSRR xkb8-kh2a | Fentanyl, state × month, 2015-2025 |
| Heroin deaths (T40.1) | VSRR xkb8-kh2a | State × month, 2015-2025 |

## Planned Robustness Checks

1. **Pre-trends:** Event-study with 5+ pre-treatment leads; HonestDiD sensitivity (Rambachan & Roth 2023)
2. **Sun & Abraham (2021)** interaction-weighted estimator as alternative to CS-DiD
3. **State-specific linear time trends** in main specification
4. **Border-pair design:** Institutions within 50 miles of state borders, comparing treated vs. untreated side
5. **Alternative treatment dates:** Robustness to different PDMP mandate coding (Buchmueller & Carey vs. Gunadi vs. Mallatt)
6. **Dropping early/late adopters** to test sensitivity to composition of treated group
7. **Bacon decomposition** of TWFE estimates to check for negative weights

## Exposure Alignment (DiD Required)

- **Who is treated:** College students in states with PDMP mandates (indirectly via opioid environment)
- **Primary estimand population:** Full-time undergraduates at 4-year institutions
- **Placebo/control population:** Graduate-heavy institutions (>50% graduate enrollment); institutions in never-treated states
- **Design:** DiD (not DDD; DDD reserved for robustness with age-group interaction)

## Placebo and Heterogeneity Battery

| Test | Expected | Rationale |
|------|----------|-----------|
| Graduate-only institutions | Null | Older students less affected by opioid misuse |
| Community colleges vs. 4-year | Larger at CC | More overlap with affected population |
| High vs. low pre-treatment prescribing rate | Dose-response | More exposure = larger effect |
| Non-opioid mortality as outcome | Null | If PDMP affects non-drug deaths, confounding present |
| HBCUs vs. non-HBCUs | Explore | Racial dimension of opioid crisis |
| Public vs. private institutions | Explore | Different student body composition |

## Power Assessment

- **Pre-treatment periods:** 5+ years for most cohorts (main wave 2012-2017, IPEDS from 2000)
- **Treated clusters:** 40+ states
- **Post-treatment periods:** 3-8 years per cohort
- **MDE given sample size:** ~0.3-0.5 pp on retention rate (α=0.05, power=0.80, 50 state clusters, 45K+ institution-year obs)
- **Plausible effect size:** 0.5-1.0 pp (based on 6% misuse prevalence × 30% reduction × 10-20 pp retention gap for misusers)

## Data Plan

1. **IPEDS** (local DuckDB, `data/ipeds/ipeds.duckdb`): All tables already available
2. **PDMP mandate dates:** Hand-coded from Gunadi (2023) Table S1, cross-referenced with Buchmueller & Carey (2018) and PDAPS
3. **CDC overdose data:** Socrata API (jx6g-fdh6 for age-specific; xkb8-kh2a for drug-specific)
4. **State controls:** FRED API (unemployment rate, population), Census ACS (demographics)
5. **Concurrent policy dates:** PDAPS, NCSL (naloxone, Good Samaritan, pill mill, Medicaid expansion, cannabis)
