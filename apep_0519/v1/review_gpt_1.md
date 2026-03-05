# GPT-5.2 Review

**Role:** External referee review
**Model:** openai/gpt-5.2
**Paper:** paper.pdf
**Timestamp:** 2026-03-05T13:28:35.537727
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 19853 in / 3825 out
**Response SHA256:** f6ed06acf670e112

---

## Summary

The paper asks an important policy question—whether stricter building energy codes causally accelerate heat pump adoption—and exploits staggered cantonal adoption of MuKEn 2014 in Switzerland using canton-by-year heating-system shares from the GWR/BFS. The headline conclusion is “small and sensitive effects,” with TWFE imprecise and a Sun–Abraham (SA) ATT statistically significant but very small.

The core problem is that **the available outcome data are missing exactly when treatment turns on for most cantons (2016–2020)**, leaving only **two post-period observations (2021–2022)** for the main panel. This severely weakens identification, makes the parallel-trends assumption largely unassessable in the relevant window, and creates substantial scope for confounding from time-varying canton-level policies and compositional changes. In its current form, I do not think the paper meets the identification/inference standard for a top general-interest journal, though it could become publishable with a redesigned empirical strategy and richer data (ideally microdata on installations/replacements or permit-level flows).

Below I focus on scientific substance and publication readiness.

---

# 1. Identification and empirical design (critical)

### 1.1 The “staggered DiD” is effectively a long-difference with heterogeneous exposure, not a conventional staggered panel
- The main panel has years **2009–2015 and 2021–2022** (Section 3.1). Treatment adoption occurs **2017–2022 for treated cohorts**, mostly inside the **2016–2020 gap**. So for a canton adopting in 2017 vs 2020, you do not observe any outcomes near adoption; you observe the stock share in 2021/2022 after varying “exposure length.”
- This is not a standard staggered DiD where one can inspect dynamic effects or pre-trends around treatment. It is closer to **two-period DiD with a dose/exposure gradient**, identified off cross-sectional differences in adoption timing interacted with a common pre/post break. That’s a legitimate estimand, but it must be framed as such and assessed accordingly.

**Why it matters:** With adoption largely unobserved, the design is vulnerable to *any* canton-specific shocks between 2015 and 2021 correlated with adoption timing (e.g., cantonal subsidy expansions, air-quality rules, political shifts, differential construction booms, urbanization, migration).

### 1.2 Parallel trends is only assessed in 2009–2015, not in the critical 2015–2021 interval
- Figure 1 shows roughly parallel pre-trends through 2015, but the identifying counterfactual requires that (absent MuKEn) treated and control cantons would have evolved similarly **through the missing period** when heat pumps accelerate and cantons adopt.
- The paper acknowledges this (Limitations), but the credibility hinge remains unresolved.

**Concrete improvement needed:** Provide evidence that *other* outcomes that should move similarly (or not) do not exhibit differential trends in the gap, or bring in data that bridge the gap (see Must-fix list).

### 1.3 Treatment is measured as “adoption year into force,” but implementation intensity and scope plausibly vary
- Section 2 notes cantons can adopt modules and adapt provisions; Section “Limitations” acknowledges binary treatment may attenuate effects. In practice, heterogeneity in enforcement, exemptions, and module adoption is likely first-order and correlated with adoption timing (e.g., early adopters may implement more stringent versions and also have stronger complementary policies).
  
**Why it matters:** Mis-measurement plus selection into treatment timing can easily produce both attenuation and spurious “effects” on non-target outcomes (as already suggested by the wood placebo).

### 1.4 Selection into adoption timing is a major threat and is not convincingly addressed
- The paper states early adopters are greener/urban/French-speaking (Section 2.3). That is precisely why one expects **differential concurrent policies** (subsidies, information campaigns, municipal bans, air-quality rules) and differential preferences.
- Canton FE absorb time-invariant differences, but not **time-varying** policy packages that likely move with adoption.

**What’s missing:** Any systematic control for **cantonal policy bundles** (subsidy generosity over time, permitting/retrofit programs, municipal fossil bans, air-quality rules on wood, grid constraints), or a strategy to isolate MuKEn from those (e.g., exploiting within-canton discontinuities tied to code applicability).

### 1.5 The “placebo failure” on wood is not a side note; it is a serious identification red flag
- Table 1 shows wood share falls significantly in treated cantons (and the paper calls it a placebo). If wood is not directly targeted (and may be favored as renewable), a significant negative estimate indicates **either**: (i) important omitted concurrent policies correlated with MuKEn timing (e.g., particulate matter restrictions), **or** (ii) systematic compositional shifts correlated with adoption timing, **or** (iii) non-parallel trends.
- In any of these cases, interpreting the fossil/gas reductions as causal becomes difficult; and even the “null” on heat pumps is not automatically reassuring because bias can go either way.

---

# 2. Inference and statistical validity (critical)

### 2.1 Cluster-robust SE with 26 clusters is borderline; you appropriately add wild bootstrap and randomization inference (RI) for TWFE
- The paper does the right thing by supplementing cluster-robust SE with wild cluster bootstrap and RI for the TWFE estimate (Section 4.5; Appendix Table “Robustness of Inference”). This is a strength.

