# GPT-5.2 Review

**Role:** External referee review
**Model:** openai/gpt-5.2
**Paper:** paper.pdf
**Timestamp:** 2026-03-04T20:23:40.788255
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 15521 in / 4875 out
**Response SHA256:** 43d874d3719c8fa0

---

## Summary

The paper studies whether voluntary Swiss municipal mergers reduce democratic participation, using municipality-level turnout in federal referendums (1990–2025) and 352 staggered merger events (1991–2024). The main estimates (TWFE with municipality FE and canton×vote-date FE; Sun & Abraham; Callaway & Sant’Anna) suggest turnout falls by roughly **1.2–3.1 pp** after mergers, with no differential pre-trends and stronger effects for smaller absorbed municipalities.

The question is important and well-matched to Swiss institutions and data richness. However, in its current form the paper is **not yet publication-ready for a top general-interest journal** because several design and inference choices create ambiguity about what variation identifies the effect, whether treatment is measured and assigned correctly under boundary harmonization, and whether the reported inference is valid given staggered adoption, multi-level aggregation, and the constructed panel. These issues are fixable, but require substantial additional work and transparency.

---

# 1. Identification and Empirical Design (Critical)

### 1.1 What is the estimand under the “2024 boundaries” panel construction?
A central design choice is to **map all historical municipalities to 2024 successor units** and (pre-merger) **aggregate turnout from multiple pre-merger communes into one successor-unit observation** (Data section, “Panel Construction and Harmonization”). This creates a consistent panel, but it changes the meaning of both the unit and the treatment:

- Before a merger, the “unit” (the 2024 municipality) is an **artificial coalition of separate political communities** that have not yet merged.  
- Treatment then becomes “the year the coalition becomes an actual municipality,” while outcomes before treatment are weighted averages across separate municipalities’ turnout.

This raises identification concerns beyond standard DiD:
- **Mechanical smoothing / attenuation:** Averaging across multiple communes pre-merger can reduce variance and potentially change the dynamics of turnout even absent treatment, especially if the underlying communes had different levels/trends. This can affect event-study lead coefficients and the post shift.
- **Composition changes in the electorate** are inherent to the aggregation: the set of eligible voters included in the “unit” changes discontinuously when you begin observing turnout at the merged entity (post) rather than an eligible-voter-weighted average of its components (pre). You argue the weighting “preserves the total turnout rate,” but that is true only if one defines the pre-period outcome as “what turnout would have been if the merged electorate existed already.” That is not the same as the observed political process.

**Concrete implication:** The paper’s main ATT is best interpreted as the effect of *administrative consolidation on turnout of the merged electorate*, not the effect on any original municipality’s turnout. That may be fine, but it needs to be (i) explicitly stated as the estimand and (ii) validated that results are not artifacts of this redefinition.

**Must-add validation:** Re-estimate using an alternative unit definition that stays closer to the original communes:
- A panel at **pre-merger commune boundaries** with treatment defined at the commune level (e.g., absorbed communes become treated at merger date; never-merged communes as controls), handling the fact that some units “die” (you can keep them with outcomes defined as the merged entity’s turnout afterward, but then you must be explicit about the estimand; or use methods for absorbing units).  
- Or a design that compares **absorbed communes** to similar non-absorbed communes within the same canton, using the commune as the unit and treating post-merger as “turnout of residents formerly in commune i” if you can map precinct/section results (if not possible, acknowledge).

At minimum, include a robustness check that uses **only mergers that are pure absorptions into an existing municipality** where you can keep a stable “recipient” unit pre/post (less artificial aggregation).

### 1.2 Treatment timing and event time are underspecified relative to vote-day data
Treatment is defined as “calendar year of the merger’s effective date” and applied to vote-day observations (Data + Empirical Strategy). Most Swiss mergers take effect on **January 1**, which helps, but the paper should be explicit:
- If a merger takes effect on Jan 1 of year g, then **all vote days in year g** are post. Good.  
- But if any mergers take effect on non-Jan-1 dates (even rarely), then some vote days in the “merger year” occur before treatment, causing misclassification.

**Must-fix:** Verify and report distribution of effective dates; if not always Jan 1, define treatment at the **exact date** and code post at the vote-day level.

### 1.3 “Voluntary” does not remove selection; it may intensify it
The key conceptual contribution is separating structural “size” effects from “resentment” in forced reforms. But voluntary mergers raise a different, potentially severe selection threat: merger propensity may be driven by **declining civic capacity**, fiscal stress, demographic change, or governance problems—each of which can independently affect turnout.

The paper leans heavily on “no pre-trends” as reassurance. That helps, but does not close the case because:
- Pre-trend tests have limited power and can miss **nonlinear selection** (e.g., turnout stable until a sudden shock triggers both merger and turnout decline).
- The long deliberation phase (Institutional Background) creates room for **anticipation and concurrent reforms** (mail voting diffusion, mobilization changes, local campaign infrastructure) that may start before the formal merger date.

