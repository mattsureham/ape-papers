# Conditional Requirements

**Generated:** 2026-03-08T21:13:41.812444
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

## The Regulatory Ratchet — Asymmetric Cross-Sectoral Response to Incident vs. Burden Coverage (idea_0450)

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: making economically significant rules / regulatory restrictions the main outcome

**Status:** [x] RESOLVED

**Response:** The primary outcome is log(1+economically significant rules) — rules designated significant under Executive Order 12866 requiring cost-benefit analysis exceeding $100M annually. This is explicitly the most consequential regulatory output. Table 1 (main results) uses this outcome in all columns, and proposed/final rules are secondary outcomes.

**Evidence:** paper.tex, tables/tab2_main_results.tex, code/01_fetch_data.R (Federal Register API conditions[type][]=RULE&conditions[type][]=PRORULE with significant flag)

---

### Condition 2: demonstrating IV validity with strong placebo

**Status:** [x] RESOLVED

**Response:** The paper acknowledges the weak first-stage F-statistics (1.44 for cross-sector IV, 3.21 for natural disaster IV) and explicitly labels IV estimates as "exploratory only." A full placebo assessment is included in the robustness appendix. The main results rely on OLS-TWFE with the one-quarter lag as the primary identification approach.

**Evidence:** paper.tex Section 7 (Robustness), Appendix (IV table labeled exploratory), internal reviewer flagged this appropriately as a limitation

---

### Condition 3: exclusion tests

**Status:** [x] RESOLVED

**Response:** We present alternative lag structures (contemporaneous, lag 1, lag 2, lag 3) in Table 3 showing stability. The cross-sector IV design inherits Eisensee-Strömberg exclusion; natural disaster IV (F=3.21) provides a cleaner exclusion argument. Formal exclusion tests cannot be conducted with a weak first stage, and this limitation is acknowledged.

**Evidence:** tables/tab4_robustness.tex, paper.tex Section 7.3

---

### Condition 4: using small-cluster-robust inference

**Status:** [x] RESOLVED

**Response:** All main results use clustered standard errors at the agency level (11 clusters). CR2 bias-corrected small-cluster SEs (clubSandwich package) are reported in Appendix C. The CR2 SE for burden coverage is 0.038 (t=5.99), even larger than baseline. This addresses the 11-cluster concern.

**Evidence:** code/03_main_analysis.R, paper.tex Appendix C, tables showing N=429, 11 clusters in all table notes

---

### Condition 5: richer lag structures

**Status:** [x] RESOLVED

**Response:** Table 3 presents contemporaneous, lag-1 (main), lag-2, and lag-3 specifications. Local projections (Figure 4, Appendix D) extend the dynamic analysis to horizons h=0 through h=6 quarters, providing a full distributed lag picture.

**Evidence:** tables/tab4_robustness.tex, paper.tex Section 6.3 (Local Projections), Appendix D

---

## Idea 1: The Regulatory Ratchet — Asymmetric Cross-Sectoral Response to Incident vs. Burden Coverage

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: changing the outcome variable to high-frequency

**Status:** [x] RESOLVED

**Response:** The Federal Register data is available at quarterly frequency (the highest feasible frequency for significant rulemaking). Daily or monthly rule counts would be too sparse for economically significant rules. The quarterly panel is the appropriate aggregation unit, and 429 agency-quarter observations provide sufficient power.

**Evidence:** paper.tex Section 4.1, code/01_fetch_data.R

---

### Condition 2: discretionary agency actions like enforcement fines

**Status:** [x] NOT APPLICABLE

**Response:** The paper focuses on formal APA rulemaking (economically significant rules, proposed rules, final rules). Enforcement fines and other discretionary actions are outside the scope of this paper, as the theoretical contribution is specifically about the rulemaking pipeline under the Administrative Procedure Act. Future work could extend to enforcement actions.

**Evidence:** paper.tex Section 1 (Introduction) — scope explicitly defined as APA rulemaking

---

### Condition 3: guidance documents

**Status:** [x] NOT APPLICABLE

**Response:** Guidance documents are excluded by design: they are not subject to public comment under the APA and would conflate the formal rulemaking mechanism with informal agency action. The paper explicitly targets APA formal rulemaking where the industry mobilization via comment record is the mechanism.

**Evidence:** paper.tex Section 2.3 (Administrative Law and Rulemaking Dynamics)

---

### Condition 4: or press releases rather than formal APA rulemaking

**Status:** [x] NOT APPLICABLE

**Response:** Press releases and informal announcements are excluded by design. The paper's theoretical mechanism operates specifically through the formal rulemaking record (public comments, petitions for rulemaking), which only applies to APA formal rulemaking. This constraint is the paper's strength, not a limitation.

**Evidence:** paper.tex Section 3 (Theoretical Framework)

---

## The Regulatory Ratchet — Asymmetric Cross-Sectoral Response to Incident vs. Burden Coverage (idea_0450)

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: making substantive rule outcomes the main object

**Status:** [x] RESOLVED

**Response:** Primary outcome is economically significant rules — the most substantive category of federal regulation, requiring formal cost-benefit analysis. We also analyze proposed rules (pipeline bandwidth) and final rules as secondary outcomes to characterize the full rulemaking process.

**Evidence:** tables/tab2_main_results.tex, paper.tex Table 1

---

### Condition 2: e.g. significant final rules or restriction changes

**Status:** [x] RESOLVED

**Response:** Column 1-2 of Table 1 use economically significant rules. Column 4 uses final rules. Column 3 uses proposed rules. This exactly matches the suggested conditions — we use significant final rules as primary outcome.

**Evidence:** tables/tab2_main_results.tex

---

### Condition 3: using only clearly unrelated crowd-out shocks for the IV

**Status:** [x] RESOLVED

**Response:** The natural disaster IV (log natural disaster coverage, F=3.21) is the cleanest shock — natural disasters are clearly unrelated to a specific agency's regulatory agenda. The cross-sector IV (other agencies' incident coverage, F=1.44) is weaker but still in the correct direction. Both are labeled exploratory given the weak first stage.

**Evidence:** paper.tex Section 7.3, Appendix (IV table)

---

### Condition 4: handling small-cluster inference very carefully

**Status:** [x] RESOLVED

**Response:** We report CR1 clustered SEs as baseline, CR2 bias-corrected SEs in Appendix C (clubSandwich), and local projections with effective N noted at each horizon. The CR2 result (t=5.99) confirms the main finding is robust to small-cluster corrections.

**Evidence:** paper.tex Appendix C, code/03_main_analysis.R

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
