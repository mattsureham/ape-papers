# GPT-5.2 Review

**Role:** External referee review
**Model:** openai/gpt-5.2
**Paper:** paper.pdf
**Timestamp:** 2026-03-04T15:41:47.826703
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 22701 in / 5002 out
**Response SHA256:** 1b1e86cd34c122e8

---

## Referee Report: “The Democratic Cost of Consolidation: Municipal Mergers and Referendum Participation in Switzerland”

### Summary
The paper studies whether Swiss municipal mergers reduce participation in *federal* referendums, using commune-level turnout (1960–2025) and a merger registry (BFS mutations). The headline result is a sharp divergence between (i) a null TWFE estimate and (ii) a negative stacked DiD estimate (≈ −1.67 pp) attributed to strong differential pre-trends (“Ashenfelter’s dip”). The paper further argues that mechanism inference via dose-response (effect vs. merger size) is estimator-dependent: TWFE implies larger mergers have *smaller* turnout declines, while stacked DiD implies larger mergers have *larger* declines, interpreted as support for free-riding.

The topic is interesting and the Swiss referendum setting is potentially valuable. However, in its current form the paper is not publication-ready for a top general-interest journal because the causal design remains fragile even after stacking: the paper documents major pre-trend violations, but the preferred estimator does not convincingly restore identification, and the inference/estimand issues created by “current-boundary” outcome measurement are not fully confronted. The mechanism claim (free-riding vs. identity) is not yet convincingly identified.

Below I focus on scientific substance and publication readiness.

---

## 1. Identification and Empirical Design (Critical)

### 1.1. Fundamental tension: documented pre-trends vs. causal claims
- The paper’s TWFE event study shows large, statistically significant negative pre-trends for treated units (Figure 3 / Table 3; event times −10 to −4 mostly significant; joint F-test rejects).
- This is *not* a minor blemish; it is direct evidence that treated and control units are on different trajectories.

**Main concern:** The stacked DiD is presented as “addressing” this, but stacking + shorter windows does not by itself solve selection on trends. If the process generating mergers is precisely civic decline, then within-window parallel trends can still fail. The paper acknowledges this in places (HonestDiD bounds widen to include zero for moderate M), but the abstract, introduction, and conclusion still read as if the stacked estimate is a credible causal ATT.

**What is missing:** evidence that *within the stacked windows* pre-trends are plausibly absent (or small enough to be ignorable), and/or a design that explicitly models/controls for differential trends rather than hoping the window is short enough.

Concrete request:
- Report stacked event studies (or cohort-specific pre-trend coefficients aggregated appropriately) using the *same stacked design* as the main estimate. The paper currently shows a TWFE event study, which is not diagnostic for the stacked estimand.
- If pre-trends persist even in ±5 or ±3 windows, the stacked DiD is not identifying a causal effect without additional assumptions/adjustments.

### 1.2. Treatment definition and the “current boundaries” outcome measurement
A central feature of the BFS referendum data is that *all historical outcomes are retrospectively harmonized to 2025 commune boundaries* (Section 4.1, 4.3; Appendix A). This raises several identification/interpretation issues that are not fully resolved:

1. **Unit of observation is the successor entity even pre-merger.**  
   For a commune that merges in year g, the series before g is already an aggregation of the eventual merged geography. That means:
   - There is no “treated geography changed at g” in the measured data; the geography is constant by construction.
   - The “treatment” is then not a boundary change in measurement but a change in political/administrative institutions within a fixed (future) geography.

   That can still be a meaningful treatment (institutional consolidation), but it needs sharper articulation of what varies at g in the data and why turnout measured on a constant geography should jump at g absent confounding.

2. **Successor-only coding masks heterogeneous exposure within merged entities.**  
   The conceptual framework emphasizes absorbed vs. absorbing communes and identity loss for absorbed residents. But the data cannot separate these groups because pre-period outcomes are aggregated and post-period outcomes are also aggregated. This severely limits mechanism identification and even affects the main estimand: the “treated unit” is a composite of multiple pre-merger communes whose pre-trends may differ.