**High-value improvements:**
- Add **diagnostics on observables** (population, age structure if available, fiscal variables, party organization proxies) in event-time around mergers to show no coincident changes that could drive turnout.  
- Implement **stacked DiD / cohort-specific stacking** (e.g., Cengiz et al.-style stacking) that restricts controls to never-treated and not-yet-treated within windows, to reduce contamination and make the identifying comparisons transparent.
- Explore an **instrumental-variables strategy** leveraging plausibly exogenous cantonal incentive program changes (Fribourg/Ticino/Glarus policy shifts are discussed but not used for identification). Even a “shift-share” style exposure to cantonal incentives, or a canton-policy timing design, could substantially strengthen causal claims if defensible.

### 1.4 Spillovers and interference are plausible and under-addressed
You note spillovers might bias toward zero but do not test them. With canton×vote-date FE, identification is within-canton on each vote day; if mergers change political mobilization networks, local media coverage, or campaign intensity in surrounding areas, controls may be partially treated.

**Concrete checks:**
- Define “neighbors” (same district / commuting zone / within X km if geography is available) and test for turnout changes among never-merged municipalities near mergers (a spatial event study).  
- Exclude municipalities in the same district as treated units as a robustness check.

### 1.5 Special case: compulsory voting in Schaffhausen
Schaffhausen has compulsory voting (with a fine), affecting turnout levels and possibly dynamics. The paper should either:
- exclude Schaffhausen or
- show results are robust to excluding it, and
- clarify whether any mergers occur there and how the canton×vote-date FE interacts with compulsory voting.

---

# 2. Inference and Statistical Validity (Critical)

### 2.1 Standard errors and clustering: several claims are not yet defensible
You cluster by municipality in the main vote-day panel regressions and show robustness to canton clustering and two-way clustering (Robustness table). Key problems:

1. **Canton clustering with 26 clusters is “stringent” but not automatically valid**: with 26 clusters, asymptotic cluster-robust inference can be unreliable; you should use **wild cluster bootstrap** (e.g., Cameron, Gelbach & Miller) for canton-level clustering if you want to interpret that column as convincing.
2. Two-way clustering by (municipality, vote date) is presented, but the SE gets *smaller*, which is unusual given strong common shocks at vote dates. This raises questions about:
   - implementation,
   - whether canton×vote-date FE already absorbs most date-level correlation, and
   - whether the remaining correlation structure is correctly handled.

**Must-fix:** For the main specifications, report inference using:
- **Wild bootstrap** at the canton level (or canton×year if relevant), and/or
- **Randomization/permutation inference** based on re-assigning treatment timing within canton under plausible assignment mechanisms, and
- For Sun-Abraham/CS estimators, use recommended bootstrap procedures and clearly state resampling unit (municipality, canton, etc.).

### 2.2 Staggered DiD: TWFE should not be framed as interpretable “baseline” without decomposition
You correctly cite negative weighting issues and provide Sun-Abraham. But the paper still interprets TWFE magnitudes substantively (Results section). Given the difference between TWFE (-1.6) and Sun-Abraham (-2.4), it is essential to show:
- a **Bacon decomposition** (or equivalent) for the TWFE,
- which comparisons drive the TWFE estimate,
- and whether already-treated units serve as controls (they will under standard TWFE).

**Must-fix:** Either (i) demote TWFE to purely descriptive and center the paper on heterogeneity-robust estimands, or (ii) provide full decomposition and explain why TWFE is informative here.

### 2.3 Callaway & Sant’Anna implementation is not comparable to main panel and seems underpowered/oddly scaled
The CS-DiD estimate is based on an **annual municipality-year panel** (Table 3), dropping to 76,117 observations. This creates multiple issues:

- It is not the same estimand as the vote-day panel unless you show equivalence. Averaging turnout across vote days changes weighting by vote-day salience and the number of vote days per year.
- The SE (0.894) is far larger than other approaches; this might reflect aggregation, bootstrap settings, or small effective sample after cohort-time cell construction.
- The table says “~1,535 municipality-year observations dropped,” which seems small relative to the difference between 2,157×36 ≈ 77,652 and 76,117, but the accounting should be explicit.

**Must-fix:** Implement CS-DiD at the **vote-day level** if feasible, or justify clearly why annual aggregation is necessary and show that results are consistent under both aggregations. Also report:
- number of treated cohorts and treated units used in CS,
- effective number of group-time cells,
- base period choice and sensitivity (universal vs varying base),
- bootstrap replications and resampling unit.

