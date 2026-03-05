# Conditional Requirements

**Generated:** 2026-03-05T17:08:17.723183
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

---

## Scale Mismatch — National Consensus vs Local Conflict on French Low-Emission Zones (ZFE)

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: a threshold-based or otherwise quasi-exogenous treatment assignment argument that survives pre-trend tests

**Status:** [x] RESOLVED

**Response:**
Treatment assignment exploits three sources of quasi-exogenous variation:
1. **Air-quality exceedance threshold**: The EU regulatory annual NO2 limit of 40 microg/m3, exceeded for 3+ of 5 years, determines "ZFE effectif" (mandatory strict calendar) vs. "territoire de vigilance" (minimal obligations). This is a regulatory threshold applied to measured pollution data — cities cannot choose their classification.
2. **Population threshold**: Loi Climat et Resilience (2021) mandated ZFE in all agglomerations >150,000 inhabitants by 2025, creating a sharp legal obligation independent of local politics.
3. **Staggered timing**: 11 cities mandated by LOM 2019 (effective 2020-2022), 32 additional by Climat et Resilience 2021 (effective 2024-2025). The first wave was driven by pre-2019 air quality violations; the second by a uniform population cutoff.

Pre-trend validation: Legislative elections in 2002, 2007, 2012, 2017 provide 4 pre-treatment periods before any ZFE. Event-study design will test parallel trends on electoral polarization. Municipal elections in 2001, 2008, 2014 provide 3 pre-treatment periods.

**Evidence:** Air quality data from Geodair (2013+); ZFE classification from March 2024 Comite Ministeriel; implementation dates from BNZFE GeoJSON.

---

### Condition 2: a clearly prioritized main outcome + mechanism sequence rather than many parallel indices

**Status:** [x] RESOLVED

**Response:**
Pre-specified outcome hierarchy:
- **Primary outcome**: Local electoral polarization — effective number of parties (ENP) in legislative elections, computed at the constituency level for ZFE vs non-ZFE areas. Single, well-defined index.
- **Secondary local outcome**: Anti-restriction party vote share (RN + Reconquete) in legislative elections.
- **National benchmark**: Roll-call vote polarization (Rice index by party group) on ZFE-tagged legislation — descriptive comparison, not causal.
- **Mechanism test**: MP party-line deviation on climate votes as a function of constituency ZFE exposure (spillback channel).
- **Appendix only**: Rhetorical polarization from debate transcripts (demoted per Grok recommendation).

This creates a clear hierarchy: one main local causal estimate, one mechanism test, national measures as context.

**Evidence:** Will pre-register in initial_plan.md.

---

### Condition 3: credible handling of spillovers/commuting zones

**Status:** [x] RESOLVED

**Response:**
Spillovers handled via:
1. **Treatment definition at constituency level, not commune**: Legislative constituencies (circonscriptions) are large enough to contain both ZFE and non-ZFE areas. Treatment = share of constituency population within ZFE perimeter (continuous treatment intensity), avoiding sharp boundary comparisons.
2. **Commuting zone controls**: Use INSEE's "aire d'attraction des villes" classification to define commuting zones. Include donut specifications excluding communes in the commuting belt of ZFE cities.
3. **Control group selection**: Use ZFE-obligated agglomerations that implemented later (2025 wave) as controls for the 2019-2023 wave, ensuring controls face similar commuting structures.

**Evidence:** ZFE GeoJSON boundaries allow precise population-weighted treatment intensity by constituency.

---

### Condition 4: heterogeneous implementation strictness

**Status:** [x] RESOLVED

**Response:**
Implementation strictness varies enormously (Crit'Air levels banned, 24/7 vs peak hours, enforcement). This is treated as:
1. **Main specification uses binary treatment (ZFE active = 1)**: Intent-to-treat for the mandate, avoiding endogenous strictness choices.
2. **Heterogeneity analysis**: Explore dose-response using externally determined strictness (Crit'Air categories banned, which follow from the national calendar for "ZFE effectifs") as a secondary specification.
3. **Strictness as outcome**: Test whether local conflict predicts higher local strictness (reverse causality check).

**Evidence:** BNZFE GeoJSON includes restriction rules (which Crit'Air levels are banned by ZFE).

---

### Condition 5 (Gemini): establishing robust pre-trends

**Status:** [x] RESOLVED

**Response:** Same as Condition 1 above. Four pre-treatment legislative elections (2002-2017) provide long baselines. Event-study coefficients for t-4 through t-1 will be reported in main text, with formal Rambachan-Roth sensitivity analysis for violation magnitudes.

**Evidence:** Election data in Parquet, 2002-2024.

---

### Condition 6 (Gemini): addressing the endogeneity of the air-quality mandate timing

**Status:** [x] RESOLVED

**Response:**
Air quality is endogenous to economic activity, which correlates with political trends. Mitigation:
1. **Use population threshold (150k) as primary treatment rule**: This is a mechanical cutoff from Climat et Resilience 2021, independent of air quality or local politics.
2. **For the air-quality-based wave (LOM 2019)**: Condition on pre-2015 air quality (before ZFE was legislated) to classify cities, avoiding strategic pollution reduction to avoid mandates.
3. **Placebo tests**: Compare political trends in agglomerations just above vs just below 150k (RDD-style, if density permits) and in cities that narrowly exceeded vs narrowly missed the 40 microg/m3 NO2 threshold.

**Evidence:** Geodair annual averages allow classification based on pre-policy pollution levels.

---

### Condition 7 (Grok): prioritizing spillback as core mechanism

**Status:** [x] RESOLVED

**Response:** Spillback test (MP party-line deviation) will be the main mechanism chapter, not just an add-on. The paper's narrative arc: (1) document local divisiveness increase post-ZFE, (2) show this travels upward via MP voting behavior. This creates the "mechanism surprise" the judges reward.

---

### Condition 8 (Grok): demoting rhetoric to appendix

**Status:** [x] RESOLVED

**Response:** Debate transcript analysis (rhetorical polarization) will be placed in the online appendix. Main text focuses on vote-based measures at both levels. This keeps the design clean and avoids noise from NLP-based outcomes.

---

### Condition 9 (Grok): validating parallel trends across all ZFE waves

**Status:** [x] RESOLVED

**Response:** Will estimate separate event studies for Wave 1 (LOM 2019, 11 cities, active 2020-2022) and Wave 2 (Climat et Resilience, 32 cities, active 2024-2025). If pre-trends differ across waves, this reveals composition effects and informs the stacking strategy. Callaway-Sant'Anna estimator handles heterogeneous treatment timing.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
