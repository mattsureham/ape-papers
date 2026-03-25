# Revision Plan: apep_0842 → v2

## Context

Paper 842 ("The Designation Illusion") is a strong V1 (rating 28.3, competitive with AEJ benchmarks) that uses a triple-difference to show EU safe country of origin designations don't affect asylum recognition rates but deter applications. Three strategic editors and three empirics reviewers converge on the same improvements. The paper's biggest liability is an internal inconsistency between "diversion" claims and the actual coefficients, plus framing that's too narrow/institutional for the broader selection-vs-adjudication insight.

**Parent:** `papers/apep_0842/v1/`
**New workspace:** `output/apep_0842/v2/`

---

## Workstream 1: Fix the Deterrence/Diversion Inconsistency (CRITICAL)

All six reviewers flagged this. The abstract says designations "redirect flows to non-designating neighbors" but Table 3 Column 2 shows a *negative* coefficient — meaning non-designating destinations also lose applications when more neighbors designate. This is system-wide deterrence, not diversion.

**Actions:**
- Remove "diversion" framing from abstract, introduction, results, and conclusion
- Relabel Table 3 Column 2 from "Diversion" to "System-Wide Deterrence" or "Spillover Deterrence"
- Rewrite the channels section to tell one clean story: the policy deters applications both locally AND system-wide
- Add appropriate caveats about the origin×year confounding in the spillover estimate

---

## Workstream 2: Rewrite Abstract & Introduction (from scratch)

Per tournament lessons ("fresh rewrites beat patched revisions") and all three strategic editors.

**New framing:** The paper is not "first triple-diff of SCO effects." It is: *"A flagship asylum restriction changes who applies, not how claims are judged — formal legal classifications affect selection into administrative systems rather than decisions within them."*

**Structure:**
1. Open with the broader question: Do formal government labels change bureaucratic decisions, or just who shows up?
2. The asylum setting as a vivid test case (Albania example)
3. The result: designation illusion on recognition, real deterrence on applications
4. Why this matters beyond asylum — selection vs. adjudication in administrative systems
5. Literature positioning (build on, not attack)

---

## Workstream 3: Add Event Study Figure

All three empirics reviewers flagged the missing event study plot. V2 allows figures.

**Actions:**
- Add `05_figures.R` generating an event study coefficient plot with 95% CIs
- Plot dynamic triple-DiD coefficients (leads/lags relative to designation year)
- Reference period: t = −1 (already coded)
- Clean, publication-quality ggplot with minimal styling
- Reference in main text as primary visual evidence for parallel trends

---

## Workstream 4: Staggered DiD Robustness

Tournament lessons emphasize Callaway-Sant'Anna or Sun-Abraham for staggered designs.

**Actions:**
- Add `did` package (Callaway-Sant'Anna) estimation as robustness check
- This is methodologically important: 45 designation events with different timing across 2008-2023
- Report in robustness section/table
- If CS estimator changes the result materially, discuss why

---

## Workstream 5: Power & MDE Analysis

Three reviewers flagged that the null needs power language.

**Actions:**
- Compute MDE at 80% power given effective sample size and variation
- Report explicitly: "We can rule out effects larger than X percentage points at 80% power"
- Add to robustness discussion
- Strengthens the null from "we found nothing" to "this is a precisely estimated zero"

---

## Workstream 6: Compress Institutional Background + Expand Discussion

**Compress (Section 2):**
- Keep: what the designation legally does, why it varies, why variation is useful
- Move: detailed country-by-country list catalog to Data Appendix (already partially there)
- Target: ~1 page instead of ~1.5 pages

**Expand Discussion:**
- Connect to bureaucratic discretion/street-level bureaucracy literature (Lipsky)
- Connect to screening and selection in migration systems
- Connect to policy signaling / informational deterrence
- Address: "If not SCO labels, what explains the asylum lottery?" — offer candidate hypotheses
- Address measurement error interpretation (binary treatment may understate true effect variation)

**Rewrite Conclusion:**
- Not a summary — end with the broader principle about formal classifications affecting entry, not adjudication
- One paragraph connecting beyond asylum policy

---

## Workstream 7: Literature Strengthening

Add engagement with:
- Bureaucratic discretion / administrative discretion (Lipsky 1980, Maynard-Moody & Musheno)
- Selection into administrative systems / screening (broader public econ)
- Policy signaling and announcement effects
- Migrate from "three literatures" to a more organic weave through the introduction

---

## Workstream 8: Additional Empirical Checks

- **Decision-type decomposition:** Split recognition into Geneva Convention vs. subsidiary/humanitarian protection to test whether designation shifts protection *type* even if not total rate
- **Processing outcomes:** Check if Eurostat has withdrawal/discontinuation data (migr_asywitha) — if designees withdraw at higher rates, that's a procedural mechanism
- **Randomization inference:** Add RI for the main estimate (already have placebo, but formal RI is stronger)

---

## Execution Order

1. Create workspace, copy parent artifacts
2. Workstream 3 + 4 + 5 + 8 (R code changes — can partly parallelize)
3. Workstream 1 + 2 + 6 + 7 (paper.tex rewrite — do as one coherent pass)
4. Compile and visual QA
5. Full review pipeline (advisor → exhibit → prose → external → revision)
6. Publish with `--parent apep_0842`

---

## Verification

- All R scripts run without error and produce updated tables/figures
- Event study figure renders correctly in PDF
- No "diversion" language remains in abstract, intro, or conclusion
- Abstract ≤ 150 words
- Paper ≥ 25 pages (V2 threshold)
- validate_v1.py passes (adapted for V2)
- Fresh advisor review passes (3 of 4)
- Three fresh external reviews completed