### 2.4 Placebo test is not interpreted correctly
You report a placebo with randomly assigned merger dates to never-merged municipalities yielding **0.157 (SE 0.085, p=0.065)** and call it “statistically insignificant and close to zero.” This is borderline and, more importantly, **a single random draw is not a valid placebo**.

**Must-fix:** Conduct a proper **randomization inference**:
- Repeat the placebo assignment many times (e.g., 1,000+), storing coefficients to form the empirical null distribution.
- Report where the true estimate lies relative to this distribution (randomization p-value).
- Do this within canton (preserve cantonal timing structure) and/or match the cohort distribution.

---

# 3. Robustness and Alternative Explanations

### 3.1 Population control is currently not credible due to imputation
Population data only starts in 2010; you carry forward 2010 to earlier years (Data section). This makes the population control largely time-invariant pre-2010 and potentially misleading, especially because:
- merger propensity is related to long-run demographic decline,
- and demographic trends may correlate with turnout.

**Must-fix (or remove):**
- Either obtain longer-run population series (Swiss municipal population exists historically in BFS/STATPOP predecessors, cantonal records, or decennial censuses), or
- drop population controls and avoid interpreting “channels beyond population change” based on a flawed control.

### 3.2 Confounding reforms: mail voting, political mobilization, and canton-level institutional changes
Switzerland saw large changes in voting convenience (mail voting adoption and usage growth) and potentially canton-specific reforms over 1990–2025. Canton×vote-date FE absorbs canton-level shocks common to municipalities, but if merged municipalities differentially adopt mail voting or experience administrative changes in vote administration, this could bias estimates.

**High-value checks:**
- If BFS provides mail-voting share by municipality (often available for elections; not sure for referendums), test whether mergers shift mode of voting.
- Test heterogeneity by period (pre/post key mail voting expansions) beyond the post-2000 split.

### 3.3 Heterogeneity analysis needs clearer separation between “absorbed” vs “absorber”
Your mechanism story emphasizes small municipalities being absorbed. But the heterogeneity uses “below-median pre-merger population among treated municipalities,” which—under the 2024-unit construction—may not cleanly distinguish absorbed components from absorbing entities.

**Concrete improvement:** Classify merger roles at the component level:
- Identify **absorbed vs continuing codes** (mutation type 26 absorption vs new creation type 21) and examine effects separately.
- For new municipalities created by merger of equals, treat separately.

### 3.4 External validity claims should be toned down unless mechanisms are tested more directly
The Discussion claims “pure institutional channel” and “structural enlargement” as the key mechanism. But there is limited direct evidence disentangling:
- identity disruption,
- changes in local political competition,
- changes in perceived efficacy,
- administrative complexity.

At minimum, treat these as plausible mechanisms, not demonstrated ones, unless you add supporting evidence (survey data on efficacy, local assembly attendance, candidate supply, party lists, etc.).

---

# 4. Contribution and Literature Positioning

The topic is well-motivated and potentially publishable, but the contribution claim (“clean separation from coercion channel”) is currently overstated because voluntary selection is itself a major confound.

**Literature gaps to address (suggested additions):**
- Modern staggered DiD and event-study practice:
  - Borusyak, Jaravel & Spiess (2021/2024) on imputation / robust event studies
  - Roth (2022) on pre-trend testing and power / sensitivity
  - de Chaisemartin & D’Haultfoeuille (2020+) on DiD with multiple time periods and heterogeneous effects
- Municipal mergers and political outcomes beyond the ones cited:
  - Additional European merger evidence (e.g., Norway, Netherlands) depending on what is closest; also work on representation/candidate entry after mergers.
- Swiss-specific merger research: you mention “fritz2020municipal” but the Swiss literature is larger (often in public admin/political science). A top journal will expect you to map that space carefully and clarify what is genuinely new (data span, staggered design, referendum frequency).

---

# 5. Results Interpretation and Claim Calibration

### 5.1 Magnitudes and persistence
- The main range (1.2–3.1 pp) is not trivial, but the paper repeatedly emphasizes “democratic costs” and “permanent loss” in strong language. Given:
  - the gap between estimators,
  - sensitivity to panel construction,
  - potential selection,
the conclusions should be **more calibrated** until the must-fix identification and inference issues are resolved.

### 5.2 “Pure institutional channel” is not supported as written
Even if coercion resentment is absent, voluntary mergers can coincide with:
- fiscal crises,
- local political dysfunction,
- demographic decline,
which can affect turnout. You need to either (i) isolate plausibly exogenous variation (e.g., incentive shocks) or (ii) frame the estimate as an effect of mergers *as they occur in equilibrium with selection*.

### 5.3 Aggregate “missing votes” calculation is not clearly correct
The “hundreds of thousands of missing votes” back-of-the-envelope depends on assumptions about:
- eligible voters per merged municipality (varies widely),
- how many referendums are affected per year,
- whether the ATT is per vote-day or per proposal.
Given the paper averages turnout across proposals per day, be careful not to overstate.

