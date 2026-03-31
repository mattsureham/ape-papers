# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-31T18:27:49.828962

---

**Idea Fidelity**

The paper remains largely faithful to the manifest. It implements the central examiner-leniency IV to estimate the causal effect of patent rejection on inventors’ interstate mobility, relying on USPTO PAIR for application and inventor data covering 2002–2014. It also emphasizes the “rejection drain” as a novel federal mechanism that redistributes knowledge workers, consistent with the original research question. The only notable divergence is that the paper stops after the first-stage outcome (inventor mobility) and does not carry through to the second stage described in the manifest—aggregating examiner-driven inventor flows to instrument state-level knowledge worker supply in the QWI data. If the final goal is to speak directly to place-based policy, the manuscript should either complete that second stage or explicitly frame the current contribution as uncovering a key microchannel that future work can integrate into macro aggregates.

---

**Summary**

Using quasi-random examiner assignment, the paper instruments for patent rejection to estimate its causal effect on inventors’ interstate moves. The IV estimate implies that rejection raises the probability of relocating by roughly 1.1 percentage points—about a 9 percent increase relative to baseline mobility—with larger effects for solo inventors and experienced patentees. These patterns are presented as evidence that rejection destroys location-specific IP rents, triggering a “rejection drain” that counteracts place-based innovation policy.

---

**Essential Points**

1. **Exclusion Restrictions and Pre-trends:** The robustness of the examiner-leniency instrument is weakened by statistically significant correlations between examiner leniency and pre-determined inventor characteristics (Table 5) and—more troublingly—by the placebo showing leniency predicts prior moves. These findings suggest that examiner assignment may not be fully orthogonal to mobility-relevant traits even after art-unit-by-year FE, which undermines the exclusion restriction. The authors need to probe whether leniency captures unobserved inventor quality (e.g., mobility proclivities) that also affects future relocation, or whether measurement error in the mobility indicator is driving the placebo. Without such diagnostics, the causal claim is premature.

2. **Linking Inventor Mobility to Regional Labor Supply:** The paper motivates the study by referencing place-based innovation policies and state-level knowledge worker supply, yet it never empirically connects the micro-level rejection-induced moves to aggregate labor-market outcomes. If the manuscript’s policy contribution hinges on this linkage, the absence of the second-stage instrumentation (aggregating examiner-driven flows to predict state knowledge-worker employment) is a significant gap that should be remedied. At a minimum, the paper should closely justify why the observed mobility effect suffices to speak to state-level “brain drain,” perhaps via back-of-the-envelope calculations or complementary robustness checks.

3. **Measurement of the Outcome:** Mobility is inferred from subsequent patent filings identified via name-based matching, which introduces both false positives (name collisions) and false negatives (name variations). The paper acknowledges this but stops short of quantifying its implications. Given that the placebo test may reflect this measurement error, the authors should either (i) construct a more precise inventor panel (e.g., by incorporating disambiguation algorithms or ORCID identifiers where available) or (ii) validate the mobility indicator against external benchmarks (e.g., known relocations within a subset of inventors). Absent such validation, it is hard to interpret whether the IV estimate reflects genuine relocation or artifact.

---

**Suggestions**

1. **Strengthen the IV credibility:**  
   - Investigate whether the imbalance in pre-determined characteristics is driven by a few art-unit-by-year cells or is systematic across the sample. You might include cell-level diagnostics (e.g., plotting leniency against average prior mobility within cells) to see if any cells drive the imbalance.  
   - Explore alternative instrument constructions—for example, using examiner-team fixed effects or leveraging the timing of examiner rotations—to see if the mobility effect persists.  
   - Consider adding a difference-in-differences-style test: compare mobility after rejection for inventors whose assigned examiners switch leniency (e.g., due to promotion) against contemporaries whose examiners remain constant.

2. **Address the placebo anomaly:**  
   - The significant coefficient in the prior-move placebo suggests either endogenous sorting or measurement error. To disentangle these channels, you might conduct the placebo using a purely administrative measure (e.g., based on employment location recorded in another USPTO table) if feasible, or restrict the sample to inventors with highly common names versus rare names to see if the coefficient attenuates (which would implicate mechanical measurement issues).  
   - Alternatively, estimate the main specification on a subsample where you can credibly track inventors across filings (e.g., those with matched ORCID/assignee identifiers) to examine whether the placebo persists.

3. **Make the policy link explicit:**  
   - If you cannot implement the second-stage QWI exercise within the current paper, provide a supplemental calculation: use the estimated per-application effect, the total number of rejections per state (or nationally), and an assumed share of inventors per state to quantify the implied annual outflow. This helps readers gauge the magnitude of the “rejection drain” even without the full state-level estimation.  
   - Discuss more explicitly how inventor mobility translates into changes in place-based returns—do movers leave the patenting system altogether, or do they continue filing elsewhere? This determines whether rejection constitutes a genuine “loss” for the original state.

4. **Clarify the interpretation of the LATE:**  
   - The paper notes that the IV identifies marginal applicants. It would be helpful to characterize those applicants more precisely—are they from specific art units, technology boundaries, or organizational settings? Perhaps compare observable characteristics (e.g., team size, prior patents, assignee type) of marginal versus “always-rejected” inventors to assess external validity.  
   - Consider conducting a sensitivity analysis that bounds the effect under different assumptions about the share of marginal applicants per leniency quintile.

5. **Augment measurement of the key outcome:**  
   - Provide more detail on how you link inventors across filings: are you matching on full names, addresses, or other identifiers? Even if a fully disambiguated dataset is unavailable, reporting the rate of name collisions or conducting validation on a manually curated subset lends credibility.  
   - If possible, use additional PAIR fields (e.g., addresses, assignees) to triangulate the state change, which helps separate genuine geographic moves from institutional re-labelling.

6. **Explore heterogeneity by geography or technology:**  
   - Are the mobility effects uniform across regions (e.g., high-tech clusters vs. emerging states) or art units? Presenting state- or technology-specific estimates could reveal whether the rejection drain is concentrated in certain innovation hubs, which in turn informs policy relevance.  
   - Similarly, examine whether the effect differs by assignee type (e.g., corporations vs. universities vs. individuals), as the theoretical mechanism (location-specific rents) may operate differently across these groups.

7. **Robustness checks:**  
   - Include regressions weighted by application counts or inventor experience to ensure results are not driven by a few prolific inventors.  
   - Test alternative mobility windows (e.g., next filing within 5 years instead of 10) to check sensitivity to the definition.  
   - Try instrumenting only within narrower time windows (e.g., art-unit-year-quarter) to assess whether the instrument’s randomness holds at finer granularity.

8. **Transparency on data limitations:**  
   - Since the study relies on publicly available datasets, consider providing code or replication files (especially given the paper’s autonomous generation context) so referees and readers can verify the construction of the leave-one-out instrument and the mobility outcome.  
   - Articulate any assumptions made during sample construction (e.g., how you handle missing state codes or examinership gaps) so readers can assess potential selection biases.

By addressing these points, the paper can better support its causal claims and sharpen its contribution to the policy debate on how federal patent decisions interact with local innovation ecosystems.
