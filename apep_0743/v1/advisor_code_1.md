# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-22T15:23:53.279588

---

**Idea Fidelity**

The paper stays broadly faithful to the manifest: it exploits the border discontinuity between states that mandate funeral director involvement and those that do not, uses Census County Business Patterns data, and focuses on death care market structure (establishments, employment, payroll) in the relevant counties. Two departures from the original idea should be noted. First, the manifest anticipated 22 border segments drawn from nine FD-required states; the paper analyzes 26 segments, implicitly adding additional treatment–control borders (e.g., Illinois–Wisconsin) that were not initially listed. Second, the manifest envisaged a longer panel (1998–2022) while the paper works with averaged 2017–2022 data. Neither change is fatal, but the paper should justify the segment expansion and clarify why it switches to a short, averaged cross-section rather than exploiting the longer panel that was originally feasible.

---

**Summary**

This paper studies whether the nine U.S. states that require families to hire a licensed funeral director for all body disposition tasks exhibit different death care market structure relative to adjacent non-mandate states. Using a border-discontinuity design across 800 county pairs (26 border segments), it finds no statistically or economically meaningful discontinuities in funeral home density, employment, firm size, payroll per worker, or crematory counts. The null result is interpreted as evidence that these mandatory licensing laws do not function primarily as entry barriers in local death care markets.

---

**Essential Points**

1. **Covariate imbalance undermines the identifying assumption.** Panel B of Table 2 reports a statistically significant discontinuity in total population across mandatory/non-mandatory borders (−43,495, SE 21,797). That imbalance is economically large relative to the treated counties and suggests that bordering counties differ systematically in market size, which could directly affect establishment counts and employment. The author needs to either show that the coefficient is robust to more flexible normalization—e.g., include county population in per-capita denominators, re-weight counties, or use a population-matched sample—or explain why the imbalance does not invalidate the smoothness assumption. In its current form, the “border-pair fixed effects + controls” specification may not be sufficient to purge the remaining population discontinuity from the estimation of the mandate effect.

2. **Averaging CBP over six years sacrifices both power and variation.** The manifest outlined an annual panel (1998–2022) and cross-border differences that could leverage repeated observations to increase precision. By collapsing the outcomes into a 2017–2022 average, the paper effectively reduces the sample to one observation per county, making the power problem described later even more acute and preventing the authors from probing pre-existing trends, temporal shocks, or lasting adjustments to the regulation. Please re-run the analysis in panel form (county-year) or at least justify why averaging is preferable (e.g., due to measurement noise) and explain how this choice affects the interpretation of the standard errors and null results.

3. **Statistical power is limited relative to the effect sizes documented in the licensing literature.** The reported minimum detectable effect (0.31 funeral homes per 10,000, i.e., ~43% of the mean) implies that the design is only sensitive to very large supply changes. Yet the discussion in the introduction frames the paper as testing entry-barrier effects comparable to the 5–18% price increases found in other licensing contexts. The authors should quantify the implied entry effect that corresponds to those price differences, demonstrate whether their design could reasonably detect such magnitudes, and, if not, qualify the policy conclusions accordingly. Right now the claims (“outcomes are statistically indistinguishable”) risk being overstated given the low power.

---

**Suggestions**

1. **Address the population imbalance more directly.** Re-estimate Table 1 and the main regressions using population-normalized weights or by pairing counties that are closer in population (e.g., Mahalanobis matching within each border segment). Alternatively, interacting the treatment with population size or including a fully flexible functional form in log population might ensure that the remaining discontinuity does not confound the mandate coefficient. Providing a scatter plot of the residualized outcome (after removing pair fixed effects) against the treatment indicator and county population could help convince readers that the treatment is not proxying for market size.

2. **Exploit the panel dimension of CBP.** If feasible, estimate the model on the full panel (2017–2022 or even earlier if data are accessible). This would allow for year fixed effects, cluster-robust standard errors with more time variation, and tests for pre-treatment trends that strengthen the causal claims even though the mandates are stable. Even a stacked-differences design with county-specific trends could reduce reliance on cross-sectional comparisons and increase precision.

3. **Enrich the outcome set with price or revenue proxies.** Since the policy concern is higher consumer prices, incorporate available proxies such as payroll per employee (already included) but also average establishment payroll (a proxy for revenue) or, if possible, direct cremation price data from consumer advocacy reports. Addressing the acknowledged limitation that CBP does not capture prices by using alternative sources (e.g., state consumer protection agencies) or even publicly available funeral home pricing surveys would move the discussion beyond market structure to consumer welfare—the heart of the licensing debate.

4. **Clarify the choice of border segments and treatment coding.** The manifest listed 22 unique segments, while the paper reports 26 segments. Provide a table that lists all segments, treatment states, and whether the border was included or dropped (with reasons, e.g., missing data). This transparency helps readers assess whether the segments cover the same regulatory contrast as advertised and avoids potential selection on borders that produce favorable nulls.

5. **Explore placebo outcomes and falsification tests.** Beyond the demographic covariates already shown, consider placebo treatments (e.g., randomly assign the mandate indicator within each segment) or placebo outcomes unrelated to funeral services to reassure readers that the estimation is not simply capturing noise. Spatial density of other service industries (e.g., florists, hospice care) could serve as such a placebo.

6. **Contextualize heterogeneous segments explicitly.** Table 3 shows considerable heterogeneity, with some borders exhibiting large positive and large negative point estimates. Instead of interpreting these as “noise,” investigate whether these differences correlate with observable features (urban/rural mix, degree of cremation penetration, presence of large chains). This could uncover mechanisms (e.g., mandates matter more where competitive pressure from chains is weak) and would turn what is now a complicated appendix table into a substantive contribution.

7. **Discuss treatment intensity and compliance.** Since the null is consistent with either non-binding regulation or with markets already equilibrated, it would help to provide evidence on the actual enforcement or utilization of home funerals. Surveys or qualitative evidence on the share of families attempting to do their own disposition could anchor the “non-binding” story and prevent readers from overgeneralizing the null.

By addressing these points, the paper would present a more nuanced and convincing case about what the null tells us regarding licensing in the death care sector.
