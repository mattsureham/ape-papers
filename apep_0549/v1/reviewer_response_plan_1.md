# Reviewer Response Plan

## Summary of Feedback

Three referee reviews received: GPT-5.4 (R1) MAJOR, GPT-5.4 (R2) MAJOR, Gemini MINOR.
Plus exhibit review (Gemini) and prose review (Gemini).

## Workstream 1: Methodology — Modern Staggered DiD (CRITICAL)

**Concern (R1 #1, R2 #1):** TWFE is not sufficient for staggered adoption; must implement Callaway-Sant'Anna, Sun-Abraham, or BJS as primary aggregate estimator.

**Response:** Code already includes CS-DiD via `did::att_gt()` but the call likely failed due to misaligned group variable format. Fix the `g` variable to use `time_id` scale, re-run, and prominently feature CS-DiD results in Table 2 and the event study. Relegate TWFE to supplementary comparison.

**Changes:**
- Fix `02_clean_data.R`: Convert `g` to time_id-compatible format
- Fix `03_main_analysis.R`: Ensure CS-DiD runs, save results properly
- Update `paper.tex`: Add CS-DiD column to Table 2, update results narration

## Workstream 2: Methodology — DDD Robustness (HIGH)

**Concern (R1 #2-3, R2 #2-3):** FARS alcohol imputation uses DOW/time variables creating mechanical correlation; DDD needs exposure normalization for varying number of Sundays per month; need wild bootstrap; need Poisson robustness.

**Response:**
- Wild bootstrap is already in code — report results prominently
- Add Poisson/PPML robustness via `fepois()`
- Add DOW-count exposure normalization (divide crashes by number of that DOW in each month)
- Add measured-BAC robustness using `DRINKING == 1` (police-reported) only from FARS Person file
- Add alternative control groups (never-treated only, drop retail-only states)

**Changes:**
- `04_robustness.R`: Add Poisson, exposure-normalized DDD, alternative control groups, measured-BAC check
- `paper.tex`: Add robustness appendix table, update Section 7

## Workstream 3: Language Calibration (REQUIRED)

**Concern (All reviewers):** Mechanism overclaimed; "precise null" overstated; welfare calculations too aggressive.

**Response:** Accept. Systematic language recalibration:
- "venue substitution" → "consistent with venue substitution hypothesis" / "one plausible interpretation"
- "precise null" → "null" for placebo (remove "precise" when CI is wide)
- "reframes the public health debate" → softer framing
- "hidden offset" → keep in title but qualify in text
- Welfare calculations → move to appendix or add heavy caveats
- "documents" → "provides suggestive evidence"

## Workstream 4: Exhibits (from Exhibit Review)

**Concern:** All figures hidden in appendix; need to move key figures to main text.

**Response:**
- Move Figure 1 (event study) to main text after Table 2
- Move Figure 5 (DOW distribution) to main text in Data section
- Move Figure 6 (mechanism summary) to main text in Results
- Move Table 4 (HonestDiD) to appendix
- Keep other appendix figures as-is

## Workstream 5: Prose (from Prose Review)

**Concern:** Dry opening; throat-clearing phrases; table narration in Results.

**Response:**
- Rewrite opening paragraph with a concrete hook
- Kill "This paper asks the natural follow-up question" → just ask it
- Kill "The remainder of the paper proceeds as follows..." paragraph
- Humanize results: translate coefficients to lives/deaths
- Shorten contribution paragraph
- Sharpen conclusion's final sentence

## Workstream 6: Design Improvements (DEFERRED)

**Concern (R1, R2):** Need actual NFL game-day data, narrower time windows, SafeGraph data.

**Response:** Acknowledge as limitations. These require entirely new data sources not available in current pipeline. Note as promising extensions in Discussion section. The current monthly NFL-season proxy, while coarse, still provides a meaningful test of the mechanism.

## Execution Order

1. Fix CS-DiD code → re-run 02, 03, 04, 05, 06
2. Add new robustness checks (Poisson, alt controls, exposure normalization)
3. Update paper.tex: methodology, results, robustness, language
4. Restructure exhibits (move figures to main text)
5. Prose improvements
6. Recompile and visual QA
