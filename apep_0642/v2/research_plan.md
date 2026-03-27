# V2 Revision Plan: apep_0642 — Regulatory Whack-a-Mole

## Context

**Parent:** apep_0642 v1 (cons=26.8, μ=30.5, 68 matches, CLEAN scan)
**Title:** "Regulatory Whack-a-Mole: Cross-Media Pollution Substitution in Response to Clean Air Act Inspections"
**Core finding:** Air releases fall 5.2% post-CAA-inspection; non-air rises 1.8%. Mechanism: CAA chemicals show substitution, non-CAA don't.
**Selection:** Both Claude and Codex independently ranked this #1 for V2 upside. Short V1 (244 lines), strong core, public EPA data, enormous room for expansion.

## The V2 Narrative (conditional on data)

**If CWA controls work and land strengthens:** "CAA inspections cause air-to-land substitution — the regulatory blind spot. Water declines are explained by correlated CWA enforcement."

**If land stays imprecise:** "Cross-media reallocation under fragmented enforcement. The receiving medium depends on what other programs are simultaneously active." (This is already publishable — Codex's point.)

**Decision rule:** Run CWA/RCRA/extensive-margin package FIRST, then lock the framing.

---

## Five Critical Changes (from V1 reviews + co-author diagnosis)

### 1. CWA + RCRA Controls (highest priority)
- Download ICIS-NPDES (CWA inspections) from EPA ECHO bulk downloads
- Download RCRA inspection data (for land disposal enforcement)
- Merge both via FRS_ID into the panel
- Control for simultaneous CWA/RCRA inspections in medium-specific regressions
- **Expected:** Water decline attenuates (CWA enforcement explains it); land effect clarifies
- Document CWA-CAA inspection correlation in a new Data subsection

### 2. Medium-Specific Decomposition (reframing)
- Table 3 (medium-by-medium with enforcement controls) becomes the central table
- Add **extensive-margin outcomes** for sparse media: `any_land_release > 0` (binary) — critical because land has 96% zeros (Codex's most important suggestion)
- Hurdle/two-part model: extensive margin (does facility start releasing to land?) + intensive margin (how much?)
- Pooled non-air remains the headline unless land clearly earns the spotlight

### 3. Event Study Figures (5 main-text figures)
1. Air vs pooled non-air event study (TWFE, with CS robustness in appendix)
2. Medium-specific decomposition event study (4-panel: Air, Water, Land, POTW)
3. CAA vs non-CAA mechanism split
4. CWA-CAA inspection overlap/timing (justifies the new controls)
5. Magnitudes/environmental relevance visualization
- RI → appendix figure (Codex: not worth a main-text slot)

### 4. Callaway-Sant'Anna (targeted robustness only)
- Run CS on medium-specific outcomes after collapsing to facility-level
- Present alongside TWFE for comparison — not as the primary specification
- The triple-diff (within-facility, within-chemical) already protects against most staggered DiD concerns

### 5. Magnitudes and Environmental Relevance (new Section 6)
- Formalize offset calculation in physical units with CIs
- High-toxicity vs low-toxicity chemical heterogeneity cut (simple, interpretable)
- Full RSEI/RMP toxicity weighting: attempt, but main text only if merge is clean and stable; otherwise appendix
- "Magnitudes and Environmental Relevance" framing (not "Welfare" — Codex's correction)

---

## Additional Analyses (from Codex feedback)

### Switching-Capacity Mechanism Test
Substitution should be stronger at facilities that already had a feasible land-disposal pathway before the CAA inspection. Split by pre-inspection `any_land_release`: if a facility was already putting chemicals in land, switching costs are lower.

### Treatment-Timing Validation
- Balance test: regress inspection year on pre-treatment facility characteristics
- Show quasi-random timing directly, not just assert it

### Treatment-Definition Check
- Document repeat inspection frequency. If most facilities have multiple inspections, the "first inspection" event-study may conflate initial deterrence with cyclical enforcement.
- Robustness: use "any inspection in year t" as alternative treatment definition

### Extensive-Margin Outcomes
- `any_land > 0` (binary), `any_water > 0`, `any_potw > 0`
- Separate from intensive margin: are facilities *starting* to release to new media, or increasing existing releases?

---

## Paper Architecture (target: 28-30 pages)

| Section | Pages | Key Content |
|---------|-------|-------------|
| Front matter | 1 | Title, abstract (≤150 words), JEL, keywords |
| 1. Introduction | 3.5 | Hook, main finding, CWA-corrected decomposition, contributions, literature |
| 2. Institutional Background | 2 | CAA enforcement, CWA enforcement (NEW), medium-specific regulation, TRI |
| 3. Data | 3 | ICIS-Air, ICIS-NPDES (NEW), RCRA (NEW), TRI, FRS. CWA-CAA correlation. Summary stats |
| 4. Empirical Strategy | 3 | Triple-diff, CWA/RCRA controls, CS robustness, identifying assumptions |
| 5. Results | 5 | Main triple-diff → Medium decomposition with controls → CS → Event studies → Mechanism |
| 6. Magnitudes & Env. Relevance | 2 | Offset calculation, toxicity heterogeneity, policy counterfactual |
| 7. Robustness | 2.5 | Inference, functional form, sample restrictions, balancing, heterogeneity |
| 8. Discussion | 1.5 | Integrated inspections, limitations |
| 9. Conclusion | 0.75 | |
| References | 2 | 20+ references |
| Appendix | 3+ | Data appendix, additional tables/figures, SDE |

## Tables and Figures

**Main text tables (8):**
1. Summary Statistics (expanded with CWA counts)
2. Main Triple-Difference (baseline + with CWA/RCRA controls)
3. Medium-Specific Decomposition with Enforcement Controls (THE central table)
4. CAA vs Non-CAA Mechanism (with controls)
5. CS Estimates vs TWFE
6. Robustness (clustering, windows, PPML, share)
7. Heterogeneity (industry, enforcement, switching capacity, facility size)
8. Offset/Magnitudes Calculation

**Main text figures (5):** Listed above in Change #3.

**Appendix:** Balancing test table, RI histogram, extensive-margin table, SDE table, two-part model.

---

## Code Pipeline

```
code/
  00_packages.R          — Add: did, patchwork, scales
  01_fetch_data.R        — Keep existing + add ICIS-NPDES and RCRA downloads
  02_clean_data.R        — Merge CWA/RCRA, create extensive-margin vars, CS cohort vars
  03_main_analysis.R     — TWFE triple-diff, medium decomp with controls, CS, mechanism
  04_robustness.R        — Balance test, RI, PPML, two-part, share spec, heterogeneity
  05_figures.R           — 5 main-text + appendix figures
  06_tables.R            — 8 main-text + appendix tables
```

## Codex's Role in Execution

- **Data validation:** After CWA/RCRA merge, Codex reviews linkage rates and inspection overlap stats
- **Formatting probe:** Before review pipeline, Codex checks paper.tex for layout issues
- **Post-review triage:** Share all external reviews with Codex, decide jointly what to address
- **Pre-referee sign-off:** Codex agrees paper is ready before Stage B

## Verification

1. All R scripts run sequentially without error
2. pdflatex compiles without warnings (no ?? references)
3. Main text ≥ 25 pages (check `\label{apep_main_text_end}`)
4. All tables/figures populated with real data
5. Pre-trends pass visual and statistical tests
6. Advisor review: 3/4 PASS
7. `revise_and_publish.py --parent apep_0642 --push` succeeds
