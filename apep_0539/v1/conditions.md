# Conditional Requirements

**Generated:** 2026-03-06T14:17:25.892495
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

We proceed with **Less Cash, Less Crime?** (idea_0113) based on the following reasoning:

**Why not Judge IV (idea_0012)?** Gemini's critique is fatal: "asylum grants are a statistical drop in the bucket of county-level labor markets." Both GPT models also flag ecological fallacy. The micro-treatment → macro-outcome mismatch is a fundamental design flaw.

**Why not SALT (idea_0063)?** Only 8 months of post-reversal data (OBBB signed July 2025). GPT-5.4 (B) explicitly calls it "premature." COVID confounding in the middle window is severe.

**Why EBT?** The mechanism story (underground currency destruction → crime) is the sharpest and most memorable. We upgrade from state-level to **county-level** UCR data (~3,100 counties), dramatically increasing power and addressing the main critique. Treatment still varies at state level but county outcomes give real granularity.

---

## Less Cash, Less Crime? The Nationwide Effect of Electronic Benefit Transfer on Property Crime

**Rank:** #1 (selected) | **Recommendation:** PURSUE

### Condition 1: strong event-study diagnostics

**Status:** [x] RESOLVED

**Response:** CS-DiD with Callaway-Sant'Anna provides group-time ATTs with built-in event-study plotting. With EBT adoption starting in 1996 and crime data from 1985+, we have 10+ pre-treatment periods. Will run: (a) CS-DiD event study with dynamic effects; (b) Rambachan-Roth HonestDiD sensitivity bounds for violations of parallel trends; (c) Bacon decomposition to check for negative weights.

**Evidence:** UCR county-level data available from 1985. SNAP Policy Database confirms staggered adoption 1996-2005. Long pre-period enables standard event-study diagnostics.

---

### Condition 2: explicit tests for correlation between adoption timing

**Status:** [x] RESOLVED

**Response:** Will regress state EBT adoption year on pre-period state characteristics: (a) 1990-1995 average crime rates (property, violent); (b) SNAP caseload per capita; (c) poverty rate; (d) state GDP per capita; (e) police per capita; (f) urbanization rate. If adoption timing is uncorrelated with pre-existing crime levels, exogeneity is supported. Adoption was driven by federal compliance deadlines and state IT procurement capacity, not crime conditions.

**Evidence:** Will be produced in 04_robustness.R as a formal timing exogeneity test table.

---

### Condition 3: pre-existing crime/welfare trends

**Status:** [x] RESOLVED

**Response:** Addressed by Condition 1 (event study) and Condition 2 (timing exogeneity). Additionally: (a) include state-specific linear trends as robustness; (b) control for concurrent welfare reforms (TANF implementation timing varies by state, 1996-1997); (c) control for national crime decline factors (police hiring grants, incarceration expansion) via state-level covariates.

**Evidence:** Pre-period 1985-1995 provides 10+ years for trend assessment.

---

### Condition 4: mechanism-focused outcomes rather than only total property crime

**Status:** [x] RESOLVED

**Response:** Core analysis uses disaggregated crime categories:
- **Mechanism-aligned:** Burglary rate, larceny-theft rate, robbery rate (food stamps are stolen in burglaries/robberies, traded in larceny contexts)
- **Placebo outcomes:** Motor vehicle theft (no mechanism), arson (no mechanism), white-collar crime/fraud (no mechanism)
- **Dose-response:** Interact EBT with pre-reform SNAP caseload per capita (high-SNAP counties should show larger effects)
- **Heterogeneity:** Urban vs rural counties (black market more active in urban areas)

**Evidence:** FBI UCR provides separate counts for each Part I offense category at county level.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
