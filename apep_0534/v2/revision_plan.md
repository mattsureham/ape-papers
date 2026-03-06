# Stage C Revision Plan — apep_0534 v2

## Review Summary

| Reviewer | Decision | Core Concern |
|----------|----------|-------------|
| GPT R1 | Reject & Resubmit | Shared outcome, bad controls, balance, timing |
| GPT R2 | Major Revision | Pseudo-replication, bad controls, timing, citation mechanical |
| Gemini | Minor Revision | Collapsed spec discrepancy, clustering, citation mechanical |
| Exhibit | — | Clean variable names, promote Figure 8, consolidate tables |
| Prose | — | Remove roadmap, strengthen conclusion, active voice |

## Consensus Issues (all 3 reviewers agree)

1. **Pseudo-replication**: Follow-on patenting is subclass×cohort aggregate → 640K "observations" share outcomes at much coarser level → precision overstated → collapsed spec shows result doesn't survive
2. **Forward citations mechanical**: Abandonments can't be cited → positive effect partly/largely database visibility
3. **Controls contaminate design**: Claims/citations coded zero for abandonments → mechanically proxy grant status → bad controls
4. **Balance tests insufficient**: Grants-only balance is post-treatment selection
5. **Treatment timing blurred**: Filing-date outcomes include pre-disposition activity
6. **IV over-interpreted**: Exclusion dubious (examiner affects scope, duration, continuation) → 2SLS not clean "grant effect"
7. **Y02 imputation coarse**: Modal subclass for abandonments may be wrong

## Revision Strategy

### Principle: Embrace the null honestly

The collapsed spec (0.009, SE=0.021) is the most credible estimate. Rather than defending the application-level result, restructure the paper around:
- **Primary: collapsed subclass-cohort analysis** (honest about effective N)
- **Supplementary: application-level** (shown for transparency, with full caveats)
- **Estimand: ITT of examiner assignment** (not "grant effect")
- **Citations: suggestive, mechanically contaminated** (not co-equal finding)

---

## Changes to Execute

### 1. RESTRUCTURE ANALYSIS: Collapsed spec becomes primary [MUST-FIX]

**R code changes (03_main_analysis.R):**
- Collapse data to subclass × filing-year level
- Treatment = mean examiner grant rate within cell
- Outcome = follow-on count (already at this level)
- FE: Y02 domain × filing year (or just filing year)
- Weight by cell size
- Report this as Table 3 (main results)
- Move application-level to Table 4 (supplementary, with pseudo-replication caveat)

### 2. REMOVE BAD CONTROLS from baseline [MUST-FIX]

**R code changes (03_main_analysis.R, 04_robustness.R):**
- Baseline specs: NO claims/citations controls
- Sensitivity: show controlled specs separately with explicit "these controls are zero-coded for abandonments" note
- First stage without controls becomes primary (F=13,006)
- First stage with controls shown as sensitivity

### 3. REFRAME ESTIMAND as ITT [MUST-FIX]

**Paper.tex changes:**
- Abstract: "effect of assignment to a more permissive examiner" not "effect of granting"
- Throughout: reduced form is primary, 2SLS is "exploratory under strong assumptions"
- New subsection in methodology: "The reduced form captures the ITT effect of examiner assignment on downstream activity. The 2SLS estimate requires the additional assumption that examiner leniency affects outcomes only through the binary grant decision—an assumption we view as demanding given that examiners also affect prosecution duration, claim scope, and continuation strategies."

### 4. DOWNGRADE CITATION INTERPRETATION [MUST-FIX]

**Paper.tex changes:**
- Remove "co-equal finding" framing
- Recast as: "Consistent with the mechanical channel—granted patents exist as citable documents while abandoned applications do not—we find a large positive citation effect. We cannot decompose this into genuine knowledge flow versus database visibility."
- Move citation regressions to secondary position
- Remove "visibility without inventive response" as paper's thesis

### 5. IMPROVE BALANCE TESTS [MUST-FIX]

**R code changes (03_main_analysis.R or new balance script):**
- Query PatEx for pre-treatment covariates observable for ALL applications:
  - Small entity status
  - Application type (utility, continuation, CIP, divisional)
  - US vs foreign applicant origin
  - Number of inventors
  - Filing year (as placebo — should be absorbed by FE)
- Run balance on full sample, not just grants
- If PatEx covariates unavailable: acknowledge limitation clearly, provide stronger institutional argument

### 6. HONEST ASSESSMENT OF COLLAPSED VS APPLICATION-LEVEL [MUST-FIX]

**Paper.tex changes:**
- New paragraph in results: "The application-level estimates in Table 4 assign a common subclass-level outcome to each application, inflating the effective sample size. Table 3 collapses to the level at which the outcome genuinely varies..."
- Acknowledge that application-level p=0.018 likely reflects pseudo-replication
- Present collapsed null as the headline finding

### 7. TIGHTEN CLAIMS THROUGHOUT [MUST-FIX]

- Abstract: "we do not find robust evidence that marginal grants increase within-subclass follow-on patenting"
- Conclusion: "the evidence is inconclusive" not "negligible effect established"
- Remove "methodologically stronger design" claims
- Policy section: much more conditional language

### 8. Y02 IMPUTATION SENSITIVITY [HIGH-VALUE]

**R code changes:**
- Restrict to art units with ≥90% Y02 purity among grants
- Show main results robust to this restriction
- Report how many art units / applications are dropped

### 9. CLARIFY FIRST-STAGE REPORTING [HIGH-VALUE]

**Paper.tex:**
- Table: show F without controls (13,006) and with controls (594) side by side
- Explain: "The controlled specification reduces the first-stage coefficient from 0.151 to 0.018 because claims and backward citations—coded as zero for abandonments—absorb grant-status variation"
- This is actually an argument FOR dropping controls

### 10. EXHIBIT IMPROVEMENTS [POLISH]

- Clean variable names in Table 4 (no underscores)
- Promote Figure 8 (Y02 trends) to main text
- Add "Mean of Dep. Var." row to main results tables
- Move Table 7 (clustering) to appendix
- Move Figure 4 (permutation) to appendix

### 11. PROSE IMPROVEMENTS [POLISH]

- Remove roadmap paragraph (end of intro)
- Strengthen conclusion ending (policy implication, not future work)
- Active voice in data section
- Vivid transition into heterogeneity

---

## Execution Order

1. Re-run 03_main_analysis.R with collapsed primary + uncontrolled baseline
2. Re-run 04_robustness.R (remove controls from baseline robustness)
3. Re-run 05_figures.R and 06_tables.R
4. Rewrite paper.tex (abstract, intro, methodology, results, discussion, conclusion)
5. Compile PDF
6. Verify 25+ pages
7. Run final advisor review
