# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-26T23:36:02.532987

---

**Idea Fidelity**

The paper partially follows the idea manifest: it targets regulatory bunching at the UK Companies Act size thresholds and leverages Companies House plus IDBR data. However, it does not implement the multi-cutoff bunching strategy sketched in the manifest. The promised multi-dimensional identification—using multiple thresholds (employees, turnover, balance sheet), cross-dimensional predictions from the two-of-three rule, and the April 2025 statutory instrument as a migration experiment—is largely absent. The empirical work instead treats the problem as a conventional single-dimension bunching exercise with a negative outcome, and the explicit analysis of the 2025 threshold change (as a treatment) never materializes. As such, the paper misses key elements of the original identification strategy and the richer data promise (multi-threshold monitoring and policy variation) laid out in the manifest.

---

**Summary**

The paper investigates whether UK private firms bunch just below the Companies Act size thresholds (10, 50, and 250 employees) using iXBRL microdata and NOMIS aggregate counts. Contrary to the expectations from prior thresholds literature, it finds no excess mass at any of these boundaries and interprets the null as evidence that the two-of-three rule creates “compliance slack,” softening the incentive to distort reported size. The paper concludes that multidimensional thresholding may be an effective design to mitigate misallocation from size-dependent regulation.

---

**Essential Points**

1. **Insufficient and selected microdata undermines identification.** The microanalysis relies on three days of filings (8,927 observations) from March 2026, of which only 24% report employee counts, heavily overrepresenting larger firms. This sample neither reflects the universe of firms near the thresholds nor provides sufficient time variation to capture dynamic responses. The paper thus lacks a credible density estimate for the relevant population, and the null finding could simply reflect sample selection rather than a genuine absence of bunching. The authors should use the long panel promised in the manifest (e.g., the full 2008–2025 CH series), or construct a representative subsample with documented reporting probabilities, before interpreting the null.

2. **Aggregate density comparisons are too coarse to detect threshold effects.** The NOMIS data aggregates firms into wide bands (e.g., 20–49, 50–99), so the analysis reduces to comparing density drops across intervals that straddle the thresholds. This coarse granularity cannot detect bunching occurring at specific employee levels (10, 50, 250), and the elasticity comparison in Table 3 is simply a rephrasing of the Pareto slope, not an identification of behavioral distortion. The claim that the regulatory and non-regulatory rates are “statistically indistinguishable” is not meaningful unless one accounts for measurement error induced by the bin widths and tests whether bunching is detectable given the aggregation. A credible test requires either finer bins (e.g., combining administrative sources to get per-employee counts) or modeling how bunching would manifest in these aggregated data and testing whether the data reject that model.

3. **The institutional mechanism is asserted, not tested.** The key explanation—the two-of-three rule providing compliance slack—remains speculative. The paper does not quantify how many firms violate the employee threshold without triggering reclassification, nor does it examine whether firms closest to the threshold exploit the slack by bumping into the financial criteria. Without such evidence, the absence of bunching could equally be due to inattention, measurement error, or the inability of small firms to fine-tune employment. A more convincing identification strategy would exploit the promised multi-dimensionality: for example, test whether employee counts bunk in firms close to the turnover/balance sheet thresholds, examine firms that temporarily exceed one criterion but not two, or exploit the April 2025 increase in financial thresholds as a panel shock. Without these tests, the causal narrative linking the two-of-three rule to the null is unsubstantiated.

Given these fundamental issues, especially the identification concerns and the disconnect from the proposed multi-threshold strategy, I am inclined to recommend rejection at this stage. The paper should be reframed with richer data, explicit utilization of the multi-dimensional institutional variation, and more rigorous testing of the proposed mechanism before reassessment.

---

**Suggestions**

*Embrace the promised multi-threshold design.* The manifest envisioned multi-cutoff bunching that takes advantage of the three-dimensional size classification and the April 2025 statutory instrument. To operationalize this, the authors should:

- Construct a panel of firms using the full Companies House historical filings (2008–2026) rather than a three-day snapshot. With sufficient observations, one can estimate per-firm trajectories around thresholds and better detect bunching.

- Incorporate turnover and balance sheet figures alongside employment. Even if all three criteria are not reported for every firm, the dynamic nature of the Companies Act reclassification (two-of-three rule for two consecutive years) allows for classification status to be inferred. One could examine firms that exceed the employee threshold but not the financial ones, and test whether their reporting behavior differs before and after temporal reclassification triggers.

- Use the April 2025 thresholds increase as a quasi-experiment: firms that previously triggered reclassification could now remain in the lower category for a longer stretch because their turnover/balance sheet bands widened. This compliance slack should reduce any remaining bunching at financial thresholds, and the paper could measure the migration of firms across the size ladder pre- and post-reform. Such a “mass migration” prediction, as mentioned in the manifest, would dramatically strengthen the research design.

*Address selection and measurement in the microdata.* The authors currently note that only 24% of filings report employee counts, likely biasing the sample toward firms that voluntarily disclose (e.g., larger firms). To make the microdata useful:

- Provide a detailed comparison between firms with and without reported counts (e.g., through matching on turnover, SIC code, or filing type). If the two groups differ systematically, the density estimates are not representative of the threshold population.

- Instead of relying on a few days of filings, aggregate across many months/years (Companies House releases daily files) to build a large, representative sample. This also allows for temporal analysis around reforms such as IR35 and the 2025 thresholds.

- Consider merging the microdata with other administrative sources (e.g., PAYE data, VAT returns) that report employee counts or proxies, to validate the observed distribution and to improve coverage near the thresholds.

*Model the two-of-three rule directly.* To move beyond narrative explanations, the paper should:

- Estimate how frequently firms exceed only one criterion versus two; these frequencies help quantify how much compliance slack the two-of-three rule actually provides.

- Use regression discontinuity or event-study designs that exploit changes in classification status (e.g., when a firm first crosses a turnover threshold while already above the employee threshold) to estimate compliance costs. If the costs are mitigated only when two criteria are exceeded, that would directly support the proposed mechanism.

- Test whether firms adjust other margins (turnover, balance sheet size, use of contractors) in response to employee thresholds. If the two-of-three rule reallocates distortion to financial dimensions, one should see bunching or bunching-like behavior in those margins. Absence of distortions in all dimensions would reinforce the case for compliance slack but should be demonstrated empirically.

*Clarify the aggregate density comparison.* The elasticity analysis in Table 3 should be supplemented or replaced with a clearer test:

- Simulate what the NOMIS bins would look like under a known amount of bunching (e.g., using a micro-level distribution with a 10% excess mass at 50 employees) and show how the aggregation would affect detection. This calibration would demonstrate whether the data can reject economically interesting levels of bunching.

- Report confidence intervals for the “rate” estimates and explicitly test whether regulatory boundaries deviate from the Pareto prediction after accounting for bin width and measurement error.

- Alternatively, focus on more granular administrative data (if available) to perform a Chetty-style bunching test directly without relying on heavily binned counts.

*Be cautious when interpreting null results.* The paper repeatedly claims that it can “rule out” substantial bunching, yet the evidence is limited. To avoid overstating:

- Report the minimum detectable effect for each threshold and dataset, and be explicit about the assumptions (power, variance) behind those calculations.

- Discuss other reasons for null findings (e.g., firms’ inability to adjust employment precisely, reporting noise) rather than attributing them solely to institutional slack.

- Frame the result as “no evidence of bunching” rather than a proof that regulation is non-distorting, and outline what additional evidence would be needed to overturn this interpretation.

*Expand the discussion of policy implications.* If the two-of-three rule truly mitigates distortion, its applicability to other regulatory settings could be explored. For instance:

- Could multi-dimensional thresholds be introduced in tax policy or labor regulation? The paper could sketch how the architecture could transfer.

- Address whether the lack of bunching is a stable long-run pattern or whether changes in enforcement/reporting (e.g., online filings affecting reported employee counts) might alter incentives.

- Consider whether the absence of bunching implies firms are already optimally sized, or whether other margins (such as contractor use) absorb the regulatory burden. This would contextualize the policy takeaway.

By implementing these suggestions, the paper could salvage its interesting premise and contribute substantively to the literature on regulatory design.
