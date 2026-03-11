# Reply to Reviewers — Round 1

**Paper:** apep_0596 v1 — When the Canal Runs Dry
**Reviews:** GPT R1 (Major Revision), GPT R2 (Major Revision), Gemini (Minor Revision)

---

## Reviewer 1 (GPT R1) — Major Revision

### 1. Treatment is only a rough proxy for actual Panama dependence (Must-fix #1)

**Response:** We agree that country-of-origin is an imperfect proxy for route-of-shipment. We have added a substantial new paragraph in the Limitations section (Section 9.4, limitation #2) acknowledging this explicitly and discussing attenuation bias. We note that route-level data (AIS/bill-of-lading) would provide a sharper treatment variable but are not publicly available at the required scale. We frame the null result as potentially reflecting attenuation from treatment mismeasurement rather than genuine resilience, and we acknowledge this interpretation in the Discussion and Conclusion.

**Not addressed:** We cannot construct alternative exposure measures based on route-level shipping data, as these data are not publicly available. This remains an acknowledged limitation.

### 2. Parallel trends are explicitly violated (Must-fix #2)

**Response:** We have computed and report a formal joint F-test of all 23 pre-treatment event-study coefficients: F(23, 12,865) = 1.86, p = 0.008. This rejects the null of parallel pre-trends. We report this result prominently in the main text (Section 6.2), the Appendix B pre-trends discussion, and the Limitations section. We cite Roth (2022) and Rambachan and Roth (2023) on the interpretation of pre-trend tests and sensitivity to violations. We explicitly state that the main result should be interpreted with the understanding that pre-period instability introduces additional uncertainty beyond what standard errors capture.

### 3. Identifying comparison is too heterogeneous (Must-fix #3)

**Response:** We acknowledge in the Limitations section that the sample includes inland customs districts with sporadic trade, which introduce noise not well-suited to detecting a maritime route-specific shock. The heterogeneity analysis shows that large ports (top tercile)—which handle the vast majority of US imports—exhibit no treatment effects. We have not restricted the main specification to maritime-only districts, as this would reduce sample size and power further in an already imprecise design.

### 4. Recalibrate claims from "no effect" to what the design can rule out (Must-fix #4)

**Response:** This was the most consequential revision. We computed minimum detectable effects and economically interpretable confidence intervals throughout the paper:
- MDE at 80% power for IQR canal share × peak drought: 0.70 log points (~100% change)
- 95% CI for same contrast: [-39%, +63%]

We rewrote the Abstract, Introduction, Results interpretation, Discussion, and Conclusion to replace "economically zero" / "no effect" language with "no detectable net effect" / "unable to detect" / "consistent with but not definitive proof of resilience." The standardized effect size is retained in Appendix F for cross-study comparability but no longer serves as the primary framing of the result.

### 5. Separate direct-effect and equilibrium/diversion estimands (Must-fix #5)

**Response:** The paper already presents separate East/Gulf and West Coast estimates in Table 4. We have clarified in the text that the main specification captures net effects (inclusive of equilibrium adjustments), while the diversion test isolates the West Coast channel.

### 6-12. High-value and optional improvements

**6. Outcome measurement:** Acknowledged in Limitations—import values cannot distinguish price from quantity responses. We cannot add TEU/vessel call data as these are not in the Census API.

**7. Triple-difference:** We have added a caveat about the concurrent Red Sea/Houthi crisis contaminating the European control group.

**8. Treatment window:** The continuous drought intensity measure already captures time-varying treatment. We have not added separate onset/peak/recovery windows, as the main specification already handles this through the continuous intensity variable.

**9. Randomization inference:** We acknowledge that unrestricted permutation may be too permissive. Within-coast RI would be more informative but reduces the permutation space.

**10. Power diagnostics:** Added (see point 4 above).

**11. Literature:** Added Rambachan and Roth (2023), Roth (2022), and Freyaldenhoven, Hansen, and Shapiro (2019).

**12. Estimand language:** Revised throughout to consistently refer to "monthly aggregate port import values" rather than "US imports" generically.

---

## Reviewer 2 (GPT R2) — Major Revision

### 1. Core identifying assumption not credible as demonstrated

**Response:** See R1 responses #1 and #2 above. We report the F-test, cite the pre-trends literature, and add treatment measurement caveats.

### 2. Treatment measured very indirectly

**Response:** See R1 response #1. We acknowledge that aggregate canal transits (not container-specific) may mismeasure the shock relevant for US container imports, and that this mismeasurement likely attenuates the coefficient.

### 3. Control group not clearly valid

**Response:** We acknowledge that West Coast and East/Gulf ports differ structurally. We note the sensitivity of the coefficient to the port-specific trend specification (moving from -0.05 to -0.75) as evidence of meaningful sensitivity to trend assumptions. This is now reported more transparently.

### 4. Economically interpretable confidence intervals and power analysis

**Response:** Added (see R1 response #4). 95% CI at realistic contrasts: [-39%, +63%].

### 5. Recalibrate claims

**Response:** Comprehensive revision (see R1 response #4).

### 6-11. Additional improvements

**6. Shipping lags:** Not implemented. Valid concern but would require a fully separate specification (distributed lags) that reduces degrees of freedom in an already imprecise design.

**7. Disaggregated outcomes:** Not feasible without commodity-level panel construction, which is beyond the scope of this revision.

**8. DDD caveat:** Added Red Sea/Houthi contamination caveat.

**9. First-stage evidence:** The paper already presents Figure 2 (transit timeline) and the drought intensity construction. Freight rate and waiting time data are not available in the Census API.

**10. Literature framing:** Revised to present the paper as evidence on temporary, partial chokepoint disruptions rather than a broad challenge to the infrastructure-trade literature.

**11. Large noisy coefficients:** Acknowledged in heterogeneity discussion and Limitations. Added winsorized specification confirming the null is not driven by outliers.

---

## Reviewer 3 (Gemini) — Minor Revision

### 1. Medium-port anomaly (Must-fix #1)

**Response:** Added winsorized specification (1st/99th percentile) in the Robustness Appendix. The winsorized coefficient is -0.049 (p=0.988), virtually identical to the non-winsorized result. This confirms that the medium-port anomaly does not mask a true negative effect in the aggregate. Strengthened the medium-port discussion language.

### 2. Pre-trend formal testing (Must-fix #2)

**Response:** Joint F-test added: F(23, 12,865) = 1.86, p = 0.008. Reported in main text and Appendix B. See detailed discussion above.

### 3. Houthi confound (High-value #3)

**Response:** The concurrent Houthi crisis is discussed in Section 2.3 and addressed via the Houthi exclusion robustness check (excluding Nov 2023–Feb 2024). We have added a caveat about the European-origin control group being potentially contaminated by the Red Sea crisis in the triple-difference discussion.

---

## Exhibit Review (Gemini Vision)

- **Table 2 headers:** Not changed in this round (etable auto-generates headers from variable names; custom headers would require manual table construction).
- **Figure 3 reformulation:** Not changed (raw levels provide useful context).
- **Table 3 consolidation:** Not changed (standalone table is clearer for the triple-diff logic).
- **Remove redundant Figure 5:** Not changed (kept for appendix completeness).
- **Elevate SDE table:** Not changed (SDE remains in Appendix F per project requirements).
- **Add map:** Not feasible without additional geocoding data for all 186 customs districts.

## Prose Review (Gemini)

- **Mechanism transitions:** Revised opening of Mechanisms section to be more narrative.
- **Gas price section:** Already relegated to "Additional Data" with brief explanation.
- **Active voice in Limitations:** Revised (e.g., "the pre-period is noisy" rather than passive constructions).
- **Final sentence:** Revised to be more direct: "the next drought will reveal how far that absorptive capacity extends."
