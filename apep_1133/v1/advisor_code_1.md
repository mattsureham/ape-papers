# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-30T11:51:18.775080

---

**Idea Fidelity**

The paper follows the manifest closely. It exploits MSHA’s accident reports with three distinct tenure variables to isolate mine-specific experience and links the accident data to employment panels to explore injury rates at the mine level. The two-stage empirical strategy (individual-level severity regression and mine-level new arrival share regression) is consistent with the design parameters. The promised robustness checks (nonlinear tenure, alternative severity thresholds, time splits, mine-type heterogeneity) are included, although the inspection-induced turnover IV mentioned in the manifest is absent from the final paper, which may weaken the argument about causal impacts of enforcement-driven displacement. Otherwise, the paper keeps faith with the original question of whether mine-specific tenure provides a “tenure shield.”

---

**Summary**

Using 222,350 MSHA injury reports with worker tenure at the total, mine, and job level, the paper documents that mine-specific tenure has little effect on injury severity conditional on occurrence but that mines with more new arrivals face substantially higher injury rates. The author interprets this as evidence that establishment-specific human capital chiefly operates at the extensive margin—preventing accidents—while once an accident occurs its severity is driven by physical circumstances. The decomposition contributes to the firm-specific human capital and workplace safety literatures by leveraging a unique regulatory dataset.

---

**Essential Points**

1. **Selection Bias in Individual-Level Severity REgression:** The identifying assumption for Equation (1) is that workers injured at the same mine-year-occupation cell who differ in tenure are comparable. However, longer-tenured workers may systematically self-select into more hazardous tasks (e.g., mentoring new hires, maintenance with higher risk) or be retained precisely because their abilities helped avoid severe incidents; conversely, short-tenure workers may receive more supervision. Without addressing such within-cell selection, the near-zero coefficient on mine tenure could reflect omitted heterogeneity rather than a true null effect. Consider exploiting quasi-experimental variation—such as sudden mine closures or enforcement actions inducing turnover—or using a bounding exercise with pre-injury hazard indicators if available.

2. **Interpretation of the “Experience Paradox” and Reporting Selection:** The finding that total experience predicts higher severity is attributed to underreporting of minor events among seasoned miners. Yet the paper lacks direct evidence that reporting intensity varies with experience; indeed, if experienced miners are assigned to riskier tasks, severity could rise mechanically. Without data on unreported incidents or task assignments, the reported paradox may be driven by omitted variable bias rather than reporting selection. The paper should explore alternative explanations (task assignment, reporting incentives) and, if possible, show that the probability of reporting or exposure to dangerous tasks is uncorrelated with total experience once other covariates are controlled.

3. **Causality of Mine-Level New-Arrival Impact:** The mine-year regressions relate injury rates to the fraction of injured workers who are new to the mine. The direction of causality is ambiguous: high injury rates might cause faster turnover (selective attrition) or draw in inexperienced workers, rather than new arrivals causing injuries. The manifest mentioned an IV strategy using inspection-induced turnover, but the paper does not implement it. Without an exogenous source of turnover, the mine-level results risk reverse causality. A first-stage showing that inspection intensity or S&S citations shift new-arrival shares, along with a second-stage injury-rate effect, would strengthen the claim that turnover causes injuries rather than merely correlating with them.

If these issues cannot be convincingly resolved, the paper should be reconsidered. As currently presented, causal claims about mine tenure and turnover risks may be overstated.

---

**Suggestions**

1. **Strengthen the Causal Argument at the Mine Level:**
   - Reintroduce the inspection-induced turnover IV discussed in the manifest. Use severe S&S citations (perhaps identified via regulatory thresholds) as an instrument for worker reallocation, exploiting variation in their timing or intensity. Demonstrating that such citations shift the new-arrival share but are plausibly exogenous to unobserved safety shocks at other mines would support a causal interpretation.
   - Alternatively, explore event-study designs around mine closures or large layoffs. If injury rates spike after a large influx of new workers due to a nearby mine’s closure (which plausibly exogenously increases turnover), that would reinforce the extensive-margin claim.

2. **Address Within-Cell Selection in the Cross-Sectional Severity Regressions:**
   - Include proxies for task assignment or supervision intensity. For instance, if the accident data contain subunit codes or shift indicators, interact tenure with these to control for the possibility that long-tenured workers are overrepresented in certain shifts or subunits.
   - Implement a leave-one-mine (or leave-one-occupation) out approach to check whether the mine tenure coefficient is driven by a few large mines with particular reporting practices.
   - Consider bounding techniques: regress severity on tenure using quantile regressions or partial identification strategies that allow for limited selection by specifying bounds on the correlation between tenure and unobservables.

3. **Clarify the Mechanism Behind the Experience Paradox:**
   - Test whether total experience predicts the probability of reporting small vs. large injuries. If the data distinguish between “days restricted” versus “days away,” comparing coefficients across these definitions could reveal whether experienced workers avoid minor injuries or simply report fewer of them.
   - If possible, use inspection reports or enforcement data to proxy for exposure to risky tasks. Show that total experience remains positively correlated with severity even after conditioning on such proxies, or argue why such proxies are unlikely to confound the interpretation.

4. **Expand on Heterogeneity and Mechanism Tests:**
   - The heterogeneity section hints that coal mines exhibit a different tenure effect. Flesh this out with deeper investigation: do coal mines with more geological variation show stronger effects? Are there subsamples (e.g., underground coal vs. surface coal) with larger tenure coefficients?
   - Examine whether the tenure shield differs by job specialization. Perhaps site-specific knowledge matters more for equipment operators vs. maintenance workers. Including occupation tenure interactions could reveal whether the effect truly arises from establishment-specific knowledge independent of task-specific expertise.

5. **Improve Presentation of Effect Sizes:**
   - The current coefficients are hard to interpret (e.g., −0.0007). Provide standardized effect sizes or translate coefficients into percentage differences for a typical range of tenure (e.g., moving from 1 year to 5 years at a mine reduces the probability of high severity by X percentage points). This would help readers grasp the practical significance of the tenure shield, particularly in light of the argument that its effect is concentrated at the extensive margin.

6. **Elaborate on Policy Implications with Caution:**
   - The paper’s policy discussion stresses turnover costs, yet the estimation gaps noted above warn against overstatement. Frame the implications as tentative: turnover is associated with higher injury rates, but causality depends on further evidence. This caution protects the contribution while still highlighting the importance of horizon-specific human capital in safety.

7. **Data Transparency and Robustness:**
   - Provide more detail on missingness. Appendix mentions 18% of records missing tenure, mostly early years. Show that the main results are robust to weighting by the inverse probability of missing tenure or restricting to post-2008 data where coverage is better. If missingness is non-random (e.g., more severe accidents have fuller reporting), this could bias severity coefficients.
   - Report first-stage F-statistics if an IV is implemented, and include alternative specifications with different bandwidths (e.g., defining new arrivals as <6 months vs. 1 year) to demonstrate robustness of the external margin finding.

In summary, the paper addresses an important question with compelling data, but it would benefit from a stronger identification strategy—especially regarding individual-level selection and mine-level causality—and clearer interpretation of counterintuitive findings. Addressing the points above would considerably strengthen confidence in the tenure shield narrative.
