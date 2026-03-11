# Reply to Reviewers — apep_0600/v1 Revision 1

## Reviewer 1 (GPT-5.4 R1) — MAJOR REVISION

### Must-fix issues

**1. Rebuild empirical strategy around credible treatment measure**
- *Response:* We acknowledge that notification dates are an imperfect proxy for economic exposure. We now discuss this limitation explicitly in the Threats to Validity section. Alternative treatment dates (legislative adoption, effective date, first enforcement) are not systematically available across all 18 countries in a harmonized format. We frame the notification-based treatment as intent-to-treat, which is appropriate for evaluating the regulatory mandate.

**2. Stop relying on TWFE as basis for "precise null"**
- *Response:* ACCEPTED. We have fundamentally restructured the framing. The paper no longer uses the phrase "precise null." We now present both estimators with explicit discussion of why the SA-IW SE is larger (cost of heterogeneity robustness with few cohorts, not misspecification). We added TWFE on the balanced 16-country sample (-0.022, SE 0.123) to show the SE gap is methodological, not sample-driven. The framing is now "no evidence of economically large effects" with explicit acknowledgment that moderate effects below 0.2pp cannot be excluded.

**3. Reassess identification with country-specific confounding**
- *Response:* ACCEPTED. We added country-specific linear time trends as a robustness specification (+0.030, SE 0.068). This directly absorbs the main identification threat — differential macro-financial trajectories correlated with transposition timing. The null survives. We also discuss this specification prominently in the main text.

**4. Replace power/MDE claims with estimator-consistent calculations**
- *Response:* ACCEPTED. The back-of-envelope MDE formula has been removed entirely. Section 5.5 is now titled "What Can the Data Rule Out?" and characterizes precision through actual confidence intervals: TWFE CI [-0.24, 0.21], WCB CI [-0.28, 0.27]. We explicitly state that moderate effects below 0.2pp cannot be excluded.

**5. Strengthen or soften mechanism claim about codification**
- *Response:* We have substantially softened the mechanism language. The heterogeneity section now explicitly acknowledges the coarseness of the 3-country stringency classification and notes that a more granular regulatory gap index would be needed for a definitive test. The codification interpretation is presented as "consistent with" the evidence rather than "strongly supported by" it.

### High-value improvements

**6. Harmonize samples across estimators** — DONE. Balanced-sample TWFE added to Table 3.

**7. Improve event-study diagnostics** — We now cite Roth et al. (2023) on pre-trends testing and discuss the limitations of pre-trend assessment in low-power settings.

**8. Reframe house price analysis** — House prices now carry a dagger footnote in both Table 2 and the SDE table, explicitly noting pre-trend contamination. The main text already framed HPI as descriptive.

**9. Expand outcomes** — Acknowledged as a limitation. Harmonized micro-data on volumes/approvals are not available cross-country for the full period.

**10. Calibrate title/abstract/conclusion** — DONE. Title changed from "The Regulatory Non-Event" to "When Harmonization Codifies the Status Quo." Abstract and conclusion substantially softened.

**11. Deepen literature positioning** — Added citations: Callaway & Sant'Anna (2021), Roth et al. (2023).

---

## Reviewer 2 (GPT-5.4 R2) — MAJOR REVISION

All concerns overlap substantially with Reviewer 1. Key additional points:

**SA ATT construction clarification** — The paper uses `fixest::sunab()` which implements the standard Sun-Abraham estimator. The "inverse-variance-weighted average" description refers to the standard aggregation of cohort-time ATTs. We have clarified this in the text.

**Few-cluster RI concerns** — We acknowledge that 500 permutations is moderate. The permutation scheme shuffles transposition dates across all 18 countries, which is the standard approach for RI in staggered DiD. We note this more explicitly in the appendix.

**Sample construction across estimators** — DONE via balanced-sample TWFE.

---

## Reviewer 3 (Gemini-3-Flash) — MINOR REVISION

**1. Clarify refined cohorts** — The balanced panel/cohort composition is now discussed more explicitly in the Identification Appendix.

**2. External validity (Non-Euro)** — The abstract and conclusion now more clearly emphasize that this is a euro area study. The conclusion adds an explicit caveat about Central and Eastern European member states.

### High-value improvements

**3. HonestDiD visualization** — The sensitivity analysis remains as text description; a full sensitivity plot would require substantial additional computation. We view the text description as adequate given the paper's other robustness checks.

**4. Volume data** — Acknowledged as a limitation; harmonized cross-country volume data is not available for the full period.

---

## Exhibit Review (Gemini)

- Moved Figure 5 (consumer placebo) and Figure 6 (RI histogram) to appendix — DONE
- Added FE indicator rows to Table 2 — DONE
- Added pre-trend caveat footnote to Table 2 HPI row — DONE
- Table note for Table 1 (N explanation) — Already addressed in main text

## Prose Review (Gemini)

- Rewrote opening paragraph for salience — DONE
- More active voice in abstract — DONE
- Removed roadmap paragraph — DONE
- Strengthened contribution paragraph — DONE