3. **Mechanical changes in eligible voter denominators at merger effective dates.**  
   The paper defines PostMerger from the merger year onward (Section 4.3). But in current-boundary data, “eligible voters” and “ballots cast” are also harmonized; it is unclear whether there is any discontinuity in denominators at g in this dataset. If the BFS backcasts eligibility counts too, then the “size ratio” and treatment timing could be partially artifacts of harmonization. This needs to be clarified and validated.

Concrete requests:
- Provide a precise data-generating description of how BFS constructs historical eligible voters and ballots cast under current boundaries. Are both numerator and denominator re-aggregated from original communes each date? Are weights contemporaneous?  
- Validate with at least one canton/merger case using non-harmonized/raw commune data (if available) or BFS documentation: show that a merger produces no mechanical discontinuity in the outcome series due purely to redefinition.
- Reframe the treatment as an *institutional change* rather than a change in geographic unit; then justify why the institutional change date is correctly aligned with observed turnout changes given retrospective boundary harmonization.

### 1.3. Staggered adoption, controls, and “never-treated” definition
The stacked design uses controls defined as “no merger during 2000–2020” (Section 5.3) and later checks “strictly never-merged” excluding post-2020 mergers (Section 7.5). This is good, but two issues remain:

- **Canton-level policy shocks and clustering of treatment timing.**  
  Merger waves are driven by canton incentives and reforms (Section 2.2). That makes “never-treated communes” within the same canton potentially poor counterfactuals if canton-level civic trends or political mobilization trends differ during merger waves.

  At minimum, the paper should show:
  - results with canton×date fixed effects (or canton-specific time trends / canton×year FE) to absorb canton-wide shocks in referendum participation and political engagement that could coincide with merger policy rollouts.
  - a design that compares treated communes to controls within the same canton (or within matched cantons), because cross-canton comparisons are particularly vulnerable here.

- **Announcement/anticipation vs. selection** is asserted rather than tested.  
  The paper argues the pre-trend begins too early for anticipation (Section 5, Threats: anticipation). But merger policy programs and discussions can start years earlier; plus, “anticipation” at the commune level may begin when cantons start offering subsidies or pushing consolidations. If those canton-level policies also affect participation (through political mobilization, salience of local governance issues, etc.), then pre-trends could be policy-induced.

Concrete requests:
- Explicitly incorporate canton-policy timing: e.g., interactions for when a canton introduced major merger incentive programs; or canton×year FE; or restrict identification to within-canton variation by adding canton×date FE in stacked design.
- Provide evidence on pre-trends relative to canton policy adoption dates, not only merger effective dates.

### 1.4. The mechanism test is not identified as stated
The paper interprets the stacked dose-response gradient (Post × log(SizeRatio)) as “confirming free-riding” and rejecting identity-loss (Sections 6.5, 8.2, conclusion). This is not yet credible because:

- **Merger size is endogenous** to the same selection process. Larger mergers may occur where (i) cantons push aggressively, (ii) civic decline is worse, (iii) parties mobilize differently, or (iv) administrative capacity is different.
- Identity-loss predictions in the conceptual framework depend on *type* (absorption vs fusion) and on which residents lose identity; but the outcome is aggregated at successor level.
- The paper acknowledges post-treatment dynamics suggest partial recovery and says that is “more consistent with identity loss” (Section 6.4), which sits uneasily with “free-riding confirmed.”

Concrete requests:
- Treat dose-response as descriptive heterogeneity unless you provide an identification strategy for size variation (e.g., instrument size ratio with plausibly exogenous geographic/topographic constraints, historical settlement patterns, or canton-imposed minimum-size rules).
- At minimum, present heterogeneity by merger type (absorption vs fusion/aggregation) *within the stacked framework*, and interpret cautiously given aggregation.

---

## 2. Inference and Statistical Validity (Critical)

### 2.1. Standard errors in stacked designs with repeated controls
The stacked dataset repeats the same control communes across cohorts (Section 5.3; N inflates to 3.85 million). The paper clusters at the original commune level, which is necessary but may not be sufficient:

- Because the same commune appears in multiple cohort-stacks, residual correlation may also be cohort-specific and date-specific in a way not captured by one-way clustering. Many stacked DiD implementations recommend:
  - two-way clustering (commune and cohort, or commune and calendar date), or
  - randomization/wild bootstrap procedures tailored to few clusters at higher levels.

You do cluster by canton as a robustness check (SE rises to 0.359), which is helpful, but canton clustering yields only 26 clusters—borderline for asymptotic cluster-robust inference.

Concrete requests:
- Report **wild cluster bootstrap** p-values for canton-clustered inference (Cameron, Gelbach & Miller-style wild bootstrap) or randomization inference at the canton level if appropriate.
- Consider two-way clustering in stacked regressions (commune × referendum date) because referendum-date shocks are common and treated/control composition changes by cohort.
- Provide sensitivity of significance to alternative inference approaches explicitly in the main results table (not only a note).

### 2.2. HonestDiD application mismatch with preferred estimator
The HonestDiD sensitivity analysis is applied to the TWFE event-study estimates (Section 7.1; Appendix B). But the preferred causal estimate is stacked DiD. If TWFE is known to mix comparisons and be contaminated in staggered settings, then sensitivity bounds based on TWFE event-study coefficients may not speak directly to the stacked estimand.

Concrete request:
- Implement HonestDiD (or an analogous sensitivity analysis) using the **stacked event-study** estimates corresponding to the preferred design. If HonestDiD cannot be directly applied, explain why and offer an alternative sensitivity analysis consistent with the stacked estimand (e.g., pre-trend adjustments, linear trend extrapolation, or bounds based on within-window pre-trend slopes).

### 2.3. Randomization inference is currently not well targeted
The RI exercise permutes merger years and re-estimates TWFE (Sections 5.6, 7.2). But:
- The paper’s core claim is that TWFE is misleading due to selection on trends; permuting years does not replicate the selection process and therefore has ambiguous interpretability.
- RI on TWFE mainly shows TWFE returns ~0 under random timing, which is unsurprising and not very informative about the stacked estimate.

Concrete requests:
- If you keep RI, apply it to the **stacked estimator** (or at least to a design closer to the preferred estimator) and explain what sharp null is being tested given staggered adoption and cohort windows.
- Alternatively, drop RI from the central narrative and treat it as a minor diagnostic.

### 2.4. Coherence of sample sizes and treatment counts
Tables are mostly coherent, but there are some red flags to resolve:
- “Treated communes = 197” are “successor entities” (TerminalCode). But merger events are 637 overall and 2000–2020 events yield 197 treated successor communes—this mapping from events to successor communes needs to be explicit: multiple events can yield the same successor over time; some successors may be treated multiple times (absorbing again later). How are multiple mergers handled?
- If a commune merges more than once within 2000–2020, the “treatment” is not a one-time adoption.

Concrete requests:
- Clarify whether treated units can have multiple merger effective dates within the analysis window, and if so how you code treatment timing (first merger, last merger, any merger) and how that affects stacking windows and event time.
- Provide counts: number of successor communes with multiple merger events; distribution of number of events per treated unit.

---

## 3. Robustness and Alternative Explanations

### 3.1. Need designs that explicitly address differential trends
Given the central threat is differential trends, robustness should include tools designed for that threat, not only window changes.

High-value checks:
- Add **unit-specific linear trends** (or canton-specific trends) in the stacked window regressions; see whether the post indicator survives.
- Use **pre-trend slope matching** (match on 1990–1999 or 1995–1999 slopes) rather than level matching (you already note this limitation).
- Implement modern staggered estimators that explicitly avoid TWFE issues without stacking:
  - Callaway & Sant’Anna (2021) group-time ATT with never-treated controls,
  - Sun & Abraham (2021) interaction-weighted event study,
  - Borusyak, Jaravel & Spiess (2021/2024) imputation estimator.
  These will not solve selection on trends automatically, but will help separate “TWFE negative weights” from “true pre-trend selection” and provide convergent evidence.

### 3.2. Canton-level confounding and spillovers
Because referendums are federal, canton-level political mobilization, party strength, and media coverage could drive turnout trends. Merger waves are canton-driven. This is a prime confounding channel.

Concrete checks:
- Include canton×referendum-date fixed effects (absorbing canton-specific turnout shocks on each date).
- Restrict to within-canton comparisons: for each cohort, only use controls from the same canton as treated units (or nearest-neighbor canton matching).
- Consider spillovers: mergers may change political engagement in neighboring communes (e.g., intercommunal competition, shared administration). If so, “controls” in the same canton might also be affected, biasing toward zero. Discuss direction and test with distance-to-treated exposure.

### 3.3. Timing granularity (years vs referendum dates)
Event time is defined in years, but there are multiple referendum dates per year and the number varies. Treatment is coded by “calendar year of merger” (Section 4.3). This can create misalignment:
- A merger effective January 1 vs December 31 within the same year changes which referendum dates are post.
- Using years could classify some pre votes as post (or vice versa).

Concrete request:
- Code treatment at the referendum-date level using exact merger effective dates relative to referendum dates (day/month), not just year. Switzerland referendum dates are known precisely; merger effective dates are precise in the registry. This is feasible and important.

---

## 4. Contribution and Literature Positioning

### 4.1. Contribution is potentially valuable but currently overstated
The “first comprehensive evidence on municipal consolidation and direct democratic participation” claim is plausible, but the paper’s identification uncertainty (and heavy reliance on an estimator choice narrative) makes the contribution feel more methodological than substantive. If the journal is general-interest, the substantive claim must be on firmer causal ground.

### 4.2. Missing/underused relevant literatures
You cite much of the municipal merger turnout literature. Methodologically, consider adding and engaging more directly with:
- **Sun & Abraham (2021)** on event studies with staggered adoption (you cite them once; should be more central given the event-study emphasis).
- **Borusyak, Jaravel & Spiess (2021/2024)** imputation approach (“revisiting event-study designs” is cited but not implemented).
- **Roth (2022)** and related work on pre-trend testing, power, and interpretation in DiD event studies (useful given your strong pre-trends).
- If you lean on “Ashenfelter’s dip” framing, connect to **Heckman & Hotz (1989)** style pre-program tests and their limitations (you cite Heckman 1999 but not the more direct pre-trend-test critique).

Policy-domain additions (depending on your framing):
- Swiss political participation and local identity literature beyond Kriesi/Funk/Freitag, particularly on communal attachment and turnout heterogeneity.

---

## 5. Results Interpretation and Claim Calibration

### 5.1. Over-claiming given HonestDiD results
Your own HonestDiD bounds (Table 7 / Appendix B) imply that for moderate violations of parallel trends the 95% set includes zero. That is an important caveat, but it conflicts with strong statements like “mergers reduce referendum turnout by 1.67 pp” (abstract and conclusion) and “confirming free-riding.”

Concrete request:
- Rewrite main takeaways to reflect that the sign is consistently negative across many specifications, but the magnitude/significance depend on assumptions about counterfactual trends—even within the stacked framework unless you can demonstrate within-window parallel trends.

### 5.2. Mechanism inference is not “confirmed”
The sign reversal is interesting and worth reporting as a warning about estimator dependence. But concluding that it “confirms free-riding” is too strong given:
- endogenous size,
- inability to separate absorbed vs absorbing turnout,
- mixed dynamic patterns (immediate drop + partial recovery).

Better framing:
- “Heterogeneity is consistent with free-riding *conditional on identifying assumptions*; TWFE can be misleading for mechanism tests.”

### 5.3. Back-of-the-envelope policy aggregation is likely overstated
The “~90,000 fewer votes per year” calculation (Section 8.1) assumes 10 referendums per year and multiplies treated communes, but turnout is measured on federal referendums where national turnout is millions; the normative meaning of 90k fewer ballots depends on whether this is net of substitution, whether treated communes are small, etc. This is not wrong mechanically but should be contextualized.

---

## 6. Actionable Revision Requests (Prioritized)

