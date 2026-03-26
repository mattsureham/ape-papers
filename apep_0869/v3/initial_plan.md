# Revision Plan: apep_0869 V1 → V2 (with Duet)

## Context

**Paper:** "The Litigation Tax on Biometrics: Evidence from Illinois's Rosenbach Ruling" (apep_0869_v1)
**Rating:** μ=29.3 (20 matches) — near APEP frontier
**Parent:** `papers/apep_0869/v1/` (locked)
**Workspace:** `output/apep_0869/v2/`
**Duet mode:** Active — Codex collaboration throughout

**Codex's critical insight (verbatim):** "The higher-ceiling version of 0869 is not 'V1 plus more tables.' It is a cleaner paper about private enforcement and firm scale. The ceiling rises if this becomes 'private enforcement and firm scale,' not 'the biometrics paper with seven new figures.'"

---

## Proposed Title

**"Private Enforcement and the Reorganization of Industry: Evidence from Biometric Litigation Risk"**

---

## The Core Design Change (Codex's recommendation, adopted)

**V1 weakness:** Binary exposed/exempt classification (Info+Prof vs Finance+Healthcare). The "exempt" control sectors may actually face BIPA exposure — this is the #1 identification critique.

**V2 fix:** Replace binary exposure with **continuous industry-level litigation exposure**. Build from:
- Pre-period biometric-use proxies (O*NET task content on "biometric data collection" tasks by occupation → crosswalk to NAICS)
- BIPA case-mix data from CourtListener (defendant industry distribution)
- Occupational biometric intensity (share of workforce in jobs involving fingerprint/face scans)

Finance and Healthcare become low-exposure benchmarks, not heroic "clean controls." The specification becomes:

```
log(Y_ist) = β × Illinois_s × Post_t × BiometricExposure_i + FE + ε
```

This is a fundamentally stronger paper than "add three robustness tables."

---

## Workstreams (Selective, not Maximalist)

### A. Reframe (Introduction, Abstract, Narrative)

Rewrite intro from scratch. Lead with: "Does enforcement design shape industrial organization?" → Private enforcement creates a litigation tax that scales with firm size → Rosenbach as clean shock → employment-establishment divergence = scale compression → enforcement architecture has first-order economic effects.

- Delay BIPA/legal detail to Section 2
- New literature: Shavell (1984), Becker-Stigler (1974), Autor et al. (2006) wrongful discharge, Holmes (1998) state borders, Suarez Serrato-Zidar (2016), Garicano et al. (2016) firm size regulation
- Conclusion: enforcement design as policy lever

### B. Rebuild Treatment Heterogeneity (Continuous Exposure)

**This is the highest-value workstream.** Replace binary exposed/exempt with continuous `BiometricExposure_i`.

Sources for the measure:
1. **O*NET task content** → occupational biometric intensity → NAICS crosswalk (O*NET is free, no API key needed)
2. **CourtListener BIPA filings** → defendant industry distribution (free API)
3. **Occupational Employment Statistics (OES)** → industry-occupation matrix → weight O*NET scores

R code:
- `01b_build_exposure.R` — Construct continuous exposure measure
- Merge into panel; run continuous triple-diff

### C. Show Scale Compression (CBP Size Classes)

**Central mechanism test.** County Business Patterns establishment counts by size class (1-4, 5-9, ..., 1000+) at county × NAICS level.

Test: Large establishments (50+, 100+, 250+) decline while small establishments (1-9, 10-19) increase in high-exposure industries in IL post-Rosenbach.

R code:
- `01c_fetch_cbp.R` — Census API download
- `03b_mechanisms.R` — Size-class triple-diff

### D. Worker Flows (QWI — Targeted)

Use QWI for **hires, separations, job creation, job destruction** only. This answers: did employment fall because firms stopped hiring, or because they actively downsized?

