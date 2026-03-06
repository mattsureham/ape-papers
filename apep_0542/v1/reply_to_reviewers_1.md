# Reply to Reviewers

## Summary of Changes

All three reviewers raised concerns about (1) the violated parallel trends, (2) the strength of causal claims, (3) transaction timing relative to the announcement, and (4) control group comparability. We have made comprehensive revisions to address these concerns while maintaining the paper's core contribution.

### Key Changes Made

1. **Softened causal language throughout.** Replaced "well-powered null" with "no detectable break." Added explicit acknowledgment that the evidence is descriptive rather than definitive. Moderated policy claims in the conclusion.

2. **Added transaction timing discussion.** New paragraph in Threats to Validity discussing HM Land Registry completion dates vs. contract dates, the ~12-week lag, and implications for detecting immediate breaks. Also added to the Limitations section.

3. **Cited Roth (2022).** Added reference on pre-test interpretation and cited it in the event-study section to frame the pre-trend evidence as diagnostic rather than corrective.

4. **Moderated Phase 1 placebo interpretation.** Changed from "suggesting construction disruption" to "suggestive, though could also reflect London market cooling." Applied this more cautious framing in both the results and conclusion sections.

5. **Acknowledged design limitations explicitly.** Added a sentence to the introduction stating that the design has important limitations including violated parallel trends, broad geographic controls, and transaction timing lags.

6. **Recalibrated policy implications.** Changed from definitive statements about benefit-cost analysis to conditional language ("if correct, carries implications...") with explicit caveats about evidentiary limits.

---

## Response to GPT-5.4 (R1)

**Core identification concern:** We agree that the violated parallel trends are the paper's central limitation. We have reframed the paper's contribution as documenting the absence of a detectable break in transaction prices rather than estimating a causal effect. The more local identification strategies suggested (station-specific ring comparisons, synthetic control, corridor GIS) are excellent ideas for future work and we have added these to the limitations section.

**"Well-powered null" overclaimed:** Removed this language throughout. We now say "no detectable break" and explicitly note the design limitations.

**Transaction timing:** Added detailed discussion of completion vs. exchange date lags and quarterly binning limitations.

**Leeds inclusion:** We have clarified the institutional history with a detailed footnote explaining that while the IRP curtailed the dedicated high-speed track to Leeds, the Leeds HS2 station site remained in planning documents until October 2023. We removed the unsubstantiated claim about dropping Leeds not changing results.

**Phase 1 placebo:** Now framed as suggestive rather than established, with the London market cooling alternative explanation front-and-center.

**Roth (2022) citation:** Added.

---

## Response to GPT-5.4 (R2)

**Design failure:** We agree that the current design cannot support strong causal claims. The paper is now explicitly framed as descriptive evidence about the absence of a detectable break, with clear acknowledgment of the limitations.

**Control group comparability:** We agree the Phase 1 vs Phase 2 comparison is not a clean counterfactual given the North-South housing market differences. This is now discussed more prominently in the limitations.

**Transaction timing:** Added comprehensive discussion of completion-date lags and their implications for detecting immediate breaks.

**Leeds/Eastern leg:** Clarified institutional history with detailed footnote.

**RI exercise:** We acknowledge this is a supplementary exercise and have not expanded it given the reviewers' (correct) point that RI cannot rescue a design with violated parallel trends.

**Station-level vs pooled discrepancy:** Added explanation of why the station-level regression absorbs between-station differences, producing different coefficients than the pooled specification.

---

## Response to Gemini-3-Flash

**Synthetic DiD / trend adjustment:** This is an excellent suggestion for future work. The current revision focuses on honestly acknowledging the design limitations rather than attempting a method switch that would require substantial additional development.

**Phase 1 composition by property type:** Good suggestion. The current revision moderates the Phase 1 interpretation rather than adding new specifications.

**Network North heterogeneity:** We discuss this confound explicitly but cannot disentangle it with available data.

**Overall:** We appreciate the constructive tone and the "Minor Revision" assessment. The suggested improvements are incorporated where feasible.
