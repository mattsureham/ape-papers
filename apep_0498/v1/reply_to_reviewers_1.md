# Reply to Reviewers

## Reviewer 1 (GPT-5.2): Reject and Resubmit

**1. Identification strategy needs stronger exogenous variation.**
We acknowledge this fundamental limitation. The grant data are only available from 2016, preventing a traditional pre/post DiD. We now explicitly label the primary specification as a TWFE regression rather than a DiD, and frame the event study as suggestive rather than definitive. We discuss the DHSC allocation formula mechanics but lack the data to construct a "distance to target" instrument.

**2. Pre-trend violations in event study.**
Acknowledged transparently. We now emphasize that the Rambachan-Roth sensitivity analysis shows the CI includes zero under strict parallel trends (M=0) and frame the event-study reversal pattern as suggestive evidence requiring further investigation. We note the 3-year rolling average creates mechanical contamination at the reference year.

**3. Confounding from Universal Credit and broader austerity.**
We have added an explicit discussion of UC rollout as a plausible spatial-temporal confounder in both the Threats to Validity and Limitations sections. Without DWP administrative data on LA-level UC rollout timing, we cannot directly control for this channel and flag it as an important limitation.

**4. Ad hoc London exclusion.**
We now present the London heterogeneity through a formal interaction model (Grant × London dummy) estimated on the full sample, rather than relying solely on subsample exclusion. We provide institutional justification for London's distinctive pattern.

**5. Treatment-outcome timing mismatch.**
We now explicitly acknowledge that the 3-year rolling average creates mechanical serial correlation and temporal smoothing, and note that the 2014 reference year blends 2013-2015 data.

---

## Reviewer 2 (Grok-4.1-Fast): Major Revision

**1. Trend-adjusted event study.**
Noted as an important robustness check that could strengthen inference. We acknowledge the pre-trends formally and rely on the Rambachan-Roth sensitivity analysis to bound the effects.

**2. Pre-2016 grant data.**
We agree this would substantially improve identification. Historical PCT spending data from King's Fund reports could potentially be used to backcast. Flagged as future work.

**3. Universal Credit control.**
Addressed in Threats to Validity and Limitations sections.

**4. Power calculations.**
We now report within-R² values (0.002-0.091) and discuss the statistical power implications explicitly in the results text.

**5. Mechanism evidence.**
We now honestly report the counterintuitive sign on treatment completion and explain it as a likely compositional effect.

---

## Reviewer 3 (Gemini-3-Flash): Major Revision

**1. Universal Credit control.**
Addressed; see Reviewer 1 response.

**2. Pre-trends.**
Addressed; see Reviewer 1 response.

**3. Spatial spillovers.**
Noted as an important extension. Drug markets do not respect LA boundaries, and cross-border treatment access is common. We acknowledge this limitation but lack the geospatial data structure to implement spatial lag models in this version.

**4. Mortality smoothing.**
Now explicitly acknowledged as a limitation. OHID reports only 3-year rolling averages; annual counts are suppressed for small LAs.

**5. Magnitude claims.**
Softened throughout. We no longer claim spending cuts explain "nearly all" of the increase. We note concurrent drug supply changes, demographic shifts, and welfare reform as contributing factors.
