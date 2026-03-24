# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant C)

**Model:** moonshotai/kimi-k2.5
**Variant:** C
**Date:** 2026-03-16T02:25:03.836682

---

 **Review of "Green Rush or Fools' Gold? Firm Dynamics and Labor Reallocation under Recreational Marijuana Legalization"**

---

### 1. Idea Fidelity

The paper substantially undershoots the research design articulated in the original manifest. The manifest promised a **county-quarter-industry-demographics** analysis using QWI's granular demographic cuts (sex×age, sex×education, race×ethnicity) to decompose effects across four dimensions including age heterogeneity and race/ethnicity gaps. The delivered paper uses **state-level aggregation**, drops all demographic heterogeneity despite having 452M+ rows of disaggregated data, and reduces the sample from 24 promised treated states to only 18 (with inconsistent reporting of 23 in Table 3). The "border county design" and "welfare test comparing earnings quality in gaining vs losing sectors" mentioned in the manifest are entirely absent. This represents a significant scope reduction that undermines the paper's novelty claims—without the demographic or geographic granularity, this becomes a standard state-level DiD paper with QWI rather than QCEW data.

---

### 2. Summary

This paper estimates the labor market effects of recreational marijuana legalization using the Callaway-Sant'Anna staggered difference-in-differences estimator on Quarterly Workforce Indicators (QWI) data. The authors find that legalization increases aggregate state employment by 2.5% but show that net firm-level job creation (establishment entry/expansion minus exit/contraction) is statistically indistinguishable from zero. The interpretation is that employment grows through the intensive margin (existing firms expanding) rather than an entrepreneurial "green rush" of new firm creation, likely due to regulatory barriers to entry.

---

### 3. Essential Points

**1. Standard errors and inference with few treated clusters are unreliable.** With only 18 treated states and state-clustered standard errors, the effective sample size for inference is dangerously small. The CS-DiD estimator requires careful handling with few treated units, yet the paper reports tight confidence intervals (e.g., [0.3%, 4.7%] for the main employment effect) that seem implausibly precise given the cluster size. The critical failure is the **healthcare placebo**: Table 4 shows a significant 5.5% effect on healthcare employment (NAICS 62), which should be unaffected by cannabis policy. This suggests either pre-trend violations, coincident policy shocks (e.g., Medicaid expansion), or insufficient cluster adjustment. The pre-trend Wald test ($p=0.43$) is underpowered with this sample size and cannot compensate for a failed placebo.

**2. The paper promises demographic heterogeneity analysis but delivers none.** The abstract, introduction, and manifest all emphasize decomposing effects by age, education, and race/ethnicity. These results are entirely absent from the paper despite the QWI data being explicitly constructed for this purpose (the manifest lists 185M rows of sex×age data and 144M rows of race×ethnicity data). This omission is particularly problematic given the policy interest in social equity and labor market disparities in cannabis legalization.

**3. The interpretation of "intensive margin" vs. "extensive margin" is unsupported.** The QWI measures *all* firm dynamics, not cannabis-specific ones. The null result on net firm job creation (FrmJbGn – FrmJbLs) conflates cannabis firms (which are likely entering) with non-cannabis firms (which may be exiting due to displacement). Without a cannabis-specific NAICS code, the decomposition cannot distinguish between "existing firms hiring more" and "new cannabis firms entering while other firms exit." The intensive margin interpretation requires assuming zero displacement, which is untested.

---

### 4. Suggestions

**Data and Sample:**
- **Use county-level variation.** The manifest correctly identified that QWI provides county-quarter granularity (~6.7M cells). State-level aggregation discards 99% of the variation and makes the design vulnerable to state-level confounders (e.g., minimum wage changes, Medicaid expansion). A border-county design (as promised) would address the healthcare placebo failure by comparing contiguous counties across state borders.
- **Include the full 24-state sample.** The paper drops Alaska, DC, Massachusetts, Michigan, and Missouri due to "incomplete coverage" but does not explain why these specific states lack data or whether the sample selection is correlated with treatment effects. If QWI coverage is incomplete for early legalizers like Massachusetts and Michigan, this induces selection bias toward states with different administrative capacities.

**Demographic Analysis:**
- **Deliver the promised heterogeneity.** The paper should include the age×industry and race×industry decompositions from the manifest. Cannabis employment skews young and has differential impacts by race due to licensing barriers. The QWI's demographic cuts (sex×age, race×ethnicity) are the unique contribution here—without them, the paper is redundant with Nicholas-Halteman & Sabia (2023/2025).
- **Report demographic-specific firm dynamics.** If young workers or Black workers are being pulled into the cannabis sector, this should appear in demographic-specific job creation flows.

**Identification and Robustness:**
- **Address the healthcare placebo failure.** A 5.5% significant effect on healthcare is a red flag. The authors should test for Medicaid expansion timing, ACA implementation, or other healthcare reforms that coincide with legalization waves. If these cannot be separated, the causal interpretation is compromised.
- **Report event-study plots, not just Wald tests.** The Wald test for pre-trends has low power. Visual event-study coefficients would reveal whether the healthcare sector shows differential pre-trends that invalidate the parallel trends assumption.
- **Use Borusyak et al. (2024) imputation estimator as robustness.** With few treated clusters, the CS-DiD may be sensitive to weighting choices. The imputation estimator provides efficient inference under staggered adoption and may yield different standard errors.

**Interpretation:**
- **Clarify the mechanism.** The claim that "employment growth operates through the intensive margin" requires showing that FrmJbGn (firm job gains) increased specifically at *existing* firms, not that net firm creation is zero. The current decomposition cannot distinguish between (a) incumbent expansion and (b) offsetting entry/exit across sectors. Use industry-specific firm dynamics (retail vs. agriculture) to sharpen this.
- **Report cannabis-specific employment indirectly.** While NAICS lacks a cannabis code, the paper could use high-resolution QWI industry codes (6-digit) or crosswalk with BLS experimental cannabis employment estimates to validate that the retail/agriculture effects align with known dispensary/cultivation locations.

**Presentation:**
- **Remove or relocate Table A.1 (Standardized Effect Sizes).** This table uses arbitrary thresholds ("Small positive," "Large positive") that lack economic interpretation. The SDE calculation for levels variables (Net Firm Job Creation) is misleading given the skewed distribution of job flows.
- **Fix inconsistencies.** Table 1 reports 18 treated states; Table 3 reports 23. The text mentions 24 legalizing states but the sample includes only 18. Clarify whether DC and the 2023 cohort (DE, MN, OH) are excluded and why.

**Recommendation:** The paper should be **revise and resubmit** only if the authors (1) move to county-level analysis with border discontinuity designs, (2) include the promised demographic heterogeneity, and (3) resolve the healthcare placebo failure through explicit controls for concurrent health policy changes. Without these changes, the causal identification is too fragile for an AER: Insights publication.
