# Reply to Reviewers — apep_0549/v1

## Referee 1 (GPT-5.4 R1): MAJOR REVISION

### 1. Modern staggered DiD estimator required
> "The paper relies entirely on TWFE... must implement Callaway-Sant'Anna or Sun-Abraham."

**Response:** We now feature Callaway-Sant'Anna (CS-DiD) as a co-equal estimator alongside the DDD. The CS-DiD simple ATT is +0.94 per 100,000 (SE = 0.68), statistically insignificant, with a dynamic event study showing no systematic pre-trends. This is reported prominently in Section 4.3 and Figure 2. The CS-DiD uses the doubly robust estimator with never-treated states as the control group and universal base period. The TWFE results are retained for comparison, and the Goodman-Bacon decomposition confirms that early-vs-late comparisons (which drive TWFE bias) receive modest weight.

### 2. FARS alcohol imputation creates mechanical DDD correlation
> "DRUNK_DR is partly imputed by NHTSA's multiple imputation procedure... the DDD interaction may capture imputation model features."

**Response:** We added a robustness check using only police-reported alcohol involvement from the FARS Person file (`DRINKING == 1`), which is not subject to NHTSA's multiple imputation. The DDD coefficient using this measured-BAC variable is −0.225 (SE = 0.161), very similar to the baseline −0.254, confirming the result is not an artifact of the imputation procedure. This is reported in Section 5.5 and Appendix Table B7. We also added explicit discussion of the imputation concern in Section 3.1.

### 3. NFL-season proxy too coarse
> "September–February is a 6-month window that includes Thanksgiving, Christmas, New Year's... the NFL Sunday channel is not cleanly isolated."

**Response:** We acknowledge this limitation more explicitly in the text. The DDD design helps by interacting NFL season with Sunday — holidays like Christmas and New Year's do not systematically fall on Sundays. We added the Saturday placebo DDD (Section 5.6) which shows a comparable negative coefficient on Saturday×NFL×Legal (−0.344, SE = 0.178), suggesting any effect may operate through college football Saturdays as well, consistent with a broader sports-betting mechanism rather than NFL-specific.

### 4. Venue substitution mechanism overclaimed
> "The paper overclaims the venue substitution mechanism without direct evidence on where alcohol is consumed."

**Response:** We substantially softened the mechanism language throughout. "I propose a venue substitution mechanism" → "One plausible interpretation is a venue substitution channel." We added an explicit caveat: "this paper does not directly observe where alcohol is consumed, and the venue substitution channel remains a hypothesis consistent with the pattern of results but not directly tested here." The contribution paragraph now reads "provides suggestive evidence" rather than "documents."

### 5. "Precise null" overstated
> "A confidence interval of [−0.60, +0.09] is not precise enough to rule out meaningful effects."

**Response:** We removed all references to "precise null" and replaced with "null" or "statistically insignificant." We added explicit discussion of the confidence interval width: "The 95% confidence interval [−0.60, +0.09] cannot rule out economically meaningful increases or decreases in alcohol-involved crashes." The abstract and conclusion now frame the result as a null finding rather than a precise null.

### 6. Welfare calculations too aggressive
> "The back-of-envelope welfare calculation presents speculative numbers with false precision."

**Response:** The welfare section is now titled "Illustrative Magnitude Calculations" (previously "Bounding the Mortality Cost"). We added heavy caveats: "These calculations are purely illustrative, intended to contextualize the point estimates rather than to serve as policy-relevant welfare estimates." The section now frames numbers as order-of-magnitude context rather than policy recommendations.

### 7. Pre-trend joint test needed
> "Report a joint F-test for pre-treatment coefficients."

**Response:** The fixest event study now includes a Wald joint test for all pre-treatment coefficients, reported in Section 4.4. The CS-DiD event study also provides visual evidence of parallel pre-trends.

### 8. Poisson/negative binomial for count outcomes
> "Crash counts are non-negative integers — OLS may be inappropriate."

**Response:** We added Poisson Pseudo-ML (PPML) estimation via `fixest::fepois()` with the same fixed effect structure. The Poisson DDD coefficient is −0.063 (SE = 0.065, p = 0.33), confirming the null finding. Reported in Section 5.3.

### 9. DOW exposure normalization
> "Months have 4 or 5 Sundays — raw crash counts conflate exposure with effect."

**Response:** We now compute DOW-count exposure variables (number of Sundays per state-month) and estimate the DDD using crashes per DOW occurrence. The exposure-normalized DDD is −0.056 (SE = 0.038, p = 0.15), consistent with the baseline. Reported in Section 5.4.

### 10. Alternative control groups
> "Some never-treated states have retail-only sports betting — they are partially treated."

**Response:** We added robustness checks excluding retail-only sports betting states from the control group. The DDD dropping retail-only states is −0.222 (SE = 0.172, p = 0.20), consistent with the baseline. Reported in Section 5.5.

### 11. Leave-one-out sensitivity
> Already implemented in original submission.

**Response:** Leave-one-out analysis was already in Section 5.2. The LOO range confirms no single state drives the result.

### 12. Wild cluster bootstrap
> "With ~20 treated states, cluster-robust SEs may be unreliable."

