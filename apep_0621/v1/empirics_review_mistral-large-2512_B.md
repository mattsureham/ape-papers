# V1 Empirics Check — mistralai/mistral-large-2512 (Variant B)

**Model:** mistralai/mistral-large-2512
**Variant:** B
**Date:** 2026-03-13T10:43:54.784069

---

### 1. Idea Fidelity

The paper closely follows the original idea manifest. It uses the IPUMS MLP linked census panels (1910–1920 and 1920–1940) to estimate the population-level intent-to-treat (ITT) effects of mothers' pension (MP) laws on children's long-run occupational attainment, as proposed. The staggered difference-in-differences (DiD) design, state-level adoption cohorts, and key outcomes (SEI, occscore, child labor, schooling) align with the manifest. The paper also incorporates the suggested robustness checks (pre-trend tests, heterogeneity by race/sex, migration controls, placebo tests) and addresses the core identification challenge: selection into adoption timing.

Two minor deviations:
- The manifest proposed a Callaway-Sant'Anna estimator for staggered DiD, but the paper uses a simpler two-period DiD (1910–1920) and cross-sectional OLS (1940). This is defensible given the limited pre-periods (only 1910) and the focus on long-run outcomes, but the paper should justify this choice.
- The manifest emphasized general equilibrium effects (e.g., peer effects, school quality), but the paper does not explicitly test these mechanisms. The discussion of program reach (2% coverage) is a reasonable proxy, but the paper could more directly engage with the manifest’s hypothesis about spillovers.

### 2. Summary

This paper uses linked census data to estimate the population-level effects of mothers' pension laws (1911–1919) on children's long-run occupational attainment. While unconditional comparisons show large positive effects, these disappear after controlling for baseline state characteristics. The paper concludes that MPs—despite their symbolic importance—were too narrowly targeted (reaching <2% of families) to generate detectable population-level improvements in intergenerational mobility. The null ITT result contrasts with Aizer et al.’s (2016) positive LATE for recipients, highlighting the distinction between program efficacy and population impact.

### 3. Essential Points

**1. Justify the empirical strategy for staggered adoption.**
The paper uses a two-period DiD (1910–1920) and cross-sectional OLS (1940) instead of the manifest’s proposed Callaway-Sant'Anna estimator. While the simpler approach is reasonable, the paper must:
   - Acknowledge the trade-off: the two-period DiD assumes parallel trends only between 1910 and 1920, which is plausible but restrictive. The cross-sectional OLS relies entirely on controls for confounding.
   - Show that the results are robust to alternative estimators (e.g., event-study plots for the 1910–1920 panel, or a stacked DiD for the long-run outcomes). The placebo test (Table 7, column 1) suggests differential trends, so the paper should demonstrate that the controlled estimates are not sensitive to functional form.

**2. Address the North-South divide more rigorously.**
The paper’s preferred specification restricts to non-Southern states, but this is not a panacea. Southern states differed systematically in ways beyond MP adoption (e.g., Jim Crow laws, agricultural economies). The paper should:
   - Test whether the null result holds in a sample of *only* Southern states (even if underpowered). If the effect is also null there, it strengthens the claim that MPs had no population-level impact.
   - Include a triple-difference design (e.g., MP adoption × North/South × post) to formally test whether the effect differs by region. This would help rule out residual confounding from regional trends.

**3. Clarify the interpretation of the null result.**
The paper argues that the null ITT reflects low program coverage (2%), but this is an assumption, not a test. To strengthen the claim:
   - Estimate the implied population effect using Aizer et al.’s LATE and the paper’s coverage estimate (0.14 × 0.02 = 0.0028). Compare this to the paper’s confidence intervals to show that the null is consistent with the back-of-the-envelope calculation.
   - Test whether the effect is larger in states with higher MP take-up (e.g., using county-level data on recipients, if available). If the effect is still null even in high-coverage states, it suggests that coverage alone does not explain the result.

### 4. Suggestions