### 2.2 The Sun–Abraham result is not inferentially credible as currently implemented/reported
- The SA ATT has SE **0.00094** vs TWFE SE **0.0081** (Table “Sun-Abraham”), nearly an order of magnitude smaller, which is extremely unusual given the same underlying canton-year aggregation and only two post years.
- You note PSD correction and a dropped cohort, but the explanation given (“aggregation reduces variance”) is not sufficient. With 26 clusters and highly persistent shares, such precision is implausible without strong functional restrictions or an error in the variance computation.

**Must-fix:** Recompute SA inference using:
1. **Cluster-robust by canton** with small-sample correction, and
2. **Wild cluster bootstrap** for SA (not just TWFE), and/or
3. A design-based RI appropriate for staggered timing (e.g., permuting adoption years and re-estimating SA ATT).
If the SA “significance” disappears under valid few-cluster inference, the abstract and conclusions must change.

### 2.3 Randomization inference procedure needs tighter alignment with institutional constraints
- The RI described permutes “adoption year across cantons” (Section 4.5). But actual adoption timing is not exchangeable: there are language-region clusters, urbanization, referendum institutions, and EnDK coordination that make some permutations unrealistic.
  
**Better:** Use **restricted randomization** (e.g., permute within language regions or within bins of pre-period heat pump levels/trends, or within political/income strata), and show sensitivity.

### 2.4 Multiple outcomes + multiple inference procedures: control familywise error or clearly label exploratory results
- Table 1 runs six outcomes; later you discuss significant gas/fossil/wood. With small N and correlated outcomes (shares sum to ~1), nominal p-values can mislead.

**Fix:** Report adjusted q-values (e.g., Benjamini–Hochberg) or pre-specify primary outcomes and treat others as secondary/exploratory.

---

# 3. Robustness and alternative explanations

### 3.1 Robustness is extensive given constraints, but many checks are not decisive because they cannot address the 2015–2021 confounding window
- Excluding 2022 does not address 2015–2021.
- Balanced panel is irrelevant because missingness is by design (whole years missing).
- Long-difference (Panel C of Table “Extended Specifications”) is useful and arguably the cleanest representation of what you can identify, but it still rests on the same assumption about the missing window.

### 3.2 Mechanisms are asserted but not testable with stock shares
- The institutional story says MuKEn affects **new construction** and **replacement at renovation**, which are flows. Your dependent variables are **stocks** (shares of existing buildings), which respond slowly and are mechanically diluted by the huge installed base.
  
**Implication:** Even a policy that strongly affects the flow could generate tiny stock effects, especially over 1–5 years. The paper acknowledges this qualitatively, but it means the null on stock shares cannot be interpreted as “code doesn’t matter” without linking to flows.

**High-value improvement:** Use **microdata or auxiliary flow data**:
- permits/building completions by heating type,
- heating-system replacement permits,
- installer/market sales by canton,
- or GWR microdata fields on installation year / renovation year (if available).
This would align outcome measurement with the policy margin.

### 3.3 Alternative explanations likely dominate and should be modeled explicitly
Given the wood placebo and selection into adoption timing, you should treat “MuKEn adoption” as part of a **policy bundle**. At minimum, assemble a canton-year panel of:
- subsidy levels and eligibility rules (cantonal top-ups),
- municipal fossil restrictions (where present),
- air-quality ordinances on wood burning,
- district heating expansion plans,
- electricity price differences and grid constraints,
- construction activity (new builds per capita), renovation rates.

Then assess whether MuKEn retains explanatory power conditional on these.

---

# 4. Contribution and literature positioning

### 4.1 Substantive contribution is potentially valuable, but currently limited by data/design
A credible causal estimate of building code effects on heating technology choice would be publishable and policy-relevant. The Swiss federal structure is an attractive lab.

### 4.2 Literature coverage: add key DiD design and policy evaluation references
You cite Goodman-Bacon, Sun–Abraham, Callaway–Sant’Anna. I recommend adding:
- **Roth et al. (2023/2024)** DiD robust inference/event study guidance (for practical diagnostics).
- **de Chaisemartin & D’Haultfœuille (2020, 2022)** on TWFE with heterogeneous effects and alternative estimators.
- **Freyaldenhoven et al. (2019)** on pre-trend testing and power (relevant given limited pre/post).
- For building decarbonization / heating transitions: consider work on heat pump subsidies and bans in Europe (there is a growing applied literature; even a few examples would help anchor magnitudes and mechanisms).

(Exact citations can be tailored, but these are the missing “expected” econometrics references in top journals.)

---

# 5. Results interpretation and claim calibration

### 5.1 The abstract and intro overstate what can be learned causally from the current dataset
- The paper says it “estimates the causal effect” and that “secular trends dominate” (Abstract/Introduction). Given the untestable 2015–2021 parallel trends and the placebo failure, the correct posture is more cautious: *“We find little evidence of incremental stock-share changes associated with earlier MuKEn adoption in 2021–2022, but estimates are sensitive and may reflect confounding policy bundles.”*

