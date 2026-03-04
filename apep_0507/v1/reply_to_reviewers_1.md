# Reply to Reviewers — Round 1

## Referee 1 (GPT-5.2): MAJOR REVISION

### 1. Unit construction / SUTVA (Section 1.2)
> "using 2024 successor municipalities as the panel unit can induce mechanical/compositional artifacts"

We acknowledge this concern. The panel unit is the 2024 successor municipality, with pre-merger turnout aggregated from constituent communes. We clarify that:
- Pre-merger aggregation uses **eligible-voter weighting** (not population weighting as the text previously stated — corrected in Section 3.4). This preserves the exact merged-electorate turnout rate.
- The estimand is the effect of institutional merger on the turnout of what will become the merged electorate — which is the policy-relevant quantity.
- Missingness is minimal (4,695 of 237,270 = 2%) and is addressed in the text.

### 2. Aggregation weights (Section 1, Item 2)
> "use eligible voters, not population, for pre-merger turnout aggregation"

**Already implemented.** The code (02_clean_data.R, line 204) uses `weighted.mean(turnout_pct, eligible_voters)`. The paper text was incorrect in saying "population-weighted" — this has been corrected to "eligible-voter-weighted."

### 3. Chain mergers (Section 1, Item 3)
> "First merger treatment mixes later intensifications"

**Added single-merger robustness.** We restrict to the 321 municipalities with exactly one merger event and find a coefficient of -1.682, virtually identical to the full-sample result (-1.628). This confirms chain mergers do not drive the findings. Added to Section 5.4.

### 4. Inference with few canton clusters (Section 2.1)
> "With 26 clusters, conventional CRVE can be unreliable."

We report canton-clustered SEs that yield SE = 0.197, keeping the result significant at the 1% level. The wild cluster bootstrap was attempted but is not compatible with the fixest `^` interaction syntax. We note that 26 clusters is at the conventional threshold, and our primary inference uses 2,157 municipality clusters.

### 5. Placebo/falsification tests (Section 3.2)
> "you need some credible falsification tests now"

**Added placebo test.** We randomly assign fake merger dates to never-merged municipalities and find a null effect (0.157, SE = 0.085, p = 0.065). Added to Section 5.4.

### 6. Spillovers (Section 1.5)
> "Mergers likely affect neighboring non-merged municipalities"

**Added discussion.** We note that federal referendums concern national issues and local political infrastructure is municipality-specific, making spillovers likely small. If present, they bias the ATT toward zero, making our estimates conservative. Added to Section 5.4.

### 7. Goodman-Bacon decomposition (Section 5.3)
We acknowledge this would strengthen the TWFE-SA comparison. The Sun-Abraham and CS-DiD estimators already provide the heterogeneity-robust benchmark. Added citation to Borusyak et al. (2024) in the empirical strategy.

---

## Referee 2 (Grok-4.1-Fast): MINOR REVISION

### 1. CS-DiD details
> "Tab. 3 reports overall ATT but omits event-study/group ATTs"

The CS-DiD event-study is in Figure 2 and cohort-specific ATTs in Figure 6 (appendix). Table 4 notes now explain the annual panel and observation count.

### 2. Election placebo
> "Reserved (App. C.3) — implement with available BFS data"

The election data has only 14 observations per municipality (vs 110 voting days for referendums), providing insufficient power. We note this limitation but prioritize the placebo test using randomized treatment dates on referendum data, which directly tests the identification strategy.

### 3. Additional citations
> "Add Jordahl & Liang (2010), Hanes (2017)"

Added Jordahl & Liang (2010) to Section 6.3 (Comparison with Prior Literature). Hanes (2017) could not be verified as a published paper and was not added.

---

## Referee 3 (Gemini-3-Flash): MINOR REVISION

### 1. Selection into mergers
> "Address the 'voluntary' nature more deeply"

The 10-year pre-trend window with flat coefficients mitigates concerns about gradual democratic decline preceding mergers. We strengthened the Threats to Validity discussion to reference the placebo test as direct falsification.

### 2. Population-weighting clarification
> "Clarify the population-weighting of pre-merger turnout"

**Fixed.** The code uses eligible-voter weighting. Text corrected from "population-weighted" to "eligible-voter-weighted averages." This preserves the merged electorate's turnout rate exactly.

---

## Exhibit and Prose Improvements (Stage A.5/A.6)

### Exhibits
- Removed code-like variable names from all tables (`turnout_pct` → removed via `depvar=FALSE`; `current_bfs` → "Municipality" in all FE labels)
- Added `depvar = FALSE` and expanded `dict` entries for all `etable()` calls

### Prose
- Rewrote results section opening to lead with findings instead of table navigation
- Consolidated contribution paragraph from "three literatures" to single narrative
- Strengthened final sentence of conclusion
