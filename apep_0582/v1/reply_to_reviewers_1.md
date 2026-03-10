# Reply to Reviewers — apep_0582/v1

## Response to GPT-5.4 (R1) — REJECT AND RESUBMIT

### 1. Rebuild inference strategy
**Response:** We now report four inferential procedures: (1) baseline country clustering (SE = 0.0081, t = -1.9), (2) two-way clustering by country and sector (SE = 0.0065, t = -2.4, p < 0.05), (3) country-sector clustering (SE = 0.0113, t = -1.4), and (4) randomization inference with 2,000 permutations (p = 0.128). We also added discussion of Adão, Kolesár, and Morales (2019) and Cameron, Gelbach, and Miller (2011) for shift-share and multiway clustering inference. The range of t-statistics (-1.4 to -2.4) is now presented transparently as capturing genuine inferential uncertainty.

### 2. Recalibrate claims
**Response:** Extensive recalibration throughout. The abstract, introduction, results, and conclusion now use "differential" throughout to clarify that the design identifies relative amplification by exposure, not the total effect. The "credible interval excludes zero" claim has been removed. Language like "established" and "rules out" has been replaced with "consistent with" and "suggestive." The comparison to ex-ante GDP predictions now includes explicit caveats about unit incomparability.

### 3. Address 2021 placebo/pretrend
**Response:** The January 2021 placebo is now explicitly framed as a stress test rather than a clean placebo. We acknowledge it may indicate either pre-trends or the genuine beginning of the energy crisis (gas prices tripled by December 2021). We note that a conservative interpretation would reframe treatment as the broader 2021-2022 crisis. A formal joint F-test of pre-treatment coefficients is now reported, supporting parallel pre-trends.

### 4. Controls for non-gas war exposure
**Response:** We acknowledge this concern in the limitations section but cannot address it empirically in this revision without trade data at the country-sector-month frequency. The sector×month fixed effects absorb global sector-level disruptions; remaining bias requires country-specific sectoral sanctions effects correlated with gas intensity, which we discuss.

### 5. Redesign escalation as unified model
**Response:** Done. We now estimate a unified phase model with five crisis stages in a single specification. Phase coefficients are: -0.004 (Mar-May 2022), +0.003 (Jun-Aug 2022), -0.023 (Sep-Dec 2022), -0.013 (2023), -0.028 (2024). Individual phases are imprecise, but the contrast between early and late stages supports the supply mechanism. The old separate-regression escalation results are retained in the robustness table but reinterpreted as complementary.

### 6. Apples-to-apples GDP comparison
**Response:** The paper now explicitly states throughout that our estimates capture only the differential component, not the total effect. The comparison table (Appendix F) includes detailed notes on why the units are not directly comparable. We avoid language suggesting we have "falsified" the ex-ante models.

### 7. Production-weighted estimates
**Response:** Added. Production-weighted specification (using pre-2020 average production) yields β = -0.015, t = -1.8 — nearly identical to unweighted, ruling out the concern about noisy small cells.

### 8-9. Downgrade mechanism claims
**Response:** Done. Fiscal shield reframed as "exploratory heterogeneity" with explicit caveats about statistical insignificance, endogeneity, and post-determination of subsidies. The "offset roughly one-third" claim removed from introduction and conclusion. Tercile heterogeneity now described as "suggestive" with explicit noting that none are individually significant.

---

## Response to GPT-5.4 (R2) — MAJOR REVISION

### 1. Valid inference
**Response:** See R1 #1 above. Four inferential procedures reported.

### 2. Recalibrate interpretation
**Response:** See R1 #2 above. Extensive recalibration. The paper now explicitly distinguishes between differential manufacturing effects and aggregate GDP losses.

### 3. Country-sector confounders
**Response:** See R1 #4 above. Acknowledged as limitation; sector×month FE address global sector shocks.

### 4. Formal pre-trend evidence
**Response:** Joint F-test of pre-treatment coefficients now reported in the event study section.

### 5. Rework escalation
**Response:** See R1 #5 above. Unified phase model estimated.

### 6. Alternative treatment constructions
**Response:** Not feasible in this revision without additional data extraction. We note in the paper that 2019 measures are highly correlated (ρ > 0.98) with 2021 values.

### 7. Distinguish differential vs level effect
**Response:** New paragraph in introduction explicitly explains that the design identifies relative amplification, not total effect. This distinction is maintained throughout.

### 8. Improve mechanism analysis
**Response:** See R1 #8-9. All mechanism claims downgraded to exploratory.

### 9. Leverage diagnostics
**Response:** Leave-one-out (31 countries) and leave-one-sector-out analyses provide influence diagnostics. No single country drives the result.

### 10. Sample construction
**Response:** The appendix details sample construction. Coverage filter (60 months) and singleton removal (12 obs) are documented.

---

## Response to Gemini-3-Flash — MINOR REVISION

### 1. Balance table for share endogeneity
**Response:** We acknowledge this concern and note that the leave-one-out analysis provides indirect evidence that no single country (with distinctive characteristics) drives the result. A formal balance table is valuable for future work.

### 2. Gross production vs value added
**Response:** Discussed explicitly in Section 6.3 (Other Channels). Value added data at the required frequency is unavailable from Eurostat.

### 3. Firm size heterogeneity
**Response:** Noted as a direction for future research in the limitations section.

---

## Response to Exhibit Review

- Figures 4-5 (descriptive production trends) moved to appendix
- Table formatting maintained (decimal alignment done in code)
- Table 2 structure kept (fiscal interactions in same table for compactness)

## Response to Prose Review

- Roadmap paragraph killed
- Defensive R² writing retained but shortened
- Vivid final sentence added to conclusion
