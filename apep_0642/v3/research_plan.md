# V3 Revision Plan: apep_0642 — From Substitution to Composition Bias

## Context

**Parent:** apep_0642 v2 (just published; 2 R&R, 1 MR from referees)
**Title:** "Cross-Media Pollution Reallocation Under Fragmented Environmental Enforcement"
**Core problem:** V2 identification is broken — balance test fails (F=18.05), pre-trends rejected (p=0.009), RI p-values >0.5. Non-consecutive TRI panel (9 of 18 years) compounds design problems. Mechanism sign inconsistent across specifications.
**Joint diagnosis:** Both Claude and Codex agree this is not a polish-away paper. It needs a design rebuild, not cosmetic fixes.

## The V3 Reframe (converged with Codex)

**V2 tried to be:** "CAA inspections cause cross-media pollution substitution"
**V3 should be:** "Air-only enforcement evaluation overstates net environmental improvement because it ignores composition shifts across media"

The key insight from Codex: the air-minus-nonair contrast (-0.089, p=0.002) is strong even when levels of non-air don't significantly rise. This means the **composition** shifts even if total pollution is hard to pin down. Air-only evaluation metrics miss this.

This is a cleaner, more defensible contribution than insisting on positive non-air substitution.

---

## Converged V3 Sequencing (Claude + Codex, 2 rounds)

### 1. Rebuild panel on 13 years immediately
- 13 TRI files already exist locally (2005, 2007-2008, 2011, 2013-2016, 2018-2022)
- Try curl for remaining 5 years (2006, 2009, 2010, 2012, 2017) in parallel
- Do NOT block on the 5 missing years — 13 is enough to decide if the paper lives
- Expected: sample grows from ~115K to ~300K+ observations

### 2. Audit and freeze variable definitions
- Fix `cwa_inspected`: keep as contemporaneous (not absorbing `cwa_post`) per Codex — it's a correlated enforcement control, not a second treatment
- Add CWA controls to the mechanism specification (currently missing from 03_main_analysis.R)
- Ensure paper text matches code for every variable definition
- Freeze: same sample, same FE structure, same CWA control, same treatment window for ALL specs

### 3. Reparameterize the main model (GPT2's suggestion)
- **Old:** Y = α_fcm + γ_t + β₁(Post×Air) + β₂(Post×NonAir) + ε
- **New:** Y = α_fcm + γ_t + θ(Post) + τ(Post×Air) + ε
- θ = common post effect (non-air base); τ = air-vs-nonair differential
- τ is the clean substitution/composition parameter
- Rewrite every claim off this parameterization

### 4. Add composition + total-release outcomes (Codex addition)
- `total_releases` (total on-site)
- `air_share` = air / total
- `air_minus_nonair` = air releases - mean(non-air releases)
- These composition outcomes are the V3 headline estimands

### 5. Stacked event study / cohort stacking
- Stack clean not-yet-treated cohorts (Cengiz-style or Sun-Abraham)
- If facility-chemical-medium level is too heavy, collapse to facility level
- Run on reparameterized spec with composition outcomes
- This replaces TWFE as the primary design

### 6. Mechanism re-run on harmonized sample/spec (moved earlier per Codex)
- Same sample, same FE, same CWA control for both split and pooled
- If the sign still flips, it's heterogeneity, not mechanism
- Present as "chemical-specific differential response" not "proof of targeted avoidance"

### 7. Decide framing based on what survives
- **If stacked composition shift survives + total releases don't fall as much as air alone:** Measurement bias paper. Headline: "Air-only enforcement evaluation overstates net environmental improvement by X%."
- **If stacked results are weak too:** Descriptive paper about correlated enforcement. Shrink claims further.

### 8. Rewrite and polish
- Lead with fragmented governance, not linked datasets
- Present composition shift as the headline
- Drop the over-defensive "regardless of direction" hedging
- Drop or demote offset-ratio magnitudes table (propagate uncertainty if kept)
- Be explicit about sample as "TRI-reporting manufacturing facilities whose inspection cohorts align with observed TRI years"
- Rewrite abstract and intro from final estimates

---

## What Codex changed from my initial plan
1. Don't block on last 5 TRI years — rebuild on 13 immediately
2. Keep CWA as contemporaneous control (not absorbing `cwa_post`)
3. Lock estimands before stacking: add composition outcomes explicitly
4. Move mechanism harmonization earlier in the sequence

## Critical Files to Modify
- `output/apep_0642/v3/code/01_fetch_data.R` — retry missing TRI years with curl
- `output/apep_0642/v3/code/02_clean_data.R` — rebuild panel on 13+ years; fix CWA variable
- `output/apep_0642/v3/code/03_main_analysis.R` — reparameterize; add composition outcomes; stacked DiD; fix mechanism CWA controls
- `output/apep_0642/v3/code/04_robustness.R` — stacked event study; updated RI
- `output/apep_0642/v3/code/05_figures.R` — new composition figures
- `output/apep_0642/v3/code/06_tables.R` — updated tables matching new specs
- `output/apep_0642/v3/paper.tex` — full rewrite with composition-bias framing

## Verification
1. Panel uses 13+ TRI years (check N ≥ 250K)
2. Reparameterized spec shows τ (air differential) clearly
3. Stacked event study runs without TWFE contamination
4. Mechanism sign is consistent across split/pooled on harmonized sample
5. Paper ≥ 25 pages, compiles cleanly
6. Advisor review: 3/4 PASS
7. `revise_and_publish.py --parent apep_0642 --push` succeeds

## Exposure Alignment
Treatment is the first FCE on-site CAA inspection. The treated population is the set of TRI-reporting manufacturing facilities matched to ICIS-Air via FRS. Treatment timing is determined by EPA inspection scheduling (capacity-constrained, not random). The outcome (chemical-medium-level releases) is measured at the same facility, ensuring direct exposure alignment. The identifying variation comes from comparing air vs non-air media within the same facility-chemical cell, before and after the first inspection.