**Data and Measurement:**
- **Linkage quality:** The paper notes that MLP linkage rates are higher in Northern states, which could bias the raw comparisons. To address this:
  - Report linkage rates by state and show that the controlled estimates are robust to inverse-probability weighting (IPW) based on linkage rates.
  - Compare the MLP sample to the full-count census (e.g., 1940) to assess representativeness.
- **Outcome measurement:** SEI and occscore are noisy proxies for economic well-being. The paper should:
  - Include wage income (INCWAGE) from the 1940 full-count census as an additional outcome, if available.
  - Test whether the null holds for binary outcomes (e.g., top quartile of SEI), which may be less sensitive to measurement error.

**Empirical Strategy:**
- **Event-study plots:** For the 1910–1920 panel, plot coefficients for leads and lags of MP adoption (e.g., 1900, 1910, 1920) to visually assess pre-trends and dynamic effects. This would complement the placebo test.
- **Alternative controls:** The paper controls for baseline demographics, but other confounders may matter (e.g., urbanization, industrial composition, contemporaneous reforms like child labor laws). The paper should:
  - Include controls for state-level economic conditions (e.g., manufacturing employment share, per capita income) in 1910.
  - Test whether the results are robust to including state-specific linear trends (as suggested in the manifest).
- **Heterogeneity by generosity:** The manifest notes that MP benefits varied 7x across states. The paper should test whether the effect is larger in states with more generous benefits (e.g., using the ICPSR dataset’s benefit levels).

**Mechanisms:**
- **Schooling channel:** The paper finds no effect on 1930 school attendance, but this may miss earlier or later effects. The paper should:
  - Test whether MP exposure affected school attendance in 1920 (for the 1910–1920 panel) or 1940 (for the long-run panel).
  - Examine whether the effect on SEI is larger for children who attended school in 1930 (a proxy for the schooling channel).
- **General equilibrium effects:** The manifest hypothesized that MPs could improve school quality or reduce stigma. The paper should:
  - Test whether MP adoption is associated with changes in school spending or teacher-student ratios (using state-level education data).
  - Examine whether the effect on SEI is larger in counties with higher MP take-up (if county-level data are available).

**Presentation:**
- **Balance table:** The pre-treatment balance table (Table A1) is critical but buried in the appendix. Move it to the main text and:
  - Include a column for the F-statistic of joint significance for each cohort.
  - Add a row for the R² of a regression of MP adoption on 1910 covariates.
- **Standardized effects:** The standardized effect sizes (Table A4) are useful but should be interpreted more cautiously. The paper should:
  - Clarify that the "large positive" effects in the unconditional specifications are driven by selection, not causation.
  - Emphasize that the controlled SDEs are the relevant ones for policy.
- **Figures:** Add a figure showing the dose-response relationship between MP exposure and SEI, with and without controls. This would make the selection bias more intuitive.

**Discussion:**
- **External validity:** The paper should discuss whether the null result generalizes to other early welfare programs (e.g., ADC, Social Security) or to modern cash transfers (e.g., EITC, child allowances).
- **Policy implications:** The paper concludes that "scale matters," but this could be sharpened. For example:
  - What coverage threshold would be needed for MPs to generate detectable population effects? (Use the back-of-the-envelope calculation to estimate this.)
  - How does this compare to modern programs like TANF or SNAP, which have higher coverage?
- **Alternative explanations:** The paper should briefly discuss other potential explanations for the null result, such as:
  - Measurement error in SEI/occscore.
  - Attrition in the MLP data (e.g., if MP recipients were less likely to be linked).
  - Crowd-out of private transfers (e.g., if MPs replaced family support).

**Minor Issues:**
- The abstract and introduction emphasize the "4.8-point gap" in SEI, but this is misleading without immediately noting that it disappears with controls. Reorder the abstract to lead with the controlled result.
- The short-run DiD results (Table 2) are hard to interpret because the "child labor" variable in 1920 captures adult employment. The paper should clarify this upfront or exclude these results.
- The paper cites Chetty et al. (2014) on geographic mobility but does not engage with their findings on the role of early childhood environments. Discuss whether the null result is surprising in light of their work.
