# V1 Empirics Check — mistralai/mistral-large-2512 (Variant A)

**Model:** mistralai/mistral-large-2512
**Variant:** A
**Date:** 2026-03-25T01:17:47.767208

---

### 1. Idea Fidelity

The paper largely adheres to the original idea manifest but deviates in several important ways:

**Strengths:**
- The core identification strategy (DiD with continuous treatment intensity using pre-2017 significance share) is faithfully implemented.
- The use of EO 13771’s rescission as a reversal test is preserved.
- The primary data source (Federal Register API) aligns with the manifest’s Regulations.gov reference, though the manifest also mentioned `eo13771Designation` fields, which are not used in the paper.

**Deviations:**
- **Outcomes:** The manifest proposed three outcomes (NPRM-to-Final duration, completion probability, withdrawal indicator) but the paper focuses on log(NPRMs), completion rate, duration, and *significance share*. The latter is a novel outcome not mentioned in the manifest, while withdrawal is omitted.
- **Unit of analysis:** The manifest suggested rule-level analysis (61,501 dockets) but the paper aggregates to agency-semester cells (1,200 observations). This reduces power and obscures heterogeneity at the rule level.
- **Treatment intensity:** The manifest defined treatment as the share of *economically significant* rules (using `priorityCategory`), but the paper uses the broader EO 12866 *significant* designation. These are not identical (economically significant is a subset of significant), which may dilute the bindingness of the constraint.
- **Secondary outcomes:** The manifest highlighted the ratio of deregulatory to regulatory dockets (using `eo13771Designation`), but this is not analyzed in the paper.

**Missed opportunities:**
- The paper does not exploit the `eo13771Designation` field to directly test whether agencies shifted toward deregulatory rules, which was a key part of the manifest’s novelty claim.
- Rule-level analysis (e.g., duration or withdrawal) could have provided more granular evidence on how the EO affected individual rules.

---

### 2. Summary

The paper exploits EO 13771’s two-for-one regulatory budget as a natural experiment to study how agencies responded to a binding constraint on rulemaking. Using a continuous DiD design with pre-existing variation in agencies’ shares of significant rules, it finds that agencies primarily adjusted by reducing the *share* of significant rules (by 18 pp) rather than the *volume* of rulemaking. This compositional shift persisted after Biden’s rescission, suggesting a reclassification ratchet. The paper contributes to the literature on regulatory design, agency behavior, and the limits of executive control over the administrative state.

---

### 3. Essential Points

**1. Treatment intensity mismatch:**
The paper uses EO 12866 *significant* designations as treatment intensity, but the manifest (and EO 13771 itself) focused on *economically significant* rules. The latter are the subset most likely to trigger the offset requirement, as they impose costs >$100M. Using the broader "significant" category may understate the bindingness of the constraint for high-intensity agencies (e.g., EPA, OSHA). The authors must:
- Justify why they deviated from the manifest’s economically significant measure.
- Show robustness to using economically significant rules as the treatment intensity (even if sample size drops).
- Clarify whether the results hold when restricting to rules with cost estimates (e.g., from Regulatory Impact Analyses).

**2. Aggregation bias and power:**
Aggregating to agency-semester cells (1,200 observations) loses granularity and reduces power. The manifest proposed rule-level analysis (61,501 dockets), which would allow:
- Direct testing of the manifest’s proposed outcomes (duration, withdrawal).
- Heterogeneity analysis (e.g., by rule complexity, agency type, or cost).
- Event studies at the rule level to validate parallel trends.
The authors should either:
- Re-run the analysis at the rule level (even if only for robustness).
- Explain why aggregation was necessary and how it affects interpretation (e.g., ecological fallacy).

**3. Mechanism ambiguity:**
The paper argues that agencies responded via reclassification, but the evidence is indirect. The key outcome—significance share—could reflect:
- **Strategic reclassification:** Agencies redesign rules to avoid the significance threshold (the paper’s claim).
- **Genuine deregulation:** Agencies issue fewer costly rules, replacing them with less impactful ones.
- **Measurement error:** Agencies misreport significance to avoid scrutiny.
The authors must:
- Provide descriptive evidence on whether the content of rules changed (e.g., comparing pre/post-EO text similarity for significant vs. non-significant rules).
- Test whether the decline in significance share is driven by new rules or reclassification of existing ones (e.g., using the Unified Agenda’s "withdrawn" or "re-proposed" statuses).
- Discuss whether the persistence post-rescission is consistent with sunk costs (reclassification) or continued deregulatory preferences.

---

### 4. Suggestions

**A. Data and Measurement:**
1. **Exploit `eo13771Designation`:**
   - The manifest highlighted this field as a key innovation. The paper should include a table showing the ratio of deregulatory to regulatory dockets by agency-semester, interacted with treatment intensity. This would directly test whether high-intensity agencies shifted toward deregulatory rules.
   - Example specification:
     ```
     DeregRatio_at = α_a + δ_t + β₁(Post2017_t × HighIntensity_a) + β₂(Post2021_t × HighIntensity_a) + ε_at
     ```
   - If `β₁ > 0`, it supports the paper’s claim that agencies adjusted compositionally.

