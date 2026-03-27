# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-27T17:57:46.815576

---

**Idea Fidelity**

The paper loosely pursues the manifest’s core question—whether disclosure thresholds suppress nonprofit growth—but diverges materially from the stated identification strategy. The manifest envisioned exploiting the 2010 reform that raised the Form 990-EZ threshold from \$100K to \$200K by comparing organizations that bunched below the old threshold (and therefore faced disclosure pressure) to those that naturally exceeded it, tracking their post-reform revenue trajectories. Instead, the paper analyzes only 2011–2022 data, compares organizations around the \$200K threshold to contemporaneous controls, and interprets differential growth after 2016 as evidence on the threshold’s bite. The critical variation induced by the threshold reform is therefore never explicitly exploited, and the sample construction departs from the intended treatment (defined by 2005–2009 bunchers). This undermines the causal interpretation promised by the manifest.

---

**Summary**

The paper assembles a panel of 1,396 nonprofits filing IRS Form 990/990-EZ between 2011 and 2022 and tests whether the \$200,000 gross receipts threshold creates a “compliance ceiling.” The analyses, including bunching estimates around the threshold, difference-in-differences growth regressions, and dynamics/transition probabilities, all point to a null: no statistically significant excess mass at \$200K and no revenue suppression for organizations near the threshold relative to mid-range controls. The paper interprets this as evidence that Form 990 compliance costs are too small to distort growth at that margin.

---

**Essential Points**

1. **Identification strategy does not leverage the 2010 reform.** The manifest promised to compare firms that complied with the old \$100K threshold (bunched pre-2010) to those that did not, exploiting the 2010 policy switch as a natural experiment. The empirical strategy in the paper, however, only uses post-reform data and compares organizations near \$200K to contemporaneous controls, with “post” defined arbitrarily around 2016. Because there is no within-unit change in the compliance regime under study, the estimated DiD coefficient cannot be interpreted as the causal effect of escaping or facing the disclosure threshold. The paper thereby fails to isolate the variation it claims motivates the study.

2. **Treatment/control definitions and timing are unclear and imply no true counterfactual.** The “constrained” group includes organizations with baseline revenue between \$170K and \$220K, but these organizations have been subject to the \$200K threshold throughout the sample window (2011–2022), as have the controls. There is no clear treatment introduction or threshold change during the analysis period, so the DiD essentially compares static cross-sectional differences over time. Without a credible source of exogenous variation—either the 2010 reform or another discrete policy shift—the results are vulnerable to persistent unobserved heterogeneity and do not isolate the compliance ceiling mechanism.

3. **Sample construction inhibits inference about the broader population of threshold-sensitive nonprofits.** The analysis relies on a stratified random sample drawn from organizations with mean revenue between \$25K and \$500K, but after exclusions the panel contains only 1,396 organizations (200 near \$200K). The bunching estimates, event study, and transition probability analyses are therefore based on a relatively small and potentially non-representative sample, especially since the ProPublica data primarily cover electronically filed returns (mandatory only after 2016). It is unclear whether the paper has adequate power to detect economically meaningful effects or whether the sample overrepresents organizations already comfortable with disclosure requirements, biasing results toward the null.

Because these issues strike at the heart of identification, addressing them is essential before the paper can credibly answer the policy question.

---

**Suggestions**

1. **Re-center the analysis on the 2009–2010 threshold reform.** To match the manifest’s promise and generate a credible causal estimate, the paper should leverage the change from \$100K to \$200K as the treatment. Specifically:
   - Construct a panel covering years both before and after 2010 (or at least 2005–2012). This will require expanding beyond the 2011–2022 electronic filing dataset—possibly by incorporating older IRS filings or aggregating data from the legacy dataset.
   - Define the treatment group as organizations that were bunching just below \$100K in the pre-reform period and therefore faced a disclosure penalty, and the control group as organizations that were never close to the threshold (e.g., consistently above \$120K but below \$200K). The post-2010 comparison should then reveal whether removing the penalty allowed treated organizations to grow faster.
   - Alternatively, implement a regression discontinuity in the pre-reform period to estimate bunching around \$100K and compare the extent of bunching before and after the reform, as well as subsequent revenue trajectories. Whatever approach is chosen, make sure the policy change induces variation in the exposure to the disclosure ceiling and that the analysis tracks the same organizations across the policy shift.