### 5.2 The Sun–Abraham “significant” ATT should not be highlighted until inference is fixed
- Right now the paper emphasizes SA p=0.009 while also reporting RI/bootstraps that cannot reject zero (for TWFE). Without comparable robust inference for SA, the emphasis is not warranted.

### 5.3 Policy implications and cost-effectiveness calculations are too strong given uncertainty and stock/flow mismatch
- The back-of-envelope uses the TWFE point estimate to infer “12,400 additional heat pumps,” but TWFE CI includes negative values, and even positive stock changes could arise through reclassification or compositional shifts.
- Also, attributing stock-share change to new installations vs replacements is speculative without flow data.

**Fix:** Either drop this section or reframe as *illustrative conditional on (i) causal interpretation and (ii) flow composition assumptions*, and propagate uncertainty using the full confidence interval (including zero).

---

# 6. Actionable revision requests (prioritized)

## 1) Must-fix issues before acceptance

1. **Redesign identification to address the 2016–2020 outcome data gap**
   - **Why:** The gap coincides with treatment rollout, undermining causal interpretation and preventing event-study diagnostics.
   - **Fix options (any viable path):**
     - Obtain **annual canton outcomes for 2016–2020** from GWR microdata or alternative BFS extracts (even if classification differs, build a crosswalk).
     - Or pivot to **microdata/flow outcomes** (new builds or replacements by heating type) observed annually through the rollout.
     - Or use **municipality-level** panel (many more clusters and variation), ideally with continuous registry updates.

2. **Fix inference for Sun–Abraham (few clusters + PSD correction)**
   - **Why:** The main “significant” result appears driven by an implausibly small SE.
   - **Concrete fix:** Re-estimate SA with (i) canton-clustered vcov with small-sample correction, (ii) wild cluster bootstrap p-values/CI for SA ATT, and (iii) a permutation/RD-style randomization inference for SA. Report diagnostics and reconcile differences.

3. **Address placebo failure and time-varying confounding explicitly**
   - **Why:** Significant “placebo” effects indicate non-parallel trends or omitted correlated policies.
   - **Fix:** Compile and control for **time-varying canton policy covariates** (subsidies, air-quality wood restrictions, district heating expansions, municipal mandates). At minimum, show that results are robust to including these controls or that they explain the placebo.

4. **Clarify the estimand and limit claims accordingly**
   - **Why:** Current framing suggests clean causal effect of adoption; the design identifies association between earlier adoption and 2021–22 stock shares under strong assumptions.
   - **Fix:** Rewrite empirical strategy/results framing: define estimand as medium-run stock-share difference by exposure length; temper causal language unless the gap is resolved.

## 2) High-value improvements

5. **Move from stock shares to flow measures aligned with policy margins**
   - **Why:** Codes primarily affect new construction and replacements.
   - **Fix:** Use permit/completions data or GWR installation-year fields to measure: probability a *new* building has a heat pump; probability a *replacement* chooses a heat pump; estimate effects on these margins.

6. **Strengthen RI with restricted assignment consistent with institutions**
   - **Why:** Exchangeability across cantons is questionable.
   - **Fix:** Restricted permutations within strata (language region, urbanization, pre-trends) and show robustness.

7. **Multiple-testing adjustments and pre-analysis hierarchy of outcomes**
   - **Why:** Six outcomes + exploratory mechanisms with small N invites false positives.
   - **Fix:** Pre-specify primary outcome(s) and adjust p-values for families.

## 3) Optional polish

8. **Formalize discussion of policy heterogeneity (modules/enforcement)**
   - **Why:** Binary treatment likely mismeasures intensity.
   - **Fix:** Code an index of MuKEn module adoption and enforcement dates; estimate dose-response.

9. **Add power calculations tied to realistic effect sizes**
   - **Why:** Readers need to know what effects the design can rule out.
   - **Fix:** Minimum detectable effect under few-cluster inference and under long-difference.

---

# 7. Overall assessment

### Key strengths
- Important policy question with broad relevance (codes vs price incentives in decarbonization).
- Transparent about estimator sensitivity and modern DiD concerns; includes wild bootstrap and RI for TWFE.
- Uses high-coverage administrative registry data and a compelling institutional setting.

### Critical weaknesses
- **Fundamental identification weakness from missing 2016–2020 outcomes during the rollout**, preventing credible causal attribution.
- **SA inference appears unreliable**; current highlighting of statistical significance is not publication-ready.
- **Placebo failure (wood) strongly suggests confounding or non-parallel trends**, undermining causal interpretation for all outcomes.
- Stock-share outcomes are poorly matched to the code’s main margins (new build/replacement flows).

### Publishability after revision
Publishable in a top field/general journal **only if** the authors can (i) bridge the rollout window with data or (ii) pivot to flow/micro outcomes that are observed during rollout, and (iii) deliver defensible few-cluster inference for the preferred estimator(s). Without that redesign, the paper’s main conclusions will remain too assumption-driven for AER/QJE/JPE/ReStud/Ecta/AEJ:EP standards.

DECISION: REJECT AND RESUBMIT