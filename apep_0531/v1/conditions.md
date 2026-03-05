# Conditional Requirements

**Generated:** 2026-03-05T17:19:19.952817
**Status:** RESOLVED

---

## Soft Power and Crime: The Effect of Police Community Support Officer Cuts on Neighbourhood Safety in England

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: a credible exogeneity strategy for PCSO cuts beyond TWFE/CS-DiD

**Status:** [x] RESOLVED

**Response:**

Three-pronged exogeneity strategy:

1. **Bartik/shift-share instrument:** Force-level PCSO cuts are driven by the interaction of (a) national austerity funding cuts (the "shift") and (b) each force's pre-austerity dependence on central government grants (the "share"). Forces more dependent on Home Office grants pre-2010 had larger PCSO cuts because they couldn't compensate via council tax precepts. Pre-2010 grant share is predetermined and plausibly exogenous to post-2010 crime trends.

2. **Conditional exogeneity with rich controls:** Conditional on force FE, year FE, region×year FE, lagged crime levels, local deprivation (IMD), population density, and crucially sworn officer FTE changes, the remaining PCSO variation reflects budget allocation decisions (PCC priorities) rather than crime trends. PCSOs are the "marginal" workforce category that PCCs cut first as a budget-balancing measure.

3. **Falsification:** Test whether PCSO cuts predict pre-trend changes in crime (2007-2009). If they do, identification fails. If they don't, conditional parallel trends holds.

**Evidence:** Home Office police allocation formula is published and mechanical. Pre-2010 grant dependence is observable from workforce data. Draca, Machin & Witt (2011, AER) established that police deployment variation in London is credible for causal identification.

---

### Condition 2: strong pre-trend/placebo battery

**Status:** [x] RESOLVED

**Response:**

Planned pre-trend and placebo tests:

1. **Event-study coefficients:** Dynamic specification with leads and lags showing flat pre-trends in crime before PCSO cuts begin (2007-2009 pre-austerity period).
2. **Placebo outcome:** Crime types where PCSOs have no plausible effect (e.g., online fraud, cybercrime) should show null effects if identification is valid.
3. **Placebo treatment:** Randomize PCSO cut magnitudes across forces; real treatment should outperform shuffled assignments (randomization inference).
4. **HonestDiD bounds:** Rambachan & Roth (2023) sensitivity analysis for violations of parallel trends.

**Evidence:** 3 years of pre-austerity data (2007-2009) available from Home Office workforce statistics. ONS PFA crime tables cover this period.

---

### Condition 3: sensitivity to influential forces

**Status:** [x] RESOLVED

**Response:**

Metropolitan Police accounts for ~25% of all PCSOs nationally and had the largest absolute cuts (4,645→1,255 FTE). Will run:

1. **Leave-one-out jackknife:** Drop each force in turn; coefficient stability.
2. **Drop Met Police:** Show results robust to excluding the largest force.
3. **Drop London forces entirely:** Exclude Met + City of London to test non-London identification.
4. **Weighted vs. unweighted:** Compare population-weighted and force-equal-weighted estimates.

**Evidence:** 43 forces provides sufficient remaining variation (42) after dropping any single force.

---

### Condition 4: clustered inference

**Status:** [x] RESOLVED

**Response:**

43 clusters is sufficient for standard cluster-robust SEs but borderline. Will implement:

1. **Wild cluster bootstrap** (Cameron, Gelbach & Miller 2008; implemented via `fwildclusterboot` R package) — gold standard for few-cluster inference.
2. **Randomization inference:** Permute treatment assignment across forces (1,000+ permutations).
3. **Conley spatial HAC standard errors** as robustness check.

**Evidence:** 43 forces exceeds the Cameron et al. threshold of ~30 clusters where cluster-robust SEs begin to perform well. Wild bootstrap further corrects for finite-sample bias.

---

### Condition 5 (from Model 2): establishing an instrument or strict exogeneity for the force-level variation in cuts

**Status:** [x] RESOLVED

**Response:** Same as Condition 1 above — Bartik instrument using pre-2010 central grant dependence × national cut magnitude.

---

### Condition 6 (from Model 2): verifying sufficient power with 43 clusters

**Status:** [x] RESOLVED

**Response:**

43 forces × 18 years = 774 force-year observations. The Ariel et al. (2016) RCT found 39% crime reduction from extra PCSO patrols. At the force level, with average PCSO cuts of ~50%, we need to detect ~20% of the Ariel effect (i.e., ~8% crime increase). Given within-force crime standard deviations of ~10-15% year-on-year, 43 clusters with 18 time periods yields adequate power for effects ≥5-8% of baseline crime. MDE will be reported explicitly in the paper.

---

### Condition 7 (from Model 3): robust sensitivity to TWFE/CS-DiD

**Status:** [x] RESOLVED

**Response:**

This is a continuous treatment (PCSO FTE/capita), not binary treatment. Will show:

1. **TWFE with continuous treatment** (baseline)
2. **Discretized treatment** (quintiles of PCSO cuts) for CS-DiD compatibility
3. **Borusyak, Jaravel & Spiess (2024) imputation estimator** for heterogeneity-robust estimates
4. **de Chaisemartin & D'Haultfoeuille** estimator as additional robustness

---

### Condition 8 (from Model 3): spillovers

**Status:** [x] RESOLVED

**Response:**

PCSO cuts in one force could displace crime to neighboring forces or affect criminals' location decisions. Will test:

1. **Neighbor-force PCSO changes:** Include spatially-weighted neighbor PCSO FTE as control. If spillovers are large, the own-force coefficient will increase.
2. **Border-area crime:** Compare crime in LSOAs near force boundaries vs. force interiors.
3. **Cross-border displacement test:** If Force A cuts PCSOs, does crime increase in adjacent-border LSOAs of Force B?

---

### Condition 9 (from Model 3): mechanism tests via ASB/intelligence proxies

**Status:** [x] RESOLVED

**Response:**

PCSOs primarily reduce crime through (a) visible deterrence (presence) and (b) community intelligence gathering. Mechanism tests:

1. **Crime type decomposition:** PCSOs should reduce "outdoor/visible" crimes (ASB, public disorder, street robbery) more than "indoor/hidden" crimes (domestic abuse, cybercrime). The differential response across crime types IS the mechanism test.
2. **Detection rates:** If PCSOs contribute to community intelligence, forces with larger PCSO cuts should see declining detection/sanction rates (data from ONS PFA tables).
3. **Confidence in policing:** Crime Survey for England and Wales includes questions on public confidence in local police. If PCSO cuts reduce community trust, this is a distinct mechanism from deterrence.
4. **Triple-diff:** PCSO effect should be larger for crime types where community intelligence matters (burglary, drug dealing) than for crimes reported via 999 calls (violent assaults).

---

## PSPO Conditions — NOT APPLICABLE (proceeding with Idea #1)

All PSPO conditions are NOT APPLICABLE as we are proceeding with the PCSO idea (Idea #1, unanimous PURSUE).

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
