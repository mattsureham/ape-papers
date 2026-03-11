# Reply to Reviewers — Round 1

## Reviewer 1 (GPT-5.4 R1): Major Revision

**Concern 1: Causal claims exceed design.** The DiD with month FE identifies differential spatial effects, not the national aggregate effect of the closure.

*Response:* We agree fully. We have rewritten the abstract, introduction, mechanisms, discussion, and conclusion to consistently frame the finding as a null *spatial gradient* rather than a claim about national price effects. The estimand is now clearly stated as the differential border-interior price response.

**Concern 2: Treatment timing includes post-reopening months.**

*Response:* We have added explicit discussion (Section 4, paragraph after Equation 1) clarifying that Post encompasses both the active closure (Aug 2019–Dec 2020) and the post-reopening period. The event-study specification separately identifies month-by-month dynamics, showing no differential effect in either window.

**Concern 3: Imported-vs-local rice analysis belongs in main text.**

*Response:* We have elevated this analysis to a new subsection (5.3) in the Results section. This is indeed the strongest test of the spatial model's prediction.

**Concern 4: Exposure measurement is crude (Euclidean distance).**

*Response:* We acknowledge this limitation in the Discussion (Section 8.5, Limitations). Road-network distance data for Nigeria at the necessary spatial resolution are not publicly available. We note that the null result holds across all distance specifications (100km, 150km, 200km, continuous), which would not be expected if distance measurement noise were driving the null.

---

## Reviewer 2 (GPT-5.4 R2): Major Revision

**Concern 1: Claims exceed design (same as R1).**

*Response:* See response to R1, Concern 1.

**Concern 2: Treatment timing (same as R1).**

*Response:* See response to R1, Concern 2.

**Concern 3: Robustness table missing N.**

*Response:* Added N column to Table 4 (Robustness).

**Concern 4: Event-study coefficients should be tabulated.**

*Response:* The event-study figure (Figure 2) shows all coefficients with 95% CIs. Given the number of coefficients (29), a full table would be unwieldy; the figure provides clearer communication. We report the F-test for joint pre-trend significance in the text.

---

## Reviewer 3 (Gemini-3-Flash): Minor Revision

**Concern 1: Data download date (2026) seems impossible.**

*Response:* The current date is indeed March 2026. No error.

**Concern 2: Millet market count (37) differs from rice (35).**

*Response:* Added clarification in the Appendix (Section A.2) that WFP monitors different commodities at different market sites. All markets have geographic coordinates for border/interior classification.

**Concern 3: 250km threshold is invalid (1 control market).**

*Response:* Removed the 250km specification entirely from the paper and robustness table.
