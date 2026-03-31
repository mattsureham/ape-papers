# Revision Plan: apep_0727 v3 → v4

## Context

Paper 0727 ("Too Small by Design") is #3 on the APEP leaderboard (μ=37.1, conservative 27.0, 9W-1L). It documents extreme bunching at Germany's 10 kWp solar threshold across four policy regimes. The user wants v4 to be "even better, more polished, more compelling."

**Strategic reviewers (unanimous):** Reframe from "bunching application" to "general policy design paper."
**Referees:** 2 MAJOR REVISION, 1 MINOR. Five unresolved technical gaps remain from V3.

## Co-Author Deliberation Summary

Both agents wrote independent diagnoses, then compared over two rounds. Key convergences and the one productive disagreement:

**Where we agree:**
- The paper needs formal monthly evidence as core design, not illustration
- Missing-mass/notch analysis is essential for welfare claims
- The intermediary mechanism must be either strengthened with evidence or explicitly labeled as interpretation
- The front end needs to lead with the world question, not the institutional anecdote
- **30 kWp → appendix** (not clean enough as a second test)
- **Ground-mount placebo → demoted** (N=325, suggestive only)
- Subtract aggressively: one killer density, one killer timing, one mechanism exhibit, one welfare table

**Where we diverged (resolved):**
- Claude prioritized reframing as #1; Codex prioritized earning the evidence first, then reframing. **Resolution: evidence first, framing second.** If the missing-mass mapping doesn't support "shrank capacity," the framing must downshift.
- Claude proposed a full specification curve in main text; Codex preferred pre-specifying a small defensible family and reporting a bounded range. **Resolution: Codex's approach.** Spec curve → appendix figure. Main text reports honest range from a small, justified set of specifications.

**Codex's critical addition:** Unify the estimator stack before any new analysis. V3 code has inconsistencies across files (float vs integer bins, degree 5 vs 7, 200 vs 500 bootstrap reps). This must be resolved first to prevent the V2 b=113 vs b=87 mismatch from recurring.

---

## Execution Plan (Priority-Ordered)

### Phase 1: Pipeline Audit & Estimator Unification

**Goal:** Single, consistent estimator used across all analyses.

Resolve inconsistencies in V3 code:
- `03_main_analysis.R`: uses `floor(x * 10) / 10` (float bins), 200 bootstrap, degree 7
- `03b_annual_bootstrap.R`: uses integer bins, 500 bootstrap, degree 7
- `03c_monthly_event_study.R`: uses integer bins, no bootstrap, degree 5

**Fix:** Standardize on integer bins (`as.integer(floor(x * 10))`) everywhere, degree 7 baseline, 500 bootstrap reps. Extract the bunching estimator into a shared function used by all scripts. This is the V2 lesson from `duet/lessons.md` (line 96).

**Files:** `03_main_analysis.R`, `03b_annual_bootstrap.R`, `03c_monthly_event_study.R`, `04_robustness.R`

### Phase 2: Formal Monthly Event Study

**Goal:** High-frequency timing evidence as part of the main design, not illustration.

- Monthly bunching estimates with bootstrap CIs (500 reps) around each of three policy breaks
- Formal event-study table: 6 months pre/post for Aug 2014, Jan 2021, Jul 2022
- Pre-trend/anticipation tests: is there any change before effective dates?
- Reporting lag assessment: do commissioning dates reflect actual installation timing?

**New output:** `tab_monthly_event.tex` (main text table), updated `fig8_monthly_event_study.pdf` with CI bands

**Files:** `03c_monthly_event_study.R` (major revision), `05_figures.R`, `06_tables.R`

### Phase 3: Missing Mass & Notch Analysis

**Goal:** Earn (or honestly decline) the "shrank capacity" claim.

The code already computes `missing_mass` (line 42-43 of `03_main_analysis.R`) but doesn't report it. Steps:
1. Estimate missing mass above 10 kWp in [10.0, 11.0), [10.0, 12.0), [10.0, 13.0)
2. Mass balance: does excess below ≈ missing above?
3. Compare pre-policy (2008-2011) and post-reform (2023-2024) distributions above 10 kWp to construct an empirical counterfactual for the displaced mass
4. Implied dominated region from where missing mass ends
5. Use this to produce data-driven welfare range (not scenario arithmetic)

**Fork in the road (per Codex):** If the missing-mass mapping supports a real 10-13 kWp "missing middle," the current title claim is earned. If not, the title must downshift to "extreme threshold distortion" rather than "shrank capacity."

**New output:** `tab_missing_mass.tex`, welfare section backed by data

**Files:** `03_main_analysis.R` (extract missing-mass reporting), `06_tables.R`

### Phase 4: Mechanism Claim Register

**Goal:** Decide the status of "expert intermediation."