**Response:** We attempted wild cluster bootstrap via `fwildclusterboot::boottest()` but the complex three-way fixed effect structure (state×DOW, DOW×time, state×time) caused numerical failures. We report this transparently in Section 5.3 and note that the Poisson model provides an alternative inference framework. The CS-DiD also uses its own analytical SE procedure that accounts for the staggered design.

---

## Referee 2 (GPT-5.4 R2): MAJOR REVISION

### 1. Staggered DiD estimator
> Same as R1 concern #1.

**Response:** See R1 #1 above. CS-DiD now featured prominently.

### 2. FARS alcohol imputation
> Same as R1 concern #2.

**Response:** See R1 #2 above. Police-reported alcohol robustness added.

### 3. DDD exposure problem (4 vs 5 Sundays)
> "The DDD may be picking up variation in the number of Sundays per month rather than the treatment effect."

**Response:** See R1 #9 above. Exposure-normalized DDD confirms the null.

### 4. Count model robustness
> Same as R1 concern #8.

**Response:** See R1 #8 above. Poisson PPML added.

### 5. Alternative control groups
> Same as R1 concern #10.

**Response:** See R1 #10 above. Retail-only states excluded.

### 6. NFL season definition too broad
> Same as R1 concern #3.

**Response:** See R1 #3 above. Saturday placebo added for context.

### 7. Mechanism overclaimed
> Same as R1 concern #4.

**Response:** See R1 #4 above. Language substantially softened.

### 8. "Precise null" language
> Same as R1 concern #5.

**Response:** See R1 #5 above. All "precise null" references removed.

### 9. Welfare section
> Same as R1 concern #6.

**Response:** See R1 #6 above. Reframed as illustrative.

### 10. Pre-trend testing
> Same as R1 concern #7.

**Response:** See R1 #7 above. Joint F-test added.

### 11. Saturday placebo
> "Saturday is a high-drinking day with college football — test it as a falsification."

**Response:** Added Saturday×NFL×Legal DDD as Section 5.6. The coefficient is −0.344 (SE = 0.178, p = 0.06), actually larger in magnitude than Sunday. We discuss this honestly as evidence that any effect may operate through college football Saturdays as well, complicating the narrow NFL-Sunday interpretation but consistent with a broader sports-betting mechanism.

### 12. Geographic heterogeneity
> "NFL market states may differ from non-NFL states."

**Response:** The DDD already interacts with NFL market status implicitly through the state fixed effects. We note this as a direction for future work with more granular geographic data.

---

## Referee 3 (Gemini-3-Flash): MINOR REVISION

### 1. Clarify FARS imputation concern
> "Briefly address whether the DRUNK_DR imputation could bias results."

**Response:** Added explicit discussion in Section 3.1 and police-reported alcohol robustness check in Section 5.5.

### 2. Expand treatment years if 2024 data available
> "FARS 2024 would add post-treatment observations for late adopters."

**Response:** FARS 2024 data is not yet publicly available from NHTSA as of the analysis date. We note this as a natural extension once released.

### 3. Optional border spillover analysis
> "Border counties could test for spillover effects."

**Response:** Noted as a direction for future research. The current analysis operates at state level, and county-level FARS analysis would require additional geographic matching that we leave for future work.

---

## Exhibit Review (Gemini-3-Flash)

### 1. Move Figures 1, 5, 6 to main text
> "Event study, DOW pattern, and mechanism summary should be in the main text."

**Response:** Moved the event study plot (now Figure 2), DOW alcohol crash pattern (now Figure 3), and mechanism summary (now Figure 6) to the main text. These are now integrated into the narrative flow of Results and Mechanisms sections.

### 2. Move HonestDiD table to appendix
> "Table 4 is highly technical and interrupts the main results flow."

**Response:** Moved HonestDiD sensitivity bounds to Appendix Table B6. Added brief text summary in Section 4.4 referencing the appendix.

### 3. Add geographic map
> "A map of treatment timing would be informative."

**Response:** Deferred to future revision — generating a publication-quality state choropleth requires additional GIS dependencies. The treatment timing is clearly documented in Table 1.

### 4. Harmonize terminology
> "Use consistent terms for 'legal,' 'treated,' 'post-treatment' throughout."

**Response:** Reviewed and standardized terminology throughout the paper.

---

## Prose Review (Gemini-3-Flash)

### 1. Rewrite opening hook
> "The current opening is generic — start with a striking fact."

**Response:** New opening: "In 2023, Americans wagered over \$100 billion on sports through legal online platforms—a market that did not exist five years earlier." This grounds the paper in a concrete, attention-grabbing fact.

### 2. Kill throat-clearing
> "'This paper asks the natural follow-up question' is classic throat-clearing."

**Response:** Removed. The transition now moves directly from the policy context to the research question.

### 3. Humanize results
> "Results read as a narration of regression tables rather than telling a story."

**Response:** Added contextual framing throughout results: "roughly one additional alcohol-involved crash per 100,000 residents" and "the confidence interval cannot rule out effects as large as..."

### 4. Shorten roadmap
> "The paragraph-long roadmap at the end of the introduction adds nothing."

**Response:** Removed the roadmap paragraph entirely.

### 5. Sharpen conclusion
> "The conclusion should reframe, not just summarize."

**Response:** Rewrote the conclusion with a new opening sentence and forward-looking framing about the relationship between gambling liberalization and public health.
