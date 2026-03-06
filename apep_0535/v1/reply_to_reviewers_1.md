# Reply to Reviewers (Stage C Revision)

## Summary of Changes

This revision addresses the three external referee reviews (GPT-5.4 R1: Major Revision, GPT-5.4 R2: Major Revision, Gemini-3: Minor Revision). The key changes are:

1. **CS-DiD subgroup heterogeneity** (all reviewers): Replaced TWFE-based heterogeneity analysis with subgroup-specific Callaway-Sant'Anna estimates for partisan groups and age cohorts. Figure 5 now shows CS-DiD ATTs for each subgroup. All subgroups show null effects.

2. **Claim calibration** (R1, R2): Substantially narrowed interpretive claims throughout abstract, introduction, and conclusion. "Precisely estimated zero" → "no detectable effect." "Consumers can distinguish" → "one interpretation." Added explicit alternative interpretations.

3. **First-stage discussion** (all reviewers): Added new paragraph in Robustness section discussing pass-through evidence from literature, implied price magnitudes, and the limitation of not having in-sample retail price data.

4. **Exogeneity language** (R1, R2): Softened from "orthogonal to macroeconomic conditions" to "plausibly exogenous." Added explicit acknowledgment that the timing regression is low-powered and does not address all confounders.

5. **Treatment timing sensitivity** (R1, R2): Added formal late-year recoding results (ATT = -0.017, SE = 0.027) showing the null is robust to shifting late-year adopters to the following calendar year.

6. **Missing literature** (R1, R2): Added de Chaisemartin & D'Haultfœuille (2020), Roth et al. (2023), Chetty, Looney & Kroft (2009), and Finkelstein (2009). Added new Tax Salience subsection in Related Literature.

7. **Dose-response caveat** (R1, R2): Explicitly acknowledged that dose-response uses TWFE and should be treated as suggestive evidence.

8. **Bundled policies** (R1, R2): Added to Limitations section as a qualification on interpreting results as a clean pump-price salience test.

9. **Cell sizes and aggregation** (R1, R2): Added paragraph reporting cell size distribution (median 378, range 13-5,822) and weighting choices.

10. **Pre-trend language** (R2): Changed "clean pre-trends" to "no detectable differential pre-trends" following Roth et al. (2023) caution.

## Responses to Individual Reviewers

### R1 (GPT-5.4 R1) — Major Revision

| Concern | Response |
|---------|----------|
| Missing first stage | Added literature-based discussion with implied magnitudes. Acknowledged as limitation. |
| Treatment timing coarseness | Added late-year recoding robustness (formally reported). |
| TWFE for heterogeneity | Replaced with CS-DiD subgroup estimates. |
| Bundled policies | Added to limitations; acknowledged as a qualification. |
| Exogeneity overclaimed | Softened throughout; acknowledged low power of timing test. |
| Claim calibration | Major rewrite of abstract, intro, discussion, conclusion. |
| Missing literature | Added 4 new references + Tax Salience subsection. |

### R2 (GPT-5.4 R2) — Major Revision

| Concern | Response |
|---------|----------|
| TWFE for heterogeneity | Replaced with CS-DiD subgroup estimates. |
| First-adoption-only coding | Acknowledged as limitation; noted that subsequent increases are rare in this sample. |
| Missing first stage | Added literature-based discussion + acknowledged limitation. |
| Identification case | Softened language; added explicit caveats. |
| Claim calibration | Major rewrite throughout. |
| Cell sizes/weighting | Added paragraph with distribution statistics. |

### R3 (Gemini-3) — Minor Revision

| Concern | Response |
|---------|----------|
| First-stage check | Added literature-based discussion. |
| Wild cluster bootstrap | Acknowledged as desirable; standard `did` package uses multiplier bootstrap which is appropriate. |

## Not Addressed (acknowledged as limitations)

- In-sample retail gasoline price event study (no EIA API key; acknowledged as limitation)
- Individual-level interview date treatment coding (unavailable in CES cumulative)
- Formal adoption hazard model (beyond scope for single revision)
- Full treatment bundling classification (acknowledged in limitations)
- Continuous treatment intensity under staggered adoption (acknowledged TWFE caveat)
- Border-state spillover analysis (acknowledged as potential attenuation source)
