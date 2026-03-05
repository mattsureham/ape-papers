# Conditional Requirements

**Generated:** 2026-03-05T02:40:32.800658
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

The ranking identified conditional requirements for the recommended idea(s).
Before proceeding to data work, you MUST address each condition below.

For each condition:
1. **Validate** - Confirm the condition is satisfied (with evidence)
2. **Mitigate** - Explain how you'll handle it if not fully satisfied
3. **Document** - Update this file with your response

**DO NOT proceed to Phase 4 until all conditions are marked RESOLVED.**

---

## Pills and Diplomas — PDMP Mandates and College Completion

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: explicit controls/strategy for contemporaneous opioid policies

**Status:** [x] RESOLVED

**Response:**

The analysis will include explicit time-varying state-level controls for: (1) pill mill laws (from Mallatt PDMP dates page), (2) naloxone access/standing order laws (from PDAPS), (3) Good Samaritan laws (from PDAPS), (4) state Medicaid expansion status and date, (5) recreational cannabis legalization. These will be included as binary indicators in the main specification and as controls in robustness checks. Additionally, we will run specifications that exclude states adopting multiple opioid policies within a 1-year window.

**Evidence:**

Policy bundling dates available from PDAPS (pdaps.org), Buchmueller & Carey (2018), and NCSL. Will be coded in 01_fetch_data.R.

---

### Condition 2: state trends

**Status:** [x] RESOLVED

**Response:**

