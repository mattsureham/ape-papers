# Reply to Reviewers — Round 1

## Reviewer 1 (GPT-5.4 R1): REJECT AND RESUBMIT

### Must-Fix Issues

**1. Rebuild comparison group and justify product selection**
- *Response:* Added explicit discussion of control group construction in Section 3.3, acknowledging the limitation that non-CHPL codes were author-selected rather than the full within-chapter universe. Added future work suggestion to extend to all non-CHPL HS6 products. Added permutation/randomization inference (1,000 random CHPL assignments) confirming the enforcement effect is not an artifact of product selection (p < 0.001).
- *Status:* Partially addressed. Full within-chapter universe would require additional data collection.

**2. Strengthen identification beyond within-HS2 DD**
- *Response:* Cannot expand country sample in this version. Instead: (a) added explicit discussion of identification limitations, including differential post-2022 dynamics as a key threat; (b) added stockpiling/mean-reversion as a named threat to validity with discussion of evidence bearing on it; (c) added randomization inference; (d) noted the extension to additional countries and a DDD design as priority future work (footnote in Section 3.2).
- *Status:* Partially addressed. Geographic expansion deferred to future work.

**3. Address timing with higher-frequency data**
- *Response:* Monthly Comtrade data are in principle available but not currently accessible for this sample. Added explicit acknowledgment that annual data with one post-enforcement year is a first-order limitation. Added discussion of anticipation/private compliance as a timing threat.
- *Status:* Acknowledged as limitation. Monthly extension deferred to future work.

**4. Rework inference**
- *Response:* Added randomization/permutation inference over CHPL product assignment (1,000 permutations, p < 0.001). Wild cluster bootstrap attempted but failed due to software compatibility issues with fixest + fwildclusterboot. Permutation inference is the more appropriate test for this setting given the small, selected product sample.
- *Status:* Addressed via permutation inference.

**5. Reframe tier regressions**
- *Response:* Completely reframed as descriptive throughout. Added prominent caveat: "These results are descriptive, not causal." Removed language about "absolute effects" and replaced with description of patterns.
- *Status:* Fully addressed.

### High-Value Improvements

**6. Validate against misclassification** — Acknowledged as limitation in Section 4.4 and Appendix C. Cannot be fully addressed without HS8/HS10 data.

**7. Treat PPML as core result** — Elevated PPML to first robustness check in Section 6.5 with extended discussion. Explicitly noted that insignificant PPML rerouting coefficient is a "notable caveat." Discussed PPML vs OLS discrepancy as informative about extensive vs intensive margin channels.

**8. Product-level matching** — Deferred to future work. Noted in Section 3.3.

**9. Sharpen displacement analysis** — Added caveat that displacement test is limited to 18 selected codes and cannot rule out substitution to other chapters, countries, or misclassified codes.

### Optional Polish

**10. Scale back causal language** — Comprehensive revision throughout. Changed "demonstrate" to "consistent with," "shows that" to "is associated with," "succeeded" to "consistent with enforcement reducing." Separated descriptive from causal claims explicitly in multiple sections.

**11. Clarify estimands** — Fixed β₂ interpretation throughout. Now explicitly state that 2024 net effect = β₁ + β₂ = 1.89, not β₂ = -3.62 alone. Removed misleading 97% semi-elasticity interpretation.

**12. Expand methodological references** — Added Callaway & Sant'Anna (2021), Roth (2022), Goodman-Bacon (2021), Cameron et al. (2008), Sun & Abraham (2021). Added paragraph on methodological positioning relative to modern DiD literature.

---

## Reviewer 2 (GPT-5.4 R2): MAJOR REVISION

### Must-Fix Issues

**1. Strengthen identification against post-2022 confounding** — See R1 response #2. Added explicit threats (stockpiling, product-specific demand cycles), permutation inference, and honest caveats throughout.

**2. Document and justify product sample** — See R1 response #1. Added transparency about selection and permutation test.

**3. Correct DD coefficient interpretation** — Fully corrected throughout. Abstract, introduction, results, and conclusion now state β₂ is the incremental 2024 change, with net 2024 effect = β₁ + β₂ = 1.89 explicitly reported.

**4. Bolster inference** — Added permutation inference (p < 0.001).

**5. Rework tier regressions** — See R1 response #5. Fully reframed as descriptive.

### High-Value Improvements

**6. Placebo tests** — Permutation inference over product assignment addresses the placebo product concern. Placebo enforcement dates and non-Russia destination checks deferred to future work.

**7. Expand displacement** — Added caveat about narrowness of test.

**8. Mirror statistics** — Added anticipation/timing discussion.

**9. Clarify descriptive vs causal** — Explicit separation added in magnitudes section, rerouting magnitude section, and discussion.

### Optional Polish

**10. De-emphasize SDE** — Kept per APEP requirements but added caveats in appendix notes.

**11. Broaden literature** — Added five modern DiD and inference references.

---

## Reviewer 3 (Gemini-3-Flash): MINOR REVISION

**1. HS code switching robustness** — Acknowledged as limitation. Cannot test without data on HS4/HS8 neighbors.

**2. Unit value analysis** — Deferred to future work. Comtrade quantity data quality is variable at HS6 level.

**3. Mirror statistics sensitivity** — Added discussion of why DD identification is robust to mirror noise.

---

## Exhibit Review (Gemini-3-Flash)

**Remove Figure 2 (redundant)** — Done. Removed transit-only CHPL line chart.

**Move Figure 5 to appendix** — Done. Top products spaghetti chart moved to Appendix D.

**Refine visual style** — Done. Updated ggplot theme to white background with minimal grids (AER/QJE style).

**Country decomposition** — Changed from stacked bar to faceted line chart per recommendation.

**Add permutation figure** — Added as new appendix figure.

---

## Prose Review (Gemini-3-Flash)

**Eliminate "planned research" apologies** — Done. Removed API rate limiting discussion from introduction. Moved broader sample details to footnote in Section 3.2.

**Shorten roadmap** — Done. Removed entire roadmap paragraph.

**Active voice** — Reviewed and maintained throughout.

**Ground magnitudes** — Added dollar-denominated discussion and PPML comparison.

**Prune throat-clearing** — Final pass completed; no remaining instances of "it is important to note" or similar.