2. **Rule-level analysis:**
   - Replicate the main results at the rule level (e.g., duration, withdrawal) to validate the aggregation. This could be an appendix table.
   - Include a figure showing the distribution of rule durations pre/post-EO for high- vs. low-intensity agencies.

3. **Cost data:**
   - Merge with Regulatory Impact Analyses (RIAs) to test whether the decline in significant rules corresponds to a decline in estimated costs. If costs fell proportionally, it suggests genuine deregulation; if not, it suggests reclassification.

4. **Alternative treatment intensity:**
   - Construct a treatment variable using the *cost* of rules (e.g., share of rules with costs >$100M) rather than significance designations. This would more directly capture the bindingness of EO 13771.

**B. Identification:**
1. **Parallel trends:**
   - The event study (Table 4) is a good start but could be improved:
     - Show event studies for *all* outcomes (not just NPRM count).
     - Include a figure plotting the coefficients with confidence intervals.
     - Test for pre-trends formally (e.g., joint significance of pre-period coefficients).

2. **Placebo tests:**
   - The placebo test (Table 5) is well done but could be expanded:
     - Run placebo tests for *all* outcomes.
     - Use multiple placebo dates (e.g., 2014H1, 2015H1) to rule out spurious trends.

3. **Dynamic effects:**
   - The paper assumes the effect is constant post-EO. Test for dynamic effects by interacting treatment intensity with semester indicators (e.g., `Post2017_t × SigShare_a × (t - 2017H1)`). This could reveal whether the effect grows over time (e.g., as agencies learn to reclassify).

**C. Mechanisms:**
1. **Reclassification vs. deregulation:**
   - Add a table showing the share of rules that were:
     - Withdrawn and re-proposed as non-significant.
     - Never finalized (extensive margin).
     - Finalized with lower costs (intensive margin).
   - Use text analysis (e.g., cosine similarity) to compare the content of significant vs. non-significant rules pre/post-EO.

2. **Heterogeneity:**
   - Test whether the effect varies by:
     - Agency type (cabinet vs. independent).
     - Rule complexity (e.g., length of NPRM text).
     - Political salience (e.g., media coverage of the rule).
   - Example: If reclassification is easier for low-salience rules, the effect should be larger for them.

3. **Rescission dynamics:**
   - The paper claims the effect persists post-rescission, but the coefficient (`β₂ = -0.157`) is not statistically different from `β₁`. Test whether `β₂ = -β₁` (full reversal) or `β₂ = 0` (no reversal) using a Wald test.

**D. Interpretation:**
1. **Policy implications:**
   - The paper argues that regulatory budgets are ineffective because agencies reclassify rules. But reclassification could still reduce regulatory costs if non-significant rules are less burdensome. The authors should:
     - Discuss whether the shift to non-significant rules likely reduced costs (e.g., by comparing cost estimates for significant vs. non-significant rules).
     - Clarify whether the persistence post-rescission is a feature (agencies learned to avoid significance) or a bug (agencies lost capacity to issue significant rules).

2. **Comparison to legal literature:**
   - The paper cites legal commentary on EO 13771 but does not engage with its findings. For example:
     - Did legal scholars predict reclassification as a response?
     - How do the paper’s results align with or contradict prior descriptive work?

3. **Generalizability:**
   - The paper mentions OECD countries with similar rules (UK, Canada). Discuss whether the U.S. experience is likely to generalize, given differences in:
     - Legal systems (e.g., UK’s rulemaking is less judicialized).
     - Agency independence (e.g., Canada’s agencies are more autonomous).
     - Enforcement (e.g., UK’s rule counts are binding; U.S. costs are not).

**E. Presentation:**
1. **Clarity:**
   - The abstract and introduction overstate the precision of the results (e.g., "reduced their share of significant rules by 18 percentage points" with `p = 0.078`). Acknowledge the imprecision and discuss power limitations.
   - Define "significant" and "economically significant" clearly in the introduction (many readers may confuse them).

2. **Figures:**
   - Add a figure showing the distribution of treatment intensity (significance share) across agencies.
   - Include a map of agencies colored by treatment intensity to visualize variation.

3. **Tables:**
   - Table 1: Add a column showing the top 5 agencies by significance share (e.g., HHS, Labor) and bottom 5 (e.g., Coast Guard, FAA).
   - Table 2: Add a column with standardized effects (like Table A1) to help readers interpret magnitudes.

4. **Appendix:**
   - Include a table showing the correlation between significance share and other agency characteristics (e.g., budget, staff size, political salience).
   - Add a robustness check using only agencies with >50 rules in the pre-period to ensure results are not driven by small agencies.

**F. Minor Suggestions:**
- The title ("The Reclassification Response") is catchy but could be more precise (e.g., "Strategic Reclassification Under a Regulatory Budget").
- The abstract’s claim that "agencies responded primarily through reclassification rather than volume reduction" is not fully supported by the data (the volume effect is imprecisely estimated). Soften this language.
- Discuss whether the results are robust to using *final* rules (not proposed rules) to define treatment intensity, as final rules are what ultimately matter for costs.
- Cite \citet{cooper2015regulatory} on the challenges of measuring regulatory output, which is relevant to the paper’s focus on classification.