### 1) Must-fix issues before acceptance
1. **Demonstrate (or refute) parallel trends within the stacked design.**  
   - *Why it matters:* stacking does not automatically address selection on trends; without this the causal claim is not credible.  
   - *Fix:* present stacked event studies and pre-trend tests for ±5 and ±3 windows; report how much pre-trend remains. If pre-trends persist, implement trend-adjusted models (unit-specific trends) and/or redesign identification.

2. **Resolve treatment timing at the referendum-date level using exact effective dates.**  
   - *Why it matters:* year-level coding can misclassify treatment status; event-time dynamics are central to the paper.  
   - *Fix:* define PostMerger by whether referendum date occurs after the exact merger effective date; redo main estimates and event studies.

3. **Clarify and validate implications of “current boundary” harmonization for identification.**  
   - *Why it matters:* it changes what the treatment is, creates aggregation issues, and can induce artifacts.  
   - *Fix:* provide BFS documentation and/or validation exercise; clearly define estimand and how pre-merger outcomes are constructed for successor units; discuss implications for mechanism claims and for interpreting size ratio.

4. **Upgrade inference for stacked design with repeated controls and few higher-level clusters.**  
   - *Why it matters:* top journals will not accept fragile standard errors.  
   - *Fix:* report two-way clustering (commune×date) and wild cluster bootstrap for canton clustering; show robustness of significance.

5. **Handle multiple mergers per unit explicitly.**  
   - *Why it matters:* treatment is not necessarily single-shot; mis-coding undermines staggered designs.  
   - *Fix:* document frequency; choose and justify first-merger vs last-merger timing; ensure stacking windows exclude subsequent mergers or treat them appropriately.

### 2) High-value improvements
6. **Implement additional staggered DiD estimators (C&S, Sun-Abraham, BJS imputation) and compare.**  
   - *Why it matters:* helps separate “TWFE weighting” from “trend selection,” triangulates results.  
   - *Fix:* report ATT and event study dynamics under these estimators using never-treated controls.

7. **Address canton-level confounding more directly.**  
   - *Why it matters:* mergers are canton-driven; turnout trends can be canton-driven.  
   - *Fix:* include canton×date FE; or restrict to within-canton controls; or add canton-policy timing controls.

8. **Recalibrate mechanism claims.**  
   - *Why it matters:* endogenous size and aggregation prevent “confirmation.”  
   - *Fix:* treat dose-response as suggestive; add heterogeneity by merger type; if possible instrument size or exploit quasi-rules.

### 3) Optional polish (substantive, not stylistic)
9. **Outcome decomposition:** ballots cast vs eligible voters (turnout denominator changes).  
   - *Why it matters:* turnout changes could reflect eligibility composition shifts.  
   - *Fix:* examine whether mergers affect eligible voter counts or registration patterns; show effects on numerator and denominator separately where feasible.

10. **Spillovers/neighbor effects:** test whether nearby controls change when neighbors merge.  
   - *Why it matters:* could bias control trends and affect interpretation.  
   - *Fix:* include distance-weighted exposure or exclude neighbors as controls.

---

## 7. Overall Assessment

### Key strengths
- Important question with a distinctive Swiss direct-democracy setting and rich long-run data.
- Transparently documents strong differential pre-trends; commendable to foreground this rather than bury it.
- The estimator-dependence of dose-response is a potentially useful warning for applied work.

### Critical weaknesses
- Identification is not yet credible: the preferred stacked DiD is not shown to satisfy within-window parallel trends, and the paper’s own sensitivity analysis suggests the effect could be zero under moderate trend violations.
- Treatment timing and “current boundary” harmonization create conceptual and practical threats that are not fully addressed.
- Inference for stacked repeated-control design needs strengthening.
- Mechanism inference is overstated relative to what the data can identify.

### Publishability after revision
With substantial redesign/strengthening—especially (i) referendum-date-precise timing, (ii) stacked-design pre-trend diagnostics and/or explicit trend adjustments, (iii) stronger inference, and (iv) more cautious mechanism claims—the paper could become competitive. As written, it is not yet at the standard for AER/QJE/JPE/ReStud/Ecta/AEJ:EP.

DECISION: MAJOR REVISION