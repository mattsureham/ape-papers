# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-04-07T20:37:39.484002

---

**Idea Fidelity**

The paper largely follows the original idea manifest. It exploits the 100-employee threshold in OSHA’s 2023 electronic reporting mandate, uses the ITA 300A Summary Data from 2016–2024, estimates both density shifts and outcomes in a difference-in-discontinuities (DinD) framework, and focuses on the information-disclosure channel by examining injury rates and bunching behavior. That said, the paper’s emphasis shifts slightly from the manifest’s stated goal of evaluating whether the rule “reports the risk away” (i.e., improves safety) to documenting avoidance behavior (“the disclosure dodge”). While this pivot is theoretically defensible, the paper could do more to clarify the counterfactual of a clean information-disclosure channel—particularly because the manifest flagged the testing of “regulation by information” as the novel contribution. Also, the manifest envisioned compositional controls by non-Appendix B industries, a pre/post event study, and bunching analyses; the paper implements all three. Hence, fidelity is high, but the narrative could better foreground how the null injury-rate result complements the bunching evidence within the original research question.

---

**Summary**

This paper studies OSHA’s 2023 mandate requiring establishments with ≥100 employees in high-hazard industries (Appendix B) to electronically file detailed injury logs. Using 2016–2024 ITA data, it combines a cross-sectional RDD at the 100-employee cutoff with temporal (pre/post 2024) and cross-industry (Appendix B vs. non-Appendix B) variation to form a difference-in-discontinuities design. The key findings are significant bunching below 100 employees among treated establishments after 2024, but no detectable reduction in injury rates among compliers; thus, firms appear to avoid disclosure rather than improve safety.

---

**Essential Points**

1. **Interpretation of the DinD Estimate:** The paper treats the difference-in-discontinuities coefficient as the causal effect of disclosure on injury rates, yet the DinD design may still be confounded by post-treatment selection: the bunching response alters which firms populate the populations immediately above and below the threshold after 2024, and this compositional shift could differ between Appendix B and non-Appendix B industries if the elasticity of size adjustment varies systematically. The manuscript acknowledges selection qualitatively but stops short of bounding or formally addressing its impact on the DinD estimator. The authors should either provide a sensitivity analysis (e.g., reweighting, Lee bounds, or worst-case bias calculations) or motivate why such selection does not threaten the DinD estimate beyond the pre/post differencing.

2. **External validity of avoidance mechanism:** The bunching result is compelling, but the paper’s conclusion that “regulation by information generates avoidance, not compliance” requires careful calibration. The documented bunching could reflect short-term administrative responses (e.g., temporary agency labor) rather than longer-run decisions not to comply. The paper should characterize the persistence and economic significance of the bunching—does it persist beyond 2024?—and quantify the actual employment adjustments (e.g., magnitude of layoffs, subcontracting). Without this, it is difficult to assess whether avoidance dominates the policy effect or simply delays it.

3. **Ruling out alternative explanations for bunching:** The key McCrary test assumes firms can finely manipulate the annual average employment count, but the data are annual averages reported with rounding or managed through multiyear payroll practices. It is unclear whether administrative reporting idiosyncrasies (e.g., rounding to the nearest whole number, differences in how workforce size is averaged) could explain the density discontinuity. The authors should provide robustness to alternative running-variable definitions (e.g., replacing annual averages with counts from alternative columns, using trimmed windows) and demonstrate that the bunching is not an artifact of reporting changes coinciding with 2024 (e.g., the new electronic submission process may have influenced how firms report employee counts even absent strategic manipulation).

If more than these three issues are critical, the paper should be rejected outright.

---

**Suggestions**

1. **Formalize the selection narrative in the DinD context.** The bunching-induced selection threatens not only cross-sectional RDD estimates but also the DinD. Consider estimating the DinD for sub-samples that exclude the manipulation window (e.g., restrict to [80,95] and [105,120]) so that the comparison does not rely on the bins most affected by bunching. Alternatively, implement Lee bounds by estimating the share of establishments that “disappear” from above-100 after the mandate and explore how much selection would be needed to overturn the null result. This would give readers a quantitative sense of whether the null is credible or driven by composition.

