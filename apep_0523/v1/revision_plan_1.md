# Revision Plan 1 — Addressing Referee Feedback

## Overview

Three external referees reviewed the paper. GPT-5.2 recommended Reject and Resubmit, Gemini-3-Flash recommended Minor Revision, and Grok-4.1-Fast provided detailed feedback. The core concern across all reviews is that the paper lacks a credible causal estimate due to pre-trend violations. This is the paper's central message — a deliberately framed negative finding.

## Changes Made

### 1. Data Coverage Clarification (Gemini concern)
- **Issue:** Figures display data through 2025 while estimation uses 2020Q1-2024Q4
- **Fix:** Added explicit clarifying text in Section 3.1 and figure notes distinguishing estimation sample from display data

### 2. Commune Count Consistency (GPT concern)
- **Issue:** Multiple commune counts cited (2,555 decree; 2,496 DVF-matched; 2,590 summed zones)
- **Fix:** Used "approximately 2,500" in abstract/intro; added explanatory footnote about DVF-match dropout

### 3. Event Study Timing (Gemini concern)
- **Issue:** Reference period labeled as k=-1 (2023Q3) should be 2023Q4
- **Fix:** Corrected all references to k=-1 = 2023Q4

### 4. Composition Effects Table (GPT concern)
- **Issue:** Composition effects referenced but no dedicated table
- **Fix:** Added Table 4 showing property type shares pre/post by treatment status

### 5. Robustness Table Clarity (GPT concern)
- **Issue:** Zone subgroup rows showed same N as full sample, unclear why
- **Fix:** Relabeled rows as "(interaction)" with explanatory note that these are interaction terms, not subsamples

### 6. Pre/Post Period Counts
- **Issue:** Various incorrect pre/post quarter counts in text
- **Fix:** Corrected to 16 pre + 4 post for baseline (2024Q1 treatment)

## What Did Not Change

- **Core finding:** The negative result (pre-trend violations invalidate causal estimates) is the paper's contribution and was not altered
- **Methodology:** TWFE, CS estimator, HonestDiD, and RI all retained as originally specified
- **Data:** No new data fetched; same DVF + TLV zoning datasets
- **Identification strategy:** DiD comparing newly-treated vs never-treated communes unchanged

## Verification

All changes verified through:
- Full PDF recompilation (pdflatex + bibtex triple pass)
- Visual inspection of all tables and figures
- Advisor review achieving 3/4 PASS (GPT, Grok, Codex passed; Gemini failed on persistent figure-data concern)
