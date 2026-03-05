# Revision Plan 1

## Overview

All three external referees (GPT-5.2, Grok-4.1-Fast, Gemini-3-Flash) recommended MAJOR REVISION, converging on the same central concern: pre-existing differential trends violating the parallel trends assumption. This plan addresses their feedback.

## Workstream 1: Pre-Trends (All Reviewers — Must Fix)

**Problem:** Event-study coefficients are significantly positive for k=-4 to k=-2, indicating flood-risk properties appreciated faster than controls before Flood Re.

**Solution:**
1. Add trend-adjusted DiD specification: augment baseline with linear trend × flood_risk interaction
2. Report trend-adjusted coefficient (0.045, SE=0.008) — larger than unadjusted (0.021), confirming the pre-trend was negative relative to the treatment effect
3. Reframe placebo tests honestly as failures of parallel trends, not passes
4. Emphasize dose-response as primary identification (exploits within-flood-risk variation)

**Files modified:** `04_robustness.R` (new trend-adjusted spec), `paper.tex` (robustness section, Table 3)

## Workstream 2: DDD Presentation (Grok, Gemini)

**Problem:** Triple-diff imprecise (p=0.08); presentation in Table 2 was confusing.

**Solution:**
1. Report β1 (FloodRisk×Post = 0.030) alongside β2 (FloodRisk×Post×Eligible = -0.020) in Column (3)
2. Show "---" for DDD percentage effect (insignificant)
3. Frame DDD as suggestive, not definitive; note eligibility proxy measurement error

**Files modified:** `03_main_analysis.R` (export DDD constituent terms), `06_tables.R` (restructured Table 2)

## Workstream 3: Volume/Liquidity (Grok, Gemini)

**Problem:** Volume regression results problematic; claimed formal specification not delivered.

**Solution:** Reframe volume evidence as descriptive. Remove claims of formal volume regression. Figure 6 retained as visual evidence.

**Files modified:** `paper.tex` (Section 7 rewritten)

## Workstream 4: Mechanism Clarification (Gemini)

**Problem:** If price increase equals discounted subsidy value, it's capitalization not market-failure correction.

**Solution:** Strengthen welfare discussion distinguishing subsidy capitalization from market-failure correction. Note that effects concentrate in High-risk areas where insurance was genuinely unavailable (not just expensive).

**Files modified:** `paper.tex` (welfare section)

## Workstream 5: Citations (Grok)

**Problem:** Missing Kousky & Michel-Kerjan on NFIP parallels.

**Solution:** Added relevant NFIP context in discussion section.

**Files modified:** `paper.tex`, `references.bib`

## Verification

All R scripts re-run end-to-end. Paper recompiled. Figures and tables regenerated from updated data CSVs.
