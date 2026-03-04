# Revision Plan 1 — apep_0185 v18

## Context

v17 published with mu=29.6 (conservative 22.2). GPT-5.2 strategic feedback identified the policy diffusion analysis as underinvested — "explicitly descriptive and undercontrolled; it dilutes the main claim." This revision builds proper causal infrastructure for the diffusion question.

## Changes Made

### Phase 1: Diffusion Data Infrastructure
1. **09a_prep_diffusion_data.R** — Fast data prep (SCI, centroids, state MW panel)
2. **09b_fetch_political_data.R** — Governor party, trifecta, union density, unemployment, CPI, gas/corp tax rates
3. **09c_state_network_exposure.R** — State-level SCI aggregation, distance-restricted IVs, placebos

### Phase 2: Analysis
4. **09d_diffusion_analysis.R** — Progressive controls (5 specs), IV, falsification, heterogeneity
5. **09e_cascade_simulation.R** — Conditional on results (skipped: Scenario B)
6. **09f_diffusion_figures.R** — Distance monotonicity figure

### Result: Scenario B (Null)
Network MW exposure does NOT predict state-level MW adoption. The coefficient is absorbed by political controls and the IV (non-adjacent states) is too weak (F=0.9). Falsification clean: gas tax (p=0.89) and corporate tax (p=0.64) placebos null.

### Phase 3: Paper Edits
- Rewrote Section 9.3 with progressive controls, null finding, falsification
- Updated intro to acknowledge null diffusion result and pre-trend F-test
- Updated conclusion with null diffusion finding and "what models should change" paragraph
- Added \newpage before Introduction
- Strengthened framing: "policy shocks travel socially" + "scale of connections matters"
- Added appendix section with falsification table and distance figure

### Phase 4: Review-Informed Refinements
Based on referee feedback (GPT: Major, Grok: Minor, Gemini: Minor):
- Softened 9% employment headline → emphasis on direction/sign, LATE interpretation
- Strengthened pre-trend F-test explanation (p=0.007 = levels, not trends)
- Fixed probability-weighted language ("no effect" → "substantially smaller")
- Added LATE framing throughout
