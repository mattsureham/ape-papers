# Reply to Reviewers

## Reviewer 1 (GPT-5.4 R1) — MAJOR REVISION

### 1. Fiscal mechanism not identified
**Concern:** The paper attributes the null to fiscal policy, but the design does not identify fiscal policy separately from mild weather, adaptation, or conservation.
**Response:** Agreed. We have reframed the paper throughout. The abstract, introduction, discussion, and conclusion now present fiscal policy as "one plausible explanation among several, including mild weather and household conservation." The paper's core contribution is documenting the null, not proving the mechanism.

### 2. "Precise zero" language overstated
**Concern:** The 95% CI of [-0.36, 1.28] does not support "precise zero" claims.
**Response:** Agreed. We have replaced all instances of "precise zero" with "no statistically detectable increase" and now report the 95% CI explicitly in the abstract and results section. Language like "unambiguously no" has been softened to "no, at least within detectable bounds."

### 3. Parallel trends evidence weaker than stated
**Concern:** The event study has few pre-periods, and winter 2015/16 is marginally significant.
**Response:** We have changed "flat pre-trends" to "pre-trends broadly consistent with the parallel trends assumption" throughout. We acknowledge the 2015/16 coefficient and the limited number of pre-periods as limitations.

### 4. Summer placebo interpretation
**Concern:** The summer placebo (p = 0.07) is not a "clean" placebo.
**Response:** We now explicitly acknowledge that "near-significance at the 10% level warrants caution" and note it "could reflect a correlated seasonal channel or simply noise." We retain the observation that the sign is inconsistent with any heating channel.

### 5. Winter-specific estimates requested
**Concern:** Pooling 2022/23 through 2024/25 may dilute the estimand.
**Response:** The event study (Figure 2) already reports winter-specific coefficients: 2022/23 = 0.39 (SE = 0.76), 2023/24 = -0.53 (SE = 0.76), 2024/25 = -0.35 (SE = 0.80). All are null. The pooled estimate is appropriate given no evidence of dynamic treatment effects.

### 6. Additional controls requested
**Concern:** Post × baseline covariates, excluding regional blocs, etc.
**Response:** We include HDD controls (Column 2), leave-one-out analysis (Figure 4), and the heterogeneity split. Adding further controls is a valuable suggestion for future work but is beyond the scope of the current revision given data availability constraints.

---

## Reviewer 2 (GPT-5.4 R2) — REJECT AND RESUBMIT

### 1. Design does not isolate fiscal mechanism
**Response:** Same as R1 point 1. Fully addressed — fiscal claims reframed as one plausible explanation.

### 2. Parallel trends not convincing
**Response:** Same as R1 point 3. Language softened throughout.

### 3. Treatment proxy is coarse
**Concern:** Country-level gas dependence is a crude proxy for household heating exposure.
**Response:** This is a valid limitation. The heterogeneity analysis (Table 5) and the gas-heating interaction (spec 6) attempt to address this. We now discuss the coarseness of the treatment proxy more explicitly in the limitations section.

### 4. Country-specific trends
**Concern:** Need sensitivity to country-specific trends.
**Response:** The event study with country FE and year-week FE already absorbs substantial variation. Country-specific linear trends would consume degrees of freedom with only 26 clusters. We acknowledge this as a limitation.

### 5. Age-specific analysis uses raw counts
**Concern:** Raw death counts rather than rates limit interpretability.
**Response:** We have clarified throughout that the age-specific regressions use raw weekly death counts and that coefficients represent additional deaths per week per unit of gas dependence. We explicitly note that magnitudes are not comparable across age groups.

### 6. Power and MDE discussion
**Concern:** Need formal minimum detectable effect analysis.
**Response:** The 95% CI is now reported prominently. The upper bound of 1.28 deaths/100k/week is acknowledged as "meaningful in absolute terms" in the limitations section.

---

## Reviewer 3 (Gemini-3-Flash) — MINOR REVISION

### 1. Age-specific population weights
**Concern:** Raw death counts weight large countries heavily.
**Response:** Acknowledged as a limitation. We now clearly describe the dependent variable as raw weekly death counts throughout.

### 2. HICP vs wholesale prices
**Concern:** Comparing TTF wholesale prices to HICP would strengthen the fiscal story.
**Response:** A valuable suggestion for future work. The current first stage using HICP (which includes subsidy effects) shows the net household exposure, which is the relevant quantity for the mortality channel.

### 3. Cause-specific mortality
**Concern:** Respiratory/cardiovascular mortality would be a stronger mechanism test.
**Response:** Eurostat weekly data is all-cause only. Cause-specific data at weekly frequency is not available for the full cross-section. This is noted as a limitation.