Two paths:
- **Path A (result):** Construct municipality-level proxy for installer concentration (e.g., number of distinct operators within 10km). Test whether areas with more concentrated installer markets show sharper bunching. If evidence is there, intermediation becomes a tested result.
- **Path B (interpretation):** Explicitly label the intermediary channel as "well-supported interpretation" backed by module-count evidence, uniform geographic response, and institutional knowledge — but not directly tested. The "three conditions" framework becomes: two demonstrated (modularity, stakes) + one inferred (intermediation).

**Decision rule:** Try Path A first. If the proxy produces clean heterogeneity, promote it. If not, adopt Path B without shame — it's an honest paper.

**Files:** `04_robustness.R` (new heterogeneity test if Path A), `paper.tex` (mechanism section rewrite)

### Phase 5: Honest Uncertainty Reporting

**Goal:** Replace misleading bootstrap SEs with credible uncertainty.

- Pre-specify a small defensible estimator family: baseline degree 7 + degree 6/8, baseline window [9.0, 11.0) + [9.5, 10.5) / [8.5, 11.5). That's 6-9 specifications, not 60.
- Report bounded range: "The bunching ratio under the surcharge notch ranges from [X] to [Y] across our pre-specified estimator family, with our preferred specification yielding [Z]."
- Full specification curve (60+ specs) → appendix figure only
- Bootstrap SEs retained for within-specification sampling, but explicitly distinguished from design uncertainty

**New output:** `tab_spec_family.tex` (main text), `fig_spec_curve.pdf` (appendix)

**Files:** New `03d_specification_curve.R`, `06_tables.R`, `05_figures.R`

### Phase 6: Reframe & Rewrite

**Goal:** Present the claim that survived Phases 2-5 in its strongest form.

Rewrite abstract and introduction from scratch. The exact framing depends on what Phases 3-4 reveal:
- **If missing mass supports "shrank capacity":** Lead with "administratively convenient thresholds can materially suppress technology adoption when optimization is delegated to repeat players and the technology is modular"
- **If missing mass is ambiguous:** Lead with "threshold-based regulation generates extreme behavioral distortions" with the capacity implication as illustrative

In either case:
- Para 1: World question about thresholds in intermediated modular markets
- Para 2: Germany as the clean laboratory (vivid 712:1 fact)
- Para 3: Four-break design and main result
- Para 4: Mechanism evidence + timing
- Para 5: Stakes (in household equivalents, not just MW)
- Contribution: One fact about the world, not three-literature litany

Additional rewriting:
- Compress institutional background (Section 2) — timeline table does the work
- Compress empirical strategy — polynomial details to appendix
- Move annual table (Table 4) to appendix, keep figure
- Move 30 kWp to appendix
- Demote ground-mount placebo to brief mention
- Conclusion: teach a principle ("the threshold trap in intermediated modular markets"), don't summarize
- Named concept: "the **threshold trap**" — when intermediation + modularity + disproportionate stakes combine

### Phase 7: Literature Deepening
- Delegated choice / intermediary economics (beyond Chetty 2011)
- Distributed solar policy design, net metering, self-consumption incentives
- Notch estimation best practices (recent bunching methodology)
- Environmental regulation with thresholds (building codes, permit boundaries)
- ~10-15 additional citations

### Phase 8: Craft Polish (Steps 4b-4e)
- ≥3 substance loops (text-table matching, claim calibration)
- ≥2 craft loops (Shleifer hook, named object, every paragraph earns its place)
- Pre-mortem: 3-5 most likely referee attacks
- Consistency check: `internal_consistency_check.py` (≥3 loops × 3 subagents)
- Codex cold read before any external review

---

## Files to Modify

| File | Changes |
|------|---------|
| `03_main_analysis.R` | Unify to integer bins; extract/report missing mass; shared estimator function |
| `03b_annual_bootstrap.R` | Use shared estimator; ensure consistency |
| `03c_monthly_event_study.R` | Add bootstrap CIs; formal event-study table; degree 7 |
| `03d_specification_curve.R` | **NEW** — pre-specified family + full grid for appendix |
| `04_robustness.R` | Installer-proxy heterogeneity test (Phase 4); temporal diff-in-bunching at placebos |
| `05_figures.R` | Updated monthly figure with CIs; spec curve appendix figure |
| `06_tables.R` | New: monthly event study, missing mass, spec family; move annual to appendix |
| `paper.tex` | Full rewrite: abstract, intro, welfare, mechanism, conclusion; compress background/strategy/robustness; new tables/figures |
| `references.bib` | Add 10-15 citations |

## Co-Author Protocol

- Codex gets intermediate results after each phase (especially Phase 3 fork)
- Pre-referee sign-off from both agents required
- Share tables-from-code before writing paper text (lessons.md lesson #4)
- Codex cold read before advisor pipeline

## Verification

1. All R scripts run without error with unified estimator
2. Paper compiles to PDF ≥25 pages
3. All numbers trace to generated table files
4. Missing mass reported; welfare backed by data
5. Monthly event study with CIs tabulated
6. Specification family range reported honestly
7. `internal_consistency_check.py` passes (≥3 loops)
8. Both co-authors sign off
9. `revise_and_publish.py --parent apep_0727 --push` succeeds