2. **Examine dynamic bunching patterns.** The paper’s bunching evidence rests on a single post-treatment year. If the avoidance response persists or grows, it strengthens the policy conclusion; if it fades, it cautions that firms simply delayed growth. When 2025 data become available, update the analysis; even now, consider using the 2023 data to explore whether there were bunching episodes around other regulatory changes (e.g., the 250-employee rule) as robustness. If possible, use establishment-level identifiers (even if noisy) to track whether establishments below 100 in 2024 reappear above 100 in 2025, which would shed light on whether avoidance signals structural change or temporary compliance.

3. **Mechanism: how do firms avoid the threshold?** If operational strategies (outsourcing, splitting establishments) explain the bunching, the welfare implications differ from that of layoffs. Use supplementary data (e.g., payroll filings, BLS QCEW) to document whether the total headcount in Appendix B industries around the threshold changes, or whether firms shift workers to staffing agencies. Even simple aggregate-level time series—like the number of staffing agency placements in high-hazard industries—could support the mechanism story. If additional data are unavailable, add discussion about how different adjustment channels would affect worker welfare and OSHA’s enforcement goals.

4. **Clarify the policy counterfactual.** The paper concludes that the threshold design creates a disclosure dodge, but the policy alternative is not fully articulated. Consider simulating the effect of a universal mandate (no threshold) versus alternative phase-in designs on the extent of bunching and the implied compliance cost. A back-of-the-envelope calculation could show how much bunching would remain under a phased structure (e.g., 75, 90, 105 employee kinks). This would give policymakers concrete guidance on how to redesign disclosure thresholds to minimize avoidance.

5. **Deepen the interpretation of the null injury-rate effect.** The paper briefly lists three possible interpretations (long-run effects, measurement noise, avoidance). Deepen this section by exploring subsidiary outcomes that might reveal early compliance responses—such as changes in the share of establishments reporting zero injuries, or shifts in the ratio of days-away cases to total cases (which might signal reporting manipulation). Even if these outcomes are noisy, consistent patterns (or the absence thereof) would help adjudicate between hypotheses.

6. **Strengthen the comparison group’s credibility.** The DinD relies on non-Appendix B industries as controls. Provide evidence that these industries do not experience their own policy shocks in 2024 (e.g., review other OSHA rules, industry-specific trends, or macro shocks) and that their size distributions did not change differentially at 100 employees. Additional placebo tests—estimating the DinD using a fake threshold (e.g., 90 employees) or treating a randomly chosen set of industries as “treated”—would boost confidence in the control group.

7. **Address potential data issues with the running variable.** The paper mentions integer-valued employee counts and possible measurement error. Clarify whether the running variable is reported as exact integers or rounded, and whether the annual averages are calculated in a consistent manner across firms or years. If the running variable has bunching at round numbers even before 2024 (e.g., 100 is already a focal point), this could contaminate the McCrary test; show density plots for earlier years to reassure readers that the bunching is new. If rounding is pervasive, consider implementing RDD methods designed for discrete running variables (e.g., Dong and Lewbel, 2015) to check robustness.

8. **Expand the discussion on enforcement complementarities.** The paper rightly notes that disclosure lacks enforcement teeth. Build on this by discussing how OSHA could augment disclosure with targeted inspections or public scorecards, grounding the argument in the broader literature on regulatory mix (information + enforcement). If feasible, simulate how combining disclosure with a modest enforcement trigger (e.g., inspections for firms with high reported rates) might change the bunching incentive.

9. **Improve presentation of tables and figures.** Table 2 (main results) currently shows columns (1)-(5) with minimal explanation. Re-label columns clearly (e.g., “Appendix B only”, “DinD—TCR”, “DinD—DART”) and provide a fuller description of the specification in the caption. Some figures (e.g., the event-study plot) use absolute scales that obscure relative differences; consider normalizing by pre-period standard deviations or including confidence bands for all years. Finally, ensure that all references in the text point to the right figure/table numbers; for instance, the text references \Cref{fig:dind} and \Cref{tab:event_study}, but the LaTeX numbering may change.

10. **Document data and code availability.** Since the paper relies on public ITA data, specify how readers can replicate the analyses—provide download links, describe any cleaning steps (e.g., how missing values were handled), and mention whether the code is available (consistent with open science practices). This will enhance transparency and allow future researchers to extend the work with additional post-2024 data.

These suggestions aim to strengthen the causal interpretation, deepen the policy relevance, and polish the empirical presentation.