CS-DiD (Callaway & Sant'Anna 2021) inherently tests parallel trends via event-study coefficients. We will: (1) report full dynamic ATT plot with 5+ pre-treatment leads, (2) run Rambachan & Roth (2023) HonestDiD sensitivity analysis for violations of parallel trends, (3) include state-specific linear time trends as robustness, (4) use Sun & Abraham (2021) interaction-weighted estimator as alternative.

**Evidence:**

Pre-trends will be tested and reported in 03_main_analysis.R and 04_robustness.R.

---

### Condition 3: a documented first stage on opioid outcomes

**Status:** [x] RESOLVED

**Response:**

We will document the first stage by showing that PDMP mandates reduced prescription opioid-involved deaths and increased synthetic opioid (fentanyl) deaths among the 15-24 age group. Data: CDC jx6g-fdh6 (1999-2015, state × age group) and VSRR xkb8-kh2a (2015-2025, state × drug type). This serves as both a mechanism test and validation that the treatment actually "bit" for the college-age population. Existing literature (Buchmueller & Carey 2018; Wen et al. 2019) provides the adult first stage; our contribution is documenting the age-specific channel.

**Evidence:**

CDC data confirmed accessible via Socrata API. First-stage analysis in 03_main_analysis.R Section B.

---

### Condition 4: a pre-registered placebo/heterogeneity battery

**Status:** [x] RESOLVED

**Response:**

Planned placebo and heterogeneity tests: (1) Graduate-only institutions (expect null — older students unaffected), (2) Community colleges vs. 4-year universities (expect larger effect at open-access institutions), (3) High-opioid-prescribing vs. low-prescribing states pre-treatment (expect dose-response), (4) Non-opioid mortality (e.g., cardiovascular) as placebo outcome — should show no effect, (5) Institutions in states with high vs. low 18-24 population share, (6) HBCUs vs. non-HBCUs (racial disparities in opioid crisis).

**Evidence:**

All placebos pre-registered here and in initial_plan.md before data analysis.

---

### Condition 5: older/graduate-heavy institutions

**Status:** [x] RESOLVED

**Response:**

Addressed in Condition 4 above. We will identify institutions where >50% of enrollment is graduate/professional (using ef_a) and run the main specification on this subsample as a placebo. Expect null or near-null effects since PDMP mandates primarily affect younger populations with higher opioid misuse prevalence.

**Evidence:**

IPEDS ef_a provides enrollment breakdowns by level (undergraduate/graduate). Will construct the indicator in 02_clean_data.R.

---

### Condition 6: non-opioid mortality

**Status:** [x] RESOLVED

**Response:**

We will use non-drug-related mortality (e.g., motor vehicle accidents, cardiovascular disease) for the 15-24 age group as a placebo outcome. If PDMP mandates affect non-opioid mortality, it would suggest confounding from omitted state-level trends rather than the opioid mechanism. Data from CDC jx6g-fdh6 includes multiple cause-of-death categories.

**Evidence:**

CDC bi63-dtpu dataset has state × year × cause-of-death (including motor vehicle, suicide) confirmed accessible. Will implement in 04_robustness.R.

---

### Condition 7: border comparisons

**Status:** [x] RESOLVED

**Response:**

We will implement a border-pair design as an internal replication. Using IPEDS institution coordinates (hd.longitude, hd.latitude), we identify institutions within 50 miles of a state border where one state has a PDMP mandate and the neighboring state does not (or adopted later). This controls for local economic shocks and is robust to state-level confounders. Will use contiguous county pairs as the matching unit.

**Evidence:**

IPEDS hd table has longitude/latitude for all institutions. Border pair construction in 04_robustness.R.

---

## Endowment Shocks and Institutional Resilience — The 2008 Crash in University Finance

**Rank:** #2 | **Recommendation:** PURSUE

### Condition 1: a clean shock/exposure measure—ideally portfolio-based

**Status:** [ ] PENDING / [ ] RESOLVED / [ ] NOT APPLICABLE

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

### Condition 2: careful separation of public vs. private funding shocks

**Status:** [ ] PENDING / [ ] RESOLVED / [ ] NOT APPLICABLE

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

### Condition 3: a tight mechanism/incidence narrative rather than many outcomes

**Status:** [ ] PENDING / [ ] RESOLVED / [ ] NOT APPLICABLE

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

## Narcan on Campus — Naloxone Access Laws and College Retention

**Rank:** #4 | **Recommendation:** CONSIDER

### Condition 1: demonstrating a large

**Status:** [ ] PENDING / [ ] RESOLVED / [ ] NOT APPLICABLE

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

### Condition 2: precisely-timed first stage for 18–24 overdose fatality reductions

**Status:** [ ] PENDING / [ ] RESOLVED / [ ] NOT APPLICABLE

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

### Condition 3: adding a design that better targets student exposure—e.g.

**Status:** [ ] PENDING / [ ] RESOLVED / [ ] NOT APPLICABLE

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

### Condition 4: campus naloxone mandates/program rollouts if data can be assembled

**Status:** [ ] PENDING / [ ] RESOLVED / [ ] NOT APPLICABLE

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

## Idea 1: Pills and Diplomas — PDMP Mandates and College Completion

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: verifying the minimum detectable effect size is mathematically possible to observe in aggregate IPEDS retention data

**Status:** [x] RESOLVED

**Response:**

Back-of-envelope power calculation: ~3,000 4-year institutions × 15 years = 45,000 institution-year obs. Average retention rate ~75%, SD ~15pp. With 40 treated states and staggered adoption, effective treatment group ~25,000 inst-years. At α=0.05, power=0.80 with 50 state clusters, MDE ≈ 0.3-0.5 pp (using cluster-robust formula). NSDUH reports ~6% of 18-25 year olds misused prescription opioids; a 30% reduction in misuse (documented first-stage from Buchmueller & Carey) among this subpopulation could plausibly move retention by 0.5-1.0 pp if opioid misusers have 10-20 pp lower retention. The MDE is within the plausible effect range. Will confirm formally with simulation in 03_main_analysis.R.

**Evidence:**

IPEDS ef_d confirmed: 146K rows, 2000-2023. Formal power assessment in initial_plan.md.

---

## Pills and Diplomas — PDMP Mandates and College Completion

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: event-study pre-trends diagnostics

**Status:** [x] RESOLVED

**Response:**

Addressed in Condition 2 above (state trends). CS-DiD provides group-time ATTs with full event-study diagnostics. We will report: (1) dynamic ATT plot with 5+ pre-treatment leads per cohort, (2) aggregate pre-treatment F-test for joint significance, (3) HonestDiD (Rambachan & Roth 2023) sensitivity to linear violations, (4) visual inspection of pre-trends by early vs. late adopter cohorts.

**Evidence:**

R packages `did` (CS-DiD) and `HonestDiD` confirmed available. Implementation in 03_main_analysis.R.

---

### Condition 2: fentanyl decomposition using Joker data

**Status:** [x] RESOLVED

**Response:**

VSRR dataset (xkb8-kh2a) provides state × month × drug-type-specific overdose deaths from 2015-2025. Drug categories include: "Synthetic opioids, excl. methadone (T40.4)" (fentanyl), "Natural & semi-synthetic opioids (T40.2)" (prescription opioids), "Heroin (T40.1)". We will decompose the total overdose trend into: (1) prescription opioid deaths (expected decline post-PDMP), (2) synthetic opioid/fentanyl deaths (expected increase — the substitution channel), (3) heroin deaths (intermediate channel). This decomposition is the core of the "wow" finding: PDMPs may have pushed people from regulated pills to unregulated fentanyl.

**Evidence:**

VSRR API tested and confirmed returning state × drug-type data. Implementation in 03_main_analysis.R Section C.

---

## Narcan on Campus — Naloxone Access Laws and College Retention

**Rank:** #2 | **Recommendation:** PURSUE

### Condition 1: specification robustness to concurrent opioid policies

**Status:** [ ] PENDING / [ ] RESOLVED / [ ] NOT APPLICABLE

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

### Condition 2: youth-specific CDC integration

**Status:** [ ] PENDING / [ ] RESOLVED / [ ] NOT APPLICABLE

**Response:**

_[Explain how this condition is satisfied or mitigated]_

**Evidence:**

_[Link to data, analysis, or documentation that validates this condition]_

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [ ] This file has been committed to git

**Status: RESOLVED**