2. **Clarify and strengthen the empirical strategy.** Assuming the data can be expanded:
   - Justify the “post” period selection. Currently “post” starts in 2016, but the threshold change occurred in 2010. If focusing on the 2016 electronic filing mandate, explain why that is the relevant policy shock and design the control group accordingly.
   - If a DID is still the preferred approach, provide evidence that the treatment and control groups had parallel pre-treatment trends (using pre-reform data) and are comparable on observables (assets, net income, sector). Without such diagnostics, it is unclear whether the null result stems from the threshold having no bite or from comparing inherently different organizations.
   - Consider alternative identification: e.g., use propensity-score matched controls around the threshold, or exploit discontinuities in compliance costs (e.g., difference between 990 and 990-EZ filings) to isolate the causal channel.

3. **Address power and representativeness concerns.** The absence of a detected effect might reflect limited precision:
   - Provide power calculations to show the minimum detectable effect size given the sample, especially for the revenue growth DiD and bunching tests. If the sample can only detect very large effects, this should be clearly acknowledged.
   - Compare the sampled organizations to the broader population in terms of size, sector, and filing behavior to assess representativeness. If the sample overrepresents organizations already filing electronically or with stable revenue, the null may not generalize to the broader set of threshold-bound nonprofits.
   - Where possible, expand the sample (e.g., include more observations from the IRS EO BMF, supplement with data from GuideStar/Candid) to improve precision and coverage.

4. **Deepen the descriptive and robustness analysis.** To provide additional context for the null:
   - Report the evolution of the Form type mix (990 vs. 990-EZ) over time around the threshold. If organizations are not switching filings, that supports the claim that compliance costs are low, but this should be documented.
   - Explore heterogeneity by sector or payroll size. Even if the average effect is null, some subsectors (e.g., arts vs. human services) may be more sensitive to disclosure costs. The Standardized Effect Size table hints at such heterogeneity; formalizing these analyses with interaction terms and robustness checks would strengthen the argument.
   - Investigate alternative outcomes beyond revenue (e.g., program expense ratios, administrative cost share, new hires) to rule out other forms of growth suppression.

5. **Engage explicitly with the bunching literature’s methods.** The paper references Kleven and Waseem’s approach but does not fully implement robustness checks common in that literature:
   - Vary the polynomial degree, bin width, and exclusion window for the counterfactual density and report whether the excess mass remains insignificant. Provide graphical diagnostics (density plots with counterfactual) for transparency.
   - Since the normalized excess mass estimates are noisy and small, consider using the recent “bunching with covariates” extensions to account for observable heterogeneity that might obscure the threshold effect.
   - Compare the estimated excess mass before and after the threshold reform (using pre-2010 data if available). Demonstrating that bunching disappeared at \$100K and did not reappear at \$200K would more directly test whether the reform affected behavior.

6. **Clarify the policy interpretation.** The conclusion currently jumps to the broader implication that disclosure thresholds need not be distortionary. Given the limited evidence presented, temper these claims by emphasizing the boundary conditions: e.g., the null pertains to the \$200K Form 990 threshold for the sampled organizations and may not generalize to higher thresholds or to organizations with less access to paid preparers. Explicitly state the range of effect sizes ruled out by the confidence intervals, so readers understand the precision of the null.

By re-anchoring the empirical strategy to the actual reform, expanding the data to include the pre-reform period, and addressing concerns about power and sample representativeness, the paper can make a much stronger and more credible contribution to the literature on compliance thresholds and nonprofit growth.
