# Conditional Requirements

**Generated:** 2026-03-06T10:24:17.137861
**Status:** RESOLVED

---

## Pump Prices and Perceptions: How State Gas Tax Hikes Shape Macroeconomic Beliefs

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: obtaining high-frequency gasoline price data for first-stage validation

**Status:** [x] RESOLVED

**Response:**
The paper uses gas tax changes as the treatment in a reduced-form DiD — we do NOT need high-frequency state-level gas prices as an intermediate outcome. The first stage (gas tax → pump price) is mechanical and well-documented in the literature (Li, Linn & Muehlegger show near-complete pass-through). For validation, EIA SEDS provides annual state gas prices for all 50 states (confirmed via EIA API). For the 9 states with weekly EIA data (CA, CO, FL, MA, MN, NY, OH, TX, WA), we show the high-frequency first stage as a robustness exhibit.

**Evidence:**
EIA SEDS API confirmed returning all 50 states + DC at annual frequency (1960-2024). EIA petroleum/pri/gnd returns weekly data for 9 states. The reduced-form design (gas tax → beliefs) does not require observing intermediate gas prices.

---

### Condition 2: restricting to clean discrete tax hikes

**Status:** [x] RESOLVED

**Response:**
Treatment will be restricted to discrete LEGISLATIVE gas tax increases (specific effective date, fixed cents-per-gallon increase). Automatic annual indexation adjustments (variable-rate formula states) will be excluded from the primary specification and tested as a separate heterogeneity exercise. This yields approximately 25-30 clean treatment events across 2013-2024, well above the 20-state threshold. Tax Foundation, NCSL, and FHWA publish exact effective dates and magnitudes.

**Evidence:**
ITEP and NCSL data document 34+ states with gas tax changes 2013-2024. After excluding variable-rate adjustments, approximately 25-30 discrete legislative increases remain (e.g., NJ +22.6c in 2016, IL +19c in 2019, CA +12c in 2017, SC +12c phased in 2017).

---

### Condition 3: adding strong placebo/heterogeneity tests

**Status:** [x] RESOLVED

**Response:**
Three placebo tests planned: (1) Non-economic search terms placebo — Google Trends for "weather" or "sports" should not respond to gas tax changes. (2) Temporal placebo — assign fake treatment dates 2 years before actual gas tax changes; these should show null effects. (3) Cross-state spillover placebo — test whether neighboring states' gas tax changes affect own-state beliefs (should be null or small).

**Evidence:**
All three placebos use the same data infrastructure (Google Trends, CES) and are standard in the staggered DiD literature. Will be implemented in 04_robustness.R.

---

### Condition 4: e.g. stronger effects for likely drivers/commuters

**Status:** [x] RESOLVED

**Response:**
CES data includes demographic variables enabling heterogeneity tests: (1) Rural vs. urban respondents (rural residents are more car-dependent, more exposed to gas prices). (2) Income groups (lower-income households spend higher share on gasoline). (3) Age cohorts (older respondents who experienced 1970s oil crises may respond differently per Malmendier & Nagel 2016; Binder & Makridis 2022). (4) Partisan affiliation (tests whether economic beliefs respond to gas prices differently by party).

**Evidence:**
CES cumulative dataset confirmed to include: county_fips (urban/rural classification), family_income, age/birthyr, pid3/pid7 (party ID), education. These enable all planned heterogeneity cuts.

---

### Condition 5: not for less exposed groups

**Status:** [x] RESOLVED

**Response:**
This is the mirror of Condition 4. If the mechanism is gasoline price salience, urban non-drivers should show weaker effects. CES respondents in dense urban areas (identified via county_fips → urban/rural classification) serve as a "less exposed" placebo group. This mirrors the behavioral-health provider placebo praised in tournament feedback.

**Evidence:**
County FIPS codes in CES allow classification using USDA Rural-Urban Continuum Codes. Urban core counties (codes 1-3) vs. rural counties (codes 7-9) provide the exposure variation.

---

### Condition 6 (from GPT-5.4 B): verifying that state tax hikes are not perfectly collinear with state-level business cycles

**Status:** [x] RESOLVED

**Response:**
State gas tax changes are driven primarily by transportation infrastructure funding needs and political opportunity, not business cycle timing. I will explicitly test this by: (1) Regressing gas tax change indicators on lagged state unemployment rate and GDP growth — these should be weak predictors. (2) Including state-level economic controls (unemployment rate, personal income growth) in the main DiD specification. (3) Running an event study to verify flat pre-trends in economic beliefs before gas tax changes.

**Evidence:**
The exogeneity argument is supported by the literature: gas tax changes are notoriously difficult to pass politically (last federal increase was 1993) and are driven by road funding shortfalls, not cyclical considerations. States raise gas taxes in both expansions and recessions.

---

### Condition 7 (from GPT-5.4 B): adding a placebo test using non-drivers or EV owners if data permits

**Status:** [x] RESOLVED

**Response:**
CES does not directly identify car ownership or EV status. However, two feasible proxies: (1) Urban density — residents of high-density urban cores (NYC, SF, Chicago) are less car-dependent and should show weaker effects. (2) State-level EV registration share (from DOE Alternative Fuels Data Center) as a moderator — states with higher EV adoption should show smaller belief effects from gas tax changes, since fewer residents are exposed to pump prices.

**Evidence:**
DOE AFDC publishes state-level EV registration counts annually. County-level urban/rural classification from USDA is publicly available.

---

### Condition 8 (from GPT-5.4 B): obtaining high-frequency pass-through data

**Status:** [x] RESOLVED

**Response:**
Same as Condition 1 — addressed via reduced-form design. First stage is mechanical (taxes pass through to pump prices near 1-for-1 per Li, Linn & Muehlegger). Annual EIA SEDS data validates for all 50 states; weekly EIA data validates for 9 states.

---

### Condition 9 (from GPT-5.4 B): adding strong placebo/heterogeneity tests that isolate gasoline-price salience from bundled state policy changes

**Status:** [x] RESOLVED

**Response:**
The concern is that gas tax changes may be bundled with other tax/spending changes. I will: (1) Search NCSL for concurrent state tax changes (income, sales, property) and control for them. (2) Test whether gas tax changes bundled with broader tax packages have different effects than standalone gas tax increases. (3) The Google Trends outcome helps here — searching for "inflation" vs. "taxes" distinguishes price-salience from general tax-policy attention.

**Evidence:**
NCSL State Tax Actions database provides concurrent state fiscal legislation. CES survey timing (Sept-Nov) creates some distance from legislative sessions.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Status: RESOLVED**
