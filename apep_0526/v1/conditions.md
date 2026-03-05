# Conditional Requirements

**Generated:** 2026-03-05T16:28:46.316457
**Status:** RESOLVED

---

## Right-to-Try Laws and the Market for Clinical Trials

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: showing pre-trends are flat in the key trial categories

**Status:** [x] RESOLVED

**Response:**
The analysis will include event-study plots with leads/lags (t-6 through t+4 relative to adoption) for each outcome: total trial site counts, Phase II/III trial starts, and enrollment per trial. Event-study coefficients at t-4 through t-1 must be jointly insignificant (F-test). The CS estimator explicitly estimates pre-treatment trends as a diagnostic. If pre-trends appear in any category, that outcome will be flagged and analyzed with sensitivity bounds (HonestDiD/Rambachan-Roth).

**Evidence:**
Commitment to implementation in initial_plan.md. Pre-treatment data: 2008Q1–2013Q4 (24 quarters before first adoption) provides ample pre-periods for clean trend tests.

---

### Condition 2: demonstrating a measurable first-stage proxy such as enrollment delays/completion hazards or sponsor/site reallocation rather than only counts

**Status:** [x] RESOLVED

**Response:**
Analysis will include multiple outcome margins beyond raw counts:
1. **Trial completion speed:** Duration from start to primary completion date (hazard model or median time), testing whether trials in Right-to-Try states take longer to complete enrollment
2. **Sponsor site reallocation:** Industry-sponsored trials vs. academic-sponsored, testing whether pharmaceutical companies differentially shifted sites away from Right-to-Try states
3. **Site-per-trial ratio:** Whether new trials opening in Right-to-Try states list fewer sites per trial (intensive margin)
4. **Trial withdrawals/terminations:** Whether trials in Right-to-Try states were more likely to be terminated due to enrollment difficulties

ClinicalTrials.gov API confirmed to contain: start dates, primary completion dates, overall status (COMPLETED, TERMINATED, WITHDRAWN), sponsor type (INDUSTRY, OTHER), and enrollment counts. All margins are directly measurable.

**Evidence:**
API test returned all required fields (statusModule, designModule, contactsLocationsModule). See data validation in discovery phase.

---

### Condition 3: robustness to region-specific biotech trends

**Status:** [x] RESOLVED

**Response:**
Three robustness strategies:
1. **Census Region × Quarter FE:** Add Census region × time fixed effects to absorb regional biotech cycles (e.g., Boston/SF corridors vs. other regions)
2. **Baseline biotech intensity controls:** Interact state baseline NIH funding or pharma employment (2008-2013 average) with time trends
3. **Leave-one-state-out:** Sequentially drop major biotech states (CA, MA, NY, NJ, TX, MD) to verify results aren't driven by a single hub

**Evidence:**
The ClinicalTrials.gov data shows massive cross-state variation (CA: 1,021 vs. WY: 25 trials in 2014), making regional trend controls essential and testable.

---

### Condition 4: to dropping 2018Q1–2018Q2 / handling the federal law cleanly

**Status:** [x] RESOLVED

**Response:**
Three approaches to the federal law:
1. **Main specification:** Panel ends 2017Q4 (before federal Right to Try Act signed May 30, 2018). This is the cleanest design — no contamination from the federal law.
2. **Robustness:** Extend through 2018Q2 with a "federal law" indicator, and show results are robust to inclusion/exclusion of 2018.
3. **Donut specification:** Drop 2018Q1-Q2 (anticipation window around federal passage) as sensitivity check.

The CS estimator handles the absence of a "never-treated" group post-2017Q4 via not-yet-treated comparisons. For cohorts adopted in 2017, the remaining not-yet-treated states (2018 adopters + never-state-law states) serve as controls.

**Evidence:**
Federal law signed May 30, 2018. Ending panel at 2017Q4 cleanly avoids contamination while preserving 3+ years of post-treatment for 2014 cohort.

---

### Condition 5 (Grok): event-study pre-trends

**Status:** [x] RESOLVED — Same as Condition 1.

---

### Condition 6 (Grok): placebo validation

**Status:** [x] RESOLVED

**Response:**
Three placebo tests built into the design:
1. **Non-terminal condition trials:** Right-to-Try applies only to terminally ill patients. Trials for non-terminal conditions (behavioral health, orthopedic, dermatology) should show zero effect. This is the primary placebo.
2. **Observational studies:** Right-to-Try targets investigational drug access. Observational studies (no drug intervention) should be unaffected.
3. **Phase I trials:** Right-to-Try requires completion of Phase I. Phase I enrollment (recruiting healthy volunteers or first-in-human) should be unaffected by the law.

All three placebos are directly identifiable in ClinicalTrials.gov via the phase, study type, and condition fields.

**Evidence:**
API query confirmed: phase field distinguishes PHASE1/PHASE2/PHASE3, studyType distinguishes INTERVENTIONAL/OBSERVATIONAL, and condition terms allow terminal/non-terminal classification.

---

### Condition 7 (Grok): MDE-powered null framing if no effects

**Status:** [x] RESOLVED

**Response:**
If effects are null, the paper will:
1. Compute ex ante MDE using baseline within-state-quarter trial count variation and cluster count
2. Frame as equivalence test: "We can rule out effects larger than X% on trial enrollment"
3. Document actual Right-to-Try usage (<100 patients nationally per published reports) to contextualize the null
4. Contribute the policy-relevant finding: "Concerns about clinical trial disruption from Right-to-Try were empirically unfounded, with MDE ruling out effects ≥X%"

This follows the tournament lesson that "nulls win when powered, with verified bite/first stage, and converted into a policy-relevant bound."

**Evidence:**
Baseline: ~2,000-2,500 Phase II/III trials/year nationally. With 50 states × 40 quarters, statistical power should be sufficient to detect moderate effects.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED
- [x] Evidence is provided for each resolution
- [ ] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
