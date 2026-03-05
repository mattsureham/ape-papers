# Reviewer Response Plan

## Key Concerns Across All Three Reviewers

1. **Cross-sectional design cannot identify causal designation effect** (all 3) — Reframe claims throughout
2. **Missing distance polynomial in parametric specification** (GPT R2) — Add to regression
3. **Boundary FE interpretation overstated** (GPT R1, R2) — Correct
4. **Overclaiming on mechanisms/labeling** (all 3) — Soften throughout
5. **Commune-level classification noise** (all 3) — Already acknowledged, strengthen caveat
6. **Donut instability** (GPT R1, R2, Gemini) — Already revised, strengthen interpretation
7. **Geocoding precision at narrow bandwidths** (GPT R1, R2, Gemini) — Add discussion

## Revision Actions

### Must-Do (Addresses core concerns)

1. **Reframe paper as documenting boundary price differentials** — change abstract, intro, conclusion
2. **Add distance polynomial to parametric specification** — modify 03_main_analysis.R and Equation 1
3. **Correct boundary FE interpretation** — rewrite Section 5 text
4. **Soften mechanism claims** — relabel as "descriptive heterogeneity"
5. **Add geocoding precision discussion** — new paragraph in Data section

### Won't Do (Requires data we don't have)

1. Pre-reform data — DVF not available pre-2020
2. ZUS polygon overlap — data not publicly available
3. Additional covariates (census, cadastral) — would require major new data pipeline
