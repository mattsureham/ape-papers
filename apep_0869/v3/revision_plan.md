# Revision Plan: apep_0869 v2 → v3 (with Duet)

## Context

**Paper:** "Private Enforcement and the Reorganization of Industry" (apep_0869_v2)
**Parent:** `papers/apep_0869/v2/` (locked)
**Workspace:** `output/apep_0869/v3/`
**Duet mode:** Active — Codex collaboration throughout
**User request:** "Avoid double spacing text, make it more compact."

## Joint Diagnosis (Claude + Codex)

Both co-authors diagnosed the same core issues:
1. The paper is 25 pages with `\onehalfspacing` — user wants it denser
2. Title/claims overclaim relative to evidence (employment effects, not "reorganization")
3. State×Quarter FE robustness row is pathological (SE=0.000, VCOV not PSD)
4. Mechanisms section lists channels rather than testing predictions
5. Introduction leads with legal drama rather than economic object

## Proposed Title

**"Enforcement Design and Industry Adjustment: Evidence from Biometric Litigation Risk"**

## Workstreams

### A. Formatting: `\singlespacing`, tighter floats, compact tables
### B. Content: conceptual framework (2-3pp), exposure validation (2-3pp), identification discussion (2pp), literature (1-2pp)
### C. Fixes: State×Quarter FE row, title downshift, abstract/intro rewrite from scratch
### D. Code: fix `04_robustness.R` table generation for pathological specification
