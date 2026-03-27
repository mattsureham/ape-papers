# V1 Empirics Check — x-ai/grok-4.1-fast (Variant B)

**Model:** x-ai/grok-4.1-fast
**Variant:** B
**Date:** 2026-03-27T17:57:55.182215

---

### 1. Idea Fidelity

The paper deviates substantially from the original idea manifest. The manifest proposed a DiD exploiting the 2010 reform to causally identify whether disclosure avoidance constrained growth, using pre-reform (2005-2009) bunchers below $100K as treated units (now freed from disclosure pressure) and never-bunchers in the $100K-$200K range (who filed full Form 990 without avoidance) as controls. Revenue trajectories would be tracked dynamically post-reform using IRS 990 XML and ProPublica data. Instead, the paper shifts to a post-reform (2011-2022) analysis testing for a "compliance ceiling" at the new $200K threshold via bunching estimates and DiD comparing cross-sectional groups near $200K ($170K-$220K baseline mean) to mid-range controls ($120K-$160K). It mentions the reform but does not use pre-reform bunchers, omits 2005-2010 data, and forgoes the key causal contrast between suppressed and unconstrained organizations. This misses the manifest's novel dynamic focus, yielding a weaker steady-state test rather than a reform-based causal estimate.

### 2. Summary

This paper examines whether the $200K Form 990-EZ threshold creates a "compliance ceiling" constraining nonprofit revenue growth, using bunching analysis and DiD on a sampled panel of 1,396 organizations from ProPublica and IRS BMF data (2011-2022). It finds no statistically significant bunching at $200K (excess mass of 0.09, similar to placebos) and no evidence of growth suppression near the threshold relative to controls ($\hat{\beta} \approx -0.04$, insignificant). The null suggests Form 990 compliance costs are too small to distort behavior at this scale, attributing this to low marginal costs, electronic filing, or disclosure frictions orthogonal to revenue.

### 3. Essential Points

1. **Weak Identification Strategy**: The DiD does not credibly identify causal effects of disclosure policy, as it compares static post-reform size groups without exploiting the 2010 reform's quasi-experimental variation (e.g., pre-reform bunchers vs. non-bunchers). Baseline means (2011-2015) likely reflect selection into groups after the reform, violating parallel trends; event studies show noisy pre-trends (e.g., $t-3$ coefficient 0.066). Authors must reorient around the manifest's design—track ~5,000-10,000 pre-2010 bunchers' growth post-reform—or clearly justify why the current cross-section isolates disclosure effects from confounders like sector or age differences.

2. **Insufficient Power and Sample Representativeness**: With only 200 "constrained" organizations (2,207 org-years) and ~300 controls, estimates are imprecise (e.g., DiD SE=0.064 on log revenue, event study CIs >0.3 wide), undermining claims to "rule out" effects (95% CI spans -16% to +9% growth). Sampling from BMF income codes and ProPublica (electronic filings only) excludes smallest/oldest organizations most sensitive to thresholds. Authors must report minimum detectable effects (e.g., via power calculations) and expand the sample (full ProPublica universe has 200K+ annual filers) or use IRS SOI aggregates for density plots.

3. **Bunching Analysis Lacks Robustness**: Excess mass at $200K is small and insignificant but not formally tested against placebos (e.g., no F-test for $\hat{b}_{200K} > \hat{b}_{150K}$). Bin size ($2K), polynomial order (7th), and exclusion window ($10K) are arbitrary; negative mass at old $100K$ is reassuring but requires pre-reform counterfactuals. Authors must provide robustness (e.g., alternative polynomials, bins, local projections) and expected bunching size from compliance cost estimates ($c/\alpha$).

Failure to address these would warrant rejection, as the paper does not support causal claims about policy effects.

### 4. Suggestions

The paper is well-written, concise, and AER:Insights-appropriate in structure, with clear institutional detail and plausible null explanations (e.g., tech-driven cost declines). To strengthen coherence and contribution:

- **Data and Sample Enhancements**: Leverage full IRS 990 XML index (705K filings/year, per manifest) or ProPublica bulk downloads for universe-level bunching (current N too small for precise densities). Extend pre-period to 2005-2010 where possible (ProPublica covers it) to validate reform effects directly—e.g., document $100K$ bunching disappearance. Tabulate group balance (e.g., by NTEE code, founding year, state) and test pre-trends formally (joint F-test on leads). Appendix A is helpful; add raw density histograms around thresholds.

- **Empirical Refinements**: For DiD, use continuous distance-to-threshold ($rev_{i,base} - 200K$) interacted with post, or RD-style local DiD within narrower windows ($190K-$210K$ treated, $130K-$170K$ controls). Incorporate triple differences (e.g., × sector or asset size) to probe heterogeneity (Appendix Table SDE hints at large sectoral variation, e.g., -0.45 SDE in health). Event study normalization (omit $t-1$) and leads/lags plot would clarify dynamics. For transition probabilities, estimate Kaplan-Meier survival curves for time-to-crossing.

- **Mechanisms and Falsification**: Expand mechanism tests—e.g., regress form-type switches or preparer fees (if available in 990 Schedule O) on proximity. Placebo on $500K$ asset threshold or pre-2010 $100K$. Quantify costs: cite preparer surveys (e.g., $300-800$ incremental, per Yetman) and simulate detectable $c$ (e.g., if $\alpha=0.5$, need $c>10K$ for observed null). Test disclosure channel via compensation bunching (Part VII data).

- **Robustness and Interpretation**: Add TWFE diagnostics (e.g., Sun-Young plot for dynamics). Heterogeneity by filer type (e.g., self-prepared vs. CPA) or growth mode (donations vs. fees, from 990 Part VIII). Discuss external validity: contrast with higher-stakes thresholds (e.g., $10M$ 990 Schedule H). For null emphasis, compute economic significance (e.g., implied $c<1\%$ revenue) and Bayesian priors on effect size.

- **Presentation Polish**: Label tables consistently (e.g., "Table 2" for DiD, "Table 3" for event study, "Table 4" for mechanisms). Use \si{\dollar} for currencies. Abstract/conclusion: quantify "no evidence" via CIs. Literature: cite more nonprofit manipulation papers (e.g., Hoopes et al. 2018 on earnings mgmt.). Total length fits Insights (~15 pages); appendices could host full densities, balance tables.

These changes would elevate a solid null study to a strong contribution, bounding disclosure costs empirically and informing threshold design.
