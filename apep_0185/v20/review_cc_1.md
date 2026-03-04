# Internal Claude Code Review — v20

## Revision Summary

This is a prose-focused revision of apep_0185/v19 (conservative rating 20.3, #12 APEP). No analysis code changes were made. All figures and tables are unchanged from v19.

## Changes Made

### Workstream 1: Abstract Rewrite
- Rewrote abstract from scratch (128 words, down from ~150)
- Removed diagnostics language (HHI, LOSO, AR intervals)
- Structure: question → method → findings → significance → mechanism

### Workstream 2: Introduction Restructure
- Tightened paragraphs 2-3 (removed redundancy)
- Led results paragraph with findings and pop-vs-prob divergence
- Added "so what" paragraph replacing diagnostics paragraph
- Moved diagnostics to compact roadmap at end of intro
- Reordered contributions: (1) network-weighted outside options (general claim), (2) pop-weighting methodology, (3) information transmission

### Workstream 3: Back-of-Envelope Calibration
- Added calibration paragraph to Section 11: 9% employment → 1,350 jobs per county → 36% response rate among MW-relevant workers → consistent with Faberman et al. (2022) search elasticities

### Workstream 4: Job Flows Reconciliation
- Quantified the hire-separation rate gap (0.058 vs 0.044 = 0.014 quarterly excess)
- Showed compounding: 0.014 × 10 quarters ≈ 14%, bracketing the 9% employment estimate

### Workstream 5: COVID Discussion
- Added explanation for pre-COVID (1.103) vs full-sample (0.826) attenuation
- Cited remote work disrupting SCI-based information flows

### Workstream 6: Revision Artifacts
- No "prior version"/"this revision"/"reviewers noted" language found
- Paper reads as standalone work

### Workstream 7: Geographic/Industry Heterogeneity
- Expanded industry heterogeneity paragraph with explicit confound-ruling logic
- Added high-bite/region preview to intro results paragraph

### Workstream 8: Conclusion
- Added El Paso/Amarillo callback with quantified implications (3% earnings, 8% employment differential)

### Post-Review Adjustment
- Tempered abstract: "The channel is information" → "The evidence is consistent with information"

## Verification Checklist
- [x] Abstract ≤ 150 words (128 words)
- [x] No diagnostics in abstract
- [x] Intro para 6 is "so what" not diagnostics
- [x] Back-of-envelope paragraph in Section 11
- [x] No revision artifact language
- [x] Page 1 = front matter only
- [x] 25+ pages main text (34 pages to conclusion)
- [x] All figures/tables present (unchanged from v19)
- [x] Advisor review: 3/4 PASS (GPT, Grok, Codex)
- [x] 3 referee reviews completed (2 Minor, 1 Major)
- [x] Compiles cleanly (53 pages, no warnings)