Do NOT overclaim cross-border relocation from QWI (Codex correctly notes QWI doesn't show this).

R code:
- `01d_fetch_qwi.R` — LEHD download for IL + 5 neighbors
- Additions to `03b_mechanisms.R`

### E. Border Reallocation (Direct Evidence)

More valuable than exotic SEs: show that high-exposure industries lost employment in IL border counties and **gained** it in adjacent counties across the state line. This is already partially in V1 (all-counties vs border specification shows attenuation), but V2 should make it explicit.

Use QCEW data already fetched: compare IL border counties to neighbor-state border counties, by exposure intensity. The "mirror image" test: IL employment decline ≈ neighbor employment gain.

R code: additions to `03_main_analysis.R`

### F. Inference Upgrade (One Clean Fix)

**Randomization inference only** (Codex: "do not do all of RI + Conley + fixed WCB unless the main result actually needs it").

Permute treatment state (5 placebos) and treatment timing (36 placebos). Report p-value as fraction of placebo estimates exceeding actual. This is clean and interpretable.

R code:
- `04b_inference.R` — Randomization inference

### G. 2024 BIPA Amendments (Suggestive, Not Backbone)

Extend QCEW to 2025 if available. Add second treatment indicator. Show leveling-off or reversal as validation.

**If the data isn't available or the reversal is weak, the paper still stands.** This is a bonus, not the linchpin.

### H. Figures (5, not 7)

1. Event study — employment (main result, extended if reversal data available)
2. Event study — establishments (the puzzle / scale compression)
3. Sector-specific event studies by exposure intensity (identification)
4. Establishment size distribution shift from CBP (mechanism)
5. Randomization inference distribution (identification)

Drop: border county map (not essential), worker flows figure (table is sufficient).

---

## What We're NOT Doing (Codex's cuts, adopted)

- ~~BFS (Census Business Formation Statistics)~~ — Too aggregated (state-level only), too far from core margin
- ~~USPTO patents~~ — Scope creep; invites technology-adoption claims the paper can't carry. If we can't show direct biometric adoption, don't claim it
- ~~Conley HAC + fixed WCB~~ — Defensive rather than convincing. RI is sufficient
- ~~Conceptual framework / simple model~~ — Only if space allows; not a priority
- ~~7 figures~~ → 5 figures
- ~~"Technology adoption" framing~~ — The paper is about enforcement design and firm scale, period

---

## Execution Order

| Phase | What |
|-------|------|
| 1 | Setup workspace, copy parent, init timing |
| 2 | Build continuous exposure measure (B) — this shapes everything else |
| 3 | Fetch data in parallel: extended QCEW + CBP + QWI |
| 4 | Main analysis with continuous exposure + border reallocation + RI |
| 5 | Mechanism analysis: CBP size classes + QWI worker flows |
| 6 | 2024 reversal test (if data available) |
| 7 | Paper rewrite: intro, narrative, sections |
| 8 | Figures |
| 9 | Compile + validate |
| 10 | Duet: pre-review sign-off with Codex |
| 11 | Review pipeline (advisor → exhibit → prose → referee → revise) |
| 12 | Publish with `--parent apep_0869 --push` |

---

## R Code Structure (V2)

```
code/
  00_packages.R          — expanded
  01_fetch_data.R        — extended to 2024-2025
  01b_build_exposure.R   — NEW: continuous biometric exposure measure
  01c_fetch_cbp.R        — NEW: County Business Patterns
  01d_fetch_qwi.R        — NEW: LEHD QWI
  02_clean_data.R        — merge exposure measure, CBP, QWI
  03_main_analysis.R     — continuous exposure triple-diff, border reallocation
  03b_mechanisms.R       — NEW: size-class tests, worker flows
  04_robustness.R        — COVID isolation (state×quarter FE, sector×quarter FE)
  04b_inference.R        — NEW: randomization inference
  05_figures.R           — NEW: 5 figures
  06_tables.R            — expanded
```

---

## Duet Touchpoints

1. **Diagnosis** — Done (Codex recommended 0869)
2. **Plan critique** — Done (Codex sharpened plan: continuous exposure, be selective)
3. **Exposure measure review** — After building continuous measure, get Codex's assessment
4. **Mechanism narrative** — After CBP + QWI results, structure Section 5 together
5. **Pre-review sign-off** — Full paper before external review

---

## Verification

- [ ] Paper compiles (pdflatex + bibtex, no errors)
- [ ] Main text ≥ 25 pages
- [ ] Continuous exposure measure is well-motivated and documented
- [ ] CBP size-class results show scale compression
- [ ] RI p-value < 0.05 for main employment result
- [ ] Event study shows flat pre-trends, break at 2019Q1
- [ ] Border reallocation: IL losses ≈ neighbor gains in high-exposure industries
- [ ] No unresolved citations
- [ ] Advisor review: 3 of 4 PASS
- [ ] Referee review: all 3 completed, feedback addressed
