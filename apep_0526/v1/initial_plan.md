# Initial Research Plan: Right-to-Try Laws and the Market for Clinical Trials

## Research Question

Did state Right-to-Try laws — which allow terminally ill patients to access investigational drugs outside clinical trials — affect the US clinical trial market? Specifically: did these laws alter trial site placement, enrollment patterns, completion speed, or the composition of trials across states?

## Policy Background

Between May 2014 (Colorado) and October 2018 (Alaska), 38 US states enacted Right-to-Try laws permitting terminally ill patients who have exhausted approved options to access drugs that have completed Phase I testing without FDA approval. Adoption was rapid and staggered: 4 states in 2014, 15 in 2015, 10 in 2016, 6 in 2017, and 3 in 2018. A federal Right to Try Act was signed May 30, 2018, covering the remaining states. Crucially, actual usage was minimal — reports suggest fewer than 100 patients used the pathway nationally — making this a test of whether *symbolic legislation* with near-zero take-up can distort innovation markets.

## Identification Strategy

**Design:** Staggered difference-in-differences using Callaway and Sant'Anna (2021) estimator.

**Treatment:** State enacts Right-to-Try law (effective date).

**Unit:** State × quarter panel.

**Panel:** 2008Q1–2017Q4 (main specification). Pre-treatment: 2008Q1–2013Q4 (24 quarters). Post-treatment: varies by cohort (up to 16 quarters for 2014 cohort).

**Treatment cohorts:** 38 states across 10 quarterly cohorts (2014Q2, 2014Q3, 2014Q4, 2015Q1-Q4, 2016Q1-Q4, 2017Q1-Q4).

**Control group:** Not-yet-treated states (CS estimator handles this without requiring a never-treated group, though ~9 states that never passed state laws before the federal act provide additional controls through 2017Q4).

## Exposure Alignment (DiD Requirements)

- **Who is treated:** Clinical trial sites located in states that enacted Right-to-Try laws
- **Primary estimand population:** Phase II/III interventional drug trials with US facilities
- **Placebo/control population:** (1) Non-terminal condition trials, (2) Observational studies, (3) Phase I trials
- **Design:** Standard DiD with staggered adoption

## Power Assessment

- **Pre-treatment periods:** 24 quarters (2008Q1–2013Q4)
- **Treated clusters:** 38 states
- **Post-treatment periods per cohort:** 4-16 quarters
- **Baseline outcome magnitude:** ~2,000-2,500 Phase II/III trial starts per year nationally; per-state-quarter counts range from ~6 (Wyoming) to ~250 (California)
- **Expected MDE:** With 50 states × 40 quarters and state-quarter clustering, should detect ~5-8% change in trial site counts

## Expected Effects and Mechanisms

**Theoretical predictions (from policy debate):**
1. **Patient substitution:** Patients may forgo trial enrollment to access drugs via Right-to-Try → reduced enrollment
2. **Sponsor avoidance:** Pharmaceutical companies may shift trial sites away from Right-to-Try states to protect enrollment integrity
3. **Regulatory uncertainty:** The law creates ambiguity about post-trial obligations and liability, discouraging site placement

**Counter-hypothesis (our prior):** With near-zero actual take-up, effects should be null. A well-powered null is the expected and policy-relevant finding.

**If effects exist:** They would operate through expectations/beliefs rather than actual diversion, which is itself an interesting finding about pharmaceutical industry decision-making.

## Primary Specification

```
Y_{s,t} = α_s + γ_t + β · RTT_{s,t} + ε_{s,t}
```

Where Y is the outcome (trial site count, enrollment, etc.) in state s, quarter t; RTT is an indicator for whether the state has an active Right-to-Try law; α_s are state FE; γ_t are quarter FE.

CS estimator: Group-time ATT(g,t) for each adoption cohort g, aggregated via inverse-probability weighting.

## Planned Outcomes

1. **Trial site counts:** Number of new trial facilities opening in state s in quarter t (Phase II/III interventional)
2. **Enrollment magnitude:** Total planned enrollment across trials starting in state s, quarter t
3. **Trial completion speed:** Median months from start to primary completion for trials starting in state s
4. **Trial terminations:** Share of trials terminated/withdrawn before completion
5. **Sponsor composition:** Share of industry-sponsored vs. academic-sponsored trials
6. **Condition composition:** Share of trials for terminal vs. non-terminal conditions

## Planned Robustness Checks

1. **Event study:** Leads (t-6 to t-1) and lags (t+0 to t+4) relative to adoption
2. **Bacon decomposition:** Identify sources of variation in TWFE estimator
3. **Randomization inference:** Permutation-based p-values for ATT
4. **Region × quarter FE:** Control for regional biotech trends
5. **Baseline biotech intensity controls:** State NIH funding × time trends
6. **Leave-one-state-out:** Drop major biotech hubs (CA, MA, NY, NJ, TX, MD) sequentially
7. **Donut specification:** Drop the quarter of adoption (anticipation concerns)
8. **End-of-panel sensitivity:** Extend to 2018Q2 with federal law controls
9. **HonestDiD/Rambachan-Roth sensitivity:** Bound effects under violations of parallel trends

## Planned Placebo Tests

1. **Non-terminal condition trials:** Behavioral health, orthopedic, dermatology (should show zero)
2. **Observational studies:** Not interventional drug trials (should show zero)
3. **Phase I trials:** Recruiting for first-in-human, not subject to Right-to-Try (should show zero)

## Data Sources

| Source | Variables | Granularity | Access |
|--------|-----------|-------------|--------|
| ClinicalTrials.gov API v2 | Trial starts, facilities, enrollment, phase, conditions, status, sponsors | Trial-facility level → state × quarter | Public API (no key needed) |
| Triage Cancer / Goldwater Institute | State Right-to-Try law effective dates | State level | Published (already collected) |
| FRED / BEA | State GDP, employment (controls) | State × quarter/year | API (key available) |

## Code Structure

```
code/
├── 00_packages.R          # Libraries and themes
├── 01_fetch_data.R         # ClinicalTrials.gov API download + state law dates
├── 02_clean_data.R         # Build state × quarter panel
├── 03_main_analysis.R      # CS-DiD, event study, main results
├── 04_robustness.R         # Bacon decomp, RI, HonestDiD, leave-one-out
├── 05_figures.R            # Event study plots, placebo results, maps
└── 06_tables.R             # Main results, robustness, summary stats
```

## Paper Structure

1. **Introduction:** The puzzle — 41 states passed laws to "save lives" with experimental drugs, but the pharmaceutical industry warned this could undermine clinical trials. We test whether these fears materialized.
2. **Background:** Right-to-Try laws, the clinical trial pipeline, FDA's Expanded Access program, theoretical channels
3. **Data:** ClinicalTrials.gov as "universe" administrative data; construction of state-quarter panel
4. **Empirical Strategy:** Staggered DiD with CS estimator; identification assumptions; power analysis
5. **Results:** Main effects, event studies, mechanism decomposition
6. **Placebo Tests and Robustness:** Non-terminal placebos, regional controls, RI, HonestDiD
7. **Welfare Analysis:** If effects found: implied drug development delays via VSLY. If null: MDE bounds on "concerns unfounded"
8. **Conclusion:** What symbolic legislation teaches us about innovation markets