---

# 6. Actionable Revision Requests (Prioritized)

## 1) Must-fix issues before acceptance

1. **Clarify and validate the estimand induced by 2024-boundary harmonization**
   - **Why it matters:** The main panel redefines units pre-treatment, potentially creating artifacts and changing the causal question.
   - **Concrete fix:** Add alternative estimations that keep original commune units where possible (absorbed communes analysis; absorption-only sample; recipient-only sample), and explicitly define the causal estimand (merged-electorate turnout vs original-commune turnout).

2. **Fix treatment timing at vote-day level using exact effective dates**
   - **Why it matters:** Misclassification biases event studies and ATT.
   - **Concrete fix:** Use SMMT mutation dates to code post-merger at the exact vote date; document that effective dates are Jan 1 or handle exceptions.

3. **Provide valid inference for main estimates**
   - **Why it matters:** The paper cannot pass without defensible uncertainty quantification.
   - **Concrete fix:** Use wild cluster bootstrap (canton-level), plus municipality-level clustered SEs; for staggered DiD estimators, follow recommended bootstrap with clear resampling unit; add randomization inference for timing.

4. **Replace the single-draw placebo with proper randomization inference**
   - **Why it matters:** Current placebo is not informative and borderline significant.
   - **Concrete fix:** 1,000+ placebo reassignments (within canton and preserving cohort distribution), report the null distribution and randomization p-values.

5. **Reconcile CS-DiD with the main vote-day panel (or implement CS at vote-day level)**
   - **Why it matters:** Current CS result is not comparable and the observation count/inference are opaque.
   - **Concrete fix:** Run CS-DiD on vote-day data or show formally/empirically that annual aggregation yields the same estimand; fully report cohort-by-time cell counts, base periods, and bootstrap settings.

6. **Remove or fix population controls**
   - **Why it matters:** Carrying 2010 population backward undermines any demographic adjustment and channel interpretation.
   - **Concrete fix:** Obtain historical population series (preferred) or drop population-based channel claims and present population controls only where valid.

## 2) High-value improvements

7. **Stacked DiD / windowed comparisons**
   - **Why it matters:** Makes identifying comparisons transparent and reduces contamination from already-treated units.
   - **Concrete fix:** Stack event-time windows by cohort with never- and not-yet-treated controls; show robustness.

8. **Selection diagnostics around mergers**
   - **Why it matters:** Voluntary selection is the main alternative explanation.
   - **Concrete fix:** Event-time plots for demographics (if available), fiscal stress proxies, eligible voter counts, and other pre-determined covariates.

9. **Spillover tests**
   - **Why it matters:** Interference can bias ATT.
   - **Concrete fix:** Spatial exposure design; exclude nearby controls; test for effects on neighbors.

10. **Role-based heterogeneity (absorbed vs absorber; new creation vs absorption)**
   - **Why it matters:** Mechanism and interpretation depend on which residents experience the “dilution.”
   - **Concrete fix:** Use mutation types to classify roles and estimate separate event studies.

## 3) Optional polish (substance-facing, not prose)

11. **More disciplined claim language about mechanisms**
   - **Why it matters:** Aligns conclusions with evidence.
   - **Concrete fix:** Reframe mechanism section as hypotheses unless additional evidence is added (surveys, local political outcomes).

12. **Add a concise decomposition/explanation of TWFE vs Sun-Abraham differences**
   - **Why it matters:** Readers will ask why estimates differ by ~50–100%.
   - **Concrete fix:** Provide Bacon weights / cohort-weight summaries and interpret.

---

# 7. Overall Assessment

### Key strengths
- Important question with direct policy relevance in a canonical direct-democracy setting.
- Rich, high-frequency national referendum data and precise administrative merger records.
- The author recognizes staggered DiD pitfalls and uses Sun-Abraham and Callaway-Sant’Anna rather than relying solely on TWFE.
- Canton×vote-date fixed effects are a thoughtful way to absorb ballot salience and canton-level shocks.

### Critical weaknesses
- The **unit harmonization to 2024 boundaries** is not innocuous and may change the estimand and induce artifacts; this is currently the biggest barrier.
- **Inference and validation** are not yet at the standard required for top journals (placebo design, bootstrap/cluster issues, CS implementation comparability).
- Voluntary selection is not convincingly ruled out; “pure institutional channel” is overstated absent stronger designs or diagnostics.

### Publishability after revision
Potentially publishable if the paper (i) demonstrates that the core finding survives under alternative unit definitions / less aggregative constructions, (ii) strengthens inference substantially, and (iii) clarifies the estimand and selection story. As written, it is not ready.

DECISION: MAJOR REVISION